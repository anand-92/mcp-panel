import Foundation
import TOMLKit

/// Utility functions for TOML conversion
enum TOMLUtils {
    /// Converts a ServerConfig dictionary to TOML string format
    static func serversToTOMLString(_ servers: [String: ServerConfig]) throws -> String {
        var lines: [String] = []
        lines.append("[mcp_servers]")
        lines.append("")

        for (name, config) in servers.sorted(by: { $0.key < $1.key }) {
            // Encode ServerConfig to JSON dict
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
            let data = try encoder.encode(config)
            let jsonDict = try JSONSerialization.jsonObject(with: data) as! [String: Any]

            // Convert to TOML section
            lines.append("[\(quoteKeyIfNeeded("mcp_servers.\(name)"))]")
            lines.append(contentsOf: dictToTOMLLines(jsonDict, indent: ""))
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }

    /// Converts a dictionary to TOML lines
    private static func dictToTOMLLines(_ dict: [String: Any], indent: String) -> [String] {
        var lines: [String] = []

        for (key, value) in dict.sorted(by: { $0.key < $1.key }) {
            if let stringValue = value as? String {
                lines.append("\(indent)\(key) = \(quoteString(stringValue))")
            } else if let intValue = value as? Int {
                lines.append("\(indent)\(key) = \(intValue)")
            } else if let doubleValue = value as? Double {
                lines.append("\(indent)\(key) = \(doubleValue)")
            } else if let boolValue = value as? Bool {
                lines.append("\(indent)\(key) = \(boolValue)")
            } else if let arrayValue = value as? [Any] {
                lines.append("\(indent)\(key) = \(arrayToTOML(arrayValue))")
            } else if let dictValue = value as? [String: Any] {
                // Inline table for nested objects
                lines.append("\(indent)\(key) = \(inlineTableToTOML(dictValue))")
            }
        }

        return lines
    }

    /// Converts array to TOML format
    private static func arrayToTOML(_ array: [Any]) -> String {
        let elements = array.map { element -> String in
            if let string = element as? String {
                return quoteString(string)
            } else if let int = element as? Int {
                return "\(int)"
            } else if let double = element as? Double {
                return "\(double)"
            } else if let bool = element as? Bool {
                return "\(bool)"
            } else if let dict = element as? [String: Any] {
                return inlineTableToTOML(dict)
            } else {
                return "\(element)"
            }
        }
        return "[\(elements.joined(separator: ", "))]"
    }

    /// Converts dictionary to inline TOML table
    private static func inlineTableToTOML(_ dict: [String: Any]) -> String {
        let pairs = dict.sorted(by: { $0.key < $1.key }).map { key, value -> String in
            let valueStr: String
            if let string = value as? String {
                valueStr = quoteString(string)
            } else if let int = value as? Int {
                valueStr = "\(int)"
            } else if let double = value as? Double {
                valueStr = "\(double)"
            } else if let bool = value as? Bool {
                valueStr = "\(bool)"
            } else if let array = value as? [Any] {
                valueStr = arrayToTOML(array)
            } else if let nestedDict = value as? [String: Any] {
                valueStr = inlineTableToTOML(nestedDict)
            } else {
                valueStr = "\(value)"
            }
            return "\(key) = \(valueStr)"
        }
        return "{ \(pairs.joined(separator: ", ")) }"
    }

    /// Quotes a string for TOML
    private static func quoteString(_ string: String) -> String {
        let escaped = string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\t", with: "\\t")
        return "\"\(escaped)\""
    }

    /// Quotes a key if it contains special characters
    private static func quoteKeyIfNeeded(_ key: String) -> String {
        // If key contains dots or special chars, quote it
        if key.contains(".") || key.contains(" ") {
            return "\"\(key)\""
        }
        return key
    }

    /// Converts TOMLTable to JSON-compatible dictionary (reusing ConfigManager logic)
    static func tomlTableToDictionary(_ table: TOMLTable) -> [String: Any]? {
        var dict: [String: Any] = [:]

        for (key, valueConvertible) in table {
            if let value = convertToAny(valueConvertible) {
                dict[key] = value
            }
        }

        return dict.isEmpty ? nil : dict
    }

    /// Helper to convert TOMLValueConvertible to Any
    private static func convertToAny(_ value: any TOMLValueConvertible) -> Any? {
        if let string = value as? String {
            return string
        } else if let int = value as? Int {
            return int
        } else if let double = value as? Double {
            return double
        } else if let bool = value as? Bool {
            return bool
        } else if let array = value as? TOMLArray {
            return array.compactMap { convertToAny($0) }
        } else if let table = value as? TOMLTable {
            return tomlTableToDictionary(table)
        }
        return nil
    }
}
