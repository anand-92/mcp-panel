import Foundation

/// Utility to extract server configurations from raw JSON input
/// Based on the original Electron version's forgiving parser
struct ServerExtractor {

    /// Extract server entries from raw JSON string
    /// Handles common issues like trailing commas, missing braces, etc.
    static func extractServerEntries(from raw: String) -> [String: ServerConfig]? {
        var normalized = raw.trimmingCharacters(in: .whitespacesAndNewlines)

        print("DEBUG ServerExtractor: Input length: \(raw.count)")

        // Handle JSON fragments: if it doesn't start with {, try wrapping it
        // This includes cases like: "server-name": { ... } (missing outer braces)
        if !normalized.hasPrefix("{") {
            print("DEBUG ServerExtractor: Adding outer braces")
            normalized = "{\(normalized)}"
        }

        // Remove trailing commas before closing braces (common copy-paste issue)
        normalized = normalized.replacingOccurrences(
            of: ",\\s*([}\\]])",
            with: "$1",
            options: .regularExpression
        )

        // Try to parse the JSON
        guard let data = normalized.data(using: .utf8) else {
            print("DEBUG ServerExtractor: Failed to convert to UTF8 data")
            return nil
        }

        do {
            guard let parsed = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                print("DEBUG ServerExtractor: Parsed JSON is not a dictionary")
                return nil
            }

            print("DEBUG ServerExtractor: Successfully parsed JSON with keys: \(parsed.keys.joined(separator: ", "))")

            // Check if it has mcpServers wrapper
            if let mcpServers = parsed["mcpServers"] as? [String: Any] {
                print("DEBUG ServerExtractor: Found mcpServers wrapper with \(mcpServers.count) servers")
                return parseServerDictionary(mcpServers)
            }

            // Otherwise treat the whole thing as server entries
            print("DEBUG ServerExtractor: No mcpServers wrapper, treating as direct server entries")
            return parseServerDictionary(parsed)
        } catch {
            print("DEBUG ServerExtractor: JSON parsing error: \(error.localizedDescription)")
            return nil
        }
    }

    /// Parse a dictionary into ServerConfig entries
    private static func parseServerDictionary(_ dict: [String: Any]) -> [String: ServerConfig]? {
        var result: [String: ServerConfig] = [:]

        print("DEBUG parseServerDictionary: Processing \(dict.count) entries")

        for (name, value) in dict {
            print("DEBUG parseServerDictionary: Processing server '\(name)'")

            guard let configDict = value as? [String: Any] else {
                print("DEBUG parseServerDictionary: Server '\(name)' value is not a dictionary")
                continue
            }

            print("DEBUG parseServerDictionary: Server '\(name)' has keys: \(configDict.keys.joined(separator: ", "))")

            if let config = parseServerConfig(configDict) {
                print("DEBUG parseServerDictionary: Successfully parsed server '\(name)', isValid: \(config.isValid)")
                result[name] = config
            } else {
                print("DEBUG parseServerDictionary: Failed to parse config for '\(name)'")
            }
        }

        print("DEBUG parseServerDictionary: Result has \(result.count) servers")
        return result.isEmpty ? nil : result
    }

    /// Parse a single server config from a dictionary
    private static func parseServerConfig(_ dict: [String: Any]) -> ServerConfig? {
        var command: String?
        var args: [String]?
        var env: [String: String]?
        var cwd: String?
        var transport: ServerTransportConfig?
        var remotes: [ServerRemoteConfig]?
        var type: String?
        var url: String?

        // Extract type
        type = dict["type"] as? String

        // Extract command (handle both string and array)
        if let cmdString = dict["command"] as? String {
            command = cmdString
        } else if let cmdArray = dict["command"] as? [Any] {
            // Handle array format: first element is command, rest are args
            let stringArray = cmdArray.compactMap { $0 as? String }
            if !stringArray.isEmpty {
                command = stringArray[0]
                if stringArray.count > 1 {
                    args = Array(stringArray.dropFirst())
                }
            }
        }

        // Extract args (if not already set from command array)
        if args == nil {
            args = dict["args"] as? [String]
        }

        // Extract env/environment (handle both field names)
        if let envDict = dict["environment"] as? [String: String] {
            env = envDict
        } else if let envDict = dict["env"] as? [String: String] {
            env = envDict
        } else if let envDict = dict["environment"] as? [String: Any] {
            env = envDict.compactMapValues { $0 as? String }
        } else if let envDict = dict["env"] as? [String: Any] {
            env = envDict.compactMapValues { $0 as? String }
        }

        // Extract cwd
        cwd = dict["cwd"] as? String

        // Extract url
        url = dict["url"] as? String

        // Extract transport
        if let transportDict = dict["transport"] as? [String: Any],
           let transportType = transportDict["type"] as? String {
            transport = ServerTransportConfig(
                type: transportType,
                url: transportDict["url"] as? String,
                headers: transportDict["headers"] as? [String: String]
            )
        }

        // Extract remotes
        if let remotesArray = dict["remotes"] as? [[String: Any]] {
            remotes = remotesArray.compactMap { remoteDict in
                guard let remoteType = remoteDict["type"] as? String,
                      let remoteURL = remoteDict["url"] as? String else {
                    return nil
                }
                return ServerRemoteConfig(
                    type: remoteType,
                    url: remoteURL,
                    headers: remoteDict["headers"] as? [String: String]
                )
            }
        }

        return ServerConfig(
            command: command,
            args: args,
            cwd: cwd,
            env: env,
            transport: transport,
            remotes: remotes,
            type: type,
            url: url
        )
    }
}
