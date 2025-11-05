import SwiftUI

struct AnimatedLoadingView: View {
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1.0
    @Environment(\.themeColors) private var themeColors

    var body: some View {
        ZStack {
            // Outer rotating ring
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(
                    AngularGradient(
                        colors: [
                            themeColors.primaryAccent,
                            themeColors.primaryAccent.opacity(0.5),
                            .clear
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .frame(width: 40, height: 40)
                .rotationEffect(.degrees(rotation))
                .shadow(color: themeColors.primaryAccent.opacity(0.5), radius: 8, x: 0, y: 0)

            // Inner pulsing circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            themeColors.primaryAccent.opacity(0.5),
                            themeColors.primaryAccent.opacity(0.2),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 15
                    )
                )
                .frame(width: 20, height: 20)
                .scaleEffect(scale)
        }
        .onAppear {
            withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                scale = 1.3
            }
        }
    }
}
