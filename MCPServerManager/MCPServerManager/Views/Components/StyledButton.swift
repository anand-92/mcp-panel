import SwiftUI

enum StyledButtonStyle {
    case primary
    case secondary
    case danger
}

struct StyledButton: View {
    let icon: String?
    let text: String
    let style: StyledButtonStyle
    let action: () -> Void

    @State private var isHovering = false
    @State private var isPressed = false
    @Environment(\.themeColors) private var themeColors

    init(icon: String? = nil, text: String, style: StyledButtonStyle, action: @escaping () -> Void) {
        self.icon = icon
        self.text = text
        self.style = style
        self.action = action
    }

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                    isPressed = false
                }
            }
            action()
        }) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                }
                Text(text)
                    .font(DesignTokens.Typography.labelSmall)
                    .primaryTextVisibility()
            }
            .foregroundColor(foregroundColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                ZStack {
                    // Base background
                    RoundedRectangle(cornerRadius: 10)
                        .fill(backgroundColor)

                    // Shimmer on hover
                    if isHovering && style == .primary {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        .white.opacity(0),
                                        .white.opacity(0.2),
                                        .white.opacity(0)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }

                    // Border for secondary style
                    if style == .secondary {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(borderColor, lineWidth: 1)
                    }
                }
            )
            .shadow(color: shadowColor, radius: isHovering ? 12 : 6, x: 0, y: isHovering ? 6 : 3)
            .scaleEffect(isPressed ? 0.95 : (isHovering ? 1.05 : 1.0))
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovering)
            .animation(.spring(response: 0.2, dampingFraction: 0.5), value: isPressed)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
    }

    private var backgroundColor: AnyShapeStyle {
        switch style {
        case .primary:
            return AnyShapeStyle(themeColors.accentGradient)
        case .secondary:
            return AnyShapeStyle(themeColors.glassBackground)
        case .danger:
            return AnyShapeStyle(LinearGradient(
                colors: [Color.red, Color.red.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary:
            return Color(hex: "#1a1a1a")
        case .secondary:
            return themeColors.primaryText
        case .danger:
            return .white
        }
    }

    private var borderColor: Color {
        isHovering ? themeColors.primaryAccent.opacity(0.4) : themeColors.borderColor
    }

    private var shadowColor: Color {
        switch style {
        case .primary:
            return themeColors.primaryAccent.opacity(isHovering ? 0.5 : 0.3)
        case .secondary:
            return .clear
        case .danger:
            return Color.red.opacity(isHovering ? 0.5 : 0.3)
        }
    }
}
