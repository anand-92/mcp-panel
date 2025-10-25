import SwiftUI

struct AddServerModal: View {
    @Binding var isPresented: Bool
    @ObservedObject var viewModel: ServerViewModel
    @Environment(\.themeColors) private var themeColors

    @State private var jsonText: String = ""
    @State private var errorMessage: String = ""

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

            // Content
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
                        .frame(height: 300)
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
        .frame(width: 600, height: 550)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(nsColor: .windowBackgroundColor))
                .shadow(radius: 30)
        )
    }

    private func formatJSON() {
        // First normalize quotes (curly quotes from Notes/Word/Slack)
        var normalized = jsonText
            .replacingOccurrences(of: """, with: "\"")  // Left double quotation mark
            .replacingOccurrences(of: """, with: "\"")  // Right double quotation mark
            .replacingOccurrences(of: "'", with: "'")   // Left single quotation mark
            .replacingOccurrences(of: "'", with: "'")   // Right single quotation mark
            .replacingOccurrences(of: "‚", with: "'")   // Single low-9 quotation mark
            .replacingOccurrences(of: "„", with: "\"")  // Double low-9 quotation mark
            .replacingOccurrences(of: "«", with: "\"")  // Left-pointing double angle quotation mark
            .replacingOccurrences(of: "»", with: "\"")  // Right-pointing double angle quotation mark
            .replacingOccurrences(of: "‹", with: "'")   // Single left-pointing angle quotation mark
            .replacingOccurrences(of: "›", with: "'")   // Single right-pointing angle quotation mark

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
        print("DEBUG AddServerModal: Starting validation")
        print("DEBUG AddServerModal: JSON text length: \(jsonText.count)")

        // Use the same forgiving parser as addServers
        guard let serverDict = ServerExtractor.extractServerEntries(from: jsonText) else {
            errorMessage = "Could not parse JSON. Check Console.app logs for details. Expected format: {\"server-name\": {\"command\": \"...\"}} or wrap in {\"mcpServers\": {...}}"
            print("DEBUG AddServerModal: ServerExtractor returned nil")
            return
        }

        print("DEBUG AddServerModal: Extracted \(serverDict.count) servers")

        guard !serverDict.isEmpty else {
            errorMessage = "No valid server configurations found in JSON"
            return
        }

        // Check if any servers are invalid
        let invalidServers = serverDict.filter { !$0.value.isValid }
        if !invalidServers.isEmpty {
            let names = invalidServers.map { $0.key }.joined(separator: ", ")
            let details = invalidServers.map { name, config in
                let reason = getInvalidReason(config)
                return "\(name): \(reason)"
            }.joined(separator: "; ")
            errorMessage = "Invalid server config(s): \(details)"
            print("DEBUG AddServerModal: Invalid servers: \(details)")
            return
        }

        errorMessage = "✓ Valid! Found \(serverDict.count) server(s)"
        print("DEBUG AddServerModal: Validation succeeded")
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
}
