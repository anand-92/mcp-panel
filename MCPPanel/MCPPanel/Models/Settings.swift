//
//  Settings.swift
//  MCP Panel
//

import Foundation

// MARK: - App Settings

struct AppSettings: Codable {
    var configPath: String
    var globalConfigPath: String?
    var autoSave: Bool
    var showOnboarding: Bool
    var viewMode: ViewMode
    var filterMode: FilterMode
    var theme: String
    var searchFuzzy: Bool

    init(
        configPath: String = "~/.claude.json",
        globalConfigPath: String? = nil,
        autoSave: Bool = true,
        showOnboarding: Bool = true,
        viewMode: ViewMode = .grid,
        filterMode: FilterMode = .all,
        theme: String = "system",
        searchFuzzy: Bool = true
    ) {
        self.configPath = configPath
        self.globalConfigPath = globalConfigPath
        self.autoSave = autoSave
        self.showOnboarding = showOnboarding
        self.viewMode = viewMode
        self.filterMode = filterMode
        self.theme = theme
        self.searchFuzzy = searchFuzzy
    }

    // Expand tilde in paths
    var expandedConfigPath: String {
        return (configPath as NSString).expandingTildeInPath
    }

    var expandedGlobalConfigPath: String? {
        guard let path = globalConfigPath else { return nil }
        return (path as NSString).expandingTildeInPath
    }
}

enum ViewMode: String, Codable, CaseIterable {
    case grid = "grid"
    case list = "list"
    case json = "json"

    var displayName: String {
        switch self {
        case .grid: return "Grid"
        case .list: return "List"
        case .json: return "Raw JSON"
        }
    }

    var iconName: String {
        switch self {
        case .grid: return "square.grid.2x2"
        case .list: return "list.bullet"
        case .json: return "curlybraces"
        }
    }
}

enum FilterMode: String, Codable, CaseIterable {
    case all = "all"
    case enabled = "enabled"
    case disabled = "disabled"

    var displayName: String {
        switch self {
        case .all: return "All Servers"
        case .enabled: return "Enabled Only"
        case .disabled: return "Disabled Only"
        }
    }

    func matches(server: ServerConfig) -> Bool {
        switch self {
        case .all:
            return true
        case .enabled:
            return server.isEnabled
        case .disabled:
            return !server.isEnabled
        }
    }
}

// MARK: - User Defaults Keys

extension AppSettings {
    private enum Keys {
        static let configPath = "configPath"
        static let globalConfigPath = "globalConfigPath"
        static let autoSave = "autoSave"
        static let showOnboarding = "showOnboarding"
        static let viewMode = "viewMode"
        static let filterMode = "filterMode"
        static let theme = "theme"
        static let searchFuzzy = "searchFuzzy"
    }

    static func load() -> AppSettings {
        let defaults = UserDefaults.standard

        return AppSettings(
            configPath: defaults.string(forKey: Keys.configPath) ?? "~/.claude.json",
            globalConfigPath: defaults.string(forKey: Keys.globalConfigPath),
            autoSave: defaults.object(forKey: Keys.autoSave) as? Bool ?? true,
            showOnboarding: defaults.object(forKey: Keys.showOnboarding) as? Bool ?? true,
            viewMode: ViewMode(rawValue: defaults.string(forKey: Keys.viewMode) ?? "grid") ?? .grid,
            filterMode: FilterMode(rawValue: defaults.string(forKey: Keys.filterMode) ?? "all") ?? .all,
            theme: defaults.string(forKey: Keys.theme) ?? "system",
            searchFuzzy: defaults.object(forKey: Keys.searchFuzzy) as? Bool ?? true
        )
    }

    func save() {
        let defaults = UserDefaults.standard

        defaults.set(configPath, forKey: Keys.configPath)
        defaults.set(globalConfigPath, forKey: Keys.globalConfigPath)
        defaults.set(autoSave, forKey: Keys.autoSave)
        defaults.set(showOnboarding, forKey: Keys.showOnboarding)
        defaults.set(viewMode.rawValue, forKey: Keys.viewMode)
        defaults.set(filterMode.rawValue, forKey: Keys.filterMode)
        defaults.set(theme, forKey: Keys.theme)
        defaults.set(searchFuzzy, forKey: Keys.searchFuzzy)
    }
}
