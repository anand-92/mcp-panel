// Modern MCP Server Manager Application
// Enhanced version with improved UX, animations, and features

// Initialize Notyf for notifications
const notyf = new Notyf({
    duration: 3000,
    position: { x: 'right', y: 'bottom' },
    ripple: true,
    dismissible: true
});

// State Management
const state = {
    servers: {},
    profiles: [],
    currentProfile: null,
    configPath: '~/.claude.json',
    viewMode: 'grid',
    filter: 'all',
    searchQuery: '',
    selectedServers: new Set(),
    isLoading: false,
    settings: {
        autoSave: false,
        confirmDelete: true,
        animations: true,
        theme: 'dark',
        accentColor: 'blue'
    }
};

// Fuse.js for fuzzy search
let fuseInstance = null;

// API Functions - Electron IPC only
const mcpApi = {
    async getServers() {
        try {
            const response = await window.api.getConfig(state.configPath);
            if (response.error) throw new Error(response.error);
            return response.servers || {};
        } catch (error) {
            console.error('Failed to fetch servers:', error);
            throw error;
        }
    },

    async saveServers(servers) {
        try {
            const response = await window.api.saveConfig(servers, state.configPath);
            if (response.error) throw new Error(response.error);
            return response;
        } catch (error) {
            console.error('Failed to save servers:', error);
            throw error;
        }
    },

    async getProfiles() {
        try {
            const response = await window.api.getProfiles();
            if (response.error) throw new Error(response.error);
            return response.profiles || [];
        } catch (error) {
            console.error('Failed to fetch profiles:', error);
            return [];
        }
    },

    async saveProfile(name, servers) {
        try {
            const response = await window.api.saveProfile(name, servers);
            if (response.error) throw new Error(response.error);
            return response;
        } catch (error) {
            console.error('Failed to save profile:', error);
            throw error;
        }
    },

    async loadProfile(name) {
        try {
            const response = await window.api.getProfile(name);
            if (response.error) throw new Error(response.error);
            return response.servers || {};
        } catch (error) {
            console.error('Failed to load profile:', error);
            throw error;
        }
    },

    async deleteProfile(name) {
        try {
            const response = await window.api.deleteProfile(name);
            if (response.error) throw new Error(response.error);
            return response;
        } catch (error) {
            console.error('Failed to delete profile:', error);
            throw error;
        }
    }
};

// UI Helper Functions
const ui = {
    showLoading() {
        state.isLoading = true;
        document.getElementById('loadingScreen').classList.remove('hidden');
    },

    hideLoading() {
        state.isLoading = false;
        setTimeout(() => {
            document.getElementById('loadingScreen').classList.add('hidden');
        }, 500);
    },

    showModal(modalId) {
        document.getElementById('modalOverlay').classList.remove('hidden');
        document.getElementById(modalId).classList.remove('hidden');

        // Focus first input in modal
        setTimeout(() => {
            const firstInput = document.querySelector(`#${modalId} input, #${modalId} textarea`);
            if (firstInput) firstInput.focus();
        }, 100);
    },

    hideModal(modalId) {
        document.getElementById('modalOverlay').classList.add('hidden');
        document.getElementById(modalId).classList.add('hidden');
    },


    formatJSON(json) {
        try {
            const obj = typeof json === 'string' ? JSON.parse(json) : json;
            return JSON.stringify(obj, null, 2);
        } catch (e) {
            return json;
        }
    },

    syntaxHighlight(json) {
        if (typeof json !== 'string') {
            json = JSON.stringify(json, null, 2);
        }

        json = json.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');

        return json.replace(/("(\\u[a-zA-Z0-9]{4}|\\[^u]|[^\\"])*"(\s*:)?|\b(true|false|null)\b|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?)/g, function (match) {
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
            return `<span class="${cls}">${match}</span>`;
        });
    }
};

// Server Management Functions
const servers = {
    async load() {
        try {
            ui.showLoading();
            state.servers = await mcpApi.getServers();
            this.render();
            this.updateSearch();
            notyf.success('Servers loaded successfully');
        } catch (error) {
            notyf.error(`Failed to load servers: ${error.message}`);
        } finally {
            ui.hideLoading();
        }
    },

    async save() {
        try {
            await mcpApi.saveServers(state.servers);

            if (state.settings.autoSave) {
                notyf.success('Changes saved automatically');
            } else {
                notyf.success('Servers saved successfully');
            }

        } catch (error) {
            notyf.error(`Failed to save servers: ${error.message}`);
        }
    },

    async add(name, config, tags = []) {
        try {
            // Validate config is valid JSON
            const configObj = typeof config === 'string' ? JSON.parse(config) : config;

            if (state.servers[name]) {
                throw new Error(`Server "${name}" already exists`);
            }

            state.servers[name] = configObj;

            if (state.settings.autoSave) {
                await this.save();
            } else {
                this.render();
                }

            notyf.success(`Server "${name}" added successfully`);
            return true;
        } catch (error) {
            notyf.error(`Failed to add server: ${error.message}`);
            return false;
        }
    },

    async update(name, config) {
        try {
            const configObj = typeof config === 'string' ? JSON.parse(config) : config;
            state.servers[name] = configObj;

            if (state.settings.autoSave) {
                await this.save();
            } else {
                this.render();
            }

            notyf.success(`Server "${name}" updated successfully`);
            return true;
        } catch (error) {
            notyf.error(`Failed to update server: ${error.message}`);
            return false;
        }
    },

    async delete(name) {
        try {
            if (state.settings.confirmDelete) {
                const confirmed = await this.confirmDelete(name);
                if (!confirmed) return;
            }

            delete state.servers[name];

            if (state.settings.autoSave) {
                await this.save();
            } else {
                this.render();
                }

            notyf.success(`Server "${name}" deleted successfully`);
        } catch (error) {
            notyf.error(`Failed to delete server: ${error.message}`);
        }
    },

    async toggle(name) {
        try {
            if (state.servers[name] === null) {
                // Re-enable: need to restore from somewhere or set a default
                state.servers[name] = { command: "placeholder", args: [] };
                notyf.success(`Server "${name}" enabled`);
            } else {
                // Disable
                state.servers[name] = null;
                notyf.warning(`Server "${name}" disabled`);
            }

            if (state.settings.autoSave) {
                await this.save();
            } else {
                this.render();
            }
        } catch (error) {
            notyf.error(`Failed to toggle server: ${error.message}`);
        }
    },

    async duplicate(name) {
        try {
            const newName = `${name}_copy`;
            const config = state.servers[name];

            if (state.servers[newName]) {
                throw new Error(`Server "${newName}" already exists`);
            }

            state.servers[newName] = JSON.parse(JSON.stringify(config));

            if (state.settings.autoSave) {
                await this.save();
            } else {
                this.render();
                }

            notyf.success(`Server duplicated as "${newName}"`);
        } catch (error) {
            notyf.error(`Failed to duplicate server: ${error.message}`);
        }
    },

    confirmDelete(name) {
        return new Promise((resolve) => {
            const confirmed = confirm(`Are you sure you want to delete server "${name}"?`);
            resolve(confirmed);
        });
    },

    getFiltered() {
        let servers = Object.entries(state.servers);

        // Apply filter
        switch (state.filter) {
            case 'active':
                servers = servers.filter(([_, config]) => config !== null);
                break;
            case 'disabled':
                servers = servers.filter(([_, config]) => config === null);
                break;
            case 'recent':
                // TODO: Implement recent sorting based on modification time
                break;
        }

        // Apply search
        if (state.searchQuery && fuseInstance) {
            const results = fuseInstance.search(state.searchQuery);
            const names = new Set(results.map(r => r.item.name));
            servers = servers.filter(([name]) => names.has(name));
        }

        return servers;
    },

    updateSearch() {
        const searchData = Object.keys(state.servers).map(name => ({
            name,
            config: JSON.stringify(state.servers[name])
        }));

        fuseInstance = new Fuse(searchData, {
            keys: ['name', 'config'],
            threshold: 0.3
        });
    },

    render() {
        const container = document.getElementById('serversContainer');
        const emptyState = document.getElementById('emptyState');
        const gridContainer = document.getElementById('serversGrid');
        const listContainer = document.getElementById('serversList');

        const filtered = this.getFiltered();

        if (filtered.length === 0 && Object.keys(state.servers).length === 0) {
            emptyState.classList.remove('hidden');
            gridContainer.classList.add('hidden');
            listContainer.classList.add('hidden');
            return;
        }

        emptyState.classList.add('hidden');

        if (state.viewMode === 'grid') {
            gridContainer.classList.remove('hidden');
            listContainer.classList.add('hidden');
            this.renderGrid(filtered);
        } else {
            gridContainer.classList.add('hidden');
            listContainer.classList.remove('hidden');
            this.renderList(filtered);
        }

        // Initialize tooltips for new elements
        tippy('[data-tooltip]', {
            content: (element) => element.getAttribute('data-tooltip'),
            placement: 'top',
            animation: 'scale'
        });
    },

    renderGrid(servers) {
        const container = document.getElementById('serversGrid');
        container.innerHTML = '';

        servers.forEach(([name, config]) => {
            const card = document.createElement('div');
            card.className = `server-card ${config === null ? 'disabled' : ''} animate-in`;
            card.dataset.server = name;

            card.innerHTML = `
                <div class="server-card-header">
                    <h3 class="server-card-title">${name}</h3>
                    <div class="server-card-status ${config === null ? 'disabled' : ''}"></div>
                </div>
                <div class="server-card-body">
                    <pre class="server-card-config">${ui.syntaxHighlight(config)}</pre>
                </div>
                <div class="server-card-footer">
                    <button class="btn-icon" data-action="edit" data-tooltip="Edit">
                        <svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor">
                            <path d="M12.146.146a.5.5 0 01.708 0l3 3a.5.5 0 010 .708l-10 10a.5.5 0 01-.168.11l-5 2a.5.5 0 01-.65-.65l2-5a.5.5 0 01.11-.168l10-10z"/>
                        </svg>
                    </button>
                    <button class="btn-icon" data-action="duplicate" data-tooltip="Duplicate">
                        <svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor">
                            <path d="M4 2a2 2 0 00-2 2v8a2 2 0 002 2h8a2 2 0 002-2V4a2 2 0 00-2-2H4z"/>
                        </svg>
                    </button>
                    <button class="btn-icon" data-action="toggle" data-tooltip="${config === null ? 'Enable' : 'Disable'}">
                        <svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor">
                            <path d="M${config === null ? '8 5v6M5 8h6' : '11 8H5'}"/>
                        </svg>
                    </button>
                    <button class="btn-icon" data-action="delete" data-tooltip="Delete">
                        <svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor">
                            <path d="M5.5 5.5A.5.5 0 016 6v6a.5.5 0 01-1 0V6a.5.5 0 01.5-.5zm2.5 0a.5.5 0 01.5.5v6a.5.5 0 01-1 0V6a.5.5 0 01.5-.5zm3 .5a.5.5 0 00-1 0v6a.5.5 0 001 0V6z"/>
                        </svg>
                    </button>
                </div>
            `;

            // Add event listeners
            card.querySelectorAll('button').forEach(btn => {
                btn.addEventListener('click', (e) => {
                    e.stopPropagation();
                    const action = btn.dataset.action;
                    this.handleAction(action, name);
                });
            });

            // Add context menu
            card.addEventListener('contextmenu', (e) => {
                e.preventDefault();
                this.showContextMenu(e, name);
            });

            container.appendChild(card);
        });
    },

    renderList(servers) {
        const container = document.getElementById('serversList');
        container.innerHTML = '';

        servers.forEach(([name, config]) => {
            const item = document.createElement('div');
            item.className = 'server-list-item animate-in';
            item.dataset.server = name;

            const isDisabled = config === null;
            const configStr = isDisabled ? 'Disabled' : JSON.stringify(config).substring(0, 50) + '...';

            item.innerHTML = `
                <input type="checkbox" class="server-list-checkbox" data-server="${name}">
                <div class="server-list-status ${isDisabled ? 'disabled' : ''}"></div>
                <div class="server-list-info">
                    <div class="server-list-name">${name}</div>
                    <div class="server-list-meta">${configStr}</div>
                </div>
                <div class="server-list-actions">
                    <button class="btn-icon" data-action="edit" data-tooltip="Edit">
                        <svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor">
                            <path d="M12.146.146a.5.5 0 01.708 0l3 3a.5.5 0 010 .708l-10 10a.5.5 0 01-.168.11l-5 2a.5.5 0 01-.65-.65l2-5a.5.5 0 01.11-.168l10-10z"/>
                        </svg>
                    </button>
                    <button class="btn-icon" data-action="toggle" data-tooltip="${isDisabled ? 'Enable' : 'Disable'}">
                        <svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor">
                            <path d="M${isDisabled ? '8 5v6M5 8h6' : '11 8H5'}"/>
                        </svg>
                    </button>
                    <button class="btn-icon" data-action="delete" data-tooltip="Delete">
                        <svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor">
                            <path d="M5.5 5.5A.5.5 0 016 6v6a.5.5 0 01-1 0V6a.5.5 0 01.5-.5zm2.5 0a.5.5 0 01.5.5v6a.5.5 0 01-1 0V6a.5.5 0 01.5-.5zm3 .5a.5.5 0 00-1 0v6a.5.5 0 001 0V6z"/>
                        </svg>
                    </button>
                </div>
            `;

            // Add event listeners
            item.querySelectorAll('button').forEach(btn => {
                btn.addEventListener('click', (e) => {
                    e.stopPropagation();
                    const action = btn.dataset.action;
                    this.handleAction(action, name);
                });
            });

            // Checkbox handler
            const checkbox = item.querySelector('.server-list-checkbox');
            checkbox.addEventListener('change', () => {
                if (checkbox.checked) {
                    state.selectedServers.add(name);
                } else {
                    state.selectedServers.delete(name);
                }
                this.updateBulkActions();
            });

            container.appendChild(item);
        });
    },

    handleAction(action, name) {
        switch (action) {
            case 'edit':
                this.showEditModal(name);
                break;
            case 'duplicate':
                this.duplicate(name);
                break;
            case 'toggle':
                this.toggle(name);
                break;
            case 'delete':
                this.delete(name);
                break;
        }
    },

    showEditModal(name) {
        const modal = document.getElementById('serverModal');
        const title = document.getElementById('modalTitle');
        const nameInput = document.getElementById('serverName');
        const configInput = document.getElementById('serverConfig');

        title.textContent = `Edit Server: ${name}`;
        nameInput.value = name;
        nameInput.disabled = true;
        configInput.value = ui.formatJSON(state.servers[name]);

        ui.showModal('serverModal');
    },

    showContextMenu(event, serverName) {
        const menu = document.getElementById('contextMenu');
        menu.classList.remove('hidden');

        // Position menu at cursor
        menu.style.left = `${event.pageX}px`;
        menu.style.top = `${event.pageY}px`;

        // Handle menu item clicks
        menu.querySelectorAll('.context-menu-item').forEach(item => {
            item.onclick = () => {
                const action = item.dataset.action;
                this.handleAction(action, serverName);
                menu.classList.add('hidden');
            };
        });

        // Hide menu on click outside
        document.addEventListener('click', () => {
            menu.classList.add('hidden');
        }, { once: true });
    },

    updateBulkActions() {
        const btn = document.getElementById('bulkActionsBtn');
        btn.disabled = state.selectedServers.size === 0;

        if (state.selectedServers.size > 0) {
            btn.innerHTML = `
                <svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor">
                    <path d="M2.5 1a1 1 0 00-1 1v1a1 1 0 001 1H3v9a2 2 0 002 2h6a2 2 0 002-2V4h.5a1 1 0 001-1V2a1 1 0 00-1-1H10a1 1 0 00-1-1H7a1 1 0 00-1 1H2.5z"/>
                </svg>
                Bulk Actions (${state.selectedServers.size})
            `;
        }
    }
};

// Profile Management
const profiles = {
    async load() {
        try {
            state.profiles = await mcpApi.getProfiles();
            this.render();
        } catch (error) {
            notyf.error(`Failed to load profiles: ${error.message}`);
        }
    },

    async save(name) {
        try {
            await mcpApi.saveProfile(name, state.servers);
            await this.load();
            notyf.success(`Profile "${name}" saved successfully`);
        } catch (error) {
            notyf.error(`Failed to save profile: ${error.message}`);
        }
    },

    async loadProfile(name) {
        try {
            state.servers = await mcpApi.loadProfile(name);
            state.currentProfile = name;
            servers.render();
            servers.updateSearch();
            notyf.success(`Profile "${name}" loaded successfully`);
        } catch (error) {
            notyf.error(`Failed to load profile: ${error.message}`);
        }
    },

    async delete(name) {
        try {
            if (confirm(`Are you sure you want to delete profile "${name}"?`)) {
                await mcpApi.deleteProfile(name);
                await this.load();
                notyf.success(`Profile "${name}" deleted successfully`);
            }
        } catch (error) {
            notyf.error(`Failed to delete profile: ${error.message}`);
        }
    },

    render() {
        const container = document.getElementById('profilesList');
        container.innerHTML = '';

        state.profiles.forEach(profile => {
            const item = document.createElement('div');
            item.className = `profile-item ${profile === state.currentProfile ? 'active' : ''}`;

            item.innerHTML = `
                <span>${profile}</span>
                <div class="profile-actions">
                    <button class="btn-icon btn-sm" data-action="load" data-tooltip="Load">
                        <svg width="14" height="14" viewBox="0 0 14 14" fill="currentColor">
                            <path d="M7 10l-5-5h3V2h4v3h3l-5 5z"/>
                        </svg>
                    </button>
                    <button class="btn-icon btn-sm" data-action="delete" data-tooltip="Delete">
                        <svg width="14" height="14" viewBox="0 0 14 14" fill="currentColor">
                            <path d="M5.5 5.5A.5.5 0 016 6v4a.5.5 0 01-1 0V6a.5.5 0 01.5-.5zm2 0a.5.5 0 01.5.5v4a.5.5 0 01-1 0V6a.5.5 0 01.5-.5z"/>
                        </svg>
                    </button>
                </div>
            `;

            item.querySelector('[data-action="load"]').addEventListener('click', (e) => {
                e.stopPropagation();
                this.loadProfile(profile);
            });

            item.querySelector('[data-action="delete"]').addEventListener('click', (e) => {
                e.stopPropagation();
                this.delete(profile);
            });

            container.appendChild(item);
        });
    }
};

// Keyboard Shortcuts
const shortcuts = {
    init() {
        document.addEventListener('keydown', (e) => {
            // Command/Ctrl + K: Focus search
            if ((e.metaKey || e.ctrlKey) && e.key === 'k') {
                e.preventDefault();
                document.getElementById('searchInput').focus();
            }

            // Command/Ctrl + N: New server
            if ((e.metaKey || e.ctrlKey) && e.key === 'n') {
                e.preventDefault();
                document.getElementById('newServerBtn').click();
            }

            // Command/Ctrl + S: Save
            if ((e.metaKey || e.ctrlKey) && e.key === 's') {
                e.preventDefault();
                servers.save();
            }

            // Command/Ctrl + R: Refresh
            if ((e.metaKey || e.ctrlKey) && e.key === 'r') {
                e.preventDefault();
                servers.load();
            }

            // Escape: Close modals
            if (e.key === 'Escape') {
                document.querySelectorAll('.modal:not(.hidden)').forEach(modal => {
                    ui.hideModal(modal.id);
                });
            }
        });
    }
};

// Event Listeners
function initEventListeners() {
    // Header buttons
    document.getElementById('sidebarToggle').addEventListener('click', () => {
        document.getElementById('appSidebar').classList.toggle('open');
    });

    document.getElementById('searchInput').addEventListener('input', (e) => {
        state.searchQuery = e.target.value;
        servers.render();
    });

    document.getElementById('settingsBtn').addEventListener('click', () => {
        ui.showModal('settingsModal');
    });

    document.getElementById('refreshBtn').addEventListener('click', () => {
        servers.load();
    });

    // View toggle
    document.getElementById('gridViewBtn').addEventListener('click', () => {
        state.viewMode = 'grid';
        document.getElementById('gridViewBtn').classList.add('active');
        document.getElementById('listViewBtn').classList.remove('active');
        servers.render();
    });

    document.getElementById('listViewBtn').addEventListener('click', () => {
        state.viewMode = 'list';
        document.getElementById('listViewBtn').classList.add('active');
        document.getElementById('gridViewBtn').classList.remove('active');
        servers.render();
    });

    // Filter select
    document.getElementById('filterSelect').addEventListener('change', (e) => {
        state.filter = e.target.value;
        servers.render();
    });

    // Quick actions
    document.getElementById('newServerBtn').addEventListener('click', () => {
        document.getElementById('modalTitle').textContent = 'Add New Server';
        document.getElementById('serverName').value = '';
        document.getElementById('serverName').disabled = false;
        document.getElementById('serverConfig').value = '';
        ui.showModal('serverModal');
    });

    document.getElementById('emptyStateBtn').addEventListener('click', () => {
        document.getElementById('newServerBtn').click();
    });

    // Server modal
    document.getElementById('serverForm').addEventListener('submit', async (e) => {
        e.preventDefault();
        const name = document.getElementById('serverName').value;
        const config = document.getElementById('serverConfig').value;

        const isEdit = document.getElementById('serverName').disabled;
        const success = isEdit ?
            await servers.update(name, config) :
            await servers.add(name, config);

        if (success) {
            ui.hideModal('serverModal');
        }
    });

    document.getElementById('formatJsonBtn').addEventListener('click', () => {
        const input = document.getElementById('serverConfig');
        try {
            input.value = ui.formatJSON(input.value);
            notyf.success('JSON formatted successfully');
        } catch (e) {
            notyf.error('Invalid JSON format');
        }
    });

    document.getElementById('validateJsonBtn').addEventListener('click', () => {
        const input = document.getElementById('serverConfig');
        try {
            JSON.parse(input.value);
            notyf.success('Valid JSON');
        } catch (e) {
            notyf.error(`Invalid JSON: ${e.message}`);
        }
    });

    document.getElementById('cancelServerBtn').addEventListener('click', () => {
        ui.hideModal('serverModal');
    });

    document.getElementById('modalClose').addEventListener('click', () => {
        ui.hideModal('serverModal');
    });

    // Settings modal
    document.getElementById('saveSettingsBtn').addEventListener('click', async () => {
        state.configPath = document.getElementById('configPath').value || '~/.claude.json';
        state.settings.autoSave = document.getElementById('autoSave').checked;
        state.settings.confirmDelete = document.getElementById('confirmDelete').checked;

        localStorage.setItem('mcp-settings', JSON.stringify(state.settings));
        localStorage.setItem('mcp-configPath', state.configPath);

        ui.hideModal('settingsModal');
        notyf.success('Settings saved');

        // Reload servers with new config path
        await servers.load();
    });

    document.getElementById('settingsClose').addEventListener('click', () => {
        ui.hideModal('settingsModal');
    });

    // Settings tabs
    document.querySelectorAll('.tab-button').forEach(btn => {
        btn.addEventListener('click', () => {
            const tabId = btn.dataset.tab;

            // Update buttons
            document.querySelectorAll('.tab-button').forEach(b => b.classList.remove('active'));
            btn.classList.add('active');

            // Update content
            document.querySelectorAll('.tab-content').forEach(content => {
                content.classList.add('hidden');
            });
            document.getElementById(`${tabId}Tab`).classList.remove('hidden');
        });
    });

    // Profile buttons
    document.getElementById('newProfileBtn').addEventListener('click', () => {
        const name = prompt('Enter profile name:');
        if (name) {
            profiles.save(name);
        }
    });

    // Import/Export
    document.getElementById('importBtn').addEventListener('click', () => {
        const input = document.createElement('input');
        input.type = 'file';
        input.accept = '.json';

        input.addEventListener('change', async (e) => {
            const file = e.target.files[0];
            if (file) {
                const reader = new FileReader();
                reader.onload = async (event) => {
                    try {
                        const config = JSON.parse(event.target.result);
                        state.servers = config.mcpServers || config;
                        await servers.save();
                        servers.render();
                        notyf.success('Configuration imported successfully');
                    } catch (error) {
                        notyf.error('Invalid configuration file');
                    }
                };
                reader.readAsText(file);
            }
        });

        input.click();
    });

    document.getElementById('exportBtn').addEventListener('click', () => {
        const data = JSON.stringify({ mcpServers: state.servers }, null, 2);
        const blob = new Blob([data], { type: 'application/json' });
        const url = URL.createObjectURL(blob);

        const a = document.createElement('a');
        a.href = url;
        a.download = 'mcp-servers-config.json';
        a.click();

        URL.revokeObjectURL(url);
        notyf.success('Configuration exported');
    });

    // Modal overlay click to close
    document.getElementById('modalOverlay').addEventListener('click', () => {
        document.querySelectorAll('.modal:not(.hidden)').forEach(modal => {
            ui.hideModal(modal.id);
        });
    });

    // Bulk actions
    document.getElementById('bulkActionsBtn').addEventListener('click', () => {
        if (state.selectedServers.size > 0) {
            const action = prompt(`What would you like to do with ${state.selectedServers.size} selected servers?\n\n1. Delete\n2. Disable\n3. Enable\n4. Export`);

            switch (action) {
                case '1':
                case 'delete':
                    if (confirm(`Delete ${state.selectedServers.size} servers?`)) {
                        state.selectedServers.forEach(name => delete state.servers[name]);
                        servers.save();
                        state.selectedServers.clear();
                        servers.render();
                    }
                    break;
                case '2':
                case 'disable':
                    state.selectedServers.forEach(name => state.servers[name] = null);
                    servers.save();
                    state.selectedServers.clear();
                    servers.render();
                    break;
                case '3':
                case 'enable':
                    // Would need stored configs to re-enable
                    notyf.warning('Cannot re-enable servers without stored configurations');
                    break;
                case '4':
                case 'export':
                    const selected = {};
                    state.selectedServers.forEach(name => {
                        selected[name] = state.servers[name];
                    });
                    const data = JSON.stringify(selected, null, 2);
                    const blob = new Blob([data], { type: 'application/json' });
                    const url = URL.createObjectURL(blob);

                    const a = document.createElement('a');
                    a.href = url;
                    a.download = 'selected-servers.json';
                    a.click();

                    URL.revokeObjectURL(url);
                    break;
            }
        }
    });
}

// Initialize Application
async function init() {
    try {
        // Load settings from localStorage
        const savedSettings = localStorage.getItem('mcp-settings');
        if (savedSettings) {
            Object.assign(state.settings, JSON.parse(savedSettings));
        }

        const savedConfigPath = localStorage.getItem('mcp-configPath');
        if (savedConfigPath) {
            state.configPath = savedConfigPath;
        }

        // Apply settings
        document.getElementById('configPath').value = state.configPath;
        document.getElementById('autoSave').checked = state.settings.autoSave;
        document.getElementById('confirmDelete').checked = state.settings.confirmDelete;

        // Initialize UI
        initEventListeners();
        shortcuts.init();

        // Load data
        await servers.load();
        await profiles.load();

        // Hide loading screen
        ui.hideLoading();

        // Show welcome message
        if (!localStorage.getItem('mcp-welcomed')) {
            setTimeout(() => {
                notyf.success('Welcome to MCP Server Manager!');
                localStorage.setItem('mcp-welcomed', 'true');
            }, 1000);
        }
    } catch (error) {
        console.error('Failed to initialize application:', error);
        notyf.error('Failed to initialize application');
        ui.hideLoading();
    }
}

// Start application when DOM is ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
} else {
    init();
}