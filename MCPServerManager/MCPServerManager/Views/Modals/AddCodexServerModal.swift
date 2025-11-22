import SwiftUI
import TOMLKit

/// CODEX-ONLY ADD SERVER MODAL
/// The forbidden zone gets its own modal. No registry. TOML only. Complete isolation.
struct AddCodexServerModal: View {
    @Binding var isPresented: Bool
    @ObservedObject var viewModel: ServerViewModel
    @Environment(\.themeColors) private var themeColors

    @State private var tomlText: String = """
    # Codex MCP Server Configuration (TOML)
    # Add your servers below in TOML format

    [mcp_servers.example]
    command = "npx"
    args = ["-y", "@modelcontextprotocol/server-example"]
    """
    @State private var errorMessage: String = ""
    @State private var showForceAlert: Bool = false
    @State private var invalidServerDetails: String = ""
    @State private var pendingSaveTOML: String = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header - Codex Themed
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CODEX ZONE")
                        .font(DesignTokens.Typography.labelSmall)
                        .foregroundColor(Color.cyan)
                        .tracking(1.5)

                    Text("Add Codex Servers")
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

            // TOML Editor
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "text.alignleft")
                        .foregroundColor(Color.cyan)
                    Text("TOML Configuration")
                        .font(DesignTokens.Typography.label)
                    Spacer()
                    Text("Codex uses TOML format exclusively")
                        .font(DesignTokens.Typography.bodySmall)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                TextEditor(text: $tomlText)
                    .font(.system(size: 13, design: .monospaced))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.black.opacity(0.3))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.cyan.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 24)

                if !errorMessage.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .font(DesignTokens.Typography.bodySmall)
                            .foregroundColor(.red)
                    }
                    .padding(.horizontal, 24)
                }
            }

            Divider()

            // Footer - Codex themed
            HStack(spacing: 12) {
                Button(action: formatTOML) {
                    HStack(spacing: 6) {
                        Image(systemName: "text.alignleft")
                        Text("Validate TOML")
                    }
                    .padding(.horizontal, 16)
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

                Spacer()

                Button(action: { isPresented = false }) {
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

                Button(action: addServers) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add to Codex")
                    }
                    .foregroundColor(Color(hex: "#1a1a1a"))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                LinearGradient(
                                    colors: [Color.cyan, Color.blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .shadow(color: Color.cyan.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)
            }
            .padding(24)
        }
        .frame(width: 700, height: 600)
        .modifier(LiquidGlassModifier(shape: RoundedRectangle(cornerRadius: 20)))
        .shadow(radius: 30)
        .alert("Invalid TOML Configuration", isPresented: $showForceAlert) {
            Button("Cancel", role: .cancel) {
                pendingSaveTOML = ""
            }
            Button("Force Save Anyway", role: .destructive) {
                forceAddServers()
            }
        } message: {
            Text("Some servers have validation errors:\n\n\(invalidServerDetails)\n\nForce save anyway?")
        }
    }

    private func formatTOML() {
        // Validate TOML syntax
        errorMessage = ""
        do {
            _ = try TOMLTable(string: tomlText)
            errorMessage = "✓ Valid TOML syntax"
        } catch {
            errorMessage = "✗ TOML parsing error: \(error.localizedDescription)"
        }
    }

    private func addServers() {
        errorMessage = ""

        // Parse TOML and extract mcp_servers section
        do {
            let table = try TOMLTable(string: tomlText)

            guard let mcpServers = table["mcp_servers"]?.table else {
                errorMessage = "Missing [mcp_servers] section in TOML"
                return
            }

            // Convert TOML to ServerConfig dictionary
            var serverDict: [String: ServerConfig] = [:]
            for (name, value) in mcpServers {
                guard let serverTable = value.table else {
                    errorMessage = "Server '\(name)' is not a valid table"
                    return
                }

                // Convert TOMLTable to dictionary then to ServerConfig
                if let serverDictRaw = tomlTableToDictionary(serverTable),
                   let jsonData = try? JSONSerialization.data(withJSONObject: serverDictRaw),
                   let config = try? JSONDecoder().decode(ServerConfig.self, from: jsonData) {
                    serverDict[name] = config
                }
            }

            // Check for invalid servers
            var invalidServers: [String: String] = [:]
            for (name, config) in serverDict {
                if !config.isValid {
                    let reason = getInvalidReason(config)
                    invalidServers[name] = reason
                }
            }

            if !invalidServers.isEmpty {
                // Has invalid servers - show force dialog
                let invalidList = invalidServers.map { "• \($0.key): \($0.value)" }.joined(separator: "\n")
                invalidServerDetails = invalidList
                pendingSaveTOML = tomlText
                showForceAlert = true
                return
            }

            // Add servers directly to viewModel
            var addedCount = 0
            for (name, config) in serverDict {
                // Create new server with Codex universe
                let newServer = ServerModel(
                    name: name,
                    config: config,
                    updatedAt: Date(),
                    inConfigs: [false, false, true],  // Only in config3 (Codex)
                    sourceUniverse: 2  // Codex universe
                )

                if let existingIndex = viewModel.servers.firstIndex(where: { $0.name == name }) {
                    viewModel.servers[existingIndex] = newServer
                } else {
                    viewModel.servers.append(newServer)
                }
                addedCount += 1
            }

            viewModel.servers.sort { $0.name < $1.name }
            viewModel.syncToConfigs()
            viewModel.showToast(message: "Added \(addedCount) server(s) to Codex", type: .success)
            isPresented = false

        } catch {
            errorMessage = "TOML parsing failed: \(error.localizedDescription)"
        }
    }

    private func tomlTableToDictionary(_ table: TOMLTable) -> [String: Any]? {
        var dict: [String: Any] = [:]
        for (key, value) in table {
            if let string = value as? String {
                dict[key] = string
            } else if let int = value as? Int {
                dict[key] = int
            } else if let double = value as? Double {
                dict[key] = double
            } else if let bool = value as? Bool {
                dict[key] = bool
            } else if let array = value as? TOMLArray {
                dict[key] = array.compactMap { convertToAny($0) }
            } else if let nestedTable = value as? TOMLTable {
                dict[key] = tomlTableToDictionary(nestedTable)
            }
        }
        return dict.isEmpty ? nil : dict
    }

    private func convertToAny(_ value: any TOMLValueConvertible) -> Any? {
        if let string = value as? String { return string }
        if let int = value as? Int { return int }
        if let double = value as? Double { return double }
        if let bool = value as? Bool { return bool }
        if let array = value as? TOMLArray {
            return array.compactMap { convertToAny($0) }
        }
        if let table = value as? TOMLTable {
            return tomlTableToDictionary(table)
        }
        return nil
    }

    private func getInvalidReason(_ config: ServerConfig) -> String {
        if config.command == nil {
            return "missing command"
        }
        if let cmd = config.command, cmd.trimmingCharacters(in: .whitespaces).isEmpty {
            return "empty command"
        }
        return "unknown issue"
    }

    private func forceAddServers() {
        // Force save the TOML configuration
        // TODO: Implement force save for TOML
        isPresented = false
    }
}
