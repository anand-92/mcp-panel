import SwiftUI

struct GlassPanel<Content: View>: View {
    let content: Content
    @Environment(\.themeColors) private var themeColors

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        if #available(macOS 26.0, *) {
            // macOS 26+: Use native Liquid Glass with interactive variant
            // Let glassEffect provide everything - no custom overlays or effects
            content
                .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: DesignTokens.cornerRadius))
        } else {
            // macOS 13-25: Traditional glass morphism
            content
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.cornerRadius)
                        .fill(themeColors.glassBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.cornerRadius)
                                .stroke(themeColors.glassBorder, lineWidth: 1)
                        )
                        .shadow(
                            color: .black.opacity(0.3),
                            radius: 20,
                            x: 0,
                            y: 10
                        )
                )
        }
    }
}
