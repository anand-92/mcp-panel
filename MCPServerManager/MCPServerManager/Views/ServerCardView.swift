import SwiftUI

struct ServerCardView: View {
    let server: ServerModel
    @Binding var activeConfigIndex: Int
    @Binding var confirmDelete: Bool
    @Binding var blurJSONPreviews: Bool
    @State private var isEditing = false
    @State private var editedConfigText: String = ""
    @State private var isHovering = false
    @State private var showingDeleteAlert = false
    @State private var showForceAlert = false
    @State private var invalidReason: String = ""
    @State private var pendingConfig: ServerConfig?
    @Environment(\.themeColors) private var themeColors

    let onToggle: () -> Void
    let onTagToggle: (ServerTag) -> Void
    let onDelete: () -> Void
    let onUpdate: (String) -> (success: Bool, invalidReason: String?, config: ServerConfig?)
    let onUpdateForced: (ServerConfig) -> Bool
    let onCustomIconSelected: ((Result<String, Error>) -> Void)?
    let onWidgetToggle: (() -> Void)?

    var body: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 12) {
                headerSection
                configSummary
                tagsSection
                configSection
                footerSection
            }
            .padding(DesignTokens.cardPadding)
        }
        .alert("Invalid Server Configuration", isPresented: $showForceAlert) {
            Button("Cancel", role: .cancel) {
                clearForceAlertState()
            }
            Button("Force Save") {
                handleForceSave()
            }
        } message: {
            Text("This server has validation errors:\n\n\(invalidReason)\n\nDo you want to force save anyway? This will override all validations.")
        }
    }

    // MARK: - View Sections

    private var headerSection: some View {
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
    }

    private var configSummary: some View {
        Text(server.config.summary)
            .font(DesignTokens.Typography.bodySmall)
            .foregroundColor(.secondary)
            .lineLimit(1)
    }

    private var tagsSection: some View {
        HStack {
            ForEach(server.tags) { tag in
                TagChip(tag: tag) {
                    onTagToggle(tag)
                }
            }

            Menu {
                ForEach(ServerTag.allCases) { tag in
                    Button(action: { onTagToggle(tag) }) {
                        HStack {
                            Text(tag.rawValue)
                            if server.tags.contains(tag) {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "tag")
                    Text(server.tags.isEmpty ? "Add Tags" : "Edit")
                }
                .font(DesignTokens.Typography.captionSmall)
                .foregroundColor(themeColors.secondaryText)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .stroke(themeColors.borderColor, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var configSection: some View {
        if isEditing {
            editorView
        } else {
            previewView
        }
    }

    private var editorView: some View {
        VStack(alignment: .trailing, spacing: 8) {
            TextEditor(text: $editedConfigText)
                .font(DesignTokens.Typography.code)
                .frame(height: 200)
                .scrollContentBackground(.hidden)
                .background(Color.black.opacity(0.3))
                .cornerRadius(8)
                .focusable(true)

            HStack(spacing: 8) {
                EditorButton(
                    title: "Format",
                    icon: "text.alignleft",
                    style: .secondary,
                    themeColors: themeColors,
                    action: { editedConfigText = formatJSON(editedConfigText) }
                )

                Spacer()

                EditorButton(
                    title: "Cancel",
                    style: .secondary,
                    themeColors: themeColors,
                    action: { isEditing = false }
                )

                EditorButton(
                    title: "Save",
                    icon: "checkmark",
                    style: .primary,
                    themeColors: themeColors,
                    action: handleSave
                )
            }
        }
    }

    private var previewView: some View {
        ZStack(alignment: .topTrailing) {
            ScrollView {
                Text(server.configJSON)
                    .font(DesignTokens.Typography.code)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .blur(radius: blurJSONPreviews ? DesignTokens.jsonPreviewBlurRadius : 0)
            }
            .frame(height: 200)
            .background(Color.black.opacity(0.3))
            .cornerRadius(8)

            if isHovering {
                Button(action: startEditing) {
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
        }
        .onHover { hovering in
            isHovering = hovering
        }
    }

    private var footerSection: some View {
        HStack {
            CustomToggleSwitch(
                isOn: Binding(
                    get: { server.inConfigs[safe: activeConfigIndex] ?? false },
                    set: { _ in onToggle() }
                )
            )

            Spacer()

            // Widget toggle button
            if let onWidgetToggle = onWidgetToggle {
                Button(action: onWidgetToggle) {
                    Image(systemName: server.showInWidget ? "widget.small.badge.minus" : "widget.small")
                        .font(.system(size: 14))
                        .foregroundColor(server.showInWidget ? themeColors.primaryAccent : themeColors.mutedText)
                }
                .buttonStyle(.plain)
                .help(server.showInWidget ? "Remove from Widget" : "Show in Widget")
            }

            Button(action: handleDeleteTapped) {
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

    // MARK: - Actions

    private func startEditing() {
        editedConfigText = server.configJSON
        isEditing = true
    }

    private func handleSave() {
        let result = onUpdate(editedConfigText)
        if result.success {
            isEditing = false
        } else if let reason = result.invalidReason {
            invalidReason = reason
            pendingConfig = result.config
            showForceAlert = true
        }
    }

    private func handleForceSave() {
        if let config = pendingConfig, onUpdateForced(config) {
            isEditing = false
        }
        clearForceAlertState()
    }

    private func handleDeleteTapped() {
        if confirmDelete {
            showingDeleteAlert = true
        } else {
            onDelete()
        }
    }

    private func clearForceAlertState() {
        showForceAlert = false
        pendingConfig = nil
        invalidReason = ""
    }

    private func formatJSON(_ string: String) -> String {
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

// MARK: - Editor Button

private struct EditorButton: View {
    enum Style {
        case primary
        case secondary
    }

    let title: String
    var icon: String?
    let style: Style
    let themeColors: ThemeColors
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                }
                Text(title)
                    .font(DesignTokens.Typography.labelSmall)
            }
            .foregroundColor(foregroundColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(background)
        }
        .buttonStyle(.plain)
    }

    private var foregroundColor: Color {
        switch style {
        case .primary:
            return Color(hex: "#1a1a1a")
        case .secondary:
            return themeColors.primaryText
        }
    }

    @ViewBuilder
    private var background: some View {
        switch style {
        case .primary:
            RoundedRectangle(cornerRadius: 8)
                .fill(themeColors.accentGradient)
                .shadow(color: themeColors.primaryAccent.opacity(0.3), radius: 6, x: 0, y: 2)
        case .secondary:
            RoundedRectangle(cornerRadius: 8)
                .fill(themeColors.glassBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(themeColors.borderColor, lineWidth: 1)
                )
        }
    }
}

// MARK: - Tag Chip

struct TagChip: View {
    let tag: ServerTag
    let action: () -> Void
    @Environment(\.themeColors) private var themeColors

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(tag.rawValue)
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
            }
            .font(DesignTokens.Typography.caption)
            .foregroundColor(themeColors.textOnAccent)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(AnyShapeStyle(themeColors.accentGradient))
            )
        }
        .buttonStyle(.plain)
    }
}
