import SwiftUI

struct GlassPanel<Content: View>: View {
    let content: Content
    @Environment(\.themeColors) private var themeColors

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        if #available(macOS 26.0, *) {
            // macOS 26+: Use native Liquid Glass
            content
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.cornerRadius)
                        .fill(themeColors.glassBackground)
                )
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: DesignTokens.cornerRadius))
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
