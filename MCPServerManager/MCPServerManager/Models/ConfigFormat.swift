import Foundation

/// Configuration file format detection
enum ConfigFormat: String, Codable, CaseIterable {
    case json = "JSON"

    var description: String {
        rawValue
    }

    var fileExtension: String {
        return ".json"
    }

    /// Detect format from file path (always JSON now)
    static func detect(from path: String) -> ConfigFormat {
        return .json
    }
}
