const express = require('express');
const fs = require('fs').promises;
const path = require('path');
const os = require('os');

const app = express();
const PORT = 3000;

app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

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

app.get('/api/config-path', (req, res) => {
    res.json({ path: getDefaultConfigPath() });
});

app.get('/api/config', async (req, res) => {
    const configPath = req.query.path || getDefaultConfigPath();

    try {
        const data = await fs.readFile(configPath, 'utf8');
        const config = JSON.parse(data);

        const mcpServers = config.mcpServers || {};

        res.json({
            success: true,
            servers: mcpServers,
            fullConfig: config
        });
    } catch (error) {
        if (error.code === 'ENOENT') {
            res.json({
                success: true,
                servers: {},
                fullConfig: { mcpServers: {} },
                isNew: true
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
        let config;
        try {
            const data = await fs.readFile(targetPath, 'utf8');
            config = JSON.parse(data);
        } catch (error) {
            config = {};
        }

        config.mcpServers = servers;

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

        if (config.mcpServers && config.mcpServers[name]) {
            delete config.mcpServers[name];
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
        const profile = JSON.parse(data);
        res.json({ success: true, servers: profile });
    } catch (error) {
        res.status(404).json({
            success: false,
            error: 'Profile not found'
        });
    }
});

app.post('/api/profile', async (req, res) => {
    const { name, servers } = req.body;
    await ensureProfilesDir();
    const profilePath = path.join(getProfilesDir(), `${name}.json`);

    try {
        await fs.writeFile(profilePath, JSON.stringify(servers, null, 2));
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

function startServer() {
    return new Promise((resolve) => {
        app.listen(PORT, () => {
            console.log(`MCP Server Manager running at http://localhost:${PORT}`);
            resolve();
        });
    });
}

module.exports = { startServer };