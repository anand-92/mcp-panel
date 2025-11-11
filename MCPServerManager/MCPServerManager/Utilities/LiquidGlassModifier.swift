import SwiftUI

/// A view modifier that applies Apple's Liquid Glass effect on macOS 26+
/// and gracefully falls back to a standard background on earlier versions.
struct LiquidGlassModifier<S: Shape>: ViewModifier {
    let shape: S
    var fillColor: Color = Color(nsColor: .windowBackgroundColor)

    func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            // macOS 26+: Use native Liquid Glass effect
            // Let glassEffect provide the material, don't apply fill
            content
                .glassEffect(.regular, in: shape)
        } else {
            // macOS 13-25: Use standard background
            content
                .background(
                    shape
                        .fill(fillColor)
                )
        }
    }
}

extension View {
    /// Applies Liquid Glass effect on macOS 26+ with graceful fallback
    func liquidGlass<S: Shape>(shape: S, fillColor: Color = Color(nsColor: .windowBackgroundColor)) -> some View {
        modifier(LiquidGlassModifier(shape: shape, fillColor: fillColor))
    }
}
