import SwiftUI

struct ToastView: View {
    let message: String
    let type: ServerViewModel.ToastType
    @Environment(\.themeColors) private var themeColors

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(DesignTokens.Typography.title3)
                .foregroundColor(.white)

            Text(message)
                .font(DesignTokens.Typography.body)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundColor)
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        )
        .padding()
    }

    private var iconName: String {
        switch type {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        }
    }

    private var backgroundColor: Color {
        switch type {
        case .success: return themeColors.successColor
        case .error: return themeColors.errorColor
        case .warning: return themeColors.warningColor
        }
    }
}
