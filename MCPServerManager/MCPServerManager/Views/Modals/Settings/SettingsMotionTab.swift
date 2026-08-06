import SwiftUI

/// Animation liveliness, hover feedback, and the Reduce Motion opt-out.
struct SettingsMotionTab: View {
    @Binding var appearance: AppearanceSettings

    @Environment(\.themeColors) private var themeColors
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if systemReduceMotion && appearance.respectReduceMotion {
                systemOverrideNotice
            }

            SettingsSectionCard(
                title: "Motion",
                icon: "wand.and.rays",
                onReset: resetMotion
            ) {
                VStack(alignment: .leading, spacing: 14) {
                    SettingsOptionPicker(label: "Animation", selection: $appearance.motionLevel)

                    Divider().opacity(0.3)

                    SettingsToggleRow(
                        isOn: $appearance.hoverEffects,
                        icon: "cursorarrow.rays",
                        label: "Hover effects",
                        description: "Highlight and scale buttons and cards under the pointer"
                    )

                    SettingsToggleRow(
                        isOn: $appearance.respectReduceMotion,
                        icon: "accessibility",
                        label: "Honor Reduce Motion",
                        description: "Disable animation when macOS asks apps to reduce motion"
                    )
                }
            }

            motionPreview
        }
    }

    private var systemOverrideNotice: some View {
        HStack(spacing: 8) {
            Image(systemName: "accessibility")
                .font(.system(size: 12))
                .foregroundStyle(themeColors.warningColor)

            Text("macOS Reduce Motion is on, so animation stays off. Turn off \"Honor Reduce Motion\" below to override it.")
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(themeColors.warningColor)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(themeColors.warningColor.opacity(0.1))
        )
    }

    private var motionPreview: some View {
        SettingsSectionCard(
            title: "Try it",
            icon: "play.circle",
            subtitle: "Hover the pill to feel the current settings"
        ) {
            MotionSampleButton(appearance: appearance)
        }
    }

    private func resetMotion() {
        let defaults = AppearanceSettings.default
        appearance.motionLevel = defaults.motionLevel
        appearance.hoverEffects = defaults.hoverEffects
        appearance.respectReduceMotion = defaults.respectReduceMotion
    }
}

// MARK: - Motion Sample

/// A hover target that animates with the pending settings, so the speed and hover
/// choices can be felt before leaving Settings.
private struct MotionSampleButton: View {
    let appearance: AppearanceSettings

    @Environment(\.themeColors) private var themeColors
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @State private var hovering = false

    /// Resolved against the live accessibility state, matching what the app will do.
    private var resolved: AppearanceSettings {
        appearance.resolved(reduceTransparency: false, reduceMotion: systemReduceMotion)
    }

    private var isActive: Bool { resolved.hoverEffects && hovering }

    var body: some View {
        HStack {
            Spacer()

            Text(isActive ? "Nice" : "Hover me")
                .font(DesignTokens.Typography.button)
                .foregroundStyle(isActive ? themeColors.textOnAccent : themeColors.primaryText)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isActive ? AnyShapeStyle(themeColors.accentGradient) : AnyShapeStyle(themeColors.glassBackground))
                        .overlay(Capsule().stroke(themeColors.borderColor, lineWidth: 1))
                )
                .scaleEffect(isActive ? 1.08 : 1)
                .onHover { isHovering in
                    withAnimation(resolved.motion(.spring(response: 0.3, dampingFraction: 0.7))) {
                        hovering = isHovering
                    }
                }

            Spacer()
        }
    }
}
