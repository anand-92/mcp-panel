//
//  FileSystemService.swift
//  MCP Panel
//

import Foundation

class FileSystemService {
    private let fileManager = FileManager.default
    private let decoder = JSONDecoder()
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    // MARK: - File Operations

    func readFile(at path: String) throws -> Data {
        let url = URL(fileURLWithPath: path)
        return try Data(contentsOf: url)
    }

    func writeFile(data: Data, to path: String) throws {
        let url = URL(fileURLWithPath: path)

        // Create parent directory if needed
        let directory = url.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: directory.path) {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }

        try data.write(to: url, options: .atomic)
    }

    func fileExists(at path: String) -> Bool {
        return fileManager.fileExists(atPath: path)
    }

    func deleteFile(at path: String) throws {
        let url = URL(fileURLWithPath: path)
        try fileManager.removeItem(at: url)
    }

    // MARK: - JSON Operations

    func readJSON<T: Decodable>(from path: String, as type: T.Type) throws -> T {
        let data = try readFile(at: path)
        return try decoder.decode(type, from: data)
    }

    func writeJSON<T: Encodable>(_ value: T, to path: String) throws {
        let data = try encoder.encode(value)
        try writeFile(data: data, to: path)
    }

    // MARK: - Directory Operations

    func createDirectory(at path: String) throws {
        let url = URL(fileURLWithPath: path)
        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
    }

    func listFiles(in directory: String, withExtension ext: String? = nil) throws -> [String] {
        let url = URL(fileURLWithPath: directory)
        let contents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)

        if let ext = ext {
            return contents
                .filter { $0.pathExtension == ext }
                .map { $0.lastPathComponent }
        }

        return contents.map { $0.lastPathComponent }
    }

    // MARK: - Path Utilities

    func expandPath(_ path: String) -> String {
        return (path as NSString).expandingTildeInPath
    }

    func applicationSupportDirectory() -> String {
        let urls = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        guard let appSupport = urls.first else {
            return expandPath("~/Library/Application Support/MCP Panel")
        }
        return appSupport.appendingPathComponent("MCP Panel").path
    }

    func profilesDirectory() -> String {
        return expandPath("~/.mcp-manager/profiles")
    }

    // MARK: - File Validation

    func validateJSONFile(at path: String) -> Bool {
        do {
            let data = try readFile(at: path)
            _ = try JSONSerialization.jsonObject(with: data)
            return true
        } catch {
            return false
        }
    }

    func getFileSize(at path: String) -> Int64? {
        do {
            let attributes = try fileManager.attributesOfItem(atPath: path)
            return attributes[.size] as? Int64
        } catch {
            return nil
        }
    }

    func getFileModificationDate(at path: String) -> Date? {
        do {
            let attributes = try fileManager.attributesOfItem(atPath: path)
            return attributes[.modificationDate] as? Date
        } catch {
            return nil
        }
    }

    // MARK: - Backup Operations

    func createBackup(of path: String) throws -> String {
        let backupPath = "\(path).backup"
        let data = try readFile(at: path)
        try writeFile(data: data, to: backupPath)
        return backupPath
    }

    func restoreBackup(from backupPath: String, to originalPath: String) throws {
        let data = try readFile(at: backupPath)
        try writeFile(data: data, to: originalPath)
    }
}

// MARK: - File System Errors

enum FileSystemError: LocalizedError {
    case fileNotFound(String)
    case invalidJSON(String)
    case writePermissionDenied(String)
    case directoryCreationFailed(String)

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "File not found: \(path)"
        case .invalidJSON(let path):
            return "Invalid JSON in file: \(path)"
        case .writePermissionDenied(let path):
            return "Permission denied writing to: \(path)"
        case .directoryCreationFailed(let path):
            return "Failed to create directory: \(path)"
        }
    }
}
