import SwiftUI

/// Builds the `Glass` value described by the user's appearance settings.
enum GlassFactory {
    /// - Returns: `nil` when glass is turned off, in which case callers should fall back
    ///   to a solid theme surface instead of a material.
    static func glass(for appearance: AppearanceSettings, accent: Color) -> Glass? {
        guard appearance.isGlassEnabled else { return nil }
        var glass: Glass = appearance.glassStyle == .clear ? .clear : .regular
        if appearance.tintGlassWithAccent {
            glass = glass.tint(accent)
        }
        return glass.interactive(appearance.interactiveGlass)
    }
}

/// A view modifier that applies Apple's Liquid Glass effect, or a solid theme-colored
/// surface when the user has turned glass off (or Reduce Transparency is honored).
struct LiquidGlassModifier<S: Shape>: ViewModifier {
    let shape: S
    var interactive: Bool = false

    @Environment(\.appearance) private var appearance
    @Environment(\.themeColors) private var themeColors

    func body(content: Content) -> some View {
        if let glass = GlassFactory.glass(for: resolvedAppearance, accent: themeColors.primaryAccent) {
            // Let glassEffect provide the material, don't apply fill
            content.glassEffect(glass, in: shape)
        } else {
            content.background(shape.fill(themeColors.panelBackground))
        }
    }

    /// `interactive` is a per-site capability, not a preference: sites that can't be
    /// interactive (a static header) must stay non-interactive regardless of the setting.
    private var resolvedAppearance: AppearanceSettings {
        guard !interactive else { return appearance }
        var copy = appearance
        copy.interactiveGlass = false
        return copy
    }
}

extension View {
    /// Applies the Liquid Glass effect clipped to the given shape.
    func liquidGlass<S: Shape>(shape: S, interactive: Bool = false) -> some View {
        modifier(LiquidGlassModifier(shape: shape, interactive: interactive))
    }
}
