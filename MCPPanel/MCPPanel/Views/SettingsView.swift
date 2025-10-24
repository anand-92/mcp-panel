//
//  SettingsView.swift
//  MCP Panel
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var configPath: String = ""
    @State private var globalConfigPath: String = ""
    @State private var autoSave: Bool = true
    @State private var searchFuzzy: Bool = true
    @State private var theme: String = "system"

    var body: some View {
        TabView {
            // General Settings
            GeneralSettingsView(
                configPath: $configPath,
                globalConfigPath: $globalConfigPath,
                autoSave: $autoSave
            )
            .tabItem {
                Label("General", systemImage: "gear")
            }

            // Search Settings
            SearchSettingsView(searchFuzzy: $searchFuzzy)
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }

            // About
            AboutView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 500, height: 400)
        .onAppear {
            loadSettings()
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveSettings()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private func loadSettings() {
        configPath = appState.settings.configPath
        globalConfigPath = appState.settings.globalConfigPath ?? ""
        autoSave = appState.settings.autoSave
        searchFuzzy = appState.settings.searchFuzzy
        theme = appState.settings.theme
    }

    private func saveSettings() {
        var settings = appState.settings
        settings.configPath = configPath
        settings.globalConfigPath = globalConfigPath.isEmpty ? nil : globalConfigPath
        settings.autoSave = autoSave
        settings.searchFuzzy = searchFuzzy
        settings.theme = theme

        appState.updateSettings(settings)

        // Reload config with new path
        Task {
            await appState.loadConfig()
        }
    }
}

struct GeneralSettingsView: View {
    @Binding var configPath: String
    @Binding var globalConfigPath: String
    @Binding var autoSave: Bool

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Claude Config Path")
                        .font(.headline)

                    HStack {
                        TextField("~/.claude.json", text: $configPath)

                        Button("Browse...") {
                            selectConfigPath()
                        }
                    }

                    Text("Path to your Claude desktop app configuration file")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Global Config Path (Optional)")
                        .font(.headline)

                    HStack {
                        TextField("~/.claude-global.json", text: $globalConfigPath)

                        Button("Browse...") {
                            selectGlobalConfigPath()
                        }
                    }

                    Text("Optional secondary configuration file")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Section {
                Toggle("Auto-save changes", isOn: $autoSave)

                Text("Automatically save configuration changes to disk")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func selectConfigPath() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.json]

        if panel.runModal() == .OK, let url = panel.url {
            configPath = url.path.replacingOccurrences(of: NSHomeDirectory(), with: "~")
        }
    }

    private func selectGlobalConfigPath() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.json]

        if panel.runModal() == .OK, let url = panel.url {
            globalConfigPath = url.path.replacingOccurrences(of: NSHomeDirectory(), with: "~")
        }
    }
}

struct SearchSettingsView: View {
    @Binding var searchFuzzy: Bool

    var body: some View {
        Form {
            Section {
                Toggle("Enable fuzzy search", isOn: $searchFuzzy)

                Text("Fuzzy search finds matches even with typos and partial matches")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Text("Search Options")
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Search searches the following fields:")
                        .font(.caption)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("• Server ID")
                        Text("• Command")
                        Text("• Arguments")
                        Text("• Environment variables")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            } header: {
                Text("Search Scope")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "gearshape.2")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)

            Text("MCP Panel")
                .font(.title)
                .fontWeight(.bold)

            Text("Native macOS Swift")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Version 2.0.0")
                .font(.caption)
                .foregroundColor(.secondary)

            Divider()
                .frame(width: 200)

            VStack(spacing: 8) {
                Text("Manage Claude MCP Server Configurations")
                    .font(.caption)

                Text("Native Swift rewrite of the Electron-based MCP Server Manager")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .padding(40)
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
