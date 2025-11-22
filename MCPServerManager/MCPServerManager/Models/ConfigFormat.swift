import Foundation

/// Configuration file format detection
enum ConfigFormat: String, Codable, CaseIterable {
    case json = "JSON"
    case toml = "TOML"

    var description: String {
        rawValue
    }

    var fileExtension: String {
        switch self {
        case .json: return ".json"
        case .toml: return ".toml"
        }
    }

    /// Detect format from file path
    static func detect(from path: String) -> ConfigFormat {
        let lowercased = path.lowercased()
        if lowercased.hasSuffix(".toml") {
            return .toml
        }
        return .json  // Default to JSON
    }
}
