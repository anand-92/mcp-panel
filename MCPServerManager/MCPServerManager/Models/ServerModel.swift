import Foundation

struct ServerModel: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var config: ServerConfig
    var enabled: Bool
    var updatedAt: Date
    var inConfigs: [Bool] // [inConfig1, inConfig2]

    init(id: UUID = UUID(),
         name: String,
         config: ServerConfig,
         enabled: Bool = false,
         updatedAt: Date = Date(),
         inConfigs: [Bool] = [false, false]) {
        self.id = id
        self.name = name
        self.config = config
        self.enabled = enabled
        self.updatedAt = updatedAt
        self.inConfigs = inConfigs
    }

    // MARK: - Computed Properties

    var configJSON: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        guard let data = try? encoder.encode(config),
              let string = String(data: data, encoding: .utf8) else {
            return "{}"
        }

        return string
    }

    var isInConfig1: Bool { inConfigs.count > 0 ? inConfigs[0] : false }
    var isInConfig2: Bool { inConfigs.count > 1 ? inConfigs[1] : false }
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
