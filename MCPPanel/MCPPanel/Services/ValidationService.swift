//
//  ValidationService.swift
//  MCP Panel
//

import Foundation

class ValidationService {

    // MARK: - Server Validation

    func validate(server: ServerConfig) -> [String] {
        var errors: [String] = []

        // Command validation
        if server.command.isEmpty {
            errors.append("Command is required")
        }

        // Check for common mistakes
        if server.command.contains(" ") && !(server.args?.isEmpty ?? true) {
            errors.append("Command should not contain spaces when args are provided separately")
        }

        // Validate command exists (basic check)
        if !server.command.isEmpty {
            let commandErrors = validateCommand(server.command)
            errors.append(contentsOf: commandErrors)
        }

        // Environment validation
        if let env = server.env {
            let envErrors = validateEnvironment(env)
            errors.append(contentsOf: envErrors)
        }

        // Args validation
        if let args = server.args {
            let argsErrors = validateArgs(args)
            errors.append(contentsOf: argsErrors)
        }

        // AlwaysAllow validation
        if let alwaysAllow = server.alwaysAllow {
            let allowErrors = validateAlwaysAllow(alwaysAllow)
            errors.append(contentsOf: allowErrors)
        }

        return errors
    }

    // MARK: - Command Validation

    private func validateCommand(_ command: String) -> [String] {
        var errors: [String] = []

        // Check if command is too long
        if command.count > 500 {
            errors.append("Command is too long (max 500 characters)")
        }

        // Check for dangerous commands
        let dangerousCommands = ["rm", "sudo", "dd", "mkfs", "format"]
        for dangerous in dangerousCommands {
            if command.hasPrefix(dangerous) || command.contains("/\(dangerous)") {
                errors.append("Warning: Command '\(dangerous)' may be dangerous")
            }
        }

        // Check if it's a valid executable path or command
        if command.hasPrefix("/") || command.hasPrefix("~") {
            // It's a path, check if it could be valid
            let expanded = (command as NSString).expandingTildeInPath
            if !FileManager.default.fileExists(atPath: expanded) {
                errors.append("Command path does not exist: \(command)")
            }
        }

        return errors
    }

    // MARK: - Environment Validation

    private func validateEnvironment(_ env: [String: String]) -> [String] {
        var errors: [String] = []

        for (key, value) in env {
            // Check for empty keys
            if key.isEmpty {
                errors.append("Environment variable key cannot be empty")
                continue
            }

            // Check for invalid characters in keys
            let validKeyPattern = "^[a-zA-Z_][a-zA-Z0-9_]*$"
            if !key.range(of: validKeyPattern, options: .regularExpression).map({ !$0.isEmpty }) ?? false {
                errors.append("Invalid environment variable name: '\(key)' (must start with letter or underscore)")
            }

            // Warn about sensitive data
            let sensitiveKeys = ["password", "secret", "token", "key", "api_key"]
            for sensitive in sensitiveKeys {
                if key.lowercased().contains(sensitive) && !value.isEmpty {
                    errors.append("Warning: '\(key)' may contain sensitive data")
                }
            }

            // Check for very long values
            if value.count > 5000 {
                errors.append("Environment variable '\(key)' has very long value (>5000 chars)")
            }
        }

        return errors
    }

    // MARK: - Args Validation

    private func validateArgs(_ args: [String]) -> [String] {
        var errors: [String] = []

        // Check for too many args
        if args.count > 100 {
            errors.append("Too many arguments (>100)")
        }

        // Check for very long args
        for (index, arg) in args.enumerated() {
            if arg.count > 1000 {
                errors.append("Argument at index \(index) is very long (>1000 chars)")
            }
        }

        // Check for empty args
        if args.contains(where: { $0.isEmpty }) {
            errors.append("Arguments contain empty strings")
        }

        return errors
    }

    // MARK: - AlwaysAllow Validation

    private func validateAlwaysAllow(_ alwaysAllow: [String]) -> [String] {
        var errors: [String] = []

        // Check for empty values
        if alwaysAllow.contains(where: { $0.isEmpty }) {
            errors.append("alwaysAllow contains empty strings")
        }

        // Check for duplicates
        let uniqueItems = Set(alwaysAllow)
        if uniqueItems.count != alwaysAllow.count {
            errors.append("alwaysAllow contains duplicate entries")
        }

        return errors
    }

    // MARK: - Config Path Validation

    func validateConfigPath(_ path: String) -> [String] {
        var errors: [String] = []

        if path.isEmpty {
            errors.append("Config path cannot be empty")
            return errors
        }

        // Expand tilde
        let expanded = (path as NSString).expandingTildeInPath

        // Check if it's a valid path format
        if !expanded.hasPrefix("/") {
            errors.append("Config path must be an absolute path")
        }

        // Check if it's a JSON file
        if !(path as NSString).pathExtension.lowercased().contains("json") {
            errors.append("Config file should have .json extension")
        }

        // Check parent directory
        let directory = (expanded as NSString).deletingLastPathComponent
        if !FileManager.default.fileExists(atPath: directory) {
            errors.append("Parent directory does not exist: \(directory)")
        }

        return errors
    }

    // MARK: - Profile Name Validation

    func validateProfileName(_ name: String) -> [String] {
        var errors: [String] = []

        if name.isEmpty {
            errors.append("Profile name cannot be empty")
            return errors
        }

        if name.count < 2 {
            errors.append("Profile name must be at least 2 characters")
        }

        if name.count > 50 {
            errors.append("Profile name must be less than 50 characters")
        }

        // Check for invalid characters
        let invalidChars = CharacterSet(charactersIn: "/\\:*?\"<>|")
        if name.rangeOfCharacter(from: invalidChars) != nil {
            errors.append("Profile name contains invalid characters")
        }

        return errors
    }
}
