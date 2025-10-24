import Foundation

class ConfigManager {
    static let shared = ConfigManager()

    private init() {}

    // MARK: - File Operations

    func expandPath(_ path: String) -> URL {
        let nsString = NSString(string: path)
        let expanded = nsString.expandingTildeInPath
        return URL(fileURLWithPath: expanded)
    }

    func readConfig(from path: String) throws -> [String: ServerConfig] {
        let url = expandPath(path)

        guard FileManager.default.fileExists(atPath: url.path) else {
            // Create empty config if it doesn't exist
            let emptyConfig: [String: Any] = ["mcpServers": [:]]
            let data = try JSONSerialization.data(withJSONObject: emptyConfig, options: [.prettyPrinted, .sortedKeys])
            try data.write(to: url)
            return [:]
        }

        let data = try Data(contentsOf: url)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]

        // Extract mcpServers section
        guard let mcpServers = json["mcpServers"] as? [String: Any] else {
            return [:]
        }

        // Convert to ServerConfig dictionary
        var servers: [String: ServerConfig] = [:]
        for (name, value) in mcpServers {
            guard let serverData = try? JSONSerialization.data(withJSONObject: value),
                  let config = try? JSONDecoder().decode(ServerConfig.self, from: serverData) else {
                continue
            }
            servers[name] = config
        }

        return servers
    }

    func writeConfig(servers: [String: ServerConfig], to path: String) throws {
        let url = expandPath(path)

        // Read existing config to preserve other keys
        var json: [String: Any] = [:]
        if FileManager.default.fileExists(atPath: url.path) {
            let data = try Data(contentsOf: url)
            json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        }

        // Convert servers to dictionary
        var mcpServers: [String: Any] = [:]
        for (name, config) in servers {
            let data = try JSONEncoder().encode(config)
            let configDict = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
            mcpServers[name] = configDict
        }

        // Update mcpServers section
        json["mcpServers"] = mcpServers

        // Write back to file
        let data = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: url, options: .atomic)
    }

    func testConnection(to path: String) throws -> Int {
        let servers = try readConfig(from: path)
        return servers.count
    }

    // MARK: - Server Operations

    func addServer(name: String, config: ServerConfig, to configPath: String) throws {
        var servers = try readConfig(from: configPath)
        servers[name] = config
        try writeConfig(servers: servers, to: configPath)
    }

    func deleteServer(name: String, from configPath: String) throws {
        var servers = try readConfig(from: configPath)
        servers.removeValue(forKey: name)
        try writeConfig(servers: servers, to: configPath)
    }

    func updateServer(name: String, config: ServerConfig, in configPath: String) throws {
        var servers = try readConfig(from: configPath)
        servers[name] = config
        try writeConfig(servers: servers, to: configPath)
    }

    // MARK: - Bulk Operations

    func addServers(_ newServers: [String: ServerConfig], to configPath: String, merge: Bool = true) throws {
        var servers = merge ? try readConfig(from: configPath) : [:]
        servers.merge(newServers) { _, new in new }
        try writeConfig(servers: servers, to: configPath)
    }

    func exportServers(from servers: [ServerModel], configIndex: Int) -> String {
        let filteredServers = servers
            .filter { $0.inConfigs[safe: configIndex] ?? false }
            .reduce(into: [String: ServerConfig]()) { result, server in
                result[server.name] = server.config
            }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        guard let data = try? encoder.encode(filteredServers),
              let string = String(data: data, encoding: .utf8) else {
            return "{}"
        }

        return string
    }
}

// MARK: - UserDefaults Extension

extension UserDefaults {
    private enum Keys {
        static let settings = "app_settings"
        static let servers = "cached_servers"
        static let hasCompletedOnboarding = "has_completed_onboarding"
    }

    var appSettings: AppSettings {
        get {
            guard let data = data(forKey: Keys.settings),
                  let settings = try? JSONDecoder().decode(AppSettings.self, from: data) else {
                return .default
            }
            return settings
        }
        set {
            let data = try? JSONEncoder().encode(newValue)
            set(data, forKey: Keys.settings)
        }
    }

    var cachedServers: [ServerModel] {
        get {
            guard let data = data(forKey: Keys.servers),
                  let servers = try? JSONDecoder().decode([ServerModel].self, from: data) else {
                return []
            }
            return servers
        }
        set {
            let data = try? JSONEncoder().encode(newValue)
            set(data, forKey: Keys.servers)
        }
    }

    var hasCompletedOnboarding: Bool {
        get { bool(forKey: Keys.hasCompletedOnboarding) }
        set { set(newValue, forKey: Keys.hasCompletedOnboarding) }
    }
}
