let currentConfigPath = '';
let currentServers = {};

async function init() {
    await loadConfigPath();
    await loadServers();
    await loadProfiles();
    setupEventListeners();
}

async function loadConfigPath() {
    try {
        const response = await fetch('/api/config-path');
        const data = await response.json();
        currentConfigPath = data.path;
        document.getElementById('configPath').value = currentConfigPath;
    } catch (error) {
        showToast('Error loading config path', 'error');
    }
}

async function loadServers() {
    try {
        const response = await fetch(`/api/config?path=${encodeURIComponent(currentConfigPath)}`);
        const data = await response.json();

        if (data.success) {
            currentServers = data.servers;
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

    if (Object.keys(currentServers).length === 0) {
        serversList.innerHTML = '<p class="no-servers">No servers configured. Click "+ Add Server" to get started.</p>';
        return;
    }

    for (const [name, config] of Object.entries(currentServers)) {
        const serverCard = createServerCard(name, config);
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

function createServerCard(name, config) {
    const card = document.createElement('div');
    card.className = 'server-card';
    card.dataset.serverName = name;

    const isEnabled = config !== null && config !== undefined;

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
        if (currentServers[name] === null || currentServers[name] === undefined) {
            showToast('Cannot enable server without configuration', 'error');
            return;
        }
    } else {
        const tempConfig = currentServers[name];
        currentServers[name] = null;

        try {
            await saveAllServers();
            showToast(`Server "${name}" disabled`, 'success');
        } catch (error) {
            currentServers[name] = tempConfig;
            renderServers();
            showToast('Error disabling server', 'error');
        }
    }
}

async function saveAllServers() {
    const cleanServers = {};
    for (const [name, config] of Object.entries(currentServers)) {
        if (config !== null && config !== undefined) {
            cleanServers[name] = config;
        }
    }

    try {
        const response = await fetch('/api/config', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                servers: cleanServers,
                configPath: currentConfigPath
            })
        });

        const data = await response.json();
        if (!data.success) {
            throw new Error(data.error);
        }
    } catch (error) {
        throw error;
    }
}

function editServer(name) {
    const config = currentServers[name];
    document.getElementById('editServerName').value = name;
    document.getElementById('editServerConfig').value = JSON.stringify(config, null, 2);
    document.getElementById('editServerModal').classList.remove('hidden');
}

async function deleteServer(name) {
    if (!confirm(`Are you sure you want to delete server "${name}"?`)) {
        return;
    }

    try {
        const response = await fetch(`/api/server/${encodeURIComponent(name)}?path=${encodeURIComponent(currentConfigPath)}`, {
            method: 'DELETE'
        });

        const data = await response.json();
        if (data.success) {
            delete currentServers[name];
            renderServers();
            showToast(`Server "${name}" deleted`, 'success');
        } else {
            showToast('Error deleting server: ' + data.error, 'error');
        }
    } catch (error) {
        showToast('Error deleting server', 'error');
    }
}

async function loadProfiles() {
    try {
        const response = await fetch('/api/profiles');
        const data = await response.json();

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
        const response = await fetch(`/api/profile/${encodeURIComponent(profileName)}`);
        const data = await response.json();

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

        const data = await response.json();
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
        const response = await fetch(`/api/profile/${encodeURIComponent(profileName)}`, {
            method: 'DELETE'
        });

        const data = await response.json();
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
    document.getElementById('refreshBtn').addEventListener('click', () => {
        loadServers();
        showToast('Servers refreshed', 'success');
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

            const data = await response.json();
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