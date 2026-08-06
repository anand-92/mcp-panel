import SwiftUI

// MARK: - Section Card

/// Titled container for a group of related settings rows.
struct SettingsSectionCard<Content: View>: View {
    let title: String
    let icon: String
    var subtitle: String?
    var onReset: (() -> Void)?
    @ViewBuilder let content: () -> Content

    @Environment(\.themeColors) private var themeColors

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(themeColors.primaryAccent)

                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(DesignTokens.Typography.label)
                        .foregroundStyle(themeColors.primaryText)

                    if let subtitle {
                        Text(subtitle)
                            .font(DesignTokens.Typography.caption)
                            .foregroundStyle(themeColors.mutedText)
                    }
                }

                Spacer()

                if let onReset {
                    Button(action: onReset) {
                        Text("Reset")
                            .font(DesignTokens.Typography.caption)
                            .foregroundStyle(themeColors.mutedText)
                    }
                    .buttonStyle(.plain)
                    .help("Reset this section to its defaults")
                }
            }

            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeColors.glassBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(themeColors.glassBorder, lineWidth: 1)
                )
        )
    }
}

// MARK: - Toggle Row

struct SettingsToggleRow: View {
    @Binding var isOn: Bool
    let icon: String
    let label: String
    let description: String

    @Environment(\.themeColors) private var themeColors

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(themeColors.primaryAccent.opacity(0.8))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(DesignTokens.Typography.label)
                    .foregroundStyle(themeColors.primaryText)

                Text(description)
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(themeColors.mutedText)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 12)

            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .labelsHidden()
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Slider Row

/// A labeled slider with a live readout. Values apply as the user drags, which is why
/// the appearance surface has no Save button.
struct SettingsSliderRow: View {
    @Binding var value: Double
    let label: String
    let range: ClosedRange<Double>
    /// Formats the trailing readout, e.g. "60%" or "16 pt".
    let format: (Double) -> String
    var step: Double = 1
    var description: String?

    @Environment(\.themeColors) private var themeColors

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(DesignTokens.Typography.labelSmall)
                    .foregroundStyle(themeColors.secondaryText)

                Spacer()

                Text(format(value))
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(themeColors.primaryAccent)
                    .monospacedDigit()
            }

            Slider(value: $value, in: range, step: step)
                .controlSize(.small)
                .tint(themeColors.primaryAccent)

            if let description {
                Text(description)
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(themeColors.mutedText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Formatters

    static func percent(_ value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }

    static func points(_ value: Double) -> String {
        "\(Int(value.rounded())) pt"
    }
}

// MARK: - Segmented Option Picker

/// Horizontal picker over an `AppearanceOption` enum, with the selected option's
/// one-line summary underneath so the choice explains itself.
struct SettingsOptionPicker<Option: AppearanceOption>: View {
    let label: String
    @Binding var selection: Option

    @Environment(\.themeColors) private var themeColors
    @Environment(\.appearance) private var appearance

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(DesignTokens.Typography.labelSmall)
                .foregroundStyle(themeColors.secondaryText)

            HStack(spacing: 6) {
                ForEach(Array(Option.allCases), id: \.self) { option in
                    optionButton(option)
                }
            }

            Text(selection.summary)
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(themeColors.mutedText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func optionButton(_ option: Option) -> some View {
        let isSelected = selection == option

        return Button {
            withAnimation(appearance.motion(.easeInOut(duration: 0.15))) {
                selection = option
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: option.icon)
                    .font(.system(size: 14, weight: .medium))
                Text(option.displayName)
                    .font(DesignTokens.Typography.caption)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
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
        .help(option.summary)
        .accessibilityLabel("\(option.displayName). \(option.summary)")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - Config Path Editor

/// Path field that commits on Enter or focus loss rather than per keystroke: every
/// commit restarts the config file watcher and reloads from disk.
struct ConfigPathEditor: View {
    let label: String
    let icon: String
    let placeholder: String
    let path: String
    let onCommit: (String) -> Void
    let onBrowse: () -> Void

    @Environment(\.themeColors) private var themeColors
    @State private var draft: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundStyle(themeColors.primaryAccent)
                    .font(.system(size: 12))

                Text(label)
                    .font(DesignTokens.Typography.labelSmall)
                    .foregroundStyle(themeColors.secondaryText)
            }

            HStack(spacing: 8) {
                TextField(placeholder, text: $draft)
                    .textFieldStyle(.roundedBorder)
                    .font(DesignTokens.Typography.code)
                    .focused($isFocused)
                    .onSubmit { onCommit(draft) }
                    .onChange(of: isFocused) { _, focused in
                        if !focused { onCommit(draft) }
                    }

                Button(action: onBrowse) {
                    Image(systemName: "folder")
                        .font(.system(size: 14))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Choose a file")
            }
        }
        .onAppear { draft = path }
        // Reflect programmatic changes (the file picker, Reset) without clobbering typing.
        .onChange(of: path) { _, newPath in
            guard !isFocused else { return }
            draft = newPath
        }
    }
}
