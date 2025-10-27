import Foundation

// MARK: - MCP Registry Service

@MainActor
class MCPRegistryService: ObservableObject {
    static let shared = MCPRegistryService()

    @Published var isLoading: Bool = false
    @Published var error: String?

    private let apiURL = "https://api.mcp.github.com/2025-09-15/v0/servers"
    private var cachedServers: [RegistryServer]?
    private var cacheTimestamp: Date?
    private let cacheTimeout: TimeInterval = 3600 // 1 hour

    private init() {}

    /// Fetch servers from the MCP registry
    func fetchServers() async throws -> [RegistryServer] {
        // Check cache first
        if let cached = cachedServers,
           let timestamp = cacheTimestamp,
           Date().timeIntervalSince(timestamp) < cacheTimeout {
            #if DEBUG
            print("MCPRegistryService: Returning cached servers (\(cached.count) servers)")
            #endif
            return cached
        }

        #if DEBUG
        print("MCPRegistryService: Fetching from API: \(apiURL)")
        #endif

        isLoading = true
        defer { isLoading = false }

        // Fetch all pages
        var allServers: [RegistryAPIServer] = []
        var cursor: String? = nil
        var pageCount = 0

        repeat {
            pageCount += 1
            let pageURL = cursor == nil ? apiURL : "\(apiURL)?cursor=\(cursor!)"

            guard let url = URL(string: pageURL) else {
                throw MCPRegistryError.invalidURL
            }

            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw MCPRegistryError.invalidResponse
            }

            guard httpResponse.statusCode == 200 else {
                throw MCPRegistryError.httpError(httpResponse.statusCode)
            }

            let apiResponse = try JSONDecoder().decode(RegistryAPIResponse.self, from: data)

            #if DEBUG
            print("MCPRegistryService: Page \(pageCount) - Fetched \(apiResponse.servers.count) servers")
            #endif

            allServers.append(contentsOf: apiResponse.servers)

            // Check for next page
            cursor = apiResponse.metadata?.nextCursor
            if cursor?.isEmpty == true {
                cursor = nil
            }
        } while cursor != nil

        #if DEBUG
        print("MCPRegistryService: Total \(allServers.count) servers fetched across \(pageCount) page(s)")
        #endif

        // Process servers and extract configs
        let registryServers = allServers.compactMap { apiServer -> RegistryServer? in
            guard let readme = apiServer.repository?.readme,
                  let config = extractConfigFromReadme(readme) else {
                #if DEBUG
                print("MCPRegistryService: Skipping \(apiServer.name) - no valid config found")
                #endif
                return nil
            }

            let packageInfo = apiServer.packages?.first
            let metadata = RegistryMetadata(
                createdAt: apiServer.createdAt,
                updatedAt: apiServer.updatedAt,
                packageIdentifier: packageInfo?.identifier,
                packageVersion: packageInfo?.version,
                registryType: packageInfo?.registryType,
                runtimeHint: packageInfo?.runtimeHint
            )

            return RegistryServer(
                id: apiServer.name,
                name: apiServer.name,
                description: apiServer.description,
                repository: apiServer.repository?.url ?? "",
                config: config,
                metadata: metadata
            )
        }

        #if DEBUG
        print("MCPRegistryService: Successfully processed \(registryServers.count) servers")
        #endif

        // Update cache
        cachedServers = registryServers
        cacheTimestamp = Date()

        return registryServers
    }

    /// Clear cached servers (force refresh on next fetch)
    func clearCache() {
        cachedServers = nil
        cacheTimestamp = nil
    }

    // MARK: - Private Helpers

    /// Extract MCP config from README markdown
    private func extractConfigFromReadme(_ readme: String) -> ServerConfig? {
        let jsonBlocks = extractJSONBlocks(from: readme)

        for block in jsonBlocks {
            if let config = parseConfigBlock(block) {
                return config
            }
        }

        return nil
    }

    /// Extract JSON code blocks from markdown
    private func extractJSONBlocks(from markdown: String) -> [String] {
        var blocks: [String] = []

        // Pattern 1: ```json\n...\n```
        let jsonPattern = #"```json\s*\n(.*?)\n```"#
        if let jsonRegex = try? NSRegularExpression(pattern: jsonPattern, options: [.dotMatchesLineSeparators]) {
            let matches = jsonRegex.matches(in: markdown, range: NSRange(markdown.startIndex..., in: markdown))
            for match in matches {
                if let range = Range(match.range(at: 1), in: markdown) {
                    blocks.append(String(markdown[range]))
                }
            }
        }

        // Pattern 2: ```\n{...}\n```
        let codeBlockPattern = #"```\s*\n(\{.*?\})\n```"#
        if let codeRegex = try? NSRegularExpression(pattern: codeBlockPattern, options: [.dotMatchesLineSeparators]) {
            let matches = codeRegex.matches(in: markdown, range: NSRange(markdown.startIndex..., in: markdown))
            for match in matches {
                if let range = Range(match.range(at: 1), in: markdown) {
                    blocks.append(String(markdown[range]))
                }
            }
        }

        return blocks
    }

    /// Try to parse a JSON block as an MCP config
    private func parseConfigBlock(_ jsonString: String) -> ServerConfig? {
        guard let data = jsonString.data(using: .utf8) else { return nil }

        // Try to decode as JSON
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        // Check if it's an mcpServers wrapper
        if let mcpServers = json["mcpServers"] as? [String: Any],
           let firstServer = mcpServers.values.first as? [String: Any] {
            return parseServerConfig(firstServer)
        }

        // Check if it's a direct server config
        if json["command"] != nil || json["args"] != nil {
            return parseServerConfig(json)
        }

        // Check if it's a nested structure
        for value in json.values {
            if let serverDict = value as? [String: Any],
               serverDict["command"] != nil || serverDict["args"] != nil {
                return parseServerConfig(serverDict)
            }
        }

        return nil
    }

    /// Parse a server config dictionary into ServerConfig
    private func parseServerConfig(_ dict: [String: Any]) -> ServerConfig? {
        guard let configData = try? JSONSerialization.data(withJSONObject: dict),
              let config = try? JSONDecoder().decode(ServerConfig.self, from: configData),
              config.isValid else {
            return nil
        }

        return config
    }
}

// MARK: - Errors

enum MCPRegistryError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid registry URL"
        case .invalidResponse:
            return "Invalid response from registry"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        }
    }
}
