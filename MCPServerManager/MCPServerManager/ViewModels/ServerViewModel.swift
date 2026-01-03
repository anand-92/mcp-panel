import Foundation
import SwiftUI
import TOMLKit

@MainActor
class ServerViewModel: ObservableObject {
    @Published var servers: [ServerModel] = []
    @Published var settings: AppSettings = .default
    @Published var searchText: String = ""
    @Published var viewMode: ViewMode = .grid
    @Published var filterMode: FilterMode = .all
    @Published var isLoading: Bool = false
    @Published var showOnboarding: Bool = false
    @Published var selectedServer: ServerModel?
    @Published var showToast: Bool = false
    @Published var toastMessage: String = ""
    @Published var toastType: ToastType = .success

    private let configManager = ConfigManager.shared
    private var skipSync = false

    // MARK: - Theme Detection

    var currentTheme: AppTheme {
        // If override theme is set, use it (unless it's "auto")
        if let overrideThemeStr = settings.overrideTheme,
           let overrideTheme = AppTheme(rawValue: overrideThemeStr),
           overrideTheme != .auto {
            return overrideTheme
        }
        // Otherwise, auto-detect from config path
        return AppTheme.detect(from: settings.activeConfigPath)
    }

    var themeColors: ThemeColors {
        DesignTokens.colors(for: currentTheme)
    }

    enum ToastType {
        case success, error, warning
    }

    init() {
        loadSettings()

        // Show onboarding if first time
        showOnboarding = !UserDefaults.standard.hasCompletedOnboarding

        // Only load servers if onboarding is complete
        if !showOnboarding {
            loadServers()
        }
    }

    // MARK: - Filtering & Searching

    var filteredServers: [ServerModel] {
        let activeIndex = settings.activeConfigIndex
        var filtered = servers

        // 🚨 NUCLEAR UNIVERSE ISOLATION 🚨
        // Codex servers NEVER appear in Claude/Gemini, and vice versa
        // This is NOT a suggestion, it's the LAW
        if activeIndex == 2 {
            // Codex universe: ONLY show Codex servers
            filtered = filtered.filter { $0.isCodexUniverse }
        } else {
            // Claude/Gemini universe: ONLY show Claude/Gemini servers
            filtered = filtered.filter { $0.isClaudeGeminiUniverse }
        }

        // Apply filter mode (within the universe)
        switch filterMode {
        case .all:
            break  // Show all servers in this universe
        case .active:
            filtered = filtered.filter { $0.inConfigs[safe: activeIndex] ?? false }
        case .disabled:
            filtered = filtered.filter { !($0.inConfigs[safe: activeIndex] ?? false) }
        case .recent:
            filtered = filtered.sorted { $0.updatedAt > $1.updatedAt }
        }

        // Apply search
        if !searchText.isEmpty {
            filtered = filtered.filter { server in
                server.name.localizedCaseInsensitiveContains(searchText) ||
                server.config.summary.localizedCaseInsensitiveContains(searchText) ||
                server.configJSON.localizedCaseInsensitiveContains(searchText)
            }
        }

        return filtered
    }

    // MARK: - Settings Management

    func loadSettings() {
        settings = UserDefaults.standard.appSettings
        // NO MIGRATION - Codex is a completely separate universe
        // Existing servers belong to Claude/Gemini (sourceUniverse defaults to 0)
        // Codex servers are brand new, created separately
    }

    func saveSettings() {
        UserDefaults.standard.appSettings = settings
        showToast(message: "Settings saved", type: .success)
    }

    func completeOnboarding(configPath: String) {
        settings.configPaths[0] = configPath
        UserDefaults.standard.appSettings = settings
        UserDefaults.standard.hasCompletedOnboarding = true
        showOnboarding = false
        loadServers()
    }

    // MARK: - Server Management

    func loadServers() {
        isLoading = true
        skipSync = true

        Task {
            do {
                let config1 = try configManager.readConfig(from: settings.config1Path)
                let config2 = try configManager.readConfig(from: settings.config2Path)
                let config3 = try configManager.readConfig(from: settings.config3Path)

                let merged = mergeConfigs(config1: config1, config2: config2, config3: config3)
                servers = merged

                // Cache to UserDefaults
                UserDefaults.standard.cachedServers = servers

                // Clean up unused custom icons
                let usedIcons = Set(servers.compactMap { $0.customIconPath })
                CustomIconManager.shared.cleanupUnusedIcons(usedFilenames: usedIcons)

                skipSync = false
                isLoading = false
            } catch {
                #if DEBUG
                print("Error loading servers: \(error)")
                #endif
                // Load from cache if available
                servers = UserDefaults.standard.cachedServers

                // Clean up unused custom icons
                let usedIcons = Set(servers.compactMap { $0.customIconPath })
                CustomIconManager.shared.cleanupUnusedIcons(usedFilenames: usedIcons)

                skipSync = false
                isLoading = false
                showToast(message: "Failed to load config: \(error.localizedDescription)", type: .error)
            }
        }
    }

    private func mergeConfigs(config1: [String: ServerConfig], config2: [String: ServerConfig], config3: [String: ServerConfig]) -> [ServerModel] {
        var merged: [String: ServerModel] = [:]
        let now = Date()

        // Start with cached servers to preserve metadata (including sourceUniverse)
        for server in UserDefaults.standard.cachedServers {
            merged[server.name] = server
        }

        // Process config1 servers (Claude Code - Universe 0)
        for (name, config) in config1 {
            if var existing = merged[name] {
                existing.config = config
                existing.inConfigs[0] = true
                merged[name] = existing
            } else {
                merged[name] = ServerModel(
                    name: name,
                    config: config,
                    updatedAt: now,
                    inConfigs: [true, false, false],
                    sourceUniverse: 0  // Claude universe
                )
            }
        }

        // Process config2 servers (Gemini CLI - Universe 1)
        for (name, config) in config2 {
            if var existing = merged[name] {
                if !existing.inConfigs[0] {
                    existing.config = config
                }
                existing.inConfigs[1] = true
                merged[name] = existing
            } else {
                merged[name] = ServerModel(
                    name: name,
                    config: config,
                    updatedAt: now,
                    inConfigs: [false, true, false],
                    sourceUniverse: 1  // Gemini universe (still Claude/Gemini group)
                )
            }
        }

        // Process config3 servers (Codex - Universe 2 - COMPLETELY ISOLATED)
        for (name, config) in config3 {
            if var existing = merged[name] {
                // Codex servers are isolated, update config regardless
                existing.config = config
                existing.inConfigs[2] = true
                merged[name] = existing
            } else {
                merged[name] = ServerModel(
                    name: name,
                    config: config,
                    updatedAt: now,
                    inConfigs: [false, false, true],
                    sourceUniverse: 2  // Codex universe - THE FORBIDDEN ZONE
                )
            }
        }

        // Reset inConfigs for servers not in their respective configs
        for (name, var server) in merged {
            if !config1.keys.contains(name) {
                server.inConfigs[0] = false
            }
            if !config2.keys.contains(name) {
                server.inConfigs[1] = false
            }
            if !config3.keys.contains(name) {
                server.inConfigs[2] = false
            }
            merged[name] = server
        }

        return Array(merged.values).sorted { $0.name < $1.name }
    }

    func syncToConfigs() {
        guard !skipSync else {
            #if DEBUG
            print("DEBUG: Skipping sync")
            #endif
            return
        }

        Task {
            do {
                let config1Servers = servers
                    .filter { $0.isInConfig1 }
                    .reduce(into: [String: ServerConfig]()) { $0[$1.name] = $1.config }

                let config2Servers = servers
                    .filter { $0.isInConfig2 }
                    .reduce(into: [String: ServerConfig]()) { $0[$1.name] = $1.config }

                let config3Servers = servers
                    .filter { $0.isInConfig3 }
                    .reduce(into: [String: ServerConfig]()) { $0[$1.name] = $1.config }

                #if DEBUG
                print("DEBUG: Syncing - Config1: \(config1Servers.count), Config2: \(config2Servers.count), Config3 (CODEX): \(config3Servers.count)")
                #endif

                try configManager.writeConfig(servers: config1Servers, to: settings.config1Path)
                try configManager.writeConfig(servers: config2Servers, to: settings.config2Path)
                try configManager.writeConfig(servers: config3Servers, to: settings.config3Path)

                // Update cache
                await MainActor.run {
                    UserDefaults.standard.cachedServers = servers
                }
            } catch {
                await MainActor.run {
                    showToast(message: "Failed to save: \(error.localizedDescription)", type: .error)
                }
            }
        }
    }

    // MARK: - Server CRUD

    func addServers(from jsonString: String, registryImages: [String: String]? = nil) -> (invalidServers: [String: String], serverDict: [String: ServerConfig])? {
        #if DEBUG
        print("DEBUG: Starting addServers with input length: \(jsonString.count)")
        if let images = registryImages {
            print("DEBUG: Registry images provided for \(images.count) servers")
        }
        #endif

        // Use forgiving parser to extract server entries
        guard let serverDict = ServerExtractor.extractServerEntries(from: jsonString) else {
            #if DEBUG
            print("DEBUG: Failed to parse JSON")
            #endif
            showToast(message: "Could not parse JSON. Please check format.", type: .error)
            return nil
        }

        guard !serverDict.isEmpty else {
            showToast(message: "No servers found in JSON", type: .warning)
            #if DEBUG
            print("DEBUG: Parsed dictionary is empty")
            #endif
            return nil
        }

        #if DEBUG
        print("DEBUG: Found \(serverDict.count) servers in JSON")
        #endif

        // Check for invalid servers first
        var invalidServers: [String: String] = [:]
        for (name, config) in serverDict {
            if !config.isValid {
                let reason = getInvalidReason(config)
                invalidServers[name] = reason
            }
        }

        // If there are invalid servers, return them for UI to handle
        if !invalidServers.isEmpty {
            return (invalidServers: invalidServers, serverDict: serverDict)
        }

        // All servers are valid, proceed with adding
        addServersInternal(serverDict: serverDict, registryImages: registryImages, skipValidation: false)
        return nil
    }

    func addServersForced(from jsonString: String, registryImages: [String: String]? = nil) {
        #if DEBUG
        print("DEBUG: Force adding servers, bypassing validation")
        #endif

        guard let serverDict = ServerExtractor.extractServerEntries(from: jsonString) else {
            showToast(message: "Could not parse JSON. Please check format.", type: .error)
            return
        }

        addServersInternal(serverDict: serverDict, registryImages: registryImages, skipValidation: true)
    }

    func addServersForced(serverDict: [String: ServerConfig], registryImages: [String: String]? = nil) {
        #if DEBUG
        print("DEBUG: Force adding servers from parsed dictionary, bypassing validation")
        #endif

        addServersInternal(serverDict: serverDict, registryImages: registryImages, skipValidation: true)
    }

    private func addServersInternal(serverDict: [String: ServerConfig], registryImages: [String: String]?, skipValidation: Bool) {
        var addedCount = 0

        for (name, config) in serverDict {
            #if DEBUG
            print("DEBUG: Processing server '\(name)'...")
            print("DEBUG: Config valid: \(config.isValid)")
            print("DEBUG: Has command: \(config.command != nil)")
            print("DEBUG: Command: \(config.command ?? "nil")")
            print("DEBUG: Args: \(config.args ?? [])")
            print("DEBUG: Has transport: \(config.transport != nil)")
            print("DEBUG: Has remotes: \(config.remotes != nil)")
            #endif

            // Note: When skipValidation is false, the caller already validates all servers
            // and returns early if any are invalid, so this check is unnecessary

            // Get registry image URL if available
            let registryImageUrl = registryImages?[name]

            if let index = self.servers.firstIndex(where: { $0.name == name }) {
                var updatedServer = self.servers[index]
                updatedServer.config = config
                updatedServer.updatedAt = Date()
                updatedServer.inConfigs[settings.activeConfigIndex] = true
                // Update registry image URL if provided
                if let imageUrl = registryImageUrl {
                    updatedServer.registryImageUrl = imageUrl
                }
                self.servers[index] = updatedServer
                #if DEBUG
                print("DEBUG: Updated existing server '\(name)'")
                #endif
            } else {
                // Brand new server - assign to current universe
                var inConfigs = [false, false, false]
                inConfigs[settings.activeConfigIndex] = true

                let newServer = ServerModel(
                    name: name,
                    config: config,
                    updatedAt: Date(),
                    inConfigs: inConfigs,
                    registryImageUrl: registryImageUrl,
                    sourceUniverse: settings.activeConfigIndex  // Lock to this universe FOREVER
                )
                self.servers.append(newServer)
                #if DEBUG
                print("DEBUG: Added new server '\(name)' to universe \(settings.activeConfigIndex)")
                #endif
            }
            addedCount += 1
        }

        self.servers.sort { $0.name < $1.name }

        // Force UI update
        objectWillChange.send()

        // Sync to files
        syncToConfigs()

        if skipValidation {
            showToast(message: "Force saved \(addedCount) server(s)", type: .success)
        } else {
            showToast(message: "Added \(addedCount) server(s)", type: .success)
        }

        #if DEBUG
        print("DEBUG: Total servers now: \(self.servers.count)")
        print("DEBUG: Filtered servers: \(filteredServers.count)")
        print("DEBUG: Active config index: \(settings.activeConfigIndex)")
        print("DEBUG: Filter mode: \(filterMode)")
        #endif
    }


    private func getInvalidReason(_ config: ServerConfig) -> String {
        if config.command == nil && config.httpUrl == nil && config.transport == nil && config.remotes == nil {
            return "missing command, httpUrl, transport, or remotes"
        }
        if let cmd = config.command, cmd.trimmingCharacters(in: .whitespaces).isEmpty {
            return "empty command"
        }
        if let httpUrlString = config.httpUrl, httpUrlString.trimmingCharacters(in: .whitespaces).isEmpty {
            return "empty httpUrl"
        }
        return "unknown issue"
    }

    func updateServer(_ server: ServerModel, with jsonString: String) -> (success: Bool, invalidReason: String?, config: ServerConfig?) {
        do {
            // Normalize quotes first (curly quotes from Notes/Word/Slack)
            let normalized = jsonString.normalizingQuotes()

            guard let data = normalized.data(using: .utf8) else {
                throw NSError(domain: "MCPServerManager", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Failed to convert JSON string to data"
                ])
            }

            // Decode with proper error propagation
            let config: ServerConfig
            do {
                config = try JSONDecoder().decode(ServerConfig.self, from: data)
            } catch {
                // Preserve the actual JSONDecoder error details
                throw NSError(domain: "MCPServerManager", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "JSON parsing error: \(error.localizedDescription)"
                ])
            }

            if !config.isValid {
                let reason = getInvalidReason(config)
                return (success: false, invalidReason: reason, config: config)
            }

            if let index = servers.firstIndex(where: { $0.id == server.id }) {
                var updated = servers[index]
                updated.config = config
                updated.updatedAt = Date()
                servers[index] = updated

                syncToConfigs()
                showToast(message: "Server updated", type: .success)
                return (success: true, invalidReason: nil, config: nil)
            }
            return (success: false, invalidReason: nil, config: nil)
        } catch {
            showToast(message: "Failed to update: \(error.localizedDescription)", type: .error)
            return (success: false, invalidReason: nil, config: nil)
        }
    }

    func updateServerForced(_ server: ServerModel, with jsonString: String) -> Bool {
        do {
            let normalized = jsonString.normalizingQuotes()

            guard let data = normalized.data(using: .utf8) else {
                throw NSError(domain: "MCPServerManager", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Failed to convert JSON string to data"
                ])
            }

            let config = try JSONDecoder().decode(ServerConfig.self, from: data)

            if let index = servers.firstIndex(where: { $0.id == server.id }) {
                var updated = servers[index]
                updated.config = config
                updated.updatedAt = Date()
                servers[index] = updated

                syncToConfigs()
                showToast(message: "Server force saved", type: .success)
                return true
            }
            return false
        } catch {
            showToast(message: "Failed to update: \(error.localizedDescription)", type: .error)
            return false
        }
    }

    func updateServerForced(_ server: ServerModel, config: ServerConfig) -> Bool {
        if let index = servers.firstIndex(where: { $0.id == server.id }) {
            var updated = servers[index]
            updated.config = config
            updated.updatedAt = Date()
            servers[index] = updated

            syncToConfigs()
            showToast(message: "Server force saved", type: .success)
            return true
        }
        return false
    }

    func applyRawJSON(_ jsonText: String) -> (success: Bool, invalidServers: [String: String]?, serverDict: [String: ServerConfig]?) {
        do {
            let normalized = jsonText.normalizingQuotes()

            guard let data = normalized.data(using: .utf8) else {
                throw NSError(domain: "Invalid JSON", code: -1)
            }

            let serverDict = try JSONDecoder().decode([String: ServerConfig].self, from: data)

            // Check for invalid servers
            var invalidServers: [String: String] = [:]
            for (name, config) in serverDict {
                if !config.isValid {
                    let reason = getInvalidReason(config)
                    invalidServers[name] = reason
                }
            }

            if !invalidServers.isEmpty {
                return (success: false, invalidServers: invalidServers, serverDict: serverDict)
            }

            // Apply changes
            applyRawJSONInternal(serverDict: serverDict, skipValidation: false)
            return (success: true, invalidServers: nil, serverDict: nil)
        } catch {
            showToast(message: "Failed to parse JSON: \(error.localizedDescription)", type: .error)
            return (success: false, invalidServers: nil, serverDict: nil)
        }
    }

    func applyRawJSONForced(_ jsonText: String) throws {
        let normalized = jsonText.normalizingQuotes()

        guard let data = normalized.data(using: .utf8) else {
            throw NSError(domain: "Invalid JSON", code: -1)
        }

        let serverDict = try JSONDecoder().decode([String: ServerConfig].self, from: data)
        applyRawJSONInternal(serverDict: serverDict, skipValidation: true)
    }

    func applyRawJSONForced(serverDict: [String: ServerConfig]) {
        applyRawJSONInternal(serverDict: serverDict, skipValidation: true)
    }

    private func applyRawJSONInternal(serverDict: [String: ServerConfig], skipValidation: Bool) {
        let configIndex = settings.activeConfigIndex

        // Remove all servers from this config
        for i in 0..<servers.count {
            servers[i].inConfigs[configIndex] = false
        }

        // Add/update servers from JSON
        // Note: When skipValidation is false, the caller already validates all servers
        // and returns early if any are invalid, so no validation check needed here
        for (name, config) in serverDict {
            if let index = servers.firstIndex(where: { $0.name == name }) {
                var updated = servers[index]
                updated.config = config
                updated.inConfigs[configIndex] = true
                updated.updatedAt = Date()
                servers[index] = updated
            } else {
                var inConfigs = [false, false, false]
                inConfigs[configIndex] = true

                let newServer = ServerModel(
                    name: name,
                    config: config,
                    updatedAt: Date(),
                    inConfigs: inConfigs,
                    sourceUniverse: configIndex  // Locked to this universe forever
                )
                servers.append(newServer)
            }
        }

        servers.sort { $0.name < $1.name }
        objectWillChange.send()
        syncToConfigs()

        let message = skipValidation ? "Configuration force saved" : "Configuration updated"
        showToast(message: message, type: .success)
    }

    // MARK: - TOML Editing (for Codex)

    func applyRawTOML(_ tomlText: String) -> (success: Bool, invalidServers: [String: String]?, serverDict: [String: ServerConfig]?) {
        do {
            // Parse TOML
            let toml = try TOMLTable(string: tomlText)
            guard let mcpServers = toml["mcp_servers"] as? TOMLTable else {
                throw NSError(domain: "Missing mcp_servers section", code: -1)
            }

            // Convert TOML to ServerConfig dictionary
            var serverDict: [String: ServerConfig] = [:]
            for (name, value) in mcpServers {
                guard let serverTable = value as? TOMLTable,
                      let jsonDict = TOMLUtils.tomlTableToDictionary(serverTable) else {
                    throw NSError(domain: "Invalid server config for \(name)", code: -1)
                }

                // Convert JSON dict to ServerConfig
                let jsonData = try JSONSerialization.data(withJSONObject: jsonDict)
                let config = try JSONDecoder().decode(ServerConfig.self, from: jsonData)
                serverDict[name] = config
            }

            // Check for invalid servers
            var invalidServers: [String: String] = [:]
            for (name, config) in serverDict {
                if !config.isValid {
                    let reason = getInvalidReason(config)
                    invalidServers[name] = reason
                }
            }

            if !invalidServers.isEmpty {
                return (success: false, invalidServers: invalidServers, serverDict: serverDict)
            }

            // Apply changes
            applyRawJSONInternal(serverDict: serverDict, skipValidation: false)
            return (success: true, invalidServers: nil, serverDict: nil)
        } catch {
            showToast(message: "Failed to parse TOML: \(error.localizedDescription)", type: .error)
            return (success: false, invalidServers: nil, serverDict: nil)
        }
    }

    func applyRawTOMLForced(_ tomlText: String) throws {
        let toml = try TOMLTable(string: tomlText)
        guard let mcpServers = toml["mcp_servers"] as? TOMLTable else {
            throw NSError(domain: "Missing mcp_servers section", code: -1)
        }

        var serverDict: [String: ServerConfig] = [:]
        for (name, value) in mcpServers {
            guard let serverTable = value as? TOMLTable,
                  let jsonDict = TOMLUtils.tomlTableToDictionary(serverTable) else {
                throw NSError(domain: "Invalid server config for \(name)", code: -1)
            }

            let jsonData = try JSONSerialization.data(withJSONObject: jsonDict)
            let config = try JSONDecoder().decode(ServerConfig.self, from: jsonData)
            serverDict[name] = config
        }

        applyRawJSONInternal(serverDict: serverDict, skipValidation: true)
    }

    func applyRawTOMLForced(serverDict: [String: ServerConfig]) {
        applyRawJSONInternal(serverDict: serverDict, skipValidation: true)
    }

    func deleteServer(_ server: ServerModel) {
        servers.removeAll { $0.id == server.id }
        syncToConfigs()
        showToast(message: "Server deleted", type: .success)
    }

    // MARK: - Tags

    private func isServerInActiveUniverse(_ server: ServerModel) -> Bool {
        let activeIndex = settings.activeConfigIndex
        if activeIndex == 2 {
            return server.isCodexUniverse
        }
        return server.isClaudeGeminiUniverse
    }

    func taggedServersCount(for tag: ServerTag) -> Int {
        servers.filter { isServerInActiveUniverse($0) && $0.tags.contains(tag) }.count
    }

    func enableServers(with tag: ServerTag) {
        let configIndex = settings.activeConfigIndex
        guard configIndex >= 0 && configIndex < 3 else {
             showToast(message: "Invalid config index", type: .error)
             return
        }

        var indicesToUpdate: [Int] = []
        var taggedCount = 0

        // 1. Identify servers to update
        for i in 0..<servers.count {
            let server = servers[i]
            guard isServerInActiveUniverse(server), server.tags.contains(tag) else { continue }
            taggedCount += 1

            if !(servers[i].inConfigs[safe: configIndex] ?? false) {
                indicesToUpdate.append(i)
            }
        }

        guard taggedCount > 0 else {
            showToast(message: "No servers tagged \(tag.rawValue)", type: .warning)
            return
        }

        guard !indicesToUpdate.isEmpty else {
            showToast(message: "All \(tag.rawValue) servers already enabled", type: .warning)
            return
        }

        // 2. Batch update
        for index in indicesToUpdate {
            servers[index].inConfigs[configIndex] = true
            servers[index].updatedAt = Date()
        }

        // 3. Single notification and sync
        objectWillChange.send()
        syncToConfigs()
        showToast(message: "Enabled \(indicesToUpdate.count) \(tag.rawValue) server(s)", type: .success)
    }

    func toggleTag(_ tag: ServerTag, for server: ServerModel) {
        guard let index = servers.firstIndex(where: { $0.id == server.id }) else { return }

        var updated = servers[index]
        if let tagIndex = updated.tags.firstIndex(of: tag) {
            updated.tags.remove(at: tagIndex)
        } else {
            updated.tags.append(tag)
        }
        updated.updatedAt = Date()
        servers[index] = updated

        // Tags are app metadata (local-only), so we only update the cache.
        // NOTE: If the user clears app data, tags will be lost.
        // Future improvement: Persist tags to a sidecar file or config metadata.
        UserDefaults.standard.cachedServers = servers
    }

    func toggleServer(_ server: ServerModel) {
        guard let index = servers.firstIndex(where: { $0.id == server.id }) else { return }

        var updated = servers[index]
        let configIndex = settings.activeConfigIndex
        updated.inConfigs[configIndex].toggle()
        updated.updatedAt = Date()
        servers[index] = updated

        syncToConfigs()

        let status = updated.inConfigs[configIndex] ? "enabled" : "disabled"
        showToast(message: "\(server.name) \(status)", type: .success)
    }

    func updateCustomIcon(for server: ServerModel, result: Result<String, Error>) {
        guard let index = servers.firstIndex(where: { $0.id == server.id }) else { return }

        switch result {
        case .success(let filename):
            // Remove old custom icon if replacing or resetting
            if let oldFilename = servers[index].customIconPath, oldFilename != filename {
                CustomIconManager.shared.removeCustomIcon(filename: oldFilename)
            }

            var updated = servers[index]
            updated.customIconPath = filename.isEmpty ? nil : filename
            updated.updatedAt = Date()
            servers[index] = updated

            // Update cache (no need to sync to config files as custom icons are app-specific)
            UserDefaults.standard.cachedServers = servers

            let message = filename.isEmpty ? "Icon reset for \(server.name)" : "Custom icon set for \(server.name)"
            showToast(message: message, type: .success)

        case .failure(let error):
            // Show specific error message from CustomIconError
            let errorMessage = error.localizedDescription
            showToast(message: errorMessage, type: .error)
        }
    }

    func toggleAllServers(_ enable: Bool) {
        let configIndex = settings.activeConfigIndex
        #if DEBUG
        print("DEBUG: toggleAllServers called with enable=\(enable), configIndex=\(configIndex), serverCount=\(servers.count)")
        #endif

        for i in 0..<servers.count {
            #if DEBUG
            let before = servers[i].inConfigs[configIndex]
            #endif
            servers[i].inConfigs[configIndex] = enable
            servers[i].updatedAt = Date()
            #if DEBUG
            print("DEBUG: Server '\(servers[i].name)': \(before) -> \(enable)")
            #endif
        }

        // Force UI update
        objectWillChange.send()

        syncToConfigs()
        let status = enable ? "enabled" : "disabled"
        showToast(message: "All servers \(status)", type: .success)
    }

    // MARK: - Import/Export

    func exportServers() -> String {
        configManager.exportServers(from: servers, configIndex: settings.activeConfigIndex)
    }

    func testConnection(to path: String) async -> Result<Int, Error> {
        do {
            let count = try configManager.testConnection(to: path)
            return .success(count)
        } catch {
            return .failure(error)
        }
    }

    // MARK: - Toast

    private var toastTask: Task<Void, Never>?

    func showToast(message: String, type: ToastType) {
        // Cancel any existing toast timer
        toastTask?.cancel()

        toastMessage = message
        toastType = type
        withAnimation {
            showToast = true
        }

        toastTask = Task { @MainActor in
            do {
                try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
                if !Task.isCancelled {
                    withAnimation {
                        showToast = false
                    }
                }
            } catch {
                // Task was cancelled, ignore
            }
        }
    }
}
