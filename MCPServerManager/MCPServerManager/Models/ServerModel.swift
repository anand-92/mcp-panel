import Foundation
import TOMLKit

struct ServerModel: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var config: ServerConfig
    var enabled: Bool
    var updatedAt: Date
    var inConfigs: [Bool] // [inConfig1, inConfig2, inConfig3]
    var registryImageUrl: String? // Image URL from MCP registry (takes precedence over fetched icons)
    var customIconPath: String? // User-selected custom icon path (takes highest precedence)

    // UNIVERSE ISOLATION: Which universe this server belongs to (0/1 = Claude/Gemini, 2 = Codex)
    // Once set, this NEVER changes. Servers stay in their universe forever.
    let sourceUniverse: Int

    init(id: UUID = UUID(),
         name: String,
         config: ServerConfig,
         enabled: Bool = false,
         updatedAt: Date = Date(),
         inConfigs: [Bool] = [false, false, false],
         registryImageUrl: String? = nil,
         customIconPath: String? = nil,
         sourceUniverse: Int = 0) {
        self.id = id
        self.name = name
        self.config = config
        self.enabled = enabled
        self.updatedAt = updatedAt
        self.inConfigs = inConfigs
        self.registryImageUrl = registryImageUrl
        self.customIconPath = customIconPath
        self.sourceUniverse = sourceUniverse
    }

    // MARK: - Computed Properties

    var configJSON: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]

        guard let data = try? encoder.encode(config),
              let string = String(data: data, encoding: .utf8) else {
            return "{}"
        }

        return string
    }

    var configTOML: String {
        // Use centralized TOML utilities
        guard let tomlString = try? TOMLUtils.serversToTOMLString([name: config]) else {
            return ""
        }

        // Extract just the server section (remove [mcp_servers] header and server name)
        let lines = tomlString.split(separator: "\n")
        let serverLines = lines.dropFirst(3) // Skip [mcp_servers], blank line, and [mcp_servers.name]
        return serverLines.joined(separator: "\n")
    }

    var isInConfig1: Bool { inConfigs.count > 0 ? inConfigs[0] : false }
    var isInConfig2: Bool { inConfigs.count > 1 ? inConfigs[1] : false }
    var isInConfig3: Bool { inConfigs.count > 2 ? inConfigs[2] : false }

    // UNIVERSE CHECKS: Strict separation between Claude/Gemini and Codex
    var isClaudeGeminiUniverse: Bool { sourceUniverse == 0 || sourceUniverse == 1 }
    var isCodexUniverse: Bool { sourceUniverse == 2 }

    /// Extract domain for icon fetching
    var iconDomain: String? {
        return DomainExtractor.extractDomain(from: name, config: config)
    }
}

// MARK: - Config Response

struct ConfigResponse: Codable {
    let success: Bool
    let servers: [String: ServerConfig]
    let fullConfig: FullConfig?
    let isNew: Bool?
    let error: String?

    struct FullConfig: Codable {
        let mcpServers: [String: ServerConfig]?
    }
}

// MARK: - Save Response

struct SaveResponse: Codable {
    let success: Bool
    let error: String?
}
