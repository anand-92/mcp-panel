import Foundation

// MARK: - Server Configuration Models

struct ServerTransportConfig: Codable, Equatable {
    var type: String
    var url: String?
    var headers: [String: String]?

    private enum CodingKeys: String, CodingKey {
        case type, url, headers
    }

    init(type: String, url: String? = nil, headers: [String: String]? = nil) {
        self.type = type
        self.url = url
        self.headers = headers
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)
        url = try container.decodeIfPresent(String.self, forKey: .url)
        headers = try container.decodeIfPresent([String: String].self, forKey: .headers)
    }
}

struct ServerRemoteConfig: Codable, Equatable {
    var type: String
    var url: String
    var headers: [String: String]?

    init(type: String, url: String, headers: [String: String]? = nil) {
        self.type = type
        self.url = url
        self.headers = headers
    }
}

struct ServerConfig: Codable, Equatable {
    var command: String?
    var args: [String]?
    var cwd: String?
    var env: [String: String]?
    var transport: ServerTransportConfig?
    var remotes: [ServerRemoteConfig]?

    // Support for new format with type field
    var type: String?
    var url: String?

    private enum CodingKeys: String, CodingKey {
        case command, args, cwd, env, transport, remotes, type, url
    }

    init(command: String? = nil,
         args: [String]? = nil,
         cwd: String? = nil,
         env: [String: String]? = nil,
         transport: ServerTransportConfig? = nil,
         remotes: [ServerRemoteConfig]? = nil,
         type: String? = nil,
         url: String? = nil) {
        self.command = command
        self.args = args
        self.cwd = cwd
        self.env = env
        self.transport = transport
        self.remotes = remotes
        self.type = type
        self.url = url
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        command = try container.decodeIfPresent(String.self, forKey: .command)
        args = try container.decodeIfPresent([String].self, forKey: .args)
        cwd = try container.decodeIfPresent(String.self, forKey: .cwd)
        env = try container.decodeIfPresent([String: String].self, forKey: .env)
        transport = try container.decodeIfPresent(ServerTransportConfig.self, forKey: .transport)
        remotes = try container.decodeIfPresent([ServerRemoteConfig].self, forKey: .remotes)
        type = try container.decodeIfPresent(String.self, forKey: .type)
        url = try container.decodeIfPresent(String.self, forKey: .url)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(command, forKey: .command)
        try container.encodeIfPresent(args, forKey: .args)
        try container.encodeIfPresent(cwd, forKey: .cwd)
        try container.encodeIfPresent(env, forKey: .env)
        try container.encodeIfPresent(transport, forKey: .transport)
        try container.encodeIfPresent(remotes, forKey: .remotes)
        try container.encodeIfPresent(type, forKey: .type)
        try container.encodeIfPresent(url, forKey: .url)
    }

    // MARK: - Validation

    var isValid: Bool {
        // Check for stdio-type servers
        if type == "stdio", let cmd = command, !cmd.trimmingCharacters(in: .whitespaces).isEmpty {
            return true
        }

        // Check for HTTP-type servers
        if type == "http", let urlString = url, !urlString.trimmingCharacters(in: .whitespaces).isEmpty {
            return true
        }

        // Check for standard command-based servers
        let hasCommand = command?.trimmingCharacters(in: .whitespaces).isEmpty == false
        let hasTransport = transport != nil
        let hasRemotes = remotes?.isEmpty == false

        return hasCommand || hasTransport || hasRemotes
    }

    // MARK: - Summary

    var summary: String {
        if let cmd = command, !cmd.trimmingCharacters(in: .whitespaces).isEmpty {
            return cmd.trimmingCharacters(in: .whitespaces)
        }

        if let transport = transport {
            let transportType = transport.type
            let urlHost = transport.url.flatMap { formatURLHost($0) } ?? "custom endpoint"
            return "Remote \(transportType) → \(urlHost)"
        }

        if let remotes = remotes, let firstRemote = remotes.first {
            let remoteType = firstRemote.type
            let urlHost = formatURLHost(firstRemote.url)
            return "Remote \(remoteType) → \(urlHost)"
        }

        return "Custom server configuration"
    }

    private func formatURLHost(_ urlString: String) -> String {
        guard let url = URL(string: urlString) else { return urlString }
        return url.host ?? urlString
    }
}
