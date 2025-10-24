//
//  ServerFormView.swift
//  MCP Panel
//

import SwiftUI

struct ServerFormView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    let server: ServerConfig?

    @State private var serverId: String = ""
    @State private var command: String = ""
    @State private var args: [String] = []
    @State private var env: [EnvVar] = []
    @State private var disabled: Bool = false
    @State private var alwaysAllow: [String] = []

    @State private var newArg: String = ""
    @State private var newEnvKey: String = ""
    @State private var newEnvValue: String = ""
    @State private var newAllowTool: String = ""

    @State private var validationErrors: [String] = []

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(server == nil ? "Add Server" : "Edit Server")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                Button("Cancel") {
                    dismiss()
                }
            }
            .padding()

            Divider()

            // Form
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Basic Info
                    Group {
                        FormField(label: "Server ID") {
                            TextField("e.g., filesystem, github", text: $serverId)
                                .disabled(server != nil) // Can't change ID when editing
                        }

                        FormField(label: "Command") {
                            TextField("e.g., npx, /usr/local/bin/mcp-server", text: $command)
                        }

                        Toggle("Disabled", isOn: $disabled)
                    }

                    Divider()

                    // Arguments
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Arguments")
                            .font(.headline)

                        ForEach(Array(args.enumerated()), id: \.offset) { index, arg in
                            HStack {
                                Text(arg)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Button(action: {
                                    args.remove(at: index)
                                }) {
                                    Image(systemName: "minus.circle")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(8)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .cornerRadius(6)
                        }

                        HStack {
                            TextField("Add argument", text: $newArg)
                                .onSubmit {
                                    addArgument()
                                }

                            Button(action: addArgument) {
                                Image(systemName: "plus.circle.fill")
                            }
                            .buttonStyle(.plain)
                            .disabled(newArg.isEmpty)
                        }
                    }

                    Divider()

                    // Environment Variables
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Environment Variables")
                            .font(.headline)

                        ForEach(Array(env.enumerated()), id: \.offset) { index, envVar in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(envVar.key)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(envVar.value)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)

                                Button(action: {
                                    env.remove(at: index)
                                }) {
                                    Image(systemName: "minus.circle")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(8)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .cornerRadius(6)
                        }

                        HStack {
                            TextField("Key", text: $newEnvKey)
                                .frame(width: 150)

                            TextField("Value", text: $newEnvValue)
                                .onSubmit {
                                    addEnvironmentVariable()
                                }

                            Button(action: addEnvironmentVariable) {
                                Image(systemName: "plus.circle.fill")
                            }
                            .buttonStyle(.plain)
                            .disabled(newEnvKey.isEmpty || newEnvValue.isEmpty)
                        }
                    }

                    Divider()

                    // Always Allow
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Always Allow Tools")
                            .font(.headline)

                        Text("Tools that should always be allowed without prompting")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        ForEach(Array(alwaysAllow.enumerated()), id: \.offset) { index, tool in
                            HStack {
                                Text(tool)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Button(action: {
                                    alwaysAllow.remove(at: index)
                                }) {
                                    Image(systemName: "minus.circle")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(8)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .cornerRadius(6)
                        }

                        HStack {
                            TextField("Tool name", text: $newAllowTool)
                                .onSubmit {
                                    addAllowTool()
                                }

                            Button(action: addAllowTool) {
                                Image(systemName: "plus.circle.fill")
                            }
                            .buttonStyle(.plain)
                            .disabled(newAllowTool.isEmpty)
                        }
                    }

                    // Validation Errors
                    if !validationErrors.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Validation Errors")
                                .font(.headline)
                                .foregroundColor(.orange)

                            ForEach(validationErrors, id: \.self) { error in
                                HStack {
                                    Image(systemName: "exclamationmark.triangle")
                                        .foregroundColor(.orange)
                                    Text(error)
                                        .font(.caption)
                                }
                            }
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding()
            }

            Divider()

            // Footer
            HStack {
                Spacer()

                Button("Cancel") {
                    dismiss()
                }

                Button(server == nil ? "Add Server" : "Save Changes") {
                    saveServer()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValid)
            }
            .padding()
        }
        .frame(width: 600, height: 700)
        .onAppear {
            loadServer()
        }
        .onChange(of: serverId) { _ in validateForm() }
        .onChange(of: command) { _ in validateForm() }
    }

    private func loadServer() {
        if let server = server {
            serverId = server.id
            command = server.command
            args = server.args ?? []
            env = (server.env ?? [:]).map { EnvVar(key: $0.key, value: $0.value) }
            disabled = server.disabled ?? false
            alwaysAllow = server.alwaysAllow ?? []
        }
        validateForm()
    }

    private func validateForm() {
        let tempServer = ServerConfig(
            id: serverId,
            command: command,
            args: args.isEmpty ? nil : args,
            env: env.isEmpty ? nil : Dictionary(uniqueKeysWithValues: env.map { ($0.key, $0.value) }),
            disabled: disabled,
            alwaysAllow: alwaysAllow.isEmpty ? nil : alwaysAllow
        )

        validationErrors = appState.validateServer(tempServer)
    }

    private var isValid: Bool {
        return !serverId.isEmpty && !command.isEmpty && validationErrors.isEmpty
    }

    private func addArgument() {
        guard !newArg.isEmpty else { return }
        args.append(newArg)
        newArg = ""
        validateForm()
    }

    private func addEnvironmentVariable() {
        guard !newEnvKey.isEmpty, !newEnvValue.isEmpty else { return }
        env.append(EnvVar(key: newEnvKey, value: newEnvValue))
        newEnvKey = ""
        newEnvValue = ""
        validateForm()
    }

    private func addAllowTool() {
        guard !newAllowTool.isEmpty else { return }
        alwaysAllow.append(newAllowTool)
        newAllowTool = ""
        validateForm()
    }

    private func saveServer() {
        let newServer = ServerConfig(
            id: serverId,
            command: command,
            args: args.isEmpty ? nil : args,
            env: env.isEmpty ? nil : Dictionary(uniqueKeysWithValues: env.map { ($0.key, $0.value) }),
            disabled: disabled,
            alwaysAllow: alwaysAllow.isEmpty ? nil : alwaysAllow
        )

        Task {
            if server == nil {
                await appState.addServer(newServer)
            } else {
                await appState.updateServer(newServer)
            }
            dismiss()
        }
    }
}

// MARK: - Supporting Views

struct FormField<Content: View>: View {
    let label: String
    let content: Content

    init(label: String, @ViewBuilder content: () -> Content) {
        self.label = label
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)

            content
        }
    }
}

struct EnvVar {
    var key: String
    var value: String
}

// MARK: - Previews

#Preview("Add Server") {
    ServerFormView(server: nil)
        .environmentObject(AppState())
}

#Preview("Edit Server") {
    ServerFormView(server: ServerConfig.sample)
        .environmentObject(AppState())
}
