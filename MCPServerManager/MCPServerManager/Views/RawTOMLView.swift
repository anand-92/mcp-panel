import SwiftUI
import TOMLKit

struct RawTOMLView: View {
    @ObservedObject var viewModel: ServerViewModel
    @Environment(\.themeColors) private var themeColors
    @State private var tomlText: String = ""
    @State private var isDirty: Bool = false
    @State private var errorMessage: String = ""
    @State private var showForceAlert: Bool = false
    @State private var invalidServerDetails: String = ""
    @State private var pendingSaveTOML: String = ""
    @State private var pendingServerDict: [String: ServerConfig]?

    var body: some View {
        VStack(spacing: 0) {
            // Info panel
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("RAW TOML EDITOR")
                        .font(DesignTokens.Typography.labelSmall)
                        .foregroundColor(.secondary)
                        .tracking(1.5)

                    Text("Edit the full Codex configuration in TOML format. Changes will be applied to the Codex config.")
                        .font(DesignTokens.Typography.bodySmall)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if isDirty {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 8, height: 8)
                        Text("Unsaved edits")
                            .font(DesignTokens.Typography.bodySmall)
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.orange.opacity(0.1))
                    )
                }
            }
            .padding(20)

            if !errorMessage.isEmpty {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text(errorMessage)
                }
                .font(DesignTokens.Typography.body)
                .foregroundColor(.red)
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.red.opacity(0.1))
                )
                .padding(.horizontal, 20)
            }

            // Text editor
            TextEditor(text: $tomlText)
                .font(DesignTokens.Typography.codeLarge)
                .scrollContentBackground(.hidden)
                .background(Color.black.opacity(0.3))
                .padding(20)
                .focusable(true)
                .blur(radius: (viewModel.settings.blurJSONPreviews && !isDirty) ? DesignTokens.jsonPreviewBlurRadius : 0)
                .onChange(of: tomlText) { newValue in
                    isDirty = newValue != serversToTOML()
                }

            // Action buttons
            HStack(spacing: 12) {
                Button(action: {
                    tomlText = serversToTOML()
                    isDirty = false
                    errorMessage = ""
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Reset")
                    }
                    .font(DesignTokens.Typography.label)
                    .foregroundColor(themeColors.primaryText)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(themeColors.glassBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(themeColors.borderColor, lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)

                Spacer()

                Button(action: applyChanges) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Apply Changes")
                    }
                    .font(DesignTokens.Typography.label)
                    .foregroundColor(isDirty ? Color(hex: "#1a1a1a") : themeColors.mutedText)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isDirty ? AnyShapeStyle(themeColors.accentGradient) : AnyShapeStyle(themeColors.glassBackground))
                    )
                    .shadow(color: isDirty ? themeColors.primaryAccent.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)
                .disabled(!isDirty)
            }
            .padding(20)
        }
        .onAppear {
            tomlText = serversToTOML()
        }
        .onChange(of: viewModel.filterMode) { _ in
            if !isDirty {
                tomlText = serversToTOML()
            }
        }
        .onChange(of: viewModel.searchText) { _ in
            if !isDirty {
                tomlText = serversToTOML()
            }
        }
        .alert("Invalid Server Configuration", isPresented: $showForceAlert) {
            Button("Cancel", role: .cancel) {
                showForceAlert = false
                pendingSaveTOML = ""
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

    private func serversToTOML() -> String {
        // Use filteredServers to respect search and filter mode
        let filteredServers = viewModel.filteredServers
            .reduce(into: [String: ServerConfig]()) { result, server in
                result[server.name] = server.config
            }

        // Use centralized TOML utilities
        guard let tomlString = try? TOMLUtils.serversToTOMLString(filteredServers) else {
            return "[mcpServers]\n"
        }

        return tomlString
    }

    private func applyChanges() {
        let result = viewModel.applyRawTOML(tomlText)

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
            pendingSaveTOML = tomlText
            pendingServerDict = result.serverDict
            showForceAlert = true
        } else {
            // TOML parsing error (toast already shown by viewModel)
            // Keep isDirty as true and don't clear error
        }
    }

    private func forceSave() {
        do {
            // Use parsed dictionary if available to avoid re-parsing
            if let serverDict = pendingServerDict {
                viewModel.applyRawTOMLForced(serverDict: serverDict)
            } else {
                // Fallback to TOML parsing
                try viewModel.applyRawTOMLForced(pendingSaveTOML)
            }
            isDirty = false
            errorMessage = ""
            showForceAlert = false
            pendingSaveTOML = ""
            pendingServerDict = nil
            invalidServerDetails = ""
        } catch {
            errorMessage = "Failed to parse TOML: \(error.localizedDescription)"
            showForceAlert = false
        }
    }
}
