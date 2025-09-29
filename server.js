const express = require('express');
const fs = require('fs').promises;
const { existsSync } = require('fs');
const path = require('path');
const os = require('os');
const open = require('open');

const app = express();
const PORT = 3000;

const REGISTRY_BASE_URL = 'https://registry.modelcontextprotocol.io';

const rendererDistPath = path.join(__dirname, 'renderer', 'dist');
const rendererIndexPath = path.join(rendererDistPath, 'index.html');
const hasRendererBuild = existsSync(rendererIndexPath);

if (!hasRendererBuild) {
    console.warn('Renderer build not found at', rendererIndexPath, '\nRun "npm run build:renderer" or start the Vite dev server.');
}

app.use(express.json());
if (hasRendererBuild) {
    app.use(express.static(rendererDistPath));
}

app.use('/registry', async (req, res) => {
    if (req.method !== 'GET') {
        res.status(405).json({ success: false, error: 'Method not allowed' });
        return;
    }

    const targetUrl = `${REGISTRY_BASE_URL}${req.originalUrl.replace(/^\/registry/, '')}`;

    try {
        const response = await fetch(targetUrl, { headers: { Accept: req.get('accept') || 'application/json' } });
        const body = await response.text();

        res.status(response.status);
        const contentType = response.headers.get('content-type');
        if (contentType) {
            res.set('content-type', contentType);
        }

        res.send(body);
    } catch (error) {
        res.status(502).json({ success: false, error: error.message });
    }
});

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

app.get('/api/config-path', (req, res) => {
    const configType = req.query.type || 'copilot';
    res.json({ path: getDefaultConfigPath(configType) });
});

app.get('/api/config', async (req, res) => {
    const configPath = req.query.path || getDefaultConfigPath();

    try {
        const data = await fs.readFile(configPath, 'utf8');
        const config = JSON.parse(data);
        const configType = detectConfigType(configPath);

        let servers = {};
        if (configType === 'copilot') {
            // Convert Copilot format to Claude format for internal use
            servers = config.servers || {};
        } else {
            servers = config.mcpServers || {};
        }

        res.json({
            success: true,
            servers: servers,
            fullConfig: config,
            configType: configType
        });
    } catch (error) {
        if (error.code === 'ENOENT') {
            const configType = detectConfigType(configPath);
            const emptyConfig = configType === 'copilot'
                ? { inputs: [], servers: {} }
                : { mcpServers: {} };

            res.json({
                success: true,
                servers: {},
                fullConfig: emptyConfig,
                isNew: true,
                configType: configType
            });
        } else {
            res.status(500).json({
                success: false,
                error: error.message
            });
        }
    }
});

app.post('/api/config', async (req, res) => {
    const { servers, configPath } = req.body;
    const targetPath = configPath || getDefaultConfigPath();

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

        res.json({ success: true });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

app.post('/api/server', async (req, res) => {
    const { name, config: serverConfig, configPath } = req.body;
    const targetPath = configPath || getDefaultConfigPath();

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

        res.json({ success: true });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

app.delete('/api/server/:name', async (req, res) => {
    const { name } = req.params;
    const configPath = req.query.path || getDefaultConfigPath();

    try {
        const data = await fs.readFile(configPath, 'utf8');
        const config = JSON.parse(data);
        const configType = detectConfigType(configPath);

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
            await fs.writeFile(configPath, JSON.stringify(config, null, 2));
            res.json({ success: true });
        } else {
            res.status(404).json({
                success: false,
                error: 'Server not found'
            });
        }
    } catch (error) {
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

app.get('/api/profiles', async (req, res) => {
    await ensureProfilesDir();
    const profilesDir = getProfilesDir();

    try {
        const files = await fs.readdir(profilesDir);
        const profiles = files
            .filter(f => f.endsWith('.json'))
            .map(f => f.replace('.json', ''));

        res.json({ success: true, profiles });
    } catch (error) {
        res.json({ success: true, profiles: [] });
    }
});

app.get('/api/profile/:name', async (req, res) => {
    const { name } = req.params;
    const profilePath = path.join(getProfilesDir(), `${name}.json`);

    try {
        const data = await fs.readFile(profilePath, 'utf8');
        const enabledServerNames = JSON.parse(data);
        res.json({ success: true, enabledServerNames });
    } catch (error) {
        res.status(404).json({
            success: false,
            error: 'Profile not found'
        });
    }
});

app.post('/api/profile', async (req, res) => {
    const { name, enabledServerNames } = req.body;
    await ensureProfilesDir();
    const profilePath = path.join(getProfilesDir(), `${name}.json`);

    try {
        // Profile now just stores array of enabled server names
        await fs.writeFile(profilePath, JSON.stringify(enabledServerNames, null, 2));
        res.json({ success: true });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

app.delete('/api/profile/:name', async (req, res) => {
    const { name } = req.params;
    const profilePath = path.join(getProfilesDir(), `${name}.json`);

    try {
        await fs.unlink(profilePath);
        res.json({ success: true });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// Global configs routes
app.get('/api/global-configs', async (req, res) => {
    const globalPath = getGlobalConfigsPath();

    try {
        const data = await fs.readFile(globalPath, 'utf8');
        res.json({ success: true, configs: JSON.parse(data) });
    } catch (error) {
        if (error.code === 'ENOENT') {
            res.json({ success: true, configs: {} });
        } else {
            res.status(500).json({ success: false, error: error.message });
        }
    }
});

app.post('/api/global-configs', async (req, res) => {
    const { configs } = req.body;
    const globalPath = getGlobalConfigsPath();

    try {
        // Ensure the .mcp-manager directory exists
        await fs.mkdir(path.dirname(globalPath), { recursive: true });
        await fs.writeFile(globalPath, JSON.stringify(configs, null, 2));
        res.json({ success: true });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

// React renderer fallback routes
app.get('/', (req, res) => {
    if (!hasRendererBuild) {
        res.status(500).send('Renderer build not found. Run "npm run build:renderer" or start the Vite dev server.');
        return;
    }
    res.sendFile(rendererIndexPath);
});

app.get('*', (req, res, next) => {
    if (req.path.startsWith('/api')) {
        return next();
    }

    if (!hasRendererBuild) {
        res.status(500).send('Renderer build not found. Run "npm run build:renderer" or start the Vite dev server.');
        return;
    }

    res.sendFile(rendererIndexPath);
});

app.listen(PORT, async () => {
    console.log(`MCP Server Manager running at http://localhost:${PORT}`);

    // Only open browser if not running in Electron
    if (!process.env.ELECTRON_APP) {
        console.log('Opening in browser...');
        await open(`http://localhost:${PORT}`);
    }
});
