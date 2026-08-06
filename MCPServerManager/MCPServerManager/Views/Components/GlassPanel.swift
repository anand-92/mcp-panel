import SwiftUI

struct GlassPanel<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        // Let glassEffect provide everything - no custom overlays or effects
        content
            .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: DesignTokens.cornerRadius))
    }
}
