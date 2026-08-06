import SwiftUI

/// Liquid Glass style, translucency, and the accessibility opt-out.
struct SettingsGlassTab: View {
    @Binding var appearance: AppearanceSettings

    @Environment(\.themeColors) private var themeColors
    @Environment(\.accessibilityReduceTransparency) private var systemReduceTransparency

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            AppearancePreviewCard(appearance: appearance)

            if isOverriddenBySystem {
                systemOverrideNotice
            }

            glassSection
            transparencySection
        }
    }

    /// True when macOS Reduce Transparency is on *and* the user asked us to honor it,
    /// in which case the glass controls below have no visible effect.
    private var isOverriddenBySystem: Bool {
        systemReduceTransparency && appearance.respectReduceTransparency
    }

    private var systemOverrideNotice: some View {
        HStack(spacing: 8) {
            Image(systemName: "accessibility")
                .font(.system(size: 12))
                .foregroundStyle(themeColors.warningColor)

            Text("macOS Reduce Transparency is on, so panels stay solid. Turn off \"Honor Reduce Transparency\" below to override it.")
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

    // MARK: - Glass

    private var glassSection: some View {
        SettingsSectionCard(
            title: "Liquid Glass",
            icon: "circle.hexagongrid.fill",
            onReset: resetGlass
        ) {
            VStack(alignment: .leading, spacing: 14) {
                SettingsOptionPicker(label: "Glass style", selection: $appearance.glassStyle)

                Divider().opacity(0.3)

                SettingsToggleRow(
                    isOn: $appearance.tintGlassWithAccent,
                    icon: "paintbrush.pointed.fill",
                    label: "Tint glass with accent",
                    description: "Wash panels with the theme's accent color"
                )
                .disabled(!appearance.isGlassEnabled)

                SettingsToggleRow(
                    isOn: $appearance.interactiveGlass,
                    icon: "hand.tap.fill",
                    label: "Interactive glass",
                    description: "Cards react to the pointer with a subtle shimmer"
                )
                .disabled(!appearance.isGlassEnabled)

                SettingsToggleRow(
                    isOn: $appearance.respectReduceTransparency,
                    icon: "accessibility",
                    label: "Honor Reduce Transparency",
                    description: "Use solid panels when macOS asks apps to reduce transparency"
                )
            }
            .opacity(appearance.isGlassEnabled ? 1 : 0.9)
        }
    }

    // MARK: - Transparency

    private var transparencySection: some View {
        SettingsSectionCard(
            title: "Transparency",
            icon: "square.on.square.dashed",
            onReset: resetTransparency
        ) {
            VStack(alignment: .leading, spacing: 16) {
                SettingsSliderRow(
                    value: $appearance.surfaceOpacity,
                    label: "Panel opacity",
                    range: AppearanceSettings.opacityRange,
                    format: SettingsSliderRow.percent,
                    step: 0.01,
                    description: "Toolbars, sidebars, and JSON surfaces inside the window"
                )

                SettingsSliderRow(
                    value: $appearance.windowBackgroundOpacity,
                    label: "Window background",
                    range: AppearanceSettings.opacityRange,
                    format: SettingsSliderRow.percent,
                    step: 0.01,
                    description: "0% lets your desktop show through the whole window"
                )

                SettingsToggleRow(
                    isOn: $appearance.shadowsEnabled,
                    icon: "shadow",
                    label: "Shadows",
                    description: "Drop shadows and accent glows around raised elements"
                )
            }
        }
    }

    // MARK: - Resets

    private func resetGlass() {
        let defaults = AppearanceSettings.default
        appearance.glassStyle = defaults.glassStyle
        appearance.tintGlassWithAccent = defaults.tintGlassWithAccent
        appearance.interactiveGlass = defaults.interactiveGlass
        appearance.respectReduceTransparency = defaults.respectReduceTransparency
    }

    private func resetTransparency() {
        let defaults = AppearanceSettings.default
        appearance.surfaceOpacity = defaults.surfaceOpacity
        appearance.windowBackgroundOpacity = defaults.windowBackgroundOpacity
        appearance.shadowsEnabled = defaults.shadowsEnabled
    }
}
