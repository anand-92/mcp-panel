import SwiftUI
import UniformTypeIdentifiers

struct SettingsModal: View {
    @Binding var isPresented: Bool
    @ObservedObject var viewModel: ServerViewModel
    @Environment(\.themeColors) private var themeColors

    @State private var config1Path: String = ""
    @State private var config2Path: String = ""
    @State private var config3Path: String = ""
    @State private var confirmDelete: Bool = true
    @State private var fetchServerLogos: Bool = true
    @State private var blurJSONPreviews: Bool = false
    @State private var selectedTheme: AppTheme = .auto
    @State private var testingConnection: Bool = false
    @State private var testResult: String = ""
    @State private var showBookmarkAlert: Bool = false
    @State private var bookmarkAlertMessage: String = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header
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

            Divider()

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Configuration Files Section
                    SettingsSection(
                        icon: "doc.text.fill",
                        title: "Configuration Files",
                        description: "Manage MCP server config files"
                    ) {
                        VStack(spacing: 16) {
                            // Config Path 1
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "1.circle.fill")
                                        .foregroundColor(themeColors.primaryAccent)
                                    Text("Config Path 1")
                                        .font(DesignTokens.Typography.label)
                                }

                                HStack {
                                    TextField("~/.claude.json", text: $config1Path)
                                        .textFieldStyle(.roundedBorder)
                                        .focusable(true)

                                    Button(action: {
                                        selectConfigFile { path in
                                            config1Path = path
                                        }
                                    }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "folder")
                                            Text("Browse")
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

                            // Config Path 2
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "2.circle.fill")
                                        .foregroundColor(themeColors.primaryAccent)
                                    Text("Config Path 2")
                                        .font(DesignTokens.Typography.label)
                                }

                                HStack {
                                    TextField("~/.settings.json", text: $config2Path)
                                        .textFieldStyle(.roundedBorder)
                                        .focusable(true)

                                    Button(action: {
                                        selectConfigFile { path in
                                            config2Path = path
                                        }
                                    }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "folder")
                                            Text("Browse")
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

                            // Config Path 3 (Codex - The Forbidden Zone)
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "3.circle.fill")
                                        .foregroundColor(themeColors.primaryAccent)
                                    Text("Config Path 3 (Codex)")
                                        .font(DesignTokens.Typography.label)
                                }

                                HStack {
                                    TextField("~/.codex.json", text: $config3Path)
                                        .textFieldStyle(.roundedBorder)
                                        .focusable(true)

                                    Button(action: {
                                        selectConfigFile { path in
                                            config3Path = path
                                        }
                                    }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "folder")
                                            Text("Browse")
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
                        }
                    }

                    // Appearance Section
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

                    // Privacy & Security Section
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

                    // Network Section
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

                            // Test Connection
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
                    }
                }
                .padding(24)
            }

            Divider()

            // Footer
            HStack(spacing: 12) {
                Spacer()

                Button(action: {
                    isPresented = false
                }) {
                    Text("Cancel")
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(.plain)

                Button(action: {
                    saveSettings()
                }) {
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
        .frame(width: 600, height: 700)
        .modifier(LiquidGlassModifier(shape: RoundedRectangle(cornerRadius: 20)))
        .shadow(radius: 30)
        .onAppear {
            config1Path = viewModel.settings.config1Path
            config2Path = viewModel.settings.config2Path
            config3Path = viewModel.settings.config3Path
            confirmDelete = viewModel.settings.confirmDelete
            fetchServerLogos = UserDefaults.standard.object(forKey: "fetchServerLogos") as? Bool ?? true
            blurJSONPreviews = viewModel.settings.blurJSONPreviews

            // Load theme from settings
            if let themeStr = viewModel.settings.overrideTheme,
               let theme = AppTheme(rawValue: themeStr) {
                selectedTheme = theme
            } else {
                selectedTheme = .auto
            }
        }
        .alert("Bookmark Storage Failed", isPresented: $showBookmarkAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(bookmarkAlertMessage)
        }
    }

    private func selectConfigFile(completion: @escaping (String) -> Void) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [UTType.json, UTType.toml]
        panel.showsHiddenFiles = true
        panel.message = "Select a config file to manage MCP servers"

        if panel.runModal() == .OK, let url = panel.url {
            // Store security-scoped bookmark for this file
            do {
                try ConfigManager.shared.storeBookmarkForConfigFile(url: url, path: url.path)

                let path = url.path.replacingOccurrences(of: NSHomeDirectory(), with: "~")
                completion(path)
            } catch {
                print("❌ Failed to store bookmark: \(error.localizedDescription)")
                // Show alert and don't save the path
                bookmarkAlertMessage = "Failed to create persistent access to the selected file. The app may not be able to access this file after restart.\n\nError: \(error.localizedDescription)"
                showBookmarkAlert = true
            }
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
                    testResult = "✓ Found \(count) server(s) in config"
                case .failure(let error):
                    testResult = "✗ Error: \(error.localizedDescription)"
                }
            }
        }
    }

    private func saveSettings() {
        viewModel.settings.configPaths = [config1Path, config2Path, config3Path]
        viewModel.settings.confirmDelete = confirmDelete
        viewModel.settings.blurJSONPreviews = blurJSONPreviews
        UserDefaults.standard.set(fetchServerLogos, forKey: "fetchServerLogos")
        viewModel.saveSettings()
        isPresented = false
    }
}

// MARK: - Settings Section Component

struct SettingsSection<Content: View>: View {
    let icon: String
    let title: String
    let description: String
    let content: () -> Content

    @Environment(\.themeColors) private var themeColors

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
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

            // Section Content
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
            // Icon
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(themeColors.primaryAccent.opacity(0.8))
                .frame(width: 24)

            // Text content
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(DesignTokens.Typography.label)

                Text(description)
                    .font(DesignTokens.Typography.bodySmall)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Toggle
            CheckboxToggle(isOn: $isOn, label: "")
        }
    }
}
