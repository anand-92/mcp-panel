import Foundation

struct AppSettings: Codable, Equatable {
    var confirmDelete: Bool
    var configPaths: [String]
    var activeConfigIndex: Int
    var windowOpacity: Double

    static let `default` = AppSettings(
        confirmDelete: true,
        configPaths: [
            "~/.claude.json",
            "~/.settings.json"
        ],
        activeConfigIndex: 0,
        windowOpacity: 1.0
    )

    init(confirmDelete: Bool = true,
         configPaths: [String] = ["~/.claude.json", "~/.settings.json"],
         activeConfigIndex: Int = 0,
         windowOpacity: Double = 1.0) {
        self.confirmDelete = confirmDelete
        self.configPaths = configPaths
        self.activeConfigIndex = max(0, min(activeConfigIndex, 1)) // Ensure 0 or 1
        self.windowOpacity = max(0.3, min(windowOpacity, 1.0)) // Clamp between 0.3 and 1.0
    }

    var activeConfigPath: String {
        configPaths[safe: activeConfigIndex] ?? configPaths[0]
    }

    var config1Path: String {
        configPaths[safe: 0] ?? "~/.claude.json"
    }

    var config2Path: String {
        configPaths[safe: 1] ?? "~/.settings.json"
    }
}

enum ViewMode: String, Codable, CaseIterable {
    case grid = "grid"
    case rawJSON = "list"

    var displayName: String {
        switch self {
        case .grid: return "Grid"
        case .rawJSON: return "Raw JSON"
        }
    }
}

enum FilterMode: String, Codable, CaseIterable {
    case all = "all"
    case active = "active"
    case disabled = "disabled"
    case recent = "recent"

    var displayName: String {
        switch self {
        case .all: return "All Servers"
        case .active: return "Active Only"
        case .disabled: return "Disabled Only"
        case .recent: return "Recently Modified"
        }
    }
}

// MARK: - Array Extension for Safe Access

extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
