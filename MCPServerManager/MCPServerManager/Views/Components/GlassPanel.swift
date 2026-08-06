import SwiftUI

struct GlassPanel<Content: View>: View {
    let content: Content

    @Environment(\.appearance) private var appearance

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        // Let glassEffect provide everything - no custom overlays or effects
        content
            .liquidGlass(
                shape: RoundedRectangle(cornerRadius: appearance.cornerRadius),
                interactive: true
            )
    }
}
