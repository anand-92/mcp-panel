import SwiftUI

struct AddServerModal: View {
    @Binding var isPresented: Bool
    @ObservedObject var viewModel: ServerViewModel
    @Environment(\.themeColors) private var themeColors

    @State private var jsonText: String = ""
    @State private var errorMessage: String = ""
    @State private var entryMode: EntryMode = .manual

    enum EntryMode {
        case manual
        case browse
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("BULK ADD")
                        .font(DesignTokens.Typography.labelSmall)
                        .foregroundColor(.secondary)
                        .tracking(1.5)

                    Text("Add Servers")
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

            // Mode Switcher
            HStack(spacing: 0) {
                ModeButton(
                    title: "Manual Entry",
                    icon: "text.cursor",
                    isSelected: entryMode == .manual,
                    themeColors: themeColors
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        entryMode = .manual
                    }
                }

                ModeButton(
                    title: "Browse Registry",
                    icon: "square.grid.2x2",
                    isSelected: entryMode == .browse,
                    themeColors: themeColors
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        entryMode = .browse
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)

            Divider()

            // Content
            Group {
                if entryMode == .manual {
                    manualEntryView
                } else {
                    BrowseRegistryView { selectedServer in
                        handleServerSelection(selectedServer)
                    }
                }
            }

            Divider()

            // Footer
            HStack(spacing: 12) {
                Button(action: formatJSON) {
                    HStack(spacing: 6) {
                        Image(systemName: "text.alignleft")
                        Text("Format JSON")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)

                Button(action: validateJSON) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.shield")
                        Text("Validate")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)

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

                Button(action: addServers) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Servers")
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
                .disabled(jsonText.isEmpty)
                .opacity(jsonText.isEmpty ? 0.5 : 1.0)
            }
            .padding(24)
        }
        .frame(
            minWidth: 700,
            idealWidth: 850,
            maxWidth: 1000,
            minHeight: 600,
            idealHeight: 750,
            maxHeight: 900
        )
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(nsColor: .windowBackgroundColor))
                .shadow(radius: 30)
        )
    }

    private func formatJSON() {
        // First normalize quotes (curly quotes from Notes/Word/Slack)
        let normalized = jsonText.normalizingQuotes()

        guard let data = normalized.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data),
              let formatted = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]),
              let result = String(data: formatted, encoding: .utf8) else {
            errorMessage = "Invalid JSON format (after normalizing quotes)"
            return
        }
        jsonText = result
        errorMessage = ""
    }

    private func validateJSON() {
        #if DEBUG
        print("DEBUG AddServerModal: Starting validation")
        print("DEBUG AddServerModal: JSON text length: \(jsonText.count)")
        #endif

        // Use the same forgiving parser as addServers
        guard let serverDict = ServerExtractor.extractServerEntries(from: jsonText) else {
            errorMessage = "Could not parse JSON. Check Console.app logs for details. Expected format: {\"server-name\": {\"command\": \"...\"}} or wrap in {\"mcpServers\": {...}}"
            #if DEBUG
            print("DEBUG AddServerModal: ServerExtractor returned nil")
            #endif
            return
        }

        #if DEBUG
        print("DEBUG AddServerModal: Extracted \(serverDict.count) servers")
        #endif

        guard !serverDict.isEmpty else {
            errorMessage = "No valid server configurations found in JSON"
            return
        }

        // Check if any servers are invalid
        let invalidServers = serverDict.filter { !$0.value.isValid }
        if !invalidServers.isEmpty {
            let details = invalidServers.map { name, config in
                let reason = getInvalidReason(config)
                return "\(name): \(reason)"
            }.joined(separator: "; ")
            errorMessage = "Invalid server config(s): \(details)"
            #if DEBUG
            print("DEBUG AddServerModal: Invalid servers: \(details)")
            #endif
            return
        }

        errorMessage = "✓ Valid! Found \(serverDict.count) server(s)"
        #if DEBUG
        print("DEBUG AddServerModal: Validation succeeded")
        #endif
    }

    private func getInvalidReason(_ config: ServerConfig) -> String {
        if config.command == nil && config.transport == nil && config.remotes == nil {
            return "missing command, transport, or remotes"
        }
        if let cmd = config.command, cmd.trimmingCharacters(in: .whitespaces).isEmpty {
            return "empty command"
        }
        return "unknown issue"
    }

    private func addServers() {
        viewModel.addServers(from: jsonText)
        isPresented = false
        jsonText = ""
        errorMessage = ""
    }

    // MARK: - Computed Views

    private var manualEntryView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("SERVER JSON")
                    .font(DesignTokens.Typography.labelSmall)
                    .foregroundColor(.secondary)
                    .tracking(1.5)

                Text("Paste server definitions in the format: {\"server-name\": {\"command\": \"...\"}} or just the config object")
                    .font(DesignTokens.Typography.bodySmall)
                    .foregroundColor(.secondary)

                TextEditor(text: $jsonText)
                    .font(DesignTokens.Typography.codeLarge)
                    .frame(minHeight: 350, idealHeight: 450, maxHeight: 600)
                    .scrollContentBackground(.hidden)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .focusable(true)

                if !errorMessage.isEmpty {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text(errorMessage)
                    }
                    .font(DesignTokens.Typography.bodySmall)
                    .foregroundColor(.red)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.red.opacity(0.1))
                    )
                }
            }
            .padding(24)
        }
    }

    // MARK: - Server Selection Handler

    private func handleServerSelection(_ server: RegistryServer) {
        // Wrap the config with the server name
        let wrappedConfig: [String: ServerConfig] = [server.displayName: server.config]

        // Format as pretty JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]

        if let data = try? encoder.encode(wrappedConfig),
           let jsonString = String(data: data, encoding: .utf8) {
            jsonText = jsonString
        } else {
            // Fallback to unwrapped config if encoding fails
            jsonText = server.configJSON
        }

        // Switch back to manual mode
        withAnimation(.easeInOut(duration: 0.2)) {
            entryMode = .manual
        }

        // Clear any errors
        errorMessage = ""

        #if DEBUG
        print("AddServerModal: Selected server '\(server.name)', populated JSON with wrapper")
        #endif
    }
}

// MARK: - Mode Button Component

struct ModeButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let themeColors: ThemeColors
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(title)
                    .font(DesignTokens.Typography.body)
            }
            .foregroundColor(isSelected ? Color(hex: "#1a1a1a") : .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(themeColors.accentGradient)
                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.03))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    }
                }
            )
        }
        .buttonStyle(.plain)
    }
}
