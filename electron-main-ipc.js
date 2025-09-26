const { app, BrowserWindow, Menu, ipcMain } = require('electron');
const path = require('path');
const fs = require('fs').promises;
const os = require('os');

let mainWindow;

// Helper functions
const getDefaultConfigPath = () => {
    return path.join(os.homedir(), '.claude.json');
};

const getProfilesDir = () => {
    return path.join(os.homedir(), '.mcp-manager', 'profiles');
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
ipcMain.handle('get-config-path', () => {
    return getDefaultConfigPath();
});

ipcMain.handle('get-config', async (event, configPath) => {
    const targetPath = configPath || getDefaultConfigPath();

    try {
        const data = await fs.readFile(targetPath, 'utf8');
        const config = JSON.parse(data);
        const mcpServers = config.mcpServers || {};

        return {
            success: true,
            servers: mcpServers,
            fullConfig: config
        };
    } catch (error) {
        if (error.code === 'ENOENT') {
            return {
                success: true,
                servers: {},
                fullConfig: { mcpServers: {} },
                isNew: true
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
    const targetPath = configPath || getDefaultConfigPath();

    try {
        let config;
        try {
            const data = await fs.readFile(targetPath, 'utf8');
            config = JSON.parse(data);
        } catch (error) {
            config = {};
        }

        config.mcpServers = servers;
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
    const targetPath = configPath || getDefaultConfigPath();

    try {
        let config;
        try {
            const data = await fs.readFile(targetPath, 'utf8');
            config = JSON.parse(data);
        } catch (error) {
            config = {};
        }

        if (!config.mcpServers) {
            config.mcpServers = {};
        }

        config.mcpServers[name] = serverConfig;
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
    const targetPath = configPath || getDefaultConfigPath();

    try {
        const data = await fs.readFile(targetPath, 'utf8');
        const config = JSON.parse(data);

        if (config.mcpServers && config.mcpServers[name]) {
            delete config.mcpServers[name];
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

ipcMain.handle('save-profile', async (event, name, servers) => {
    await ensureProfilesDir();
    const profilePath = path.join(getProfilesDir(), `${name}.json`);

    try {
        await fs.writeFile(profilePath, JSON.stringify(servers, null, 2));
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

    // Load the HTML file directly
    mainWindow.loadFile(path.join(__dirname, 'public', 'index.html'));

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