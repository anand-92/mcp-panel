import Foundation

/// Configuration file format detection
enum ConfigFormat: String, Codable, CaseIterable {
    case json = "JSON"

    var description: String {
        rawValue
    }

    var fileExtension: String {
        switch self {
        case .json: return ".json"
        }
    }

    /// Detect format from file path
    static func detect(from path: String) -> ConfigFormat {
        return .json  // Always JSON
    }
}
