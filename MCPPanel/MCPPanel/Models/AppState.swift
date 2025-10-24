//
//  AppState.swift
//  MCP Panel
//

import Foundation
import SwiftUI

@MainActor
class AppState: ObservableObject {
    // MARK: - Published Properties

    // Configuration
    @Published var servers: [String: ServerConfig] = [:]
    @Published var globalServers: [String: ServerConfig] = [:]
    @Published var settings: AppSettings
    @Published var profiles: [Profile] = []

    // UI State
    @Published var selectedServer: ServerConfig?
    @Published var searchQuery: String = ""
    @Published var isLoading: Bool = false
    @Published var error: AppError?

    // Modals & Sheets
    @Published var showServerModal: Bool = false
    @Published var showSettings: Bool = false
    @Published var showOnboarding: Bool = false
    @Published var editingServer: ServerConfig?

    // Notifications
    @Published var notificationMessage: String?
    @Published var notificationType: NotificationType = .info

    // Other
    @Published var focusSearch: Bool = false
    @Published var rawJsonText: String = ""
    @Published var isEditingRawJson: Bool = false

    // Services
    private let fileService: FileSystemService
    private let configService: ConfigService
    private let searchService: SearchService
    private let validationService: ValidationService

    // MARK: - Initialization

    init() {
        self.settings = AppSettings.load()
        self.fileService = FileSystemService()
        self.configService = ConfigService(fileService: fileService)
        self.searchService = SearchService()
        self.validationService = ValidationService()

        self.showOnboarding = settings.showOnboarding
    }

    // MARK: - Config Operations

    func loadConfig() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let config = try await configService.loadConfig(from: settings.expandedConfigPath)
            servers = config.mcpServers

            // Load global config if available
            if let globalPath = settings.expandedGlobalConfigPath {
                do {
                    let globalConfig = try await configService.loadConfig(from: globalPath)
                    globalServers = globalConfig.mcpServers
                } catch {
                    // Global config is optional, don't show error
                    print("Global config not loaded: \(error)")
                }
            }

            updateRawJsonText()
            showNotification("Configuration loaded successfully", type: .success)
        } catch {
            self.error = AppError.loadFailed(error.localizedDescription)
            showNotification("Failed to load configuration", type: .error)
        }
    }

    func saveConfig() async {
        guard settings.autoSave else { return }

        do {
            let config = ClaudeConfig(mcpServers: servers)
            try await configService.saveConfig(config, to: settings.expandedConfigPath)

            // Save global config if configured
            if let globalPath = settings.expandedGlobalConfigPath {
                let globalConfig = ClaudeConfig(mcpServers: globalServers)
                try await configService.saveConfig(globalConfig, to: globalPath)
            }

            updateRawJsonText()
            showNotification("Configuration saved", type: .success)
        } catch {
            self.error = AppError.saveFailed(error.localizedDescription)
            showNotification("Failed to save configuration", type: .error)
        }
    }

    // MARK: - Server Operations

    func addServer(_ server: ServerConfig) async {
        servers[server.id] = server
        await saveConfig()
        showNotification("Server '\(server.id)' added", type: .success)
    }

    func updateServer(_ server: ServerConfig) async {
        servers[server.id] = server
        await saveConfig()
        showNotification("Server '\(server.id)' updated", type: .success)
    }

    func deleteServer(id: String) async {
        servers.removeValue(forKey: id)
        if selectedServer?.id == id {
            selectedServer = nil
        }
        await saveConfig()
        showNotification("Server '\(id)' deleted", type: .success)
    }

    func toggleServerEnabled(id: String) async {
        guard var server = servers[id] else { return }
        server.disabled = !(server.disabled ?? false)
        servers[id] = server
        await saveConfig()

        let status = server.isEnabled ? "enabled" : "disabled"
        showNotification("Server '\(id)' \(status)", type: .info)
    }

    func duplicateServer(id: String) async {
        guard let server = servers[id] else { return }

        var newId = "\(id)_copy"
        var counter = 1
        while servers[newId] != nil {
            newId = "\(id)_copy\(counter)"
            counter += 1
        }

        let duplicated = ServerConfig(
            id: newId,
            command: server.command,
            args: server.args,
            env: server.env,
            disabled: server.disabled,
            alwaysAllow: server.alwaysAllow
        )

        servers[newId] = duplicated
        await saveConfig()
        showNotification("Server duplicated as '\(newId)'", type: .success)
    }

    // MARK: - Profile Operations

    func loadProfiles() async {
        do {
            profiles = try await configService.loadProfiles()
        } catch {
            print("Failed to load profiles: \(error)")
        }
    }

    func saveProfile(name: String) async {
        do {
            let profile = Profile(name: name, servers: servers)
            try await configService.saveProfile(profile)
            await loadProfiles()
            showNotification("Profile '\(name)' saved", type: .success)
        } catch {
            showNotification("Failed to save profile", type: .error)
        }
    }

    func loadProfile(_ profile: Profile) async {
        servers = profile.servers
        await saveConfig()
        showNotification("Profile '\(profile.name)' loaded", type: .success)
    }

    func deleteProfile(_ profile: Profile) async {
        do {
            try await configService.deleteProfile(profile)
            await loadProfiles()
            showNotification("Profile '\(profile.name)' deleted", type: .success)
        } catch {
            showNotification("Failed to delete profile", type: .error)
        }
    }

    // MARK: - Import/Export

    func importConfig() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.json]

        if panel.runModal() == .OK, let url = panel.url {
            Task {
                do {
                    let config = try await configService.loadConfig(from: url.path)
                    servers = config.mcpServers
                    await saveConfig()
                    showNotification("Configuration imported", type: .success)
                } catch {
                    showNotification("Failed to import configuration", type: .error)
                }
            }
        }
    }

    func exportConfig() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "mcp-config.json"

        if panel.runModal() == .OK, let url = panel.url {
            Task {
                do {
                    let config = ClaudeConfig(mcpServers: servers)
                    try await configService.saveConfig(config, to: url.path)
                    showNotification("Configuration exported", type: .success)
                } catch {
                    showNotification("Failed to export configuration", type: .error)
                }
            }
        }
    }

    // MARK: - Search & Filter

    var filteredServers: [ServerConfig] {
        let filtered = servers.values.filter { server in
            settings.filterMode.matches(server: server)
        }

        if searchQuery.isEmpty {
            return Array(filtered).sorted { $0.id < $1.id }
        }

        return searchService.search(
            query: searchQuery,
            in: Array(filtered),
            fuzzy: settings.searchFuzzy
        )
    }

    // MARK: - View Mode

    func toggleViewMode() {
        let modes = ViewMode.allCases
        if let currentIndex = modes.firstIndex(of: settings.viewMode) {
            let nextIndex = (currentIndex + 1) % modes.count
            settings.viewMode = modes[nextIndex]
            settings.save()
        }
    }

    // MARK: - Raw JSON Editing

    func updateRawJsonText() {
        let config = ClaudeConfig(mcpServers: servers)
        if let jsonData = try? JSONEncoder().encode(config),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            rawJsonText = jsonString.prettyPrinted()
        }
    }

    func saveRawJson() async {
        guard let data = rawJsonText.data(using: .utf8) else {
            showNotification("Invalid JSON text", type: .error)
            return
        }

        do {
            let config = try JSONDecoder().decode(ClaudeConfig.self, from: data)
            servers = config.mcpServers
            await saveConfig()
            isEditingRawJson = false
            showNotification("JSON configuration saved", type: .success)
        } catch {
            showNotification("Invalid JSON format: \(error.localizedDescription)", type: .error)
        }
    }

    // MARK: - Notifications

    private func showNotification(_ message: String, type: NotificationType) {
        notificationMessage = message
        notificationType = type

        // Auto-dismiss after 3 seconds
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            if notificationMessage == message {
                notificationMessage = nil
            }
        }
    }

    // MARK: - Validation

    func validateServer(_ server: ServerConfig) -> [String] {
        return validationService.validate(server: server)
    }

    // MARK: - Settings

    func updateSettings(_ newSettings: AppSettings) {
        settings = newSettings
        settings.save()
    }

    func dismissOnboarding() {
        showOnboarding = false
        settings.showOnboarding = false
        settings.save()
    }
}

// MARK: - Supporting Types

enum AppError: LocalizedError {
    case loadFailed(String)
    case saveFailed(String)
    case validationFailed(String)

    var errorDescription: String? {
        switch self {
        case .loadFailed(let message):
            return "Load failed: \(message)"
        case .saveFailed(let message):
            return "Save failed: \(message)"
        case .validationFailed(let message):
            return "Validation failed: \(message)"
        }
    }
}

enum NotificationType {
    case info
    case success
    case warning
    case error

    var color: Color {
        switch self {
        case .info: return .blue
        case .success: return .green
        case .warning: return .orange
        case .error: return .red
        }
    }
}

// MARK: - String Extensions

extension String {
    func prettyPrinted() -> String {
        guard let data = self.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data),
              let prettyData = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]),
              let prettyString = String(data: prettyData, encoding: .utf8) else {
            return self
        }
        return prettyString
    }
}
