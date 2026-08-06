import SwiftUI

/// Compact action button used by the inline card editor and the inspector's JSON tab.
struct EditorButton: View {
    enum Style {
        case primary
        case secondary
    }

    let title: String
    var icon: String?
    let style: Style
    let themeColors: ThemeColors
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                }
                Text(title)
                    .font(DesignTokens.Typography.labelSmall)
            }
            .foregroundColor(foregroundColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(background)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.45)
    }

    private var foregroundColor: Color {
        switch style {
        case .primary:
            return themeColors.textOnAccent
        case .secondary:
            return themeColors.primaryText
        }
    }

    @ViewBuilder
    private var background: some View {
        switch style {
        case .primary:
            RoundedRectangle(cornerRadius: 8)
                .fill(themeColors.accentGradient)
                .shadow(color: themeColors.primaryAccent.opacity(0.3), radius: 6, x: 0, y: 2)
        case .secondary:
            RoundedRectangle(cornerRadius: 8)
                .fill(themeColors.glassBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(themeColors.borderColor, lineWidth: 1)
                )
        }
    }
}
