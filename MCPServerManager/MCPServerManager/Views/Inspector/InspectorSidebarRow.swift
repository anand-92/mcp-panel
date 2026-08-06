import SwiftUI

/// A single row in the inspector sidebar: icon, name, transport, health dot and an
/// inline enable switch.
///
/// The switch is a sibling control rather than part of the row's selection button, so
/// flipping a server on or off never changes which server the detail pane is showing.
struct InspectorSidebarRow: View {
    let server: ServerModel
    let healthStatus: ServerHealthStatus
    let isSelected: Bool
    let onSelect: () -> Void
    let onToggle: () -> Void

    @Environment(\.themeColors) private var themeColors
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 8) {
            Button(action: onSelect) {
                HStack(spacing: 8) {
                    ServerIconView(server: server, size: 22)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(server.name)
                            .font(DesignTokens.Typography.labelSmall)
                            .foregroundStyle(isSelected ? themeColors.primaryText : themeColors.secondaryText)
                            .lineLimit(1)
                            .truncationMode(.middle)

                        HStack(spacing: 4) {
                            Text(server.config.transportLabel)
                                .font(DesignTokens.Typography.caption)
                                .foregroundStyle(themeColors.mutedText)
                                .lineLimit(1)

                            HealthStatusIndicator(
                                status: healthStatus,
                                themeColors: themeColors,
                                showsLabel: false
                            )
                        }
                    }

                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Select \(server.name)")
            .accessibilityAddTraits(isSelected ? [.isSelected] : [])

            InspectorRowSwitch(isOn: server.enabled, action: onToggle)
                .accessibilityLabel(server.enabled ? "Disable \(server.name)" : "Enable \(server.name)")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(rowBackground)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovering = hovering
        }
    }

    @ViewBuilder
    private var rowBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(fillColor)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? themeColors.primaryAccent.opacity(0.35) : Color.clear, lineWidth: 1)
            )
    }

    private var fillColor: Color {
        if isSelected {
            return themeColors.primaryAccent.opacity(0.12)
        }
        return isHovering ? themeColors.glassBackground : Color.clear
    }
}

// MARK: - Row Switch

/// Small enable switch sized for a dense list row. Deliberately not
/// `CustomToggleSwitch`, which is 44×24 and too large for a 34 pt row.
private struct InspectorRowSwitch: View {
    let isOn: Bool
    let action: () -> Void

    @Environment(\.themeColors) private var themeColors
    @Environment(\.appearance) private var appearance

    var body: some View {
        Button(action: action) {
            ZStack {
                Capsule()
                    .fill(isOn ? AnyShapeStyle(themeColors.accentGradient) : AnyShapeStyle(themeColors.mutedText.opacity(0.25)))
                    .frame(width: 30, height: 17)

                Circle()
                    .fill(Color.white)
                    .frame(width: 13, height: 13)
                    .shadow(color: .black.opacity(0.25), radius: 1.5, x: 0, y: 1)
                    .offset(x: isOn ? 6.5 : -6.5)
            }
            .animation(appearance.motion(.spring(response: 0.28, dampingFraction: 0.8)), value: isOn)
        }
        .buttonStyle(.plain)
    }
}
