import SwiftUI

// MARK: - App Constants

enum AppConstants {
    static let appName = "MCP Panel"
    static let defaultConfigPath = "~/.claude.json"
    static let mcpRegistryURL = "https://lobehub.com/mcp"
}

// MARK: - Design Tokens

enum DesignTokens {
    // MARK: - Theme-Aware Colors

    // Get colors for the current theme
    static func colors(for theme: AppTheme) -> ThemeColors {
        return ThemeColors.forTheme(theme)
    }

    // MARK: - Legacy Color Properties (for backward compatibility during migration)

    static let primaryGradient = LinearGradient(
        colors: [.cyan, .blue, .purple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let glassBackground = Color.white.opacity(0.05)
    static let glassBorder = Color.white.opacity(0.1)

    static let backgroundGradient = LinearGradient(
        colors: [
            Color(red: 0.016, green: 0.027, blue: 0.071),
            Color(red: 0.027, green: 0.067, blue: 0.122),
            Color(red: 0.012, green: 0.020, blue: 0.063)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let successColor = Color.green
    static let errorColor = Color.red
    static let warningColor = Color.orange
    static let activeColor = Color.blue

    // MARK: - Typography

    // Font Family Names
    enum FontFamily {
        static let sans = "Poppins"
        static let serif = "Crimson Pro"
    }

    /// The live appearance settings backing every scaled token below.
    @MainActor
    private static var appearance: AppearanceSettings { AppearanceRuntime.current }

    // Font Weights
    enum FontWeight {
        case regular
        case medium
        case semibold
        case bold

        var suffix: String {
            switch self {
            case .regular: return "-Regular"
            case .medium: return "-Medium"
            case .semibold: return "-SemiBold"
            case .bold: return "-Bold"
            }
        }

        var systemWeight: Font.Weight {
            switch self {
            case .regular: return .regular
            case .medium: return .medium
            case .semibold: return .semibold
            case .bold: return .bold
            }
        }
    }

    /// Rounds a scaled point size to a whole number: fractional font sizes make custom
    /// fonts render with uneven metrics next to the AppKit controls beside them.
    @MainActor
    private static func scaled(_ size: CGFloat) -> CGFloat {
        max(6, (size * appearance.textSize.scale).rounded())
    }

    // UI font honoring the user's typeface and text-size preferences.
    @MainActor
    static func sans(size: CGFloat, weight: FontWeight = .regular) -> Font {
        let pointSize = scaled(size)
        switch appearance.uiFont {
        case .poppins:
            return Font.custom(FontFamily.sans + weight.suffix, size: pointSize)
        case .system:
            return Font.system(size: pointSize, weight: weight.systemWeight)
        case .serif:
            return Font.custom(FontFamily.serif + weight.suffix, size: pointSize)
        }
    }

    // Serif fonts (Crimson Pro) - for body text and reading
    @MainActor
    static func serif(size: CGFloat, weight: FontWeight = .regular) -> Font {
        return Font.custom(FontFamily.serif + weight.suffix, size: scaled(size))
    }

    // Monospace font for code/JSON
    static let monoFont = Font.system(.body, design: .monospaced)

    /// Monospaced font at the user's configured code size, offset for the smaller and
    /// larger code styles so their relative sizes are preserved.
    @MainActor
    static func mono(offset: CGFloat = 0) -> Font {
        Font.system(size: max(7, appearance.codeFontSize + offset), design: .monospaced)
    }

    // Semantic Typography System. These are computed (not stored) so changing the
    // text-size or UI-font preference re-renders every label that uses them.
    @MainActor
    enum Typography {
        // Display & Titles (Sans)
        static var hero: Font { sans(size: 60, weight: .bold) }        // Onboarding emoji-like text
        static var display: Font { sans(size: 40, weight: .bold) }    // Empty state icons
        static var title1: Font { sans(size: 28, weight: .bold) }     // Main titles
        static var title2: Font { sans(size: 22, weight: .semibold) } // Modal titles, server names
        static var title3: Font { sans(size: 20, weight: .semibold) } // Section headers

        // Body Text
        static var bodyLarge: Font { sans(size: 17, weight: .regular) }  // Main body text
        static var body: Font { sans(size: 14, weight: .regular) }       // Standard body text
        static var bodySmall: Font { sans(size: 12, weight: .regular) }  // Secondary text

        // UI Elements
        static var buttonLarge: Font { sans(size: 16, weight: .semibold) }
        static var button: Font { sans(size: 14, weight: .medium) }
        static var label: Font { sans(size: 14, weight: .regular) }
        static var labelSmall: Font { sans(size: 12, weight: .regular) }
        static var caption: Font { sans(size: 11, weight: .regular) }
        static var captionSmall: Font { sans(size: 10, weight: .bold) }

        // Code & Technical (Monospace)
        static var codeLarge: Font { mono(offset: 2) }
        static var code: Font { mono() }
        static var codeSmall: Font { mono(offset: -2) }
    }

    // MARK: - Spacing

    @MainActor static var cornerRadius: CGFloat { appearance.cornerRadius }
    @MainActor static var cardPadding: CGFloat { appearance.cardPadding }
    @MainActor static var gridSpacing: CGFloat { appearance.gridSpacing }

    // MARK: - Effects

    @MainActor static var jsonPreviewBlurRadius: CGFloat { appearance.jsonBlurStrength }
}

// MARK: - Grid Configuration

@MainActor
enum GridConfiguration {
    static var columns: [GridItem] {
        let minimum = AppearanceRuntime.current.minCardWidth
        return [
            GridItem(.adaptive(minimum: minimum, maximum: minimum * 1.5), spacing: DesignTokens.gridSpacing)
        ]
    }
}
