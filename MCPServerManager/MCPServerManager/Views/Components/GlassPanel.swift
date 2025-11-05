import SwiftUI

struct GlassPanel<Content: View>: View {
    let content: Content
    let enableHoverEffects: Bool
    let enableShimmer: Bool

    @Environment(\.themeColors) private var themeColors
    @State private var isHovering = false
    @State private var mouseLocation: CGPoint = .zero
    @State private var shimmerOffset: CGFloat = -200

    init(enableHoverEffects: Bool = true,
         enableShimmer: Bool = true,
         @ViewBuilder content: () -> Content) {
        self.enableHoverEffects = enableHoverEffects
        self.enableShimmer = enableShimmer
        self.content = content()
    }

    var body: some View {
        GeometryReader { geometry in
            content
                .background(
                    ZStack {
                        // Base glass background
                        RoundedRectangle(cornerRadius: DesignTokens.cornerRadius)
                            .fill(themeColors.glassBackground)

                        // Shimmer effect
                        if enableShimmer && isHovering {
                            RoundedRectangle(cornerRadius: DesignTokens.cornerRadius)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            .clear,
                                            .white.opacity(0.1),
                                            .white.opacity(0.2),
                                            .white.opacity(0.1),
                                            .clear
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .offset(x: shimmerOffset)
                                .blur(radius: 10)
                        }

                        // Gradient glow based on mouse position
                        if enableHoverEffects && isHovering {
                            RoundedRectangle(cornerRadius: DesignTokens.cornerRadius)
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            themeColors.primaryAccent.opacity(0.2),
                                            .clear
                                        ],
                                        center: UnitPoint(
                                            x: mouseLocation.x / geometry.size.width,
                                            y: mouseLocation.y / geometry.size.height
                                        ),
                                        startRadius: 0,
                                        endRadius: 200
                                    )
                                )
                        }

                        // Animated border
                        RoundedRectangle(cornerRadius: DesignTokens.cornerRadius)
                            .stroke(
                                isHovering ?
                                    themeColors.primaryAccent.opacity(0.4) :
                                    themeColors.glassBorder,
                                lineWidth: isHovering ? 1.5 : 1
                            )
                    }
                )
                .shadow(
                    color: isHovering ?
                        themeColors.primaryAccent.opacity(0.3) :
                        .black.opacity(0.3),
                    radius: isHovering ? 30 : 20,
                    x: 0,
                    y: isHovering ? 15 : 10
                )
                .scaleEffect(isHovering ? 1.02 : 1.0)
                .rotation3DEffect(
                    .degrees(isHovering ? calculateTilt(in: geometry) : 0),
                    axis: calculateTiltAxis(in: geometry)
                )
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isHovering)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: mouseLocation)
                .onContinuousHover { phase in
                    switch phase {
                    case .active(let location):
                        mouseLocation = location
                        if !isHovering {
                            isHovering = true
                            if enableShimmer {
                                withAnimation(.linear(duration: 0.6)) {
                                    shimmerOffset = geometry.size.width + 200
                                }
                            }
                        }
                    case .ended:
                        isHovering = false
                        shimmerOffset = -200
                    }
                }
        }
    }

    private func calculateTilt(in geometry: GeometryProxy) -> Double {
        guard enableHoverEffects else { return 0 }
        let centerX = geometry.size.width / 2
        let centerY = geometry.size.height / 2
        let distanceX = mouseLocation.x - centerX
        let distanceY = mouseLocation.y - centerY
        let maxDistance = sqrt(pow(centerX, 2) + pow(centerY, 2))
        let distance = sqrt(pow(distanceX, 2) + pow(distanceY, 2))
        return min(distance / maxDistance * 5, 5) // Max 5 degrees tilt
    }

    private func calculateTiltAxis(in geometry: GeometryProxy) -> (x: CGFloat, y: CGFloat, z: CGFloat) {
        guard enableHoverEffects else { return (0, 0, 1) }
        let centerX = geometry.size.width / 2
        let centerY = geometry.size.height / 2
        let deltaX = mouseLocation.x - centerX
        let deltaY = mouseLocation.y - centerY
        return (x: -deltaY, y: deltaX, z: 0)
    }
}
