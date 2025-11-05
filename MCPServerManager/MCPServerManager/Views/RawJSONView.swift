import SwiftUI

struct RawJSONView: View {
    @ObservedObject var viewModel: ServerViewModel
    @Environment(\.themeColors) private var themeColors
    @State private var jsonText: String = ""
    @State private var isDirty: Bool = false
    @State private var errorMessage: String = ""
    @State private var showForceAlert: Bool = false
    @State private var invalidServerDetails: String = ""
    @State private var pendingSaveJSON: String = ""
    @State private var pendingServerDict: [String: ServerConfig]?

    var body: some View {
        VStack(spacing: 0) {
            // Info panel with gradient background
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "curlybraces")
                            .font(DesignTokens.Typography.title3)
                            .foregroundColor(themeColors.primaryAccent)
                        Text("RAW JSON EDITOR")
                            .font(DesignTokens.Typography.labelSmall)
                            .foregroundColor(themeColors.primaryAccent)
                            .tracking(1.5)
                    }

                    Text("Edit the full configuration in JSON format. Changes will be applied to the active config.")
                        .font(DesignTokens.Typography.bodySmall)
                        .foregroundColor(.secondary)
                        .secondaryTextVisibility()
                }

                Spacer()

                if isDirty {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 8, height: 8)
                            .scaleEffect(1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.5).repeatForever(autoreverses: true), value: isDirty)
                        Text("Unsaved edits")
                            .font(DesignTokens.Typography.bodySmall)
                            .foregroundColor(.orange)
                            .primaryTextVisibility()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.orange.opacity(0.15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                            )
                            .shadow(color: Color.orange.opacity(0.3), radius: 8, x: 0, y: 4)
                    )
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
                }
            }
            .padding(20)
            .background(
                LinearGradient(
                    colors: [
                        themeColors.glassBackground,
                        themeColors.glassBackground.opacity(0.5)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            if !errorMessage.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(DesignTokens.Typography.title3)
                    Text(errorMessage)
                        .font(DesignTokens.Typography.body)
                        .primaryTextVisibility()
                }
                .foregroundColor(.red)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.red.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: Color.red.opacity(0.3), radius: 8, x: 0, y: 4)
                )
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }

            // Text editor with enhanced styling and blur support
            ZStack(alignment: .topLeading) {
                TextEditor(text: $jsonText)
                    .font(DesignTokens.Typography.codeLarge)
                    .scrollContentBackground(.hidden)
                    .background(Color.black.opacity(0.4))
                    .padding(20)
                    .focusable(true)
                    .blur(radius: (viewModel.settings.blurJSONPreviews && !isDirty) ? DesignTokens.jsonPreviewBlurRadius : 0)
                    .onChange(of: jsonText) { newValue in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isDirty = newValue != serversToJSON()
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isDirty ?
                                    themeColors.primaryAccent.opacity(0.3) :
                                    Color.white.opacity(0.05),
                                lineWidth: 2
                            )
                            .padding(20)
                    )
            }

            // Action buttons with enhanced styling
            HStack(spacing: 12) {
                StyledButton(
                    icon: "text.alignleft",
                    text: "Format JSON",
                    style: .secondary
                ) {
                    formatJSON()
                }

                StyledButton(
                    icon: "arrow.counterclockwise",
                    text: "Reset",
                    style: .secondary
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        jsonText = serversToJSON()
                        isDirty = false
                        errorMessage = ""
                    }
                }

                Spacer()

                // Apply button with pulsing effect when dirty
                StyledButton(
                    icon: "checkmark.circle.fill",
                    text: "Apply Changes",
                    style: .primary
                ) {
                    applyChanges()
                }
                .disabled(!isDirty)
                .opacity(isDirty ? 1.0 : 0.5)
                .scaleEffect(isDirty ? 1.0 : 0.98)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDirty)
            }
            .padding(20)
            .background(
                LinearGradient(
                    colors: [
                        themeColors.glassBackground.opacity(0.5),
                        themeColors.glassBackground
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .onAppear {
            jsonText = serversToJSON()
        }
        .onChange(of: viewModel.filterMode) { _ in
            if !isDirty {
                jsonText = serversToJSON()
            }
        }
        .onChange(of: viewModel.searchText) { _ in
            if !isDirty {
                jsonText = serversToJSON()
            }
        }
        .alert("Invalid Server Configuration", isPresented: $showForceAlert) {
            Button("Cancel", role: .cancel) {
                showForceAlert = false
                pendingSaveJSON = ""
                pendingServerDict = nil
                invalidServerDetails = ""
            }
            Button("Force Save") {
                forceSave()
            }
        } message: {
            Text("The following servers have validation errors:\n\n\(invalidServerDetails)\n\nDo you want to force save anyway? This will override all validations.")
        }
    }

    private func serversToJSON() -> String {
        // Use filteredServers to respect search and filter mode
        let filteredServers = viewModel.filteredServers
            .reduce(into: [String: ServerConfig]()) { result, server in
                result[server.name] = server.config
            }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]

        guard let data = try? encoder.encode(filteredServers),
              let string = String(data: data, encoding: .utf8) else {
            return "{}"
        }

        return string
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

    private func applyChanges() {
        let result = viewModel.applyRawJSON(jsonText)

        if result.success {
            // Success
            isDirty = false
            errorMessage = ""
        } else if let invalidServers = result.invalidServers {
            // Validation failed, show force save alert
            let details = invalidServers.map { name, reason in
                "\(name): \(reason)"
            }.joined(separator: "\n")

            invalidServerDetails = details
            pendingSaveJSON = jsonText
            pendingServerDict = result.serverDict  // Store parsed dictionary to avoid re-parsing
            showForceAlert = true
        } else {
            // JSON parsing error (toast already shown by viewModel)
            // Keep isDirty as true and don't clear error
        }
    }

    private func forceSave() {
        do {
            // Use parsed dictionary if available to avoid re-parsing
            if let serverDict = pendingServerDict {
                viewModel.applyRawJSONForced(serverDict: serverDict)
            } else {
                // Fallback to JSON parsing (shouldn't happen in normal flow)
                try viewModel.applyRawJSONForced(pendingSaveJSON)
            }
            isDirty = false
            errorMessage = ""
            showForceAlert = false
            pendingSaveJSON = ""
            pendingServerDict = nil
            invalidServerDetails = ""
        } catch {
            errorMessage = "Failed to parse JSON: \(error.localizedDescription)"
            showForceAlert = false
        }
    }
}
