import SwiftUI

/// A view modifier that applies Apple's Liquid Glass effect.
struct LiquidGlassModifier<S: Shape>: ViewModifier {
    let shape: S

    func body(content: Content) -> some View {
        // Let glassEffect provide the material, don't apply fill
        content
            .glassEffect(.regular, in: shape)
    }
}

extension View {
    /// Applies the Liquid Glass effect clipped to the given shape.
    func liquidGlass<S: Shape>(shape: S) -> some View {
        modifier(LiquidGlassModifier(shape: shape))
    }
}
