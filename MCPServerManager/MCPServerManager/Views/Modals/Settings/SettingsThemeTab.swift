import SwiftUI

/// Theme swatches and the light/dark/system mode switch.
struct SettingsThemeTab: View {
    @Binding var appearance: AppearanceSettings
    @Binding var selectedTheme: AppTheme
    let onThemeSelected: (AppTheme) -> Void

    @Environment(\.themeColors) private var themeColors

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SettingsSectionCard(
                title: "Color Scheme",
                icon: "circle.lefthalf.filled",
                subtitle: "Light themes look best in Light mode"
            ) {
                SettingsOptionPicker(label: "Appearance", selection: $appearance.appearanceMode)
            }

            SettingsSectionCard(title: "Theme", icon: "paintpalette.fill", subtitle: "\(AppTheme.allCases.count) built-in themes") {
                ThemePickerGrid(
                    selectedTheme: $selectedTheme,
                    onThemeSelected: onThemeSelected
                )
            }
        }
    }
}
