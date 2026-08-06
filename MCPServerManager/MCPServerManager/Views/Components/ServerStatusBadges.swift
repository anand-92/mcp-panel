import SwiftUI

// MARK: - Transport Badge

/// Capsule badge showing a server's transport ("stdio" / "HTTP" / "SSE").
struct TransportBadge: View {
    let label: String
    let themeColors: ThemeColors

    var body: some View {
        Text(label)
            .font(DesignTokens.Typography.captionSmall)
            .foregroundStyle(themeColors.primaryAccent)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(themeColors.primaryAccent.opacity(0.15))
                    .overlay(
                        Capsule()
                            .stroke(themeColors.primaryAccent.opacity(0.3), lineWidth: 1)
                    )
            )
            .accessibilityLabel("Transport: \(label)")
    }
}

// MARK: - Health Status

/// Dot + label summarizing a server's last health check.
struct HealthStatusIndicator: View {
    let status: ServerHealthStatus
    let themeColors: ThemeColors
    var showsLabel: Bool = true

    var body: some View {
        HStack(spacing: 5) {
            if status == .checking {
                ProgressView()
                    .controlSize(.small)
                    .scaleEffect(0.55)
                    .frame(width: 10, height: 10)
            } else {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
            }

            if showsLabel {
                Text(statusLabel)
                    .font(DesignTokens.Typography.captionSmall)
                    .foregroundStyle(themeColors.secondaryText)
                    .lineLimit(1)
            }
        }
        .help(status.message)
        .accessibilityLabel("Health status: \(status.message)")
    }

    private var statusLabel: String {
        switch status {
        case .unchecked:
            return "Not checked"
        case .checking:
            return "Checking"
        case .reachable:
            return "Reachable"
        case .authRequired:
            return "Auth required"
        case .unreachable:
            return "Unreachable"
        case .unsupported:
            return "Unsupported"
        }
    }

    private var statusColor: Color {
        switch status {
        case .unchecked:
            return themeColors.mutedText.opacity(0.7)
        case .checking:
            return themeColors.primaryAccent
        case .reachable:
            return themeColors.successColor
        case .authRequired:
            return themeColors.warningColor
        case .unreachable, .unsupported:
            return themeColors.errorColor
        }
    }
}
