import SwiftUI

/// Config paths, startup, and the confirmation/visibility toggles.
struct SettingsGeneralTab: View {
    @ObservedObject var viewModel: ServerViewModel
    let onSelectConfigFile: (@escaping (String) -> Void) -> Void

    @Environment(\.themeColors) private var themeColors
    @State private var launchAtLoginRequiresApproval = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            configSection
            startupSection
            behaviorSection
        }
        .onAppear { refreshApprovalState() }
    }

    // MARK: - Config Files

    private var configSection: some View {
        SettingsSectionCard(
            title: "Configuration Files",
            icon: "doc.text.fill",
            subtitle: "Paths are saved when you press Return or leave the field"
        ) {
            VStack(spacing: 16) {
                ConfigPathEditor(
                    label: "Active MCP Config",
                    icon: "1.circle.fill",
                    placeholder: AppConstants.defaultConfigPath,
                    path: viewModel.settings.configPath,
                    onCommit: commitConfigPath,
                    onBrowse: { onSelectConfigFile(commitConfigPath) }
                )

                Divider().opacity(0.3)

                ConfigPathEditor(
                    label: "Droid (Optional)",
                    icon: "2.circle.fill",
                    placeholder: "~/.factory/mcp.json",
                    path: viewModel.settings.droidConfigPath ?? "",
                    onCommit: commitDroidPath,
                    onBrowse: { onSelectConfigFile(commitDroidPath) }
                )

                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 11))
                        .foregroundStyle(themeColors.mutedText)
                    Text("Leave Droid path empty to keep Droid sync disabled.")
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(themeColors.mutedText)
                    Spacer()
                }
            }
        }
    }

    // MARK: - Startup

    private var startupSection: some View {
        SettingsSectionCard(title: "Startup", icon: "power.circle.fill") {
            VStack(spacing: 12) {
                SettingsToggleRow(
                    isOn: Binding(
                        get: { viewModel.settings.launchAtLogin },
                        set: { applyLaunchAtLogin($0) }
                    ),
                    icon: "power.circle.fill",
                    label: "Launch at Login",
                    description: "Start MCP Panel when you log in"
                )

                if viewModel.settings.launchAtLogin && launchAtLoginRequiresApproval {
                    approvalNotice
                }
            }
        }
    }

    private var approvalNotice: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(themeColors.warningColor)
                .font(.system(size: 12))

            Text("Approval required in System Settings")
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(themeColors.warningColor)

            Spacer()

            Button(action: openLoginItemsSettings) {
                Text("Open Settings")
                    .font(DesignTokens.Typography.caption)
            }
            .buttonStyle(.link)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(themeColors.warningColor.opacity(0.1))
        )
    }

    // MARK: - Behavior

    private var behaviorSection: some View {
        SettingsSectionCard(title: "Behavior", icon: "checkmark.shield.fill") {
            VStack(spacing: 14) {
                SettingsToggleRow(
                    isOn: settingsBinding(\.confirmDelete),
                    icon: "trash.circle.fill",
                    label: "Confirm before deleting",
                    description: "Show a confirmation dialog when deleting servers"
                )

                Divider().opacity(0.3)

                SettingsToggleRow(
                    isOn: settingsBinding(\.blurJSONPreviews),
                    icon: "eye.slash.fill",
                    label: "Blur JSON previews",
                    description: "Hide sensitive values in card previews until you edit"
                )
            }
        }
    }

    // MARK: - Actions

    private func settingsBinding(_ keyPath: WritableKeyPath<AppSettings, Bool>) -> Binding<Bool> {
        Binding(
            get: { viewModel.settings[keyPath: keyPath] },
            set: { newValue in
                viewModel.settings[keyPath: keyPath] = newValue
                viewModel.persistSettings()
            }
        )
    }

    private func commitConfigPath(_ path: String) {
        let trimmed = path.trimmed
        let resolved = trimmed.isEmpty ? AppConstants.defaultConfigPath : trimmed
        guard resolved != viewModel.settings.configPath else { return }
        viewModel.settings.configPath = resolved
        viewModel.saveSettings()
        viewModel.loadServers()
    }

    private func commitDroidPath(_ path: String) {
        let trimmed = path.trimmed
        let resolved: String? = trimmed.isEmpty ? nil : trimmed
        guard resolved != viewModel.settings.droidConfigPath else { return }
        viewModel.settings.droidConfigPath = resolved
        viewModel.saveSettings()
    }

    private func applyLaunchAtLogin(_ enabled: Bool) {
        viewModel.settings.launchAtLogin = enabled
        viewModel.persistSettings()

        guard let appDelegate = NSApp.delegate as? AppDelegate else { return }
        let updated = appDelegate.updateLaunchAtLogin(enabled: enabled)
        launchAtLoginRequiresApproval = enabled && appDelegate.launchAtLoginRequiresApproval()

        if !updated {
            viewModel.showToast(
                message: "Failed to update Launch at Login. Check System Settings > Login Items.",
                type: .error
            )
        } else if launchAtLoginRequiresApproval {
            viewModel.showToast(
                message: "Launch at Login needs approval in System Settings > Login Items.",
                type: .warning
            )
        }
    }

    private func refreshApprovalState() {
        let requiresApproval = (NSApp.delegate as? AppDelegate)?.launchAtLoginRequiresApproval() ?? false
        launchAtLoginRequiresApproval = viewModel.settings.launchAtLogin && requiresApproval
    }

    private func openLoginItemsSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension"),
           NSWorkspace.shared.open(url) {
            return
        }
        if let url = URL(string: "x-apple.systempreferences:") {
            NSWorkspace.shared.open(url)
        }
    }
}
