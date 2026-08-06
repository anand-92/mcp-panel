import SwiftUI

/// Spacing density, individual metrics, and typography.
struct SettingsLayoutTab: View {
    @Binding var appearance: AppearanceSettings

    @Environment(\.themeColors) private var themeColors

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            AppearancePreviewCard(appearance: appearance)
            densitySection
            spacingSection
            textSection
        }
    }

    // MARK: - Density

    private var densitySection: some View {
        SettingsSectionCard(
            title: "Density",
            icon: "arrow.up.and.down.and.arrow.left.and.right",
            subtitle: "A preset for all four spacing values below"
        ) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    ForEach(LayoutDensity.allCases, id: \.self) { density in
                        densityButton(density)
                    }
                }

                Text(appearance.matchedDensity?.summary ?? "Custom spacing")
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(themeColors.mutedText)
            }
        }
    }

    private func densityButton(_ density: LayoutDensity) -> some View {
        let isSelected = appearance.matchedDensity == density

        return Button {
            appearance.apply(density)
        } label: {
            VStack(spacing: 4) {
                Image(systemName: density.icon)
                    .font(.system(size: 14, weight: .medium))
                Text(density.displayName)
                    .font(DesignTokens.Typography.caption)
                    .lineLimit(1)
            }
            .foregroundStyle(isSelected ? themeColors.primaryAccent : themeColors.secondaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? themeColors.primaryAccent.opacity(0.14) : themeColors.glassBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                isSelected ? themeColors.primaryAccent.opacity(0.45) : themeColors.borderColor,
                                lineWidth: 1
                            )
                    )
            )
            .contentShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .help(density.summary)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    // MARK: - Spacing

    private var spacingSection: some View {
        SettingsSectionCard(
            title: "Spacing",
            icon: "ruler.fill",
            onReset: resetSpacing
        ) {
            VStack(alignment: .leading, spacing: 16) {
                SettingsSliderRow(
                    value: $appearance.cornerRadius,
                    label: "Corner radius",
                    range: AppearanceSettings.cornerRadiusRange,
                    format: SettingsSliderRow.points,
                    description: "0 pt gives cards and modals sharp corners"
                )

                SettingsSliderRow(
                    value: $appearance.cardPadding,
                    label: "Card padding",
                    range: AppearanceSettings.cardPaddingRange,
                    format: SettingsSliderRow.points
                )

                SettingsSliderRow(
                    value: $appearance.gridSpacing,
                    label: "Grid spacing",
                    range: AppearanceSettings.gridSpacingRange,
                    format: SettingsSliderRow.points
                )

                SettingsSliderRow(
                    value: $appearance.minCardWidth,
                    label: "Minimum card width",
                    range: AppearanceSettings.minCardWidthRange,
                    format: SettingsSliderRow.points,
                    step: 10,
                    description: "Narrower cards fit more columns across the grid"
                )
            }
        }
    }

    // MARK: - Text

    private var textSection: some View {
        SettingsSectionCard(
            title: "Text",
            icon: "textformat",
            onReset: resetText
        ) {
            VStack(alignment: .leading, spacing: 16) {
                SettingsOptionPicker(label: "Text size", selection: $appearance.textSize)

                Divider().opacity(0.3)

                SettingsOptionPicker(label: "Interface font", selection: $appearance.uiFont)

                Divider().opacity(0.3)

                SettingsSliderRow(
                    value: $appearance.codeFontSize,
                    label: "Code font size",
                    range: AppearanceSettings.codeFontSizeRange,
                    format: SettingsSliderRow.points,
                    description: "JSON editors and config previews"
                )

                SettingsSliderRow(
                    value: $appearance.jsonBlurStrength,
                    label: "JSON blur strength",
                    range: AppearanceSettings.jsonBlurRange,
                    format: SettingsSliderRow.points,
                    description: "Used when \"Blur JSON previews\" is on in General"
                )
            }
        }
    }

    private func resetSpacing() {
        appearance.apply(.standard)
    }

    private func resetText() {
        let defaults = AppearanceSettings.default
        appearance.textSize = defaults.textSize
        appearance.uiFont = defaults.uiFont
        appearance.codeFontSize = defaults.codeFontSize
        appearance.jsonBlurStrength = defaults.jsonBlurStrength
    }
}
