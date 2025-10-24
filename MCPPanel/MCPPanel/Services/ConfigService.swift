//
//  ConfigService.swift
//  MCP Panel
//

import Foundation

actor ConfigService {
    private let fileService: FileSystemService

    init(fileService: FileSystemService) {
        self.fileService = fileService
    }

    // MARK: - Config File Operations

    func loadConfig(from path: String) async throws -> ClaudeConfig {
        let expandedPath = fileService.expandPath(path)

        guard fileService.fileExists(at: expandedPath) else {
            // Return empty config if file doesn't exist
            return ClaudeConfig()
        }

        do {
            return try fileService.readJSON(from: expandedPath, as: ClaudeConfig.self)
        } catch {
            throw ConfigError.loadFailed(path: expandedPath, reason: error.localizedDescription)
        }
    }

    func saveConfig(_ config: ClaudeConfig, to path: String) async throws {
        let expandedPath = fileService.expandPath(path)

        // Create backup before saving
        if fileService.fileExists(at: expandedPath) {
            _ = try? fileService.createBackup(of: expandedPath)
        }

        do {
            try fileService.writeJSON(config, to: expandedPath)
        } catch {
            throw ConfigError.saveFailed(path: expandedPath, reason: error.localizedDescription)
        }
    }

    func testConfigPath(_ path: String) async -> ConfigPathTestResult {
        let expandedPath = fileService.expandPath(path)

        var result = ConfigPathTestResult(
            path: path,
            exists: false,
            readable: false,
            writable: false,
            validJSON: false
        )

        // Check if file exists
        result.exists = fileService.fileExists(at: expandedPath)

        if result.exists {
            // Check if readable
            do {
                _ = try fileService.readFile(at: expandedPath)
                result.readable = true

                // Check if valid JSON
                result.validJSON = fileService.validateJSONFile(at: expandedPath)
            } catch {
                result.readable = false
            }

            // Check if writable (try to read then write back)
            if result.readable {
                do {
                    let data = try fileService.readFile(at: expandedPath)
                    try fileService.writeFile(data: data, to: expandedPath)
                    result.writable = true
                } catch {
                    result.writable = false
                }
            }
        } else {
            // File doesn't exist, check if we can create it
            let directory = (expandedPath as NSString).deletingLastPathComponent
            let fileManager = FileManager.default
            result.writable = fileManager.isWritableFile(atPath: directory)
        }

        return result
    }

    func getConfigPath() -> String {
        return fileService.expandPath("~/.claude.json")
    }

    // MARK: - Profile Operations

    func loadProfiles() async throws -> [Profile] {
        let profilesDir = fileService.profilesDirectory()

        // Create directory if it doesn't exist
        if !fileService.fileExists(at: profilesDir) {
            try fileService.createDirectory(at: profilesDir)
            return []
        }

        let files = try fileService.listFiles(in: profilesDir, withExtension: "json")

        var profiles: [Profile] = []
        for filename in files {
            let path = (profilesDir as NSString).appendingPathComponent(filename)
            if let profile = try? loadProfile(from: path, filename: filename) {
                profiles.append(profile)
            }
        }

        return profiles.sorted { $0.name < $1.name }
    }

    func loadProfile(from path: String, filename: String) throws -> Profile {
        let profileFile = try fileService.readJSON(from: path, as: ProfileFile.self)

        // Extract UUID from filename (format: {uuid}.json)
        let uuidString = (filename as NSString).deletingPathExtension
        let id = UUID(uuidString: uuidString) ?? UUID()

        return profileFile.toProfile(id: id)
    }

    func saveProfile(_ profile: Profile) async throws {
        let profilesDir = fileService.profilesDirectory()

        // Create directory if it doesn't exist
        if !fileService.fileExists(at: profilesDir) {
            try fileService.createDirectory(at: profilesDir)
        }

        let filename = "\(profile.id.uuidString).json"
        let path = (profilesDir as NSString).appendingPathComponent(filename)

        let profileFile = ProfileFile(from: profile)
        try fileService.writeJSON(profileFile, to: path)
    }

    func deleteProfile(_ profile: Profile) async throws {
        let profilesDir = fileService.profilesDirectory()
        let filename = "\(profile.id.uuidString).json"
        let path = (profilesDir as NSString).appendingPathComponent(filename)

        try fileService.deleteFile(at: path)
    }

    // MARK: - Global Config Operations

    func loadGlobalConfigs() async throws -> [String: ClaudeConfig] {
        // In the original app, this loads multiple global configs
        // For now, we'll just return a dictionary with the single global config if it exists
        var configs: [String: ClaudeConfig] = [:]

        let globalPath = fileService.expandPath("~/.claude-global.json")
        if fileService.fileExists(at: globalPath) {
            let config = try await loadConfig(from: globalPath)
            configs["global"] = config
        }

        return configs
    }

    func saveGlobalConfigs(_ configs: [String: ClaudeConfig]) async throws {
        // Save the primary global config
        if let globalConfig = configs["global"] {
            let globalPath = fileService.expandPath("~/.claude-global.json")
            try await saveConfig(globalConfig, to: globalPath)
        }
    }

    // MARK: - Server Operations

    func addServer(_ server: ServerConfig, to config: inout ClaudeConfig) {
        config.mcpServers[server.id] = server
    }

    func updateServer(_ server: ServerConfig, in config: inout ClaudeConfig) {
        config.mcpServers[server.id] = server
    }

    func deleteServer(id: String, from config: inout ClaudeConfig) {
        config.mcpServers.removeValue(forKey: id)
    }

    // MARK: - Validation

    func validateConfig(_ config: ClaudeConfig) -> [String] {
        var errors: [String] = []

        for (id, server) in config.mcpServers {
            if server.id != id {
                errors.append("Server ID mismatch: key '\(id)' != server.id '\(server.id)'")
            }

            let serverErrors = server.validationErrors()
            for error in serverErrors {
                errors.append("\(id): \(error)")
            }
        }

        return errors
    }
}

// MARK: - Supporting Types

struct ConfigPathTestResult {
    var path: String
    var exists: Bool
    var readable: Bool
    var writable: Bool
    var validJSON: Bool

    var isValid: Bool {
        return (exists && readable && writable && validJSON) || (!exists && writable)
    }

    var statusMessage: String {
        if !exists {
            return writable ? "Path is writable (file will be created)" : "Directory is not writable"
        }

        if !readable {
            return "File is not readable"
        }

        if !validJSON {
            return "File is not valid JSON"
        }

        if !writable {
            return "File is not writable"
        }

        return "Path is valid"
    }
}

enum ConfigError: LocalizedError {
    case loadFailed(path: String, reason: String)
    case saveFailed(path: String, reason: String)
    case invalidConfig(String)
    case profileNotFound(String)

    var errorDescription: String? {
        switch self {
        case .loadFailed(let path, let reason):
            return "Failed to load config from \(path): \(reason)"
        case .saveFailed(let path, let reason):
            return "Failed to save config to \(path): \(reason)"
        case .invalidConfig(let reason):
            return "Invalid configuration: \(reason)"
        case .profileNotFound(let name):
            return "Profile not found: \(name)"
        }
    }
}
