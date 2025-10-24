import SwiftUI

// MARK: - App Constants

enum AppConstants {
    static let appName = "MCP Server Manager"
    static let defaultConfigPath = "~/.claude.json"
    static let defaultSettingsPath = "~/.settings.json"
    static let mcpRegistryURL = "https://lobehub.com/mcp"
}

// MARK: - Design Tokens

enum DesignTokens {
    // MARK: - Colors

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

    static let cyberpunkBackgroundGradient = LinearGradient(
        colors: [
            Color(red: 0.035, green: 0.0, blue: 0.094),
            Color(red: 0.043, green: 0.004, blue: 0.259),
            Color(red: 0.008, green: 0.0, blue: 0.059)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let successColor = Color.green
    static let errorColor = Color.red
    static let warningColor = Color.orange
    static let activeColor = Color.blue

    // MARK: - Typography

    static let monoFont = Font.system(.body, design: .monospaced)

    // MARK: - Spacing

    static let cornerRadius: CGFloat = 16
    static let cardPadding: CGFloat = 16
    static let gridSpacing: CGFloat = 16

    // MARK: - Shadows

    static func glassCardShadow(cyberpunk: Bool = false) -> some View {
        EmptyView()
            .shadow(color: cyberpunk ? .cyan.opacity(0.3) : .black.opacity(0.3), radius: 20, x: 0, y: 10)
    }
}

// MARK: - Grid Configuration

enum GridConfiguration {
    static let columns = [
        GridItem(.adaptive(minimum: 400, maximum: 600), spacing: 16)
    ]
    static let minCardHeight: CGFloat = 280
}
