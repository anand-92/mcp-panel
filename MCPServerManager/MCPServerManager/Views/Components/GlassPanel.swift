import SwiftUI

// MARK: - Glass Layer Types

enum GlassLayer {
    case layer1  // Deep background (0.01-0.02) - Furthest back
    case layer2  // Content panels (0.03-0.06) - Cards, main content
    case layer3  // Elevated panels (0.05-0.08) - Toolbars, headers
    case layer4  // Overlays (0.10-0.15) - Modals, tooltips
    case layer5  // Interactive focus (0.15-0.25) - Hover/active states

    var shadowRadius: CGFloat {
        switch self {
        case .layer1: return 8
        case .layer2: return 15
        case .layer3: return 22
        case .layer4: return 30
        case .layer5: return 40
        }
    }

    var shadowOpacity: Double {
        switch self {
        case .layer1: return 0.15
        case .layer2: return 0.25
        case .layer3: return 0.35
        case .layer4: return 0.45
        case .layer5: return 0.55
        }
    }

    var shadowY: CGFloat {
        switch self {
        case .layer1: return 2
        case .layer2: return 6
        case .layer3: return 10
        case .layer4: return 15
        case .layer5: return 20
        }
    }
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
