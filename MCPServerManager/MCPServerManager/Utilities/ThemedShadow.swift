import SwiftUI

/// Applies a decorative shadow that the user can switch off in Settings.
///
/// Only for elevation and glow. The 1–2 pt shadows that give toggle knobs their
/// shape are part of those controls and stay unconditional.
private struct ThemedShadow: ViewModifier {
    let color: Color
    let radius: CGFloat
    let xOffset: CGFloat
    let yOffset: CGFloat

    @Environment(\.appearance) private var appearance

    func body(content: Content) -> some View {
        if appearance.shadowsEnabled {
            content.shadow(color: color, radius: radius, x: xOffset, y: yOffset)
        } else {
            content
        }
    }
}

extension View {
    /// A decorative shadow, suppressed when the user turns shadows off.
    func themedShadow(
        color: Color = .black.opacity(0.33),
        radius: CGFloat,
        x xOffset: CGFloat = 0,
        y yOffset: CGFloat = 0
    ) -> some View {
        modifier(ThemedShadow(color: color, radius: radius, xOffset: xOffset, yOffset: yOffset))
    }
}
