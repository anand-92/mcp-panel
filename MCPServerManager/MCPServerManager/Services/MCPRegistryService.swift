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

    // Compiled regex patterns for better performance
    private static let jsonBlockRegex = try! NSRegularExpression(pattern: #"```json\s*\n(.*?)\n```"#, options: [.dotMatchesLineSeparators])
    private static let codeBlockRegex = try! NSRegularExpression(pattern: #"```\s*\n(\{.*?\})\n```"#, options: [.dotMatchesLineSeparators])
    private static let inlineRegex = try! NSRegularExpression(pattern: #""[^"]+"\s*:\s*\{[\s\S]*?"command"\s*:[\s\S]*?\}"#, options: [])

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
            let pageURL = apiURL + (cursor.flatMap { $0.isEmpty ? nil : $0 }.map { "?cursor=\($0)" } ?? "")

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

            let apiResponse: RegistryAPIResponse
            do {
                apiResponse = try JSONDecoder().decode(RegistryAPIResponse.self, from: data)
            } catch {
                throw MCPRegistryError.decodingError(error)
            }

            #if DEBUG
            print("MCPRegistryService: Page \(pageCount) - Fetched \(apiResponse.servers.count) servers")
            #endif

            allServers.append(contentsOf: apiResponse.servers)

            // Check for next page
            cursor = apiResponse.metadata?.nextCursor.flatMap { $0.isEmpty ? nil : $0 }
        } while cursor != nil

        #if DEBUG
        print("MCPRegistryService: Total \(allServers.count) servers fetched across \(pageCount) page(s)")
        #endif

        // Process servers and extract configs
        let registryServers = allServers.compactMap { apiServer -> RegistryServer? in
            // Try to get config from remotes first (HTTP/SSE servers)
            var config: ServerConfig?

            if let remotes = apiServer.remotes, !remotes.isEmpty {
                config = createConfigFromRemotes(remotes)
                #if DEBUG
                if config != nil {
                    print("MCPRegistryService: Using remotes config for \(apiServer.name)")
                }
                #endif
            }

            // Fall back to README extraction if no remotes
            if config == nil, let readme = apiServer.repository?.readme {
                config = extractConfigFromReadme(readme)
                #if DEBUG
                if config != nil {
                    print("MCPRegistryService: Extracted config from README for \(apiServer.name)")
                }
                #endif
            }

            guard let finalConfig = config else {
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

            // Extract image URL from metadata (prefer preferredImage, fallback to ownerAvatarUrl)
            let imageUrl = apiServer.meta?.publisherProvided?.github?.preferredImage
                        ?? apiServer.meta?.publisherProvided?.github?.ownerAvatarUrl

            return RegistryServer(
                id: apiServer.name,
                name: apiServer.name,
                description: apiServer.description,
                repository: apiServer.repository?.url ?? "",
                config: finalConfig,
                metadata: metadata,
                imageUrl: imageUrl
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

    /// Create config from API remotes data (HTTP/SSE servers)
    private func createConfigFromRemotes(_ remotes: [APIRemoteConfig]) -> ServerConfig? {
        // Use the first remote
        guard let remote = remotes.first else { return nil }

        // Map transport type to our config format
        let transportType: String
        switch remote.transportType.lowercased() {
        case "sse":
            transportType = "sse"
        case "http", "https":
            transportType = "http"
        default:
            transportType = remote.transportType
        }

        // Create config with type and url
        let config = ServerConfig(
            command: nil,
            args: nil,
            cwd: nil,
            env: nil,
            transport: nil,
            remotes: nil,
            type: transportType,
            url: remote.url
        )

        // Validate it's a proper remote config
        guard config.isValid else { return nil }

        return config
    }

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
        let matches1 = Self.jsonBlockRegex.matches(in: markdown, range: NSRange(markdown.startIndex..., in: markdown))
        for match in matches1 {
            if let range = Range(match.range(at: 1), in: markdown) {
                blocks.append(String(markdown[range]))
            }
        }

        // Pattern 2: ```\n{...}\n```
        let matches2 = Self.codeBlockRegex.matches(in: markdown, range: NSRange(markdown.startIndex..., in: markdown))
        for match in matches2 {
            if let range = Range(match.range(at: 1), in: markdown) {
                blocks.append(String(markdown[range]))
            }
        }

        // Pattern 3: Inline JSON with server name (e.g., "server-name": { ... })
        // This catches configs like: "chroma": { "command": "uvx", "args": [...] }
        let matches3 = Self.inlineRegex.matches(in: markdown, range: NSRange(markdown.startIndex..., in: markdown))
        for match in matches3 {
            if let range = Range(match.range, in: markdown) {
                let jsonStr = String(markdown[range])
                // Try to find the complete JSON object (handle nested braces)
                if let completeJson = extractCompleteJSON(from: markdown, startingAt: range.lowerBound) {
                    blocks.append(completeJson)
                } else {
                    // Fallback: wrap in braces to make it valid JSON
                    blocks.append("{\(jsonStr)}")
                }
            }
        }

        return blocks
    }

    /// Extract a complete JSON object with proper brace matching
    private func extractCompleteJSON(from text: String, startingAt: String.Index) -> String? {
        var depth = 0
        var startIndex: String.Index?
        var endIndex: String.Index?
        var inString = false
        var escapeNext = false

        var currentIndex = startingAt

        while currentIndex < text.endIndex {
            let char = text[currentIndex]

            if escapeNext {
                escapeNext = false
                currentIndex = text.index(after: currentIndex)
                continue
            }

            if char == "\\" {
                escapeNext = true
                currentIndex = text.index(after: currentIndex)
                continue
            }

            if char == "\"" {
                inString.toggle()
                currentIndex = text.index(after: currentIndex)
                continue
            }

            if !inString {
                if char == "{" {
                    if startIndex == nil {
                        startIndex = currentIndex
                    }
                    depth += 1
                } else if char == "}" {
                    depth -= 1
                    if depth == 0 && startIndex != nil {
                        endIndex = text.index(after: currentIndex)
                        break
                    }
                }
            }

            currentIndex = text.index(after: currentIndex)
        }

        if let start = startIndex, let end = endIndex {
            return String(text[start..<end])
        }

        return nil
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
