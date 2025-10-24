import Foundation
import SwiftUI

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

    enum ToastType {
        case success, error, warning
    }

    init() {
        loadSettings()
        loadServers()

        // Show onboarding if first time
        showOnboarding = !UserDefaults.standard.hasCompletedOnboarding
    }

    // MARK: - Filtering & Searching

    var filteredServers: [ServerModel] {
        let activeIndex = settings.activeConfigIndex

        var filtered = servers

        // Apply filter mode
        switch filterMode {
        case .all:
            break
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

                let merged = mergeConfigs(config1: config1, config2: config2)
                servers = merged

                // Cache to UserDefaults
                UserDefaults.standard.cachedServers = servers

                skipSync = false
                isLoading = false
            } catch {
                print("Error loading servers: \(error)")
                // Load from cache if available
                servers = UserDefaults.standard.cachedServers
                skipSync = false
                isLoading = false
                showToast(message: "Failed to load config: \(error.localizedDescription)", type: .error)
            }
        }
    }

    private func mergeConfigs(config1: [String: ServerConfig], config2: [String: ServerConfig]) -> [ServerModel] {
        var merged: [String: ServerModel] = [:]
        let now = Date()

        // Start with cached servers to preserve metadata
        for server in UserDefaults.standard.cachedServers {
            merged[server.name] = server
        }

        // Process config1 servers
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
                    inConfigs: [true, false]
                )
            }
        }

        // Process config2 servers
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
                    inConfigs: [false, true]
                )
            }
        }

        // Reset inConfigs for servers not in either config
        for (name, var server) in merged {
            if !config1.keys.contains(name) {
                server.inConfigs[0] = false
            }
            if !config2.keys.contains(name) {
                server.inConfigs[1] = false
            }
            merged[name] = server
        }

        return Array(merged.values).sorted { $0.name < $1.name }
    }

    func syncToConfigs() {
        guard !skipSync else {
            print("DEBUG: Skipping sync")
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

                print("DEBUG: Syncing - Config1: \(config1Servers.count) servers, Config2: \(config2Servers.count) servers")

                try configManager.writeConfig(servers: config1Servers, to: settings.config1Path)
                try configManager.writeConfig(servers: config2Servers, to: settings.config2Path)

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

    func addServers(from jsonString: String) {
        do {
            guard let data = jsonString.data(using: .utf8) else {
                throw NSError(domain: "Invalid JSON", code: -1)
            }

            // Try to parse - check for mcpServers wrapper FIRST
            var serverDict: [String: ServerConfig]?

            // Try format 1: Full config with mcpServers wrapper (most common)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let mcpServers = json["mcpServers"] as? [String: Any] {
                print("DEBUG: Found mcpServers wrapper, extracting...")
                let mcpData = try JSONSerialization.data(withJSONObject: mcpServers)
                serverDict = try JSONDecoder().decode([String: ServerConfig].self, from: mcpData)
            }
            // Try format 2: Direct server dictionary
            else if let direct = try? JSONDecoder().decode([String: ServerConfig].self, from: data) {
                print("DEBUG: Parsed as direct server dictionary")
                serverDict = direct
            }
            // Unrecognized format
            else {
                throw NSError(domain: "Unrecognized JSON format", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Expected either {\"name\": {...}} or {\"mcpServers\": {\"name\": {...}}}"
                ])
            }

            guard let servers = serverDict, !servers.isEmpty else {
                showToast(message: "No servers found in JSON", type: .warning)
                print("DEBUG: Parsed dictionary is empty")
                return
            }

            print("DEBUG: Found \(servers.count) servers in JSON")

            var addedCount = 0
            var invalidCount = 0

            for (name, config) in servers {
                print("DEBUG: Processing server '\(name)'...")
                print("DEBUG: Config valid: \(config.isValid)")
                print("DEBUG: Has command: \(config.command != nil)")
                print("DEBUG: Has transport: \(config.transport != nil)")
                print("DEBUG: Has remotes: \(config.remotes != nil)")

                guard config.isValid else {
                    print("DEBUG: Skipping invalid config for \(name)")
                    invalidCount += 1
                    continue
                }

                if let index = self.servers.firstIndex(where: { $0.name == name }) {
                    var updatedServer = self.servers[index]
                    updatedServer.config = config
                    updatedServer.updatedAt = Date()
                    updatedServer.inConfigs[settings.activeConfigIndex] = true
                    self.servers[index] = updatedServer
                    print("DEBUG: Updated existing server '\(name)'")
                } else {
                    var inConfigs = [false, false]
                    inConfigs[settings.activeConfigIndex] = true

                    let newServer = ServerModel(
                        name: name,
                        config: config,
                        updatedAt: Date(),
                        inConfigs: inConfigs
                    )
                    self.servers.append(newServer)
                    print("DEBUG: Added new server '\(name)'")
                }
                addedCount += 1
            }

            self.servers.sort { $0.name < $1.name }

            // Force UI update
            objectWillChange.send()

            // Sync to files
            syncToConfigs()

            if invalidCount > 0 {
                showToast(message: "Added \(addedCount) server(s), skipped \(invalidCount) invalid", type: .warning)
            } else {
                showToast(message: "Added \(addedCount) server(s)", type: .success)
            }

            print("DEBUG: Total servers now: \(self.servers.count)")
            print("DEBUG: Filtered servers: \(filteredServers.count)")
            print("DEBUG: Active config index: \(settings.activeConfigIndex)")
            print("DEBUG: Filter mode: \(filterMode)")
        } catch {
            print("DEBUG: Error parsing JSON: \(error)")
            showToast(message: "Invalid JSON: \(error.localizedDescription)", type: .error)
        }
    }

    func updateServer(_ server: ServerModel, with jsonString: String) {
        do {
            guard let data = jsonString.data(using: .utf8),
                  let config = try? JSONDecoder().decode(ServerConfig.self, from: data) else {
                throw NSError(domain: "Invalid JSON", code: -1)
            }

            guard config.isValid else {
                throw NSError(domain: "Invalid server config", code: -1)
            }

            if let index = servers.firstIndex(where: { $0.id == server.id }) {
                var updated = servers[index]
                updated.config = config
                updated.updatedAt = Date()
                servers[index] = updated

                syncToConfigs()
                showToast(message: "Server updated", type: .success)
            }
        } catch {
            showToast(message: "Failed to update: \(error.localizedDescription)", type: .error)
        }
    }

    func deleteServer(_ server: ServerModel) {
        servers.removeAll { $0.id == server.id }
        syncToConfigs()
        showToast(message: "Server deleted", type: .success)
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

    func toggleAllServers(_ enable: Bool) {
        let configIndex = settings.activeConfigIndex

        for i in 0..<servers.count {
            servers[i].inConfigs[configIndex] = enable
            servers[i].updatedAt = Date()
        }

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

    private func showToast(message: String, type: ToastType) {
        toastMessage = message
        toastType = type
        withAnimation {
            showToast = true
        }

        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            withAnimation {
                showToast = false
            }
        }
    }
}
