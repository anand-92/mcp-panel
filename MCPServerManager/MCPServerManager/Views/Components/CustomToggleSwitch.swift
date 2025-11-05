import SwiftUI

struct CustomToggleSwitch: View {
    @Binding var isOn: Bool
    var label: String = ""

    @State private var isHovering = false
    @State private var bounceScale: CGFloat = 1.0
    @Environment(\.themeColors) private var themeColors

    var body: some View {
        Button(action: {
            // Bounce animation on toggle
            withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) {
                bounceScale = 1.2
            }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                isOn.toggle()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    bounceScale = 1.0
                }
            }
        }) {
            HStack(spacing: 12) {
                if !label.isEmpty {
                    Text(label)
                        .font(DesignTokens.Typography.label)
                        .foregroundColor(.primary)
                }

                ZStack {
                    // Background track with gradient
                    Capsule()
                        .fill(isOn ? AnyShapeStyle(toggleGradient) : AnyShapeStyle(Color.gray.opacity(0.3)))
                        .frame(width: 50, height: 28)
                        .overlay(
                            Capsule()
                                .stroke(isOn ? themeColors.primaryAccent.opacity(0.5) : Color.clear, lineWidth: isHovering ? 2 : 0)
                        )
                        .shadow(
                            color: isOn ? themeColors.primaryAccent.opacity(0.4) : .clear,
                            radius: isHovering ? 12 : 8,
                            x: 0,
                            y: 4
                        )

                    // Knob with gradient and glow
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.white, Color.white.opacity(0.9)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 22, height: 22)
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                        .shadow(color: isOn ? themeColors.primaryAccent.opacity(0.6) : .clear, radius: 6, x: 0, y: 0)
                        .overlay(
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            .white.opacity(0.3),
                                            .clear
                                        ],
                                        center: .topLeading,
                                        startRadius: 0,
                                        endRadius: 15
                                    )
                                )
                        )
                        .scaleEffect(bounceScale)
                        .offset(x: isOn ? 11 : -11)
                }
                .scaleEffect(isHovering ? 1.05 : 1.0)
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovering)
        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isOn)
        .onHover { hovering in
            isHovering = hovering
        }
    }

    private var toggleGradient: LinearGradient {
        LinearGradient(
            colors: [
                themeColors.primaryAccent,
                themeColors.primaryAccent.opacity(0.8),
                Color.green
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

struct CheckboxToggle: View {
    @Binding var isOn: Bool
    var label: String

    var body: some View {
        Button(action: { isOn.toggle() }) {
            HStack(spacing: 8) {
                Image(systemName: isOn ? "checkmark.square.fill" : "square")
                    .foregroundColor(isOn ? .blue : .gray)
                    .font(DesignTokens.Typography.title3)

                Text(label)
                    .font(DesignTokens.Typography.label)
                    .foregroundColor(.primary)
            }
        }
        .buttonStyle(.plain)
    }
}
