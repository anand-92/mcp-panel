import Foundation
import TOMLKit

class ConfigManager {
    static let shared = ConfigManager()

    private init() {}

    // MARK: - File Operations

    func expandPath(_ path: String) -> URL {
        let nsString = NSString(string: path)
        let expanded = nsString.expandingTildeInPath
        return URL(fileURLWithPath: expanded)
    }

    /// Resolves a URL for the given path, using bookmarks if available
    private func resolveURL(for path: String) -> URL? {
        // First try to resolve from bookmark
        if let bookmarkedURL = BookmarkManager.shared.resolveBookmark(for: path) {
            return bookmarkedURL
        }

        // Fallback to direct path expansion (will only work if file was just selected via picker)
        return expandPath(path)
    }

    /// Executes a closure with access to the config file at the given path
    private func withConfigAccess<T>(_ path: String, _ closure: (URL) throws -> T) throws -> T {
        guard let url = resolveURL(for: path) else {
            throw NSError(
                domain: "ConfigManager",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Permission denied for '\(path)'. Click Settings → Browse to grant access."]
            )
        }

        // Try with security-scoped access first
        if BookmarkManager.shared.hasBookmark(for: path) {
            return try url.withSecurityScopedAccess(closure)
        }

        // Fallback to direct access (for newly selected files)
        return try closure(url)
    }

    func readConfig(from path: String) throws -> [String: ServerConfig] {
        let format = ConfigFormat.detect(from: path)

        return try withConfigAccess(path) { url in
            // If file doesn't exist, return empty dictionary instead of trying to create it
            // This prevents permission errors on app launch when bookmarks aren't established
            guard FileManager.default.fileExists(atPath: url.path) else {
                return [:]
            }

            let data = try Data(contentsOf: url)

            // Parse based on format
            if format == .toml {
                return try self.parseTOML(data: data)
            } else {
                return try self.parseJSON(data: data)
            }
        }
    }

    // MARK: - JSON Parsing

    private func parseJSON(data: Data) throws -> [String: ServerConfig] {
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

    // MARK: - TOML Parsing

    private func parseTOML(data: Data) throws -> [String: ServerConfig] {
        guard let tomlString = String(data: data, encoding: .utf8) else {
            throw NSError(
                domain: "ConfigManager",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Failed to decode TOML file as UTF-8"]
            )
        }

        let toml: TOMLTable
        do {
            toml = try TOMLTable(string: tomlString)
        } catch {
            throw NSError(
                domain: "ConfigManager",
                code: 3,
                userInfo: [NSLocalizedDescriptionKey: "Failed to parse TOML: \(error.localizedDescription)"]
            )
        }

        // Extract [mcp_servers.<name>] section
        guard let serversTable = toml["mcp_servers"]?.table else {
            return [:]
        }

        // Convert each server config
        var servers: [String: ServerConfig] = [:]
        for (name, value) in serversTable {
            guard let serverTable = value.table else {
                continue
            }

            // Convert TOMLTable to dictionary, then to ServerConfig
            if let serverDict = self.tomlTableToDictionary(serverTable),
               let jsonData = try? JSONSerialization.data(withJSONObject: serverDict),
               let config = try? JSONDecoder().decode(ServerConfig.self, from: jsonData) {
                servers[name] = config
            }
        }

        return servers
    }

    /// Converts a TOMLTable to a Swift Dictionary recursively
    private func tomlTableToDictionary(_ table: TOMLTable) -> [String: Any]? {
        var dict: [String: Any] = [:]

        for (key, valueConvertible) in table {
            // Convert TOMLValueConvertible to concrete type
            if let string = valueConvertible as? String {
                dict[key] = string
            } else if let int = valueConvertible as? Int {
                dict[key] = int
            } else if let double = valueConvertible as? Double {
                dict[key] = double
            } else if let bool = valueConvertible as? Bool {
                dict[key] = bool
            } else if let array = valueConvertible as? TOMLArray {
                dict[key] = array.compactMap { convertToAny($0) }
            } else if let nestedTable = valueConvertible as? TOMLTable {
                dict[key] = tomlTableToDictionary(nestedTable)
            }
        }

        return dict.isEmpty ? nil : dict
    }

    /// Helper to convert TOMLValueConvertible to Any
    private func convertToAny(_ value: any TOMLValueConvertible) -> Any? {
        if let string = value as? String {
            return string
        } else if let int = value as? Int {
            return int
        } else if let double = value as? Double {
            return double
        } else if let bool = value as? Bool {
            return bool
        } else if let array = value as? TOMLArray {
            return array.compactMap { convertToAny($0) }
        } else if let table = value as? TOMLTable {
            return tomlTableToDictionary(table)
        }
        return nil
    }

    func writeConfig(servers: [String: ServerConfig], to path: String) throws {
        let format = ConfigFormat.detect(from: path)

        try withConfigAccess(path) { url in
            if format == .toml {
                // Write TOML format
                try self.writeTOMLConfig(servers: servers, to: url)
            } else {
                // Write JSON format
                try self.writeJSONConfig(servers: servers, to: url)
            }
        }
    }

    private func writeJSONConfig(servers: [String: ServerConfig], to url: URL) throws {
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
        try data.write(to: url)
    }

    private func writeTOMLConfig(servers: [String: ServerConfig], to url: URL) throws {
        var rootTable: TOMLTable
        
        // 1. Try to read existing file to preserve other sections
        if FileManager.default.fileExists(atPath: url.path),
           let data = try? Data(contentsOf: url),
           let string = String(data: data, encoding: .utf8) {
            do {
                rootTable = try TOMLTable(string: string)
            } catch {
                print("⚠️ Failed to parse existing TOML, starting fresh: \(error)")
                rootTable = TOMLTable()
            }
        } else {
            rootTable = TOMLTable()
        }

        // 2. Generate new [mcp_servers] table
        // We use TOMLEncoder to correctly serialize our complex ServerConfig (with AnyCodable)
        // into a TOML string, then parse it back to a table to merge.
        let encoder = TOMLEncoder()
        let wrapper = ["mcp_servers": servers]
        let serversTOML = try encoder.encode(wrapper)
        let tempTable = try TOMLTable(string: serversTOML)
        
        // 3. Update the root table with the new servers
        // This preserves all other top-level keys in rootTable
        if let newServers = tempTable["mcp_servers"] {
            rootTable["mcp_servers"] = newServers
        }
        
        // 4. Write back to file
        try String(describing: rootTable).write(to: url, atomically: false, encoding: .utf8)
    }

    func testConnection(to path: String) throws -> Int {
        let servers = try readConfig(from: path)
        return servers.count
    }

    /// Stores a security-scoped bookmark for a user-selected config file
    /// Call this after user selects a file via file picker
    func storeBookmarkForConfigFile(url: URL, path: String) throws {
        // Start accessing the security-scoped resource
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        // Store the bookmark
        try BookmarkManager.shared.storeBookmark(for: url)

        print("📌 Stored bookmark for config: \(path)")
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
