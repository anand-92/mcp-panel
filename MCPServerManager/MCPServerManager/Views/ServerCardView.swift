import SwiftUI

struct ServerCardView: View {
    let server: ServerModel
    @Binding var activeConfigIndex: Int
    @Binding var confirmDelete: Bool
    @State private var isEditing = false
    @State private var editedJSON: String = ""
    @State private var isHovering = false
    @State private var showingDeleteAlert = false
    @Environment(\.themeColors) private var themeColors

    let onToggle: () -> Void
    let onDelete: () -> Void
    let onUpdate: (String) -> Bool

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

                    ServerIconView(server: server, size: 40)
                }

                // Config summary
                Text(server.config.summary)
                    .font(DesignTokens.Typography.bodySmall)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                // JSON preview or editor
                if isEditing {
                    VStack(alignment: .trailing, spacing: 8) {
                        TextEditor(text: $editedJSON)
                            .font(DesignTokens.Typography.code)
                            .frame(height: 200)
                            .scrollContentBackground(.hidden)
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(8)
                            .focusable(true)

                        HStack(spacing: 8) {
                            Button(action: {
                                editedJSON = formatJSON(editedJSON)
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
                                if onUpdate(editedJSON) {
                                    isEditing = false
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
                            Text(server.configJSON)
                                .font(DesignTokens.Typography.code)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(8)
                        }
                        .frame(height: 200)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(8)

                        if isHovering {
                            Button(action: {
                                editedJSON = server.configJSON
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
    }

    private func formatJSON(_ string: String) -> String {
        guard let data = string.data(using: .utf8),
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
