const { contextBridge, ipcRenderer } = require('electron');

// Expose protected methods that allow the renderer process to use
// the ipcRenderer without exposing the entire object
contextBridge.exposeInMainWorld('api', {
    // Config operations
    getConfigPath: (configType) => ipcRenderer.invoke('get-config-path', configType),
    selectConfigFile: () => ipcRenderer.invoke('select-config-file'),
    getConfig: (path) => ipcRenderer.invoke('get-config', path),
    saveConfig: (servers, configPath) => ipcRenderer.invoke('save-config', servers, configPath),

    // Server operations
    addServer: (name, config, configPath) => ipcRenderer.invoke('add-server', name, config, configPath),
    deleteServer: (name, configPath) => ipcRenderer.invoke('delete-server', name, configPath),

    // Profile operations
    getProfiles: () => ipcRenderer.invoke('get-profiles'),
    getProfile: (name) => ipcRenderer.invoke('get-profile', name),
    saveProfile: (name, servers) => ipcRenderer.invoke('save-profile', name, servers),
    deleteProfile: (name) => ipcRenderer.invoke('delete-profile', name),

    // Global configs operations
    getGlobalConfigs: () => ipcRenderer.invoke('get-global-configs'),
    saveGlobalConfigs: (configs) => ipcRenderer.invoke('save-global-configs', configs),

    // Platform info
    getPlatform: () => process.platform,

    // Registry proxy
    fetchRegistry: (options) => ipcRenderer.invoke('fetch-registry', options)
});
