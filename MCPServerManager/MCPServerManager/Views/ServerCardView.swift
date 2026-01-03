import SwiftUI

struct ServerCardView: View {
    let server: ServerModel
    @Binding var activeConfigIndex: Int
    @Binding var confirmDelete: Bool
    @Binding var blurJSONPreviews: Bool
    @State private var isEditing = false
    @State private var editedConfigText: String = ""  // Holds either JSON or TOML
    @State private var isHovering = false
    @State private var showingDeleteAlert = false
    @State private var showForceAlert = false
    @State private var invalidReason: String = ""
    @State private var pendingSaveJSON: String = ""
    @State private var pendingConfig: ServerConfig?
    @Environment(\.themeColors) private var themeColors

    let onToggle: () -> Void
    let onTagToggle: (ServerTag) -> Void
    let onDelete: () -> Void
    let onUpdate: (String) -> (success: Bool, invalidReason: String?, config: ServerConfig?)
    let onUpdateForced: (ServerConfig) -> Bool
    let onCustomIconSelected: ((Result<String, Error>) -> Void)?

    var body: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 12) {
                // Header with icon
                HStack(alignment: .top) {
                    Text(server.name)
                        .font(DesignTokens.Typography.title2)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Spacer()

                    ServerIconView(
                        server: server,
                        size: 40,
                        onCustomIconSelected: onCustomIconSelected
                    )
                }

                // Config summary
                Text(server.config.summary)
                    .font(DesignTokens.Typography.bodySmall)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Tags")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(themeColors.mutedText)

                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 70), spacing: 6)],
                        alignment: .leading,
                        spacing: 6
                    ) {
                        ForEach(ServerTag.allCases) { tag in
                            TagToggleChip(
                                tag: tag,
                                isSelected: server.tags.contains(tag),
                                action: { onTagToggle(tag) }
                            )
                        }
                    }
                }

                // Config preview or editor
                if isEditing && !server.isCodexUniverse {
                    // Inline editing only for Claude/Gemini (JSON)
                    VStack(alignment: .trailing, spacing: 8) {
                        TextEditor(text: $editedConfigText)
                            .font(DesignTokens.Typography.code)
                            .frame(height: 200)
                            .scrollContentBackground(.hidden)
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(8)
                            .focusable(true)

                        HStack(spacing: 8) {
                            Button(action: {
                                editedConfigText = formatJSON(editedConfigText)
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "text.alignleft")
                                        .font(.system(size: 12))
                                    Text("Format")
                                        .font(DesignTokens.Typography.labelSmall)
                                }
                                .foregroundColor(themeColors.primaryText)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(themeColors.glassBackground)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(themeColors.borderColor, lineWidth: 1)
                                        )
                                )
                            }
                            .buttonStyle(.plain)

                            Spacer()

                            Button(action: {
                                isEditing = false
                            }) {
                                Text("Cancel")
                                    .font(DesignTokens.Typography.labelSmall)
                                    .foregroundColor(themeColors.primaryText)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(themeColors.glassBackground)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(themeColors.borderColor, lineWidth: 1)
                                            )
                                    )
                            }
                            .buttonStyle(.plain)

                            Button(action: {
                                let result = onUpdate(editedConfigText)
                                if result.success {
                                    isEditing = false
                                } else if let reason = result.invalidReason {
                                    // Show force save alert
                                    invalidReason = reason
                                    pendingSaveJSON = editedConfigText
                                    pendingConfig = result.config  // Store parsed config to avoid re-parsing
                                    showForceAlert = true
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12))
                                    Text("Save")
                                        .font(DesignTokens.Typography.labelSmall)
                                }
                                .foregroundColor(Color(hex: "#1a1a1a"))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(themeColors.accentGradient)
                                )
                                .shadow(color: themeColors.primaryAccent.opacity(0.3), radius: 6, x: 0, y: 2)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } else {
                    ZStack(alignment: .topTrailing) {
                        ScrollView {
                            Text(server.isCodexUniverse ? server.configTOML : server.configJSON)
                                .font(DesignTokens.Typography.code)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(8)
                                .blur(radius: (blurJSONPreviews && !isEditing) ? DesignTokens.jsonPreviewBlurRadius : 0)
                        }
                        .frame(height: 200)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(8)

                        if isHovering && !server.isCodexUniverse {
                            // Only show edit button for Claude/Gemini (JSON)
                            // Codex servers must use Raw TOML editor
                            Button(action: {
                                editedConfigText = server.configJSON
                                isEditing = true
                            }) {
                                Image(systemName: "pencil")
                                    .font(DesignTokens.Typography.labelSmall)
                                    .padding(6)
                                    .background(Color.blue.opacity(0.8))
                                    .foregroundColor(.white)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .padding(8)
                        }

                        if server.isCodexUniverse && isHovering {
                            // Show info tooltip for Codex servers
                            Text("Use Raw Editor")
                                .font(DesignTokens.Typography.labelSmall)
                                .foregroundColor(.secondary)
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.black.opacity(0.7))
                                )
                                .padding(8)
                        }
                    }
                    .onHover { hovering in
                        isHovering = hovering
                    }
                }

                // Footer
                HStack {
                    CustomToggleSwitch(
                        isOn: Binding(
                            get: { server.inConfigs[safe: activeConfigIndex] ?? false },
                            set: { _ in onToggle() }
                        )
                    )

                    Spacer()

                    Button(action: {
                        if confirmDelete {
                            showingDeleteAlert = true
                        } else {
                            onDelete()
                        }
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                    .alert("Delete Server", isPresented: $showingDeleteAlert) {
                        Button("Cancel", role: .cancel) { }
                        Button("Delete", role: .destructive) {
                            onDelete()
                        }
                    } message: {
                        Text("Are you sure you want to delete '\(server.name)'?")
                    }
                }
            }
            .padding(DesignTokens.cardPadding)
        }
        .alert("Invalid Server Configuration", isPresented: $showForceAlert) {
            Button("Cancel", role: .cancel) {
                showForceAlert = false
                pendingSaveJSON = ""
                pendingConfig = nil
                invalidReason = ""
            }
            Button("Force Save") {
                // Use parsed config if available to avoid re-parsing
                if let config = pendingConfig {
                    if onUpdateForced(config) {
                        isEditing = false
                    }
                }
                showForceAlert = false
                pendingSaveJSON = ""
                pendingConfig = nil
                invalidReason = ""
            }
        } message: {
            Text("This server has validation errors:\n\n\(invalidReason)\n\nDo you want to force save anyway? This will override all validations.")
        }
    }

    private func formatJSON(_ string: String) -> String {
        // First normalize quotes (curly quotes from Notes/Word/Slack)
        let normalized = string.normalizingQuotes()

        guard let data = normalized.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data),
              let formatted = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]),
              let result = String(data: formatted, encoding: .utf8) else {
            return string
        }
        return result
    }
}

struct ConfigBadge: View {
    let number: Int
    let isActive: Bool
    let isCurrentConfig: Bool

    var body: some View {
        Text("\(number)")
            .font(DesignTokens.Typography.captionSmall)
            .foregroundColor(isActive ? .white : .gray)
            .frame(width: 18, height: 18)
            .background(
                Circle()
                    .fill(badgeColor)
                    .shadow(color: isActive && isCurrentConfig ? .blue.opacity(0.5) : .clear, radius: 4)
            )
    }

    private var badgeColor: Color {
        if isActive && isCurrentConfig {
            return .blue
        } else if isActive {
            return .gray
        } else {
            return .gray.opacity(0.3)
        }
    }
}

struct TagToggleChip: View {
    let tag: ServerTag
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.themeColors) private var themeColors

    var body: some View {
        Button(action: action) {
            Text(tag.rawValue)
                .font(DesignTokens.Typography.caption)
                .foregroundColor(isSelected ? themeColors.textOnAccent : themeColors.secondaryText)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(isSelected ? AnyShapeStyle(themeColors.accentGradient) : AnyShapeStyle(themeColors.glassBackground))
                        .overlay(
                            Capsule()
                                .stroke(isSelected ? themeColors.primaryAccent.opacity(0.6) : themeColors.borderColor, lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }
}
