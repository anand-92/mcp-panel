import SwiftUI

// MARK: - Theme Type

enum AppTheme: String, CaseIterable {
    case claudeCode = "Claude Code"
    case geminiCLI = "Gemini CLI"
    case `default` = "Default"

    // Detect theme from config path
    static func detect(from configPath: String) -> AppTheme {
        let lowercased = configPath.lowercased()

        if lowercased.contains("claude") {
            return .claudeCode
        } else if lowercased.contains("settings") || lowercased.contains("gemini") {
            return .geminiCLI
        } else {
            return .default
        }
    }
}

// MARK: - Theme Colors

struct ThemeColors {
    // Background colors
    let mainBackground: Color
    let sidebarBackground: Color
    let panelBackground: Color
    let glassBackground: Color
    let glassBorder: Color

    // Multi-layer glass system for depth
    let glassLayer1: Color  // Deep background (0.01-0.02) - Furthest back
    let glassLayer2: Color  // Content panels (0.03-0.06) - Cards, main content
    let glassLayer3: Color  // Elevated panels (0.05-0.08) - Toolbars, headers
    let glassLayer4: Color  // Overlays (0.10-0.15) - Modals, tooltips
    let glassLayer5: Color  // Interactive focus (0.15-0.25) - Hover/active states

    // Multi-layer border system
    let borderLayer1: Color  // Subtle borders (0.3-0.4)
    let borderLayer2: Color  // Medium borders (0.6-0.7)
    let borderLayer3: Color  // Strong borders (0.9-1.0)

    // Text colors
    let primaryText: Color
    let secondaryText: Color
    let mutedText: Color

    // Accent colors
    let primaryAccent: Color
    let secondaryAccent: Color
    let successColor: Color
    let errorColor: Color
    let warningColor: Color

    // UI element colors
    let borderColor: Color
    let selectionColor: Color
    let lineHighlight: Color

    // Gradients
    let backgroundGradient: LinearGradient
    let accentGradient: LinearGradient

    // MARK: - Theme Presets

    static let claudeCode = ThemeColors(
        // Background - pitch black base
        mainBackground: Color(hex: "#0b0e14"),
        sidebarBackground: Color(hex: "#262626"),
        panelBackground: Color(hex: "#0b0e14"),
        glassBackground: Color.white.opacity(0.02),
        glassBorder: Color(hex: "#303030").opacity(0.5),

        // Multi-layer glass system for sophisticated depth
        glassLayer1: Color.white.opacity(0.015),  // Deep background
        glassLayer2: Color.white.opacity(0.04),   // Content panels (cards)
        glassLayer3: Color.white.opacity(0.06),   // Elevated panels (toolbars)
        glassLayer4: Color.white.opacity(0.12),   // Overlays (modals)
        glassLayer5: Color.white.opacity(0.20),   // Interactive focus

        // Multi-layer borders
        borderLayer1: Color(hex: "#303030").opacity(0.3),  // Subtle
        borderLayer2: Color(hex: "#303030").opacity(0.6),  // Medium
        borderLayer3: Color(hex: "#303030").opacity(0.9),  // Strong

        // Text colors
        primaryText: Color(hex: "#c3c1ba"),
        secondaryText: Color(hex: "#faf8f1").opacity(0.7),
        mutedText: Color(hex: "#c3c1ba").opacity(0.5),

        // Accent colors - Claude Code brand
        primaryAccent: Color(hex: "#d87757"), // Claude Code primary
        secondaryAccent: Color(hex: "#faf8f1"), // Secondary
        successColor: Color.green,
        errorColor: Color(hex: "#f14444"), // Destructive red
        warningColor: Color.orange,

        // UI elements
        borderColor: Color(hex: "#303030"),
        selectionColor: Color(hex: "#d87757").opacity(0.3),
        lineHighlight: Color(hex: "#262626"),

        // Gradients
        backgroundGradient: LinearGradient(
            colors: [
                Color(hex: "#0b0e14"),
                Color(hex: "#262626"),
                Color(hex: "#0b0e14")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        accentGradient: LinearGradient(
            colors: [
                Color(hex: "#d87757"),
                Color(hex: "#faf8f1")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )

    static let geminiCLI = ThemeColors(
        // Ayu Dark - pitch black background
        mainBackground: Color(hex: "#0b0e14"),
        sidebarBackground: Color(hex: "#0F1419"),
        panelBackground: Color(hex: "#0b0e14"),
        glassBackground: Color.white.opacity(0.03),
        glassBorder: Color(hex: "#3D4149"),

        // Multi-layer glass system for sophisticated depth
        glassLayer1: Color.white.opacity(0.02),   // Deep background
        glassLayer2: Color.white.opacity(0.045),  // Content panels (cards)
        glassLayer3: Color.white.opacity(0.07),   // Elevated panels (toolbars)
        glassLayer4: Color.white.opacity(0.13),   // Overlays (modals)
        glassLayer5: Color.white.opacity(0.22),   // Interactive focus

        // Multi-layer borders
        borderLayer1: Color(hex: "#3D4149").opacity(0.4),  // Subtle
        borderLayer2: Color(hex: "#3D4149").opacity(0.7),  // Medium
        borderLayer3: Color(hex: "#3D4149"),               // Strong

        // Text colors - Ayu Dark palette
        primaryText: Color(hex: "#aeaca6"),
        secondaryText: Color(hex: "#aeaca6").opacity(0.8),
        mutedText: Color(hex: "#646A71"),

        // Accent colors - Ayu Dark vibrant palette
        primaryAccent: Color(hex: "#39BAE6"), // Accent Blue
        secondaryAccent: Color(hex: "#59C2FF"), // Light Blue
        successColor: Color(hex: "#AAD94C"), // Accent Green
        errorColor: Color(hex: "#F26D78"), // Accent Red
        warningColor: Color(hex: "#FFB454"), // Accent Yellow

        // UI elements
        borderColor: Color(hex: "#3D4149"),
        selectionColor: Color(hex: "#39BAE6").opacity(0.3),
        lineHighlight: Color(hex: "#0F1419"),

        // Gradients - vibrant Ayu Dark accents
        backgroundGradient: LinearGradient(
            colors: [
                Color(hex: "#0b0e14"),
                Color(hex: "#0F1419"),
                Color(hex: "#0b0e14")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        accentGradient: LinearGradient(
            colors: [
                Color(hex: "#59C2FF"), // Light Blue
                Color(hex: "#39BAE6"), // Accent Blue
                Color(hex: "#D2A6FF"), // Accent Purple
                Color(hex: "#95E6CB")  // Accent Cyan
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )

    static let `default` = ThemeColors(
        // Original cyberpunk-ish theme
        mainBackground: Color(red: 0.016, green: 0.027, blue: 0.071),
        sidebarBackground: Color(red: 0.027, green: 0.067, blue: 0.122),
        panelBackground: Color(red: 0.012, green: 0.020, blue: 0.063),
        glassBackground: Color.white.opacity(0.05),
        glassBorder: Color.white.opacity(0.1),

        // Multi-layer glass system for sophisticated depth
        glassLayer1: Color.white.opacity(0.025),  // Deep background
        glassLayer2: Color.white.opacity(0.055),  // Content panels (cards)
        glassLayer3: Color.white.opacity(0.08),   // Elevated panels (toolbars)
        glassLayer4: Color.white.opacity(0.14),   // Overlays (modals)
        glassLayer5: Color.white.opacity(0.24),   // Interactive focus

        // Multi-layer borders
        borderLayer1: Color.white.opacity(0.06),  // Subtle
        borderLayer2: Color.white.opacity(0.12),  // Medium
        borderLayer3: Color.white.opacity(0.25),  // Strong

        // Text colors
        primaryText: Color.white.opacity(0.9),
        secondaryText: Color.white.opacity(0.7),
        mutedText: Color.white.opacity(0.5),

        // Accent colors
        primaryAccent: Color.cyan,
        secondaryAccent: Color.blue,
        successColor: Color.green,
        errorColor: Color.red,
        warningColor: Color.orange,

        // UI elements
        borderColor: Color.white.opacity(0.1),
        selectionColor: Color.blue.opacity(0.3),
        lineHighlight: Color.white.opacity(0.05),

        // Gradients
        backgroundGradient: LinearGradient(
            colors: [
                Color(red: 0.016, green: 0.027, blue: 0.071),
                Color(red: 0.027, green: 0.067, blue: 0.122),
                Color(red: 0.012, green: 0.020, blue: 0.063)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        accentGradient: LinearGradient(
            colors: [.cyan, .blue, .purple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )

    // Get theme colors for a specific theme type
    static func forTheme(_ theme: AppTheme) -> ThemeColors {
        switch theme {
        case .claudeCode:
            return .claudeCode
        case .geminiCLI:
            return .geminiCLI
        case .default:
            return .default
        }
    }
}

// MARK: - Color Extension for Hex Support

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Environment Keys for Theme

private struct ThemeColorsKey: EnvironmentKey {
    static let defaultValue: ThemeColors = .default
}

private struct CurrentThemeKey: EnvironmentKey {
    static let defaultValue: AppTheme = .default
}

extension EnvironmentValues {
    var themeColors: ThemeColors {
        get { self[ThemeColorsKey.self] }
        set { self[ThemeColorsKey.self] = newValue }
    }

    var currentTheme: AppTheme {
        get { self[CurrentThemeKey.self] }
        set { self[CurrentThemeKey.self] = newValue }
    }
}
