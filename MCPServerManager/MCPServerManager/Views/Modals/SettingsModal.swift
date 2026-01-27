import SwiftUI
import UniformTypeIdentifiers

struct SettingsModal: View {
    @Binding var isPresented: Bool
    @ObservedObject var viewModel: ServerViewModel
    @Environment(\.themeColors) private var themeColors

    @State private var config1Path: String = ""
    @State private var config2Path: String = ""
    @State private var confirmDelete: Bool = true
    @State private var fetchServerLogos: Bool = true
    @State private var blurJSONPreviews: Bool = false
    @State private var selectedTheme: AppTheme = .auto
    @State private var testingConnection: Bool = false
    @State private var testResult: String = ""
    @State private var showBookmarkAlert: Bool = false
    @State private var bookmarkAlertMessage: String = ""

    // Menu Bar settings
    @State private var menuBarModeEnabled: Bool = false
    @State private var hideDockIconInMenuBarMode: Bool = false
    @State private var launchAtLogin: Bool = false
    @State private var launchAtLoginRequiresApproval: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            headerView
            Divider()
            contentScrollView
            Divider()
            footerView
        }
        .frame(width: 600, height: 700)
        .modifier(LiquidGlassModifier(shape: RoundedRectangle(cornerRadius: 20)))
        .shadow(radius: 30)
        .onAppear(perform: loadSettings)
        .alert("Bookmark Storage Failed", isPresented: $showBookmarkAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(bookmarkAlertMessage)
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("PREFERENCES")
                    .font(DesignTokens.Typography.labelSmall)
                    .foregroundColor(.secondary)
                    .tracking(1.5)

                Text("Settings")
                    .font(DesignTokens.Typography.title2)
            }

            Spacer()

            Button(action: { isPresented = false }) {
                Image(systemName: "xmark")
                    .font(DesignTokens.Typography.title3)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(24)
    }

    // MARK: - Content

    private var contentScrollView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                configurationFilesSection
                menuBarSection
                appearanceSection
                privacySecuritySection
                networkSection
            }
            .padding(24)
        }
    }

    private var configurationFilesSection: some View {
        SettingsSection(
            icon: "doc.text.fill",
            title: "Configuration Files",
            description: "Manage MCP server config files"
        ) {
            VStack(spacing: 16) {
                ConfigPathRow(
                    number: 1,
                    placeholder: "~/.claude.json",
                    path: $config1Path,
                    onBrowse: { selectConfigFile { config1Path = $0 } }
                )

                ConfigPathRow(
                    number: 2,
                    placeholder: "~/.settings.json",
                    path: $config2Path,
                    onBrowse: { selectConfigFile { config2Path = $0 } }
                )
            }
        }
    }

    private var menuBarSection: some View {
        SettingsSection(
            icon: "menubar.rectangle",
            title: "Menu Bar",
            description: "Quick access from the menu bar"
        ) {
            VStack(spacing: 16) {
                SettingsToggleRow(
                    isOn: $menuBarModeEnabled,
                    icon: "menubar.arrow.up.rectangle",
                    label: "Show in Menu Bar",
                    description: "Add a menu bar icon for quick server access"
                )

                if menuBarModeEnabled {
                    SettingsToggleRow(
                        isOn: $hideDockIconInMenuBarMode,
                        icon: "dock.rectangle",
                        label: "Hide Dock Icon",
                        description: "Run as menu bar-only app (no Dock icon)"
                    )
                }

                Divider()

                SettingsToggleRow(
                    isOn: $launchAtLogin,
                    icon: "power.circle.fill",
                    label: "Launch at Login",
                    description: "Start MCP Server Manager when you log in"
                )

                HStack(spacing: 12) {
                    Text(launchAtLogin && launchAtLoginRequiresApproval
                         ? "Approval required in System Settings > Login Items."
                         : "Manage startup behavior in System Settings.")
                        .font(DesignTokens.Typography.bodySmall)
                        .foregroundColor(.secondary)

                    Spacer()

                    Button(action: openLoginItemsSettings) {
                        HStack(spacing: 4) {
                            Text("Open Settings")
                            Image(systemName: "arrow.up.forward.square")
                        }
                        .font(DesignTokens.Typography.labelSmall)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var appearanceSection: some View {
        SettingsSection(
            icon: "paintbrush.fill",
            title: "Appearance",
            description: "Customize the app's look and feel"
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Theme")
                    .font(DesignTokens.Typography.label)

                Picker("", selection: $selectedTheme) {
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        Text(theme.rawValue).tag(theme)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: selectedTheme) { newTheme in
                    viewModel.settings.overrideTheme = newTheme == .auto ? nil : newTheme.rawValue
                    viewModel.saveSettings()
                }

                Text("'Auto' detects theme based on active config (Claude Code or Gemini CLI)")
                    .font(DesignTokens.Typography.bodySmall)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var privacySecuritySection: some View {
        SettingsSection(
            icon: "lock.shield.fill",
            title: "Privacy & Security",
            description: "Control data visibility and confirmations"
        ) {
            VStack(spacing: 16) {
                SettingsToggleRow(
                    isOn: $confirmDelete,
                    icon: "trash.circle.fill",
                    label: "Confirm before deleting",
                    description: "Show confirmation dialog when deleting servers"
                )

                SettingsToggleRow(
                    isOn: $blurJSONPreviews,
                    icon: "eye.slash.fill",
                    label: "Blur JSON previews",
                    description: "Apply blur to code previews (removed when editing)"
                )
            }
        }
    }

    private var networkSection: some View {
        SettingsSection(
            icon: "network",
            title: "Network",
            description: "Configure internet-based features"
        ) {
            VStack(spacing: 16) {
                SettingsToggleRow(
                    isOn: $fetchServerLogos,
                    icon: "photo.circle.fill",
                    label: "Fetch server logos",
                    description: "Download logos from internet (no tracking)"
                )

                Divider()

                testConnectionView
            }
        }
    }

    private var testConnectionView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: testConnection) {
                HStack {
                    Image(systemName: testingConnection ? "arrow.triangle.2.circlepath" : "network.badge.shield.half.filled")
                    if testingConnection {
                        ProgressView()
                            .scaleEffect(0.7)
                    }
                    Text(testingConnection ? "Testing..." : "Test Connection")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .buttonStyle(.bordered)
            .disabled(testingConnection)

            if !testResult.isEmpty {
                Text(testResult)
                    .font(DesignTokens.Typography.bodySmall)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Footer

    private var footerView: some View {
        HStack(spacing: 12) {
            Spacer()

            GlassButton(label: "Cancel") {
                isPresented = false
            }

            Button(action: saveSettings) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Save Settings")
                }
                .foregroundColor(Color(hex: "#1a1a1a"))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(themeColors.accentGradient)
                )
                .shadow(color: themeColors.primaryAccent.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)
        }
        .padding(24)
    }

    // MARK: - Actions

    private func loadSettings() {
        config1Path = viewModel.settings.config1Path
        config2Path = viewModel.settings.config2Path
        confirmDelete = viewModel.settings.confirmDelete
        fetchServerLogos = UserDefaults.standard.object(forKey: "fetchServerLogos") as? Bool ?? true
        blurJSONPreviews = viewModel.settings.blurJSONPreviews

        // Menu Bar settings
        menuBarModeEnabled = viewModel.settings.menuBarModeEnabled
        hideDockIconInMenuBarMode = viewModel.settings.hideDockIconInMenuBarMode
        launchAtLogin = viewModel.settings.launchAtLogin
        let requiresApproval = (NSApp.delegate as? AppDelegate)?.launchAtLoginRequiresApproval() ?? false
        launchAtLoginRequiresApproval = launchAtLogin && requiresApproval

        if let themeStr = viewModel.settings.overrideTheme,
           let theme = AppTheme(rawValue: themeStr) {
            selectedTheme = theme
        } else {
            selectedTheme = .auto
        }
    }

    private func selectConfigFile(completion: @escaping (String) -> Void) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [UTType.json]
        panel.showsHiddenFiles = true
        panel.message = "Select a config file to manage MCP servers"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            try ConfigManager.shared.storeBookmarkForConfigFile(url: url, path: url.path)
            let path = url.path.replacingOccurrences(of: NSHomeDirectory(), with: "~")
            completion(path)
        } catch {
            print("Failed to store bookmark: \(error.localizedDescription)")
            bookmarkAlertMessage = "Failed to create persistent access to the selected file. The app may not be able to access this file after restart.\n\nError: \(error.localizedDescription)"
            showBookmarkAlert = true
        }
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

    private func testConnection() {
        testingConnection = true
        testResult = ""

        Task {
            let result = await viewModel.testConnection(to: config1Path)

            await MainActor.run {
                testingConnection = false

                switch result {
                case .success(let count):
                    testResult = "Found \(count) server(s) in config"
                case .failure(let error):
                    testResult = "Error: \(error.localizedDescription)"
                }
            }
        }
    }

    private func saveSettings() {
        viewModel.settings.configPaths = [config1Path, config2Path]
        viewModel.settings.confirmDelete = confirmDelete
        viewModel.settings.blurJSONPreviews = blurJSONPreviews
        UserDefaults.standard.set(fetchServerLogos, forKey: "fetchServerLogos")

        // Menu Bar settings
        viewModel.settings.menuBarModeEnabled = menuBarModeEnabled
        viewModel.settings.hideDockIconInMenuBarMode = hideDockIconInMenuBarMode
        viewModel.settings.launchAtLogin = launchAtLogin

        viewModel.saveSettings()

        // Apply menu bar changes immediately
        if let appDelegate = NSApp.delegate as? AppDelegate {
            appDelegate.updateMenuBarMode(
                enabled: menuBarModeEnabled,
                hideDock: hideDockIconInMenuBarMode,
                viewModel: viewModel
            )

            // Update launch at login
            let launchUpdated = appDelegate.updateLaunchAtLogin(enabled: launchAtLogin)
            launchAtLoginRequiresApproval = launchAtLogin && appDelegate.launchAtLoginRequiresApproval()
            if !launchUpdated {
                viewModel.showToast(message: "Failed to update Launch at Login. Check System Settings > Login Items.", type: .error)
            } else if launchAtLoginRequiresApproval {
                viewModel.showToast(message: "Launch at Login needs approval in System Settings > Login Items.", type: .warning)
            }
        }

        isPresented = false
    }
}

// MARK: - Config Path Row Component

private struct ConfigPathRow: View {
    let number: Int
    let placeholder: String
    @Binding var path: String
    let onBrowse: () -> Void

    @Environment(\.themeColors) private var themeColors

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "\(number).circle.fill")
                    .foregroundColor(themeColors.primaryAccent)
                Text("Config Path \(number)")
                    .font(DesignTokens.Typography.label)
            }

            HStack {
                TextField(placeholder, text: $path)
                    .textFieldStyle(.roundedBorder)
                    .focusable(true)

                GlassButton(icon: "folder", label: "Browse", action: onBrowse)
            }
        }
    }
}

// MARK: - Glass Button Component

private struct GlassButton: View {
    var icon: String?
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon)
                }
                Text(label)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Settings Section Component

struct SettingsSection<Content: View>: View {
    let icon: String
    let title: String
    let description: String
    @ViewBuilder let content: () -> Content

    @Environment(\.themeColors) private var themeColors

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeColors.primaryAccent)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(DesignTokens.Typography.title3)

                    Text(description)
                        .font(DesignTokens.Typography.bodySmall)
                        .foregroundColor(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                content()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - Settings Toggle Row Component

struct SettingsToggleRow: View {
    @Binding var isOn: Bool
    let icon: String
    let label: String
    let description: String

    @Environment(\.themeColors) private var themeColors

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(themeColors.primaryAccent.opacity(0.8))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(DesignTokens.Typography.label)

                Text(description)
                    .font(DesignTokens.Typography.bodySmall)
                    .foregroundColor(.secondary)
            }

            Spacer()

            CheckboxToggle(isOn: $isOn, label: "")
        }
    }
}
