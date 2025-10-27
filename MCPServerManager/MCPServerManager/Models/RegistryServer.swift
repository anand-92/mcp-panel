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
    let imageUrl: String?

    init(id: String,
         name: String,
         description: String,
         repository: String,
         config: ServerConfig,
         metadata: RegistryMetadata,
         imageUrl: String? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.repository = repository
        self.config = config
        self.metadata = metadata
        self.imageUrl = imageUrl
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
    let metadata: PaginationMetadata?
}

struct PaginationMetadata: Codable {
    let count: Int
    let nextCursor: String?
    let totalPages: Int

    enum CodingKeys: String, CodingKey {
        case count
        case nextCursor = "next_cursor"
        case totalPages = "total_pages"
    }
}

struct RegistryAPIServer: Codable {
    let name: String
    let description: String
    let repository: RepositoryInfo?
    let packages: [PackageInfo]?
    let remotes: [APIRemoteConfig]?
    let createdAt: String?
    let updatedAt: String?
    let meta: ServerMeta?

    enum CodingKeys: String, CodingKey {
        case name, description, repository, packages, remotes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case meta = "_meta"
    }
}

struct ServerMeta: Codable {
    let publisherProvided: PublisherProvided?

    enum CodingKeys: String, CodingKey {
        case publisherProvided = "io.modelcontextprotocol.registry/publisher-provided"
    }
}

struct PublisherProvided: Codable {
    let github: GitHubMetadata?
}

struct GitHubMetadata: Codable {
    let opengraphImageUrl: String?
    let ownerAvatarUrl: String?
    let preferredImage: String?

    enum CodingKeys: String, CodingKey {
        case opengraphImageUrl = "opengraph_image_url"
        case ownerAvatarUrl = "owner_avatar_url"
        case preferredImage = "preferred_image"
    }
}

struct APIRemoteConfig: Codable {
    let transportType: String
    let url: String
    let headers: [APIHeader]?

    enum CodingKeys: String, CodingKey {
        case transportType = "transport_type"
        case url, headers
    }
}

struct APIHeader: Codable {
    let name: String
    let value: String
    let variables: [String: APIHeaderVariable]?
}

struct APIHeaderVariable: Codable {
    let description: String?
    let isSecret: Bool?

    enum CodingKeys: String, CodingKey {
        case description
        case isSecret = "is_secret"
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
