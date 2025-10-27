import Foundation

// MARK: - Registry Server Model

/// Represents a server from the MCP GitHub registry
struct RegistryServer: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let repository: String
    let config: ServerConfig
    let metadata: RegistryMetadata

    init(id: String,
         name: String,
         description: String,
         repository: String,
         config: ServerConfig,
         metadata: RegistryMetadata) {
        self.id = id
        self.name = name
        self.description = description
        self.repository = repository
        self.config = config
        self.metadata = metadata
    }

    /// Display name (without org prefix)
    var displayName: String {
        name.split(separator: "/").last.map(String.init) ?? name
    }

    /// Formatted config as pretty JSON string
    var configJSON: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]

        guard let data = try? encoder.encode(config),
              let string = String(data: data, encoding: .utf8) else {
            return "{}"
        }

        return string
    }
}

// MARK: - Registry Metadata

struct RegistryMetadata: Codable {
    let createdAt: String?
    let updatedAt: String?
    let packageIdentifier: String?
    let packageVersion: String?
    let registryType: String?
    let runtimeHint: String?

    enum CodingKeys: String, CodingKey {
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case packageIdentifier = "package_identifier"
        case packageVersion = "package_version"
        case registryType = "registry_type"
        case runtimeHint = "runtime_hint"
    }
}

// MARK: - Registry API Response Models

struct RegistryAPIResponse: Codable {
    let servers: [RegistryAPIServer]
}

struct RegistryAPIServer: Codable {
    let name: String
    let description: String
    let repository: RepositoryInfo?
    let packages: [PackageInfo]?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case name, description, repository, packages
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct RepositoryInfo: Codable {
    let url: String
    let readme: String?
}

struct PackageInfo: Codable {
    let identifier: String?
    let version: String?
    let registryType: String?
    let runtimeHint: String?

    enum CodingKeys: String, CodingKey {
        case identifier
        case version
        case registryType = "registry_type"
        case runtimeHint = "runtime_hint"
    }
}
