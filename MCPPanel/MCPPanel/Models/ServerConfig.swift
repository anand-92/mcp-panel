//
//  ServerConfig.swift
//  MCP Panel
//

import Foundation

// MARK: - Server Configuration Models

struct ServerConfig: Codable, Identifiable, Hashable {
    let id: String
    var command: String
    var args: [String]?
    var env: [String: String]?
    var disabled: Bool?
    var alwaysAllow: [String]?

    enum CodingKeys: String, CodingKey {
        case command, args, env, disabled, alwaysAllow
    }

    init(id: String, command: String, args: [String]? = nil, env: [String: String]? = nil,
         disabled: Bool? = nil, alwaysAllow: [String]? = nil) {
        self.id = id
        self.command = command
        self.args = args
        self.env = env
        self.disabled = disabled
        self.alwaysAllow = alwaysAllow
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = ""  // Will be set when loading from dictionary
        self.command = try container.decode(String.self, forKey: .command)
        self.args = try container.decodeIfPresent([String].self, forKey: .args)
        self.env = try container.decodeIfPresent([String: String].self, forKey: .env)
        self.disabled = try container.decodeIfPresent(Bool.self, forKey: .disabled)
        self.alwaysAllow = try container.decodeIfPresent([String].self, forKey: .alwaysAllow)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(command, forKey: .command)
        try container.encodeIfPresent(args, forKey: .args)
        try container.encodeIfPresent(env, forKey: .env)
        try container.encodeIfPresent(disabled, forKey: .disabled)
        try container.encodeIfPresent(alwaysAllow, forKey: .alwaysAllow)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: ServerConfig, rhs: ServerConfig) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Config File Structure

struct ClaudeConfig: Codable {
    var mcpServers: [String: ServerConfig]

    init(mcpServers: [String: ServerConfig] = [:]) {
        self.mcpServers = mcpServers
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let serversDict = try container.decode([String: ServerConfig].self, forKey: .mcpServers)

        // Set the ID for each server based on its key
        var servers: [String: ServerConfig] = [:]
        for (key, var server) in serversDict {
            server = ServerConfig(
                id: key,
                command: server.command,
                args: server.args,
                env: server.env,
                disabled: server.disabled,
                alwaysAllow: server.alwaysAllow
            )
            servers[key] = server
        }
        self.mcpServers = servers
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(mcpServers, forKey: .mcpServers)
    }

    enum CodingKeys: String, CodingKey {
        case mcpServers
    }
}

// MARK: - Validation & Helpers

extension ServerConfig {
    var isValid: Bool {
        return !command.isEmpty
    }

    var displayName: String {
        return id.isEmpty ? "Unnamed Server" : id
    }

    var isEnabled: Bool {
        return !(disabled ?? false)
    }

    var environmentCount: Int {
        return env?.count ?? 0
    }

    var argumentCount: Int {
        return args?.count ?? 0
    }

    var allowedToolsCount: Int {
        return alwaysAllow?.count ?? 0
    }

    // Check if command appears to be an npm package
    var isNpmPackage: Bool {
        return command.hasPrefix("npx") || command.contains("node_modules")
    }

    // Check if command is absolute path
    var isAbsolutePath: Bool {
        return command.hasPrefix("/") || command.hasPrefix("~")
    }

    // Validation errors
    func validationErrors() -> [String] {
        var errors: [String] = []

        if command.isEmpty {
            errors.append("Command is required")
        }

        if command.contains(" ") && !(args?.isEmpty ?? true) {
            errors.append("Command should not contain spaces when args are provided")
        }

        if let env = env {
            for (key, value) in env {
                if key.isEmpty {
                    errors.append("Environment variable key cannot be empty")
                }
                if value.isEmpty {
                    errors.append("Environment variable '\(key)' has empty value")
                }
            }
        }

        return errors
    }

    var hasValidationErrors: Bool {
        return !validationErrors().isEmpty
    }
}

// MARK: - Sample Data

extension ServerConfig {
    static let sample = ServerConfig(
        id: "example-server",
        command: "npx",
        args: ["-y", "@modelcontextprotocol/server-example"],
        env: ["ENV_VAR": "value"],
        disabled: false
    )

    static let samples = [
        ServerConfig(
            id: "filesystem",
            command: "npx",
            args: ["-y", "@modelcontextprotocol/server-filesystem", "/tmp"],
            disabled: false
        ),
        ServerConfig(
            id: "github",
            command: "npx",
            args: ["-y", "@modelcontextprotocol/server-github"],
            env: ["GITHUB_TOKEN": "your_token_here"],
            disabled: false
        ),
        ServerConfig(
            id: "postgres",
            command: "npx",
            args: ["-y", "@modelcontextprotocol/server-postgres"],
            env: ["POSTGRES_URL": "postgresql://localhost/mydb"],
            disabled: true
        )
    ]
}
