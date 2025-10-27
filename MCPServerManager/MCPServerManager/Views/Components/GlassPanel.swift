import SwiftUI

// MARK: - Glass Layer Types

/// Defines depth layers for the glass morphism design system
///
/// **Usage Guidelines:**
/// - `.layer1` - Furthest back elements (deep backgrounds, base panels)
/// - `.layer2` - Content containers (cards, content panels) - **Use this for most components**
/// - `.layer3` - Elevated UI (toolbars, headers, navigation)
/// - `.layer4` - Overlays (tooltips, dropdowns)
/// - `.layer5` - Interactive states (hover, active, focus)
///
/// **When to use custom styling instead of GlassPanel:**
/// - Modal dialogs may use `glassLayer4` color directly with custom shadows for extra emphasis
/// - Full-screen overlays that need unique backdrop treatment
/// - Components with specific interaction patterns requiring non-standard depth
enum GlassLayer {
    case layer1  // Deep background (0.01-0.02) - Furthest back
    case layer2  // Content panels (0.03-0.06) - Cards, main content
    case layer3  // Elevated panels (0.05-0.08) - Toolbars, headers
    case layer4  // Overlays (0.10-0.15) - Modals, tooltips
    case layer5  // Interactive focus (0.15-0.25) - Hover/active states

    /// Shadow properties grouped as (radius, opacity, y-offset) for clarity
    private var shadowProperties: (radius: CGFloat, opacity: Double, y: CGFloat) {
        switch self {
        case .layer1: return (8, 0.15, 2)
        case .layer2: return (15, 0.25, 6)
        case .layer3: return (22, 0.35, 10)
        case .layer4: return (30, 0.45, 15)
        case .layer5: return (40, 0.55, 20)
        }
    }

    var shadowRadius: CGFloat { shadowProperties.radius }
    var shadowOpacity: Double { shadowProperties.opacity }
    var shadowY: CGFloat { shadowProperties.y }
}

// MARK: - Glass Panel Component

struct GlassPanel<Content: View>: View {
    let content: Content
    let layer: GlassLayer
    let customCornerRadius: CGFloat?

    @Environment(\.themeColors) private var themeColors

    init(
        layer: GlassLayer = .layer2,
        cornerRadius: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.layer = layer
        self.customCornerRadius = cornerRadius
    }

    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: customCornerRadius ?? DesignTokens.cornerRadius)
                    .fill(glassColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: customCornerRadius ?? DesignTokens.cornerRadius)
                            .stroke(borderColor, lineWidth: 1)
                    )
                    .shadow(
                        color: .black.opacity(layer.shadowOpacity),
                        radius: layer.shadowRadius,
                        x: 0,
                        y: layer.shadowY
                    )
            )
    }

    private var glassColor: Color {
        switch layer {
        case .layer1: return themeColors.glassLayer1
        case .layer2: return themeColors.glassLayer2
        case .layer3: return themeColors.glassLayer3
        case .layer4: return themeColors.glassLayer4
        case .layer5: return themeColors.glassLayer5
        }
    }

    private var borderColor: Color {
        switch layer {
        case .layer1, .layer2: return themeColors.borderLayer1
        case .layer3: return themeColors.borderLayer2
        case .layer4, .layer5: return themeColors.borderLayer3
        }
    }
}

// MARK: - Code Editor Background

/// A reusable background component for code editors (TextEditor, code views)
/// Combines glass layer with dark text scrim for optimal code readability
struct CodeEditorBackground: View {
    @Environment(\.themeColors) private var themeColors

    var body: some View {
        ZStack {
            themeColors.glassLayer2
            Color.black.opacity(0.25)  // Text scrim for code readability
        }
    }
}

// MARK: - View Extension for Code Editor Background

extension View {
    /// Applies the standard code editor background (glass + text scrim)
    func codeEditorBackground() -> some View {
        self.background(CodeEditorBackground())
    }
}
