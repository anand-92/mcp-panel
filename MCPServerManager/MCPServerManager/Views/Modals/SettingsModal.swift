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
    @State private var windowOpacity: Double = 1.0
    @State private var testingConnection: Bool = false
    @State private var testResult: String = ""

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
                VStack(alignment: .leading, spacing: 24) {
                    // Config Path 1
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Config Path 1")
                            .font(DesignTokens.Typography.label)

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
                        Text("Config Path 2")
                            .font(DesignTokens.Typography.label)

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

                    Divider()

                    // Confirm Delete
                    VStack(alignment: .leading, spacing: 8) {
                        CheckboxToggle(isOn: $confirmDelete, label: "Confirm before deleting servers")

                        Text("Show confirmation dialog when deleting servers")
                            .font(DesignTokens.Typography.bodySmall)
                            .foregroundColor(.secondary)
                    }

                    Divider()

                    // Fetch Server Logos
                    VStack(alignment: .leading, spacing: 8) {
                        CheckboxToggle(isOn: $fetchServerLogos, label: "Fetch server logos from internet")

                        Text("Automatically download logos for servers. When disabled, only generic icons will be shown. Respects your privacy - no tracking.")
                            .font(DesignTokens.Typography.bodySmall)
                            .foregroundColor(.secondary)
                    }

                    Divider()

                    // Window Translucency
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Window Translucency")
                                .font(DesignTokens.Typography.label)

                            Spacer()

                            Text("\(Int(windowOpacity * 100))%")
                                .font(DesignTokens.Typography.bodySmall)
                                .foregroundColor(.secondary)
                                .monospacedDigit()
                        }

                        Slider(value: $windowOpacity, in: 0.3...1.0, step: 0.05)
                            .onChange(of: windowOpacity) { newValue in
                                // Update in real-time
                                viewModel.settings.windowOpacity = newValue
                                viewModel.saveSettings()
                            }

                        Text("Adjust the transparency of the application window")
                            .font(DesignTokens.Typography.bodySmall)
                            .foregroundColor(.secondary)
                    }

                    Divider()

                    // Test Connection
                    VStack(alignment: .leading, spacing: 8) {
                        Button(action: testConnection) {
                            HStack {
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
        .frame(width: 550, height: 600)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(nsColor: .windowBackgroundColor))
                .shadow(radius: 30)
        )
        .onAppear {
            config1Path = viewModel.settings.config1Path
            config2Path = viewModel.settings.config2Path
            confirmDelete = viewModel.settings.confirmDelete
            fetchServerLogos = UserDefaults.standard.object(forKey: "fetchServerLogos") as? Bool ?? true
            windowOpacity = viewModel.settings.windowOpacity
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

        if panel.runModal() == .OK, let url = panel.url {
            // Store security-scoped bookmark for this file
            do {
                try ConfigManager.shared.storeBookmarkForConfigFile(url: url, path: url.path)

                let path = url.path.replacingOccurrences(of: NSHomeDirectory(), with: "~")
                completion(path)
            } catch {
                print("❌ Failed to store bookmark: \(error.localizedDescription)")
                // Still allow the user to use the path, but warn them
                let path = url.path.replacingOccurrences(of: NSHomeDirectory(), with: "~")
                completion(path)
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
        viewModel.settings.configPaths = [config1Path, config2Path]
        viewModel.settings.confirmDelete = confirmDelete
        viewModel.settings.windowOpacity = windowOpacity
        UserDefaults.standard.set(fetchServerLogos, forKey: "fetchServerLogos")
        viewModel.saveSettings()
        isPresented = false
    }
}
