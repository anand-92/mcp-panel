import SwiftUI

struct GlassPanel<Content: View>: View {
    let content: Content
    @Environment(\.themeColors) private var themeColors

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
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
