const { app, BrowserWindow, Menu, ipcMain } = require('electron');
const path = require('path');
const fs = require('fs').promises;
const os = require('os');

let mainWindow;

const isDev = !app.isPackaged;
const rendererDistPath = path.join(__dirname, 'renderer', 'dist');
const rendererIndexPath = path.join(rendererDistPath, 'index.html');
const devServerUrl = process.env.VITE_DEV_SERVER_URL || process.env.ELECTRON_RENDERER_URL;
const REGISTRY_BASE_URL = 'https://registry.modelcontextprotocol.io';

// Helper functions
const getDefaultConfigPath = (configType = 'copilot') => {
    if (configType === 'copilot') {
        return path.join(process.cwd(), '.vscode', 'mcp.json');
    }
    return path.join(os.homedir(), '.claude.json');
};

const detectConfigType = (configPath) => {
    if (configPath && (configPath.includes('.vscode/mcp.json') || configPath.endsWith('mcp.json'))) {
        return 'copilot';
    }
    return 'claude';
};

const getProfilesDir = () => {
    return path.join(os.homedir(), '.mcp-manager', 'profiles');
};

const getGlobalConfigsPath = () => {
    return path.join(os.homedir(), '.mcp-manager', 'global-configs.json');
};

const ensureProfilesDir = async () => {
    const dir = getProfilesDir();
    try {
        await fs.mkdir(path.dirname(dir), { recursive: true });
        await fs.mkdir(dir, { recursive: true });
    } catch (error) {
        console.error('Error creating profiles directory:', error);
    }
};

// IPC Handlers
ipcMain.handle('get-config-path', (event, configType) => {
    return getDefaultConfigPath(configType);
});

ipcMain.handle('get-config', async (event, configPath) => {
    let targetPath = configPath || getDefaultConfigPath();

    // Expand tilde to home directory
    if (targetPath && targetPath.startsWith('~/')) {
        targetPath = path.join(os.homedir(), targetPath.slice(2));
    }

    try {
        const data = await fs.readFile(targetPath, 'utf8');
        const config = JSON.parse(data);
        const configType = detectConfigType(targetPath);

        let servers = {};
        if (configType === 'copilot') {
            // Convert Copilot format to Claude format for internal use
            servers = config.servers || {};
        } else {
            servers = config.mcpServers || {};
        }

        return {
            success: true,
            servers: servers,
            fullConfig: config,
            configType: configType
        };
    } catch (error) {
        if (error.code === 'ENOENT') {
            const configType = detectConfigType(targetPath);
            const emptyConfig = configType === 'copilot'
                ? { inputs: [], servers: {} }
                : { mcpServers: {} };

            return {
                success: true,
                servers: {},
                fullConfig: emptyConfig,
                isNew: true,
                configType: configType
            };
        } else {
            return {
                success: false,
                error: error.message
            };
        }
    }
});

ipcMain.handle('save-config', async (event, servers, configPath) => {
    let targetPath = configPath || getDefaultConfigPath();

    // Expand tilde to home directory
    if (targetPath && targetPath.startsWith('~/')) {
        targetPath = path.join(os.homedir(), targetPath.slice(2));
    }

    try {
        const configType = detectConfigType(targetPath);
        let config;

        try {
            const data = await fs.readFile(targetPath, 'utf8');
            config = JSON.parse(data);
        } catch (error) {
            // Initialize with appropriate structure based on config type
            config = configType === 'copilot'
                ? { inputs: [{ type: "promptString" }], servers: {} }
                : {};
        }

        // Update the appropriate field based on config type
        if (configType === 'copilot') {
            config.servers = servers;
            // Ensure inputs array exists
            if (!config.inputs) {
                config.inputs = [{ type: "promptString" }];
            }
        } else {
            config.mcpServers = servers;
        }

        // Create directory if it doesn't exist (for Copilot .vscode folder)
        const dir = path.dirname(targetPath);
        await fs.mkdir(dir, { recursive: true });

        await fs.writeFile(targetPath, JSON.stringify(config, null, 2));

        return { success: true };
    } catch (error) {
        return {
            success: false,
            error: error.message
        };
    }
});

ipcMain.handle('add-server', async (event, name, serverConfig, configPath) => {
    let targetPath = configPath || getDefaultConfigPath();

    // Expand tilde to home directory
    if (targetPath && targetPath.startsWith('~/')) {
        targetPath = path.join(os.homedir(), targetPath.slice(2));
    }

    try {
        const configType = detectConfigType(targetPath);
        let config;

        try {
            const data = await fs.readFile(targetPath, 'utf8');
            config = JSON.parse(data);
        } catch (error) {
            config = configType === 'copilot'
                ? { inputs: [{ type: "promptString" }], servers: {} }
                : {};
        }

        // Add server based on config type
        if (configType === 'copilot') {
            if (!config.servers) {
                config.servers = {};
            }
            config.servers[name] = serverConfig;
        } else {
            if (!config.mcpServers) {
                config.mcpServers = {};
            }
            config.mcpServers[name] = serverConfig;
        }

        // Create directory if it doesn't exist
        const dir = path.dirname(targetPath);
        await fs.mkdir(dir, { recursive: true });

        await fs.writeFile(targetPath, JSON.stringify(config, null, 2));

        return { success: true };
    } catch (error) {
        return {
            success: false,
            error: error.message
        };
    }
});

ipcMain.handle('delete-server', async (event, name, configPath) => {
    let targetPath = configPath || getDefaultConfigPath();

    // Expand tilde to home directory
    if (targetPath && targetPath.startsWith('~/')) {
        targetPath = path.join(os.homedir(), targetPath.slice(2));
    }

    try {
        const data = await fs.readFile(targetPath, 'utf8');
        const config = JSON.parse(data);
        const configType = detectConfigType(targetPath);

        let deleted = false;
        if (configType === 'copilot') {
            if (config.servers && config.servers[name]) {
                delete config.servers[name];
                deleted = true;
            }
        } else {
            if (config.mcpServers && config.mcpServers[name]) {
                delete config.mcpServers[name];
                deleted = true;
            }
        }

        if (deleted) {
            await fs.writeFile(targetPath, JSON.stringify(config, null, 2));
            return { success: true };
        } else {
            return {
                success: false,
                error: 'Server not found'
            };
        }
    } catch (error) {
        return {
            success: false,
            error: error.message
        };
    }
});

ipcMain.handle('get-profiles', async () => {
    await ensureProfilesDir();
    const profilesDir = getProfilesDir();

    try {
        const files = await fs.readdir(profilesDir);
        const profiles = files
            .filter(f => f.endsWith('.json'))
            .map(f => f.replace('.json', ''));

        return { success: true, profiles };
    } catch (error) {
        return { success: true, profiles: [] };
    }
});

ipcMain.handle('get-profile', async (event, name) => {
    const profilePath = path.join(getProfilesDir(), `${name}.json`);

    try {
        const data = await fs.readFile(profilePath, 'utf8');
        const profile = JSON.parse(data);
        return { success: true, servers: profile };
    } catch (error) {
        return {
            success: false,
            error: 'Profile not found'
        };
    }
});

ipcMain.handle('save-profile', async (event, name, enabledServerNames) => {
    await ensureProfilesDir();
    const profilePath = path.join(getProfilesDir(), `${name}.json`);

    try {
        // Profile now just stores array of enabled server names
        await fs.writeFile(profilePath, JSON.stringify(enabledServerNames, null, 2));
        return { success: true };
    } catch (error) {
        return {
            success: false,
            error: error.message
        };
    }
});

ipcMain.handle('delete-profile', async (event, name) => {
    const profilePath = path.join(getProfilesDir(), `${name}.json`);

    try {
        await fs.unlink(profilePath);
        return { success: true };
    } catch (error) {
        return {
            success: false,
            error: error.message
        };
    }
});

// Global configs handlers
ipcMain.handle('get-global-configs', async () => {
    const globalPath = getGlobalConfigsPath();

    try {
        const data = await fs.readFile(globalPath, 'utf8');
        return { success: true, configs: JSON.parse(data) };
    } catch (error) {
        if (error.code === 'ENOENT') {
            return { success: true, configs: {} };
        }
        return { success: false, error: error.message };
    }
});

ipcMain.handle('save-global-configs', async (event, configs) => {
    const globalPath = getGlobalConfigsPath();

    try {
        // Ensure the .mcp-manager directory exists
        await fs.mkdir(path.dirname(globalPath), { recursive: true });
        await fs.writeFile(globalPath, JSON.stringify(configs, null, 2));
        return { success: true };
    } catch (error) {
        return { success: false, error: error.message };
    }
});

ipcMain.handle('fetch-registry', async (event, options = {}) => {
    const url = new URL('/v0/servers', REGISTRY_BASE_URL);

    if (options.limit) {
        url.searchParams.set('limit', String(options.limit));
    }

    if (options.cursor) {
        url.searchParams.set('cursor', options.cursor);
    }

    if (options.query) {
        url.searchParams.set('query', options.query);
    }

    const response = await fetch(url.toString(), { headers: { Accept: 'application/json' } });

    if (!response.ok) {
        throw new Error(`Registry request failed with status ${response.status}`);
    }

    return response.json();
});

function createWindow() {
    mainWindow = new BrowserWindow({
        width: 1200,
        height: 800,
        webPreferences: {
            preload: path.join(__dirname, 'preload.js'),
            contextIsolation: true,
            nodeIntegration: false
        },
        icon: path.join(__dirname, 'assets', 'icon.png'),
        title: 'MCP Server Manager'
    });

    if (isDev && devServerUrl) {
        mainWindow.loadURL(devServerUrl);
    } else {
        mainWindow.loadFile(rendererIndexPath);
    }

    // Create application menu
    const template = [
        {
            label: 'MCP Manager',
            submenu: [
                { label: 'About MCP Manager', role: 'about' },
                { type: 'separator' },
                { label: 'Quit', accelerator: 'Command+Q', click: () => app.quit() }
            ]
        },
        {
            label: 'Edit',
            submenu: [
                { label: 'Undo', accelerator: 'Command+Z', role: 'undo' },
                { label: 'Redo', accelerator: 'Shift+Command+Z', role: 'redo' },
                { type: 'separator' },
                { label: 'Cut', accelerator: 'Command+X', role: 'cut' },
                { label: 'Copy', accelerator: 'Command+C', role: 'copy' },
                { label: 'Paste', accelerator: 'Command+V', role: 'paste' },
                { label: 'Select All', accelerator: 'Command+A', role: 'selectall' }
            ]
        },
        {
            label: 'View',
            submenu: [
                { label: 'Reload', accelerator: 'Command+R', click: () => mainWindow.reload() },
                { label: 'Toggle Developer Tools', accelerator: 'Alt+Command+I', click: () => mainWindow.webContents.toggleDevTools() }
            ]
        }
    ];

    const menu = Menu.buildFromTemplate(template);
    Menu.setApplicationMenu(menu);

    mainWindow.on('closed', () => {
        mainWindow = null;
    });
}

app.whenReady().then(createWindow);

app.on('window-all-closed', () => {
    if (process.platform !== 'darwin') {
        app.quit();
    }
});

app.on('activate', () => {
    if (mainWindow === null) {
        createWindow();
    }
});
