import SwiftUI
import UniformTypeIdentifiers

struct SettingsModal: View {
    @Binding var isPresented: Bool
    @ObservedObject var viewModel: ServerViewModel

    @State private var config1Path: String = ""
    @State private var config2Path: String = ""
    @State private var confirmDelete: Bool = true
    @State private var cyberpunkMode: Bool = false
    @State private var testingConnection: Bool = false
    @State private var testResult: String = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("PREFERENCES")
                        .font(.system(size: 12))
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .tracking(1.5)

                    Text("Settings")
                        .font(.system(size: 22))
                        .fontWeight(.bold)
                }

                Spacer()

                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 20))
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
                            .font(.system(size: 14))
                            .fontWeight(.semibold)

                        HStack {
                            TextField("~/.claude.json", text: $config1Path)
                                .textFieldStyle(.roundedBorder)
                                .focusable(true)

                            Button("Browse") {
                                selectConfigFile { path in
                                    config1Path = path
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                    }

                    // Config Path 2
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Config Path 2")
                            .font(.system(size: 14))
                            .fontWeight(.semibold)

                        HStack {
                            TextField("~/.settings.json", text: $config2Path)
                                .textFieldStyle(.roundedBorder)
                                .focusable(true)

                            Button("Browse") {
                                selectConfigFile { path in
                                    config2Path = path
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                    }

                    Divider()

                    // Confirm Delete
                    VStack(alignment: .leading, spacing: 8) {
                        CheckboxToggle(isOn: $confirmDelete, label: "Confirm before deleting servers")

                        Text("Show confirmation dialog when deleting servers")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }

                    // Cyberpunk Mode
                    VStack(alignment: .leading, spacing: 8) {
                        CheckboxToggle(isOn: $cyberpunkMode, label: "Cyberpunk Mode")

                        Text("Adds extra neon flair to the UI")
                            .font(.system(size: 12))
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
                                .font(.system(size: 12))
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

                Button("Cancel") {
                    isPresented = false
                }
                .buttonStyle(.bordered)

                Button("Save Settings") {
                    saveSettings()
                }
                .buttonStyle(.borderedProminent)
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
            cyberpunkMode = viewModel.settings.cyberpunkMode
        }
    }

    private func selectConfigFile(completion: @escaping (String) -> Void) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [UTType.json]
        panel.showsHiddenFiles = true

        if panel.runModal() == .OK, let url = panel.url {
            let path = url.path.replacingOccurrences(of: NSHomeDirectory(), with: "~")
            completion(path)
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
        viewModel.settings.cyberpunkMode = cyberpunkMode
        viewModel.saveSettings()
        isPresented = false
    }
}
