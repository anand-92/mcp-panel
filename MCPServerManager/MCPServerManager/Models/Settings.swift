import Foundation

struct AppSettings: Codable, Equatable {
    var confirmDelete: Bool
    var configPaths: [String]
    var activeConfigIndex: Int
    var windowOpacity: Double
    var textVisibilityBoost: Double
    var overrideTheme: String? // nil = auto-detect, otherwise use the theme name

    static let `default` = AppSettings(
        confirmDelete: true,
        configPaths: [
            "~/.claude.json",
            "~/.settings.json"
        ],
        activeConfigIndex: 0,
        windowOpacity: 1.0,
        textVisibilityBoost: 0.5,
        overrideTheme: nil
    )

    init(confirmDelete: Bool = true,
         configPaths: [String] = ["~/.claude.json", "~/.settings.json"],
         activeConfigIndex: Int = 0,
         windowOpacity: Double = 1.0,
         textVisibilityBoost: Double = 0.5,
         overrideTheme: String? = nil) {
        self.confirmDelete = confirmDelete
        self.configPaths = configPaths
        self.activeConfigIndex = max(0, min(activeConfigIndex, 1)) // Ensure 0 or 1
        self.windowOpacity = max(0.3, min(windowOpacity, 1.0)) // Clamp between 0.3 and 1.0
        self.textVisibilityBoost = max(0.0, min(textVisibilityBoost, 1.0)) // Clamp between 0.0 and 1.0
        self.overrideTheme = overrideTheme
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

    /// Calculates how much extra opacity to add to text based on window translucency
    /// - Returns: A value between 0.0 and 1.0 representing the opacity boost
    func textOpacityBoost() -> Double {
        // When window is fully opaque (1.0), no boost needed
        // When window is translucent (e.g., 0.3), boost kicks in proportionally
        let transparencyLevel = 1.0 - windowOpacity
        return transparencyLevel * textVisibilityBoost
    }

    /// Applies the text visibility boost to a base opacity value
    /// - Parameter baseOpacity: The original opacity value (e.g., 0.7 for secondary text)
    /// - Returns: The adjusted opacity value that maintains better visibility
    func adjustedTextOpacity(_ baseOpacity: Double) -> Double {
        // Add the boost to the base opacity, clamped to max 1.0
        // This makes text more opaque as the window becomes more transparent
        return min(1.0, baseOpacity + textOpacityBoost())
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
