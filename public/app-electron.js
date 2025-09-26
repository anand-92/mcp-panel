let currentConfigPath = '';
let globalServerConfigs = {}; // All server configurations
let currentProfile = []; // Array of enabled server names for current profile
let currentProfileName = ''; // Name of currently loaded profile

// Check if running in Electron
const isElectron = window.api !== undefined;

async function init() {
    await loadConfigPath();
    await loadGlobalConfigs();
    await loadCurrentServers(); // Load from Claude config to populate global configs (respects manual changes)
    await loadProfiles();
    setupEventListeners();

    // Auto-refresh every 30 seconds to detect manual changes
    setInterval(async () => {
        const oldProfileLength = currentProfile.length;
        const oldGlobalCount = Object.keys(globalServerConfigs).length;
        await loadCurrentServers();

        // Only show notification if there were actual changes
        if (currentProfile.length !== oldProfileLength || Object.keys(globalServerConfigs).length !== oldGlobalCount) {
            console.log('Auto-refresh detected changes in Claude config');
        }
    }, 30000);
}

async function loadConfigPath() {
    try {
        if (isElectron) {
            currentConfigPath = await window.api.getConfigPath();
        } else {
            const response = await fetch('/api/config-path');
            const data = await response.json();
            currentConfigPath = data.path;
        }
        document.getElementById('configPath').value = currentConfigPath;
    } catch (error) {
        showToast('Error loading config path', 'error');
    }
}

async function loadGlobalConfigs() {
    try {
        let data;
        if (isElectron) {
            data = await window.api.getGlobalConfigs();
        } else {
            const response = await fetch('/api/global-configs');
            data = await response.json();
        }

        if (data.success) {
            globalServerConfigs = data.configs || {};
        }
    } catch (error) {
        console.error('Error loading global configs:', error);
        globalServerConfigs = {};
    }
}

async function saveGlobalConfigs() {
    try {
        let data;
        if (isElectron) {
            data = await window.api.saveGlobalConfigs(globalServerConfigs);
        } else {
            const response = await fetch('/api/global-configs', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ configs: globalServerConfigs })
            });
            data = await response.json();
        }

        if (!data.success) {
            console.error('Error saving global configs:', data.error);
        }
    } catch (error) {
        console.error('Error saving global configs:', error);
    }
}

async function loadCurrentServers() {
    try {
        let data;
        if (isElectron) {
            data = await window.api.getConfig(currentConfigPath);
        } else {
            const response = await fetch(`/api/config?path=${encodeURIComponent(currentConfigPath)}`);
            data = await response.json();
        }

        if (data.success) {
            // Always merge servers from Claude config into global configs (including new manual additions)
            let hasNewServers = false;
            for (const [name, config] of Object.entries(data.servers)) {
                if (!globalServerConfigs[name]) {
                    globalServerConfigs[name] = config;
                    hasNewServers = true;
                    console.log(`Detected new server in Claude config: ${name}`);
                }
            }

            // Set current profile to enabled servers from Claude config (respecting manual changes)
            currentProfile = Object.keys(data.servers);

            // Only save global configs if we found new servers
            if (hasNewServers) {
                await saveGlobalConfigs();
                showToast('Detected new servers in Claude config', 'info');
            }

            renderServers();

            if (data.isNew) {
                showToast('No config file found. A new one will be created when you save.', 'info');
            }
        } else {
            showToast('Error loading servers: ' + data.error, 'error');
        }
    } catch (error) {
        showToast('Error loading servers', 'error');
    }
}

function renderServers() {
    const serversList = document.getElementById('serversList');
    serversList.innerHTML = '';

    if (Object.keys(globalServerConfigs).length === 0) {
        serversList.innerHTML = '<p class="no-servers">No servers configured. Click "+ Add Server" to get started.</p>';
        return;
    }

    // Show all servers from global configs, with enablement based on current profile
    for (const [name, config] of Object.entries(globalServerConfigs)) {
        const isEnabled = currentProfile.includes(name);
        const serverCard = createServerCard(name, config, isEnabled);
        serversList.appendChild(serverCard);
    }
}

function syntaxHighlightJSON(json) {
    if (typeof json !== 'string') {
        json = JSON.stringify(json, null, 2);
    }

    return json.replace(/("(\\u[a-fA-F0-9]{4}|\\[^u]|[^\\"])*"(\s*:)?|\b(true|false|null)\b|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?)/g,
        function (match) {
            let cls = 'json-number';
            if (/^"/.test(match)) {
                if (/:$/.test(match)) {
                    cls = 'json-key';
                } else {
                    cls = 'json-string';
                }
            } else if (/true|false/.test(match)) {
                cls = 'json-boolean';
            } else if (/null/.test(match)) {
                cls = 'json-null';
            }
            return '<span class="' + cls + '">' + match + '</span>';
        });
}

function createServerCard(name, config, isEnabled = false) {
    const card = document.createElement('div');
    card.className = 'server-card';
    card.dataset.serverName = name;

    card.innerHTML = `
        <div class="server-header">
            <h3>${name}</h3>
            <div class="server-status">
                <span class="status-indicator ${isEnabled ? 'active' : ''}"></span>
                <label class="toggle">
                    <input type="checkbox" ${isEnabled ? 'checked' : ''} data-server="${name}">
                    <span class="toggle-slider"></span>
                </label>
            </div>
        </div>
        <div class="server-details">
            <pre>${syntaxHighlightJSON(config)}</pre>
        </div>
        <div class="server-actions">
            <button class="btn btn-sm" onclick="editServer('${name}')">Edit</button>
            <button class="btn btn-sm btn-danger" onclick="deleteServer('${name}')">Delete</button>
        </div>
    `;

    const toggle = card.querySelector('input[type="checkbox"]');
    toggle.addEventListener('change', (e) => {
        toggleServer(name, e.target.checked);
    });

    return card;
}

async function toggleServer(name, enabled) {
    if (enabled) {
        // Add server to current profile
        if (!currentProfile.includes(name)) {
            currentProfile.push(name);
        }
    } else {
        // Remove server from current profile
        currentProfile = currentProfile.filter(serverName => serverName !== name);
    }

    try {
        await saveCurrentProfile();
        renderServers();
        showToast(`Server "${name}" ${enabled ? 'enabled' : 'disabled'}`, 'success');
    } catch (error) {
        // Revert the change on error
        if (enabled) {
            currentProfile = currentProfile.filter(serverName => serverName !== name);
        } else {
            if (!currentProfile.includes(name)) {
                currentProfile.push(name);
            }
        }
        renderServers();
        showToast(`Error ${enabled ? 'enabling' : 'disabling'} server`, 'error');
    }
}

async function saveCurrentProfile() {
    // Save current profile to Claude config (only enabled servers)
    const serversToSave = {};
    for (const serverName of currentProfile) {
        if (globalServerConfigs[serverName]) {
            serversToSave[serverName] = globalServerConfigs[serverName];
        }
    }

    try {
        let data;
        if (isElectron) {
            data = await window.api.saveConfig(serversToSave, currentConfigPath);
        } else {
            const response = await fetch('/api/config', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    servers: serversToSave,
                    configPath: currentConfigPath
                })
            });
            data = await response.json();
        }

        if (!data.success) {
            throw new Error(data.error);
        }
    } catch (error) {
        throw error;
    }
}

async function saveAllServers() {
    // Deprecated - use saveCurrentProfile instead
    await saveCurrentProfile();
}

function editServer(name) {
    const config = globalServerConfigs[name];
    document.getElementById('editServerName').value = name;
    document.getElementById('editServerConfig').value = JSON.stringify(config, null, 2);
    document.getElementById('editServerModal').classList.remove('hidden');
}

async function deleteServer(name) {
    if (!confirm(`Are you sure you want to delete server "${name}"?`)) {
        return;
    }

    try {
        // Remove from global configs
        delete globalServerConfigs[name];

        // Remove from current profile if present
        currentProfile = currentProfile.filter(serverName => serverName !== name);

        // Save both global configs and current profile
        await saveGlobalConfigs();
        await saveCurrentProfile();
        renderServers();
        showToast(`Server "${name}" deleted`, 'success');
    } catch (error) {
        showToast('Error deleting server', 'error');
    }
}

async function loadProfiles() {
    try {
        let data;
        if (isElectron) {
            data = await window.api.getProfiles();
        } else {
            const response = await fetch('/api/profiles');
            data = await response.json();
        }

        if (data.success) {
            const select = document.getElementById('profileSelect');
            select.innerHTML = '<option value="">Select a profile...</option>';

            data.profiles.forEach(profile => {
                const option = document.createElement('option');
                option.value = profile;
                option.textContent = profile;
                select.appendChild(option);
            });
        }
    } catch (error) {
        showToast('Error loading profiles', 'error');
    }
}

async function loadProfile() {
    const select = document.getElementById('profileSelect');
    const profileName = select.value;

    if (!profileName) {
        showToast('Please select a profile', 'warning');
        return;
    }

    try {
        let data;
        if (isElectron) {
            data = await window.api.getProfile(profileName);
        } else {
            const response = await fetch(`/api/profile/${encodeURIComponent(profileName)}`);
            data = await response.json();
        }

        if (data.success) {
            currentServers = data.servers;
            await saveAllServers();
            renderServers();
            showToast(`Profile "${profileName}" loaded`, 'success');
        } else {
            showToast('Error loading profile: ' + data.error, 'error');
        }
    } catch (error) {
        showToast('Error loading profile', 'error');
    }
}

async function saveProfile() {
    const profileName = document.getElementById('profileName').value.trim();

    if (!profileName) {
        showToast('Please enter a profile name', 'warning');
        return;
    }

    try {
        let data;
        if (isElectron) {
            data = await window.api.saveProfile(profileName, currentServers);
        } else {
            const response = await fetch('/api/profile', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    name: profileName,
                    servers: currentServers
                })
            });
            data = await response.json();
        }

        if (data.success) {
            showToast(`Profile "${profileName}" saved`, 'success');
            document.getElementById('saveProfileForm').classList.add('hidden');
            document.getElementById('profileName').value = '';
            await loadProfiles();
        } else {
            showToast('Error saving profile: ' + data.error, 'error');
        }
    } catch (error) {
        showToast('Error saving profile', 'error');
    }
}

async function deleteProfile() {
    const select = document.getElementById('profileSelect');
    const profileName = select.value;

    if (!profileName) {
        showToast('Please select a profile to delete', 'warning');
        return;
    }

    if (!confirm(`Are you sure you want to delete profile "${profileName}"?`)) {
        return;
    }

    try {
        let data;
        if (isElectron) {
            data = await window.api.deleteProfile(profileName);
        } else {
            const response = await fetch(`/api/profile/${encodeURIComponent(profileName)}`, {
                method: 'DELETE'
            });
            data = await response.json();
        }

        if (data.success) {
            showToast(`Profile "${profileName}" deleted`, 'success');
            await loadProfiles();
        } else {
            showToast('Error deleting profile: ' + data.error, 'error');
        }
    } catch (error) {
        showToast('Error deleting profile', 'error');
    }
}

function setupEventListeners() {
    document.getElementById('refreshBtn').addEventListener('click', async () => {
        showToast('Refreshing from Claude config...', 'info');
        await loadCurrentServers();
        showToast('Servers refreshed from Claude config', 'success');
    });

    document.getElementById('addServerBtn').addEventListener('click', () => {
        document.getElementById('addServerForm').classList.remove('hidden');
    });

    document.getElementById('cancelServerBtn').addEventListener('click', () => {
        document.getElementById('addServerForm').classList.add('hidden');
        document.getElementById('serverName').value = '';
        document.getElementById('serverConfig').value = '';
    });

    document.getElementById('saveServerBtn').addEventListener('click', async () => {
        const name = document.getElementById('serverName').value.trim();
        const configStr = document.getElementById('serverConfig').value.trim();

        if (!name) {
            showToast('Please enter a server name', 'warning');
            return;
        }

        let config;
        try {
            config = JSON.parse(configStr);
        } catch (error) {
            showToast('Invalid JSON configuration', 'error');
            return;
        }

        try {
            let data;
            if (isElectron) {
                data = await window.api.addServer(name, config, currentConfigPath);
            } else {
                const response = await fetch('/api/server', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({
                        name,
                        config,
                        configPath: currentConfigPath
                    })
                });
                data = await response.json();
            }

            if (data.success) {
                currentServers[name] = config;
                renderServers();
                showToast(`Server "${name}" added`, 'success');
                document.getElementById('addServerForm').classList.add('hidden');
                document.getElementById('serverName').value = '';
                document.getElementById('serverConfig').value = '';
            } else {
                showToast('Error adding server: ' + data.error, 'error');
            }
        } catch (error) {
            showToast('Error adding server', 'error');
        }
    });

    document.getElementById('settingsBtn').addEventListener('click', () => {
        document.getElementById('settingsModal').classList.remove('hidden');
    });

    document.getElementById('closeSettingsBtn').addEventListener('click', () => {
        document.getElementById('settingsModal').classList.add('hidden');
    });

    document.getElementById('saveSettingsBtn').addEventListener('click', () => {
        currentConfigPath = document.getElementById('configPath').value;
        document.getElementById('settingsModal').classList.add('hidden');
        loadServers();
        showToast('Settings saved', 'success');
    });

    document.getElementById('saveEditBtn').addEventListener('click', async () => {
        const name = document.getElementById('editServerName').value;
        const configStr = document.getElementById('editServerConfig').value.trim();

        let config;
        try {
            config = JSON.parse(configStr);
        } catch (error) {
            showToast('Invalid JSON configuration', 'error');
            return;
        }

        currentServers[name] = config;
        await saveAllServers();
        renderServers();
        showToast(`Server "${name}" updated`, 'success');
        document.getElementById('editServerModal').classList.add('hidden');
    });

    document.getElementById('cancelEditBtn').addEventListener('click', () => {
        document.getElementById('editServerModal').classList.add('hidden');
    });

    document.getElementById('loadProfileBtn').addEventListener('click', loadProfile);

    document.getElementById('saveProfileBtn').addEventListener('click', () => {
        document.getElementById('saveProfileForm').classList.remove('hidden');
    });

    document.getElementById('confirmSaveProfile').addEventListener('click', saveProfile);

    document.getElementById('cancelSaveProfile').addEventListener('click', () => {
        document.getElementById('saveProfileForm').classList.add('hidden');
        document.getElementById('profileName').value = '';
    });

    document.getElementById('deleteProfileBtn').addEventListener('click', deleteProfile);

    // Show/hide delete button based on profile selection
    document.getElementById('profileSelect').addEventListener('change', (e) => {
        const deleteBtn = document.getElementById('deleteProfileBtn');
        if (e.target.value) {
            deleteBtn.classList.remove('hidden');
        } else {
            deleteBtn.classList.add('hidden');
        }
    });

    document.addEventListener('click', (e) => {
        if (e.target.classList.contains('modal')) {
            e.target.classList.add('hidden');
        }
    });
}

function showToast(message, type = 'info') {
    const toast = document.getElementById('toast');
    toast.textContent = message;
    toast.className = `toast ${type}`;
    toast.classList.add('show');

    setTimeout(() => {
        toast.classList.remove('show');
    }, 3000);
}

document.addEventListener('DOMContentLoaded', init);