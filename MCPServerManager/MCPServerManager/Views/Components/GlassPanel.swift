import SwiftUI

struct GlassPanel<Content: View>: View {
    let content: Content
    @Environment(\.cyberpunkMode) private var cyberpunkMode

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.cornerRadius)
                    .fill(cyberpunkMode ? AnyShapeStyle(cyberpunkGlassBackground) : AnyShapeStyle(DesignTokens.glassBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.cornerRadius)
                            .stroke(cyberpunkMode ? Color.cyan.opacity(0.3) : DesignTokens.glassBorder, lineWidth: 1)
                    )
                    .shadow(
                        color: cyberpunkMode ? .cyan.opacity(0.3) : .black.opacity(0.3),
                        radius: cyberpunkMode ? 25 : 20,
                        x: 0,
                        y: 10
                    )
            )
    }

    private var cyberpunkGlassBackground: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.067, green: 0.141, blue: 0.275).opacity(0.82),
                Color(red: 0.035, green: 0.043, blue: 0.173).opacity(0.88)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Environment Key for Cyberpunk Mode

private struct CyberpunkModeKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var cyberpunkMode: Bool {
        get { self[CyberpunkModeKey.self] }
        set { self[CyberpunkModeKey.self] = newValue }
    }
}
