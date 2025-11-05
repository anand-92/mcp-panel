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
                    VStack(alignment: .leading, spacing: 4) {
                        Text(server.name)
                            .font(DesignTokens.Typography.title2)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .primaryTextVisibility()
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: server.name)

                        // Config summary - moved here for better hierarchy
                        Text(server.config.summary)
                            .font(DesignTokens.Typography.bodySmall)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .secondaryTextVisibility()
                    }

                    Spacer()

                    ServerIconView(server: server, size: 40)
                        .scaleEffect(isHovering && !isEditing ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovering)
                }

                // JSON preview or editor with smooth transition
                if isEditing {
                    VStack(alignment: .trailing, spacing: 8) {
                        TextEditor(text: $editedJSON)
                            .font(DesignTokens.Typography.code)
                            .frame(height: 200)
                            .scrollContentBackground(.hidden)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.black.opacity(0.4))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(themeColors.primaryAccent.opacity(0.3), lineWidth: 1)
                                    )
                            )
                            .cornerRadius(12)
                            .focusable(true)
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.95).combined(with: .opacity),
                                removal: .scale(scale: 0.95).combined(with: .opacity)
                            ))

                        HStack(spacing: 8) {
                            StyledButton(
                                icon: "text.alignleft",
                                text: "Format",
                                style: .secondary
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    editedJSON = formatJSON(editedJSON)
                                }
                            }

                            Spacer()

                            StyledButton(
                                text: "Cancel",
                                style: .secondary
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    isEditing = false
                                }
                            }

                            StyledButton(
                                icon: "checkmark",
                                text: "Save",
                                style: .primary
                            ) {
                                if onUpdate(editedJSON) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        isEditing = false
                                    }
                                }
                            }
                        }
                    }
                } else {
                    ZStack(alignment: .topTrailing) {
                        ScrollView {
                            Text(server.configJSON)
                                .font(DesignTokens.Typography.code)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .secondaryTextVisibility()
                        }
                        .frame(height: 200)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.3))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            isHovering ?
                                                themeColors.primaryAccent.opacity(0.2) :
                                                Color.white.opacity(0.05),
                                            lineWidth: 1
                                        )
                                )
                        )
                        .cornerRadius(12)

                        if isHovering {
                            Button(action: {
                                editedJSON = server.configJSON
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    isEditing = true
                                }
                            }) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(width: 32, height: 32)
                                    .background(
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [
                                                        themeColors.primaryAccent,
                                                        themeColors.primaryAccent.opacity(0.8)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .shadow(color: themeColors.primaryAccent.opacity(0.4), radius: 8, x: 0, y: 4)
                                    )
                            }
                            .buttonStyle(.plain)
                            .padding(10)
                            .transition(.scale.combined(with: .opacity))
                            .scaleEffect(isHovering ? 1.0 : 0.8)
                        }
                    }
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovering)
                    .onHover { hovering in
                        isHovering = hovering
                    }
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.95).combined(with: .opacity),
                        removal: .scale(scale: 0.95).combined(with: .opacity)
                    ))
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
                            .secondaryTextVisibility()
                    }
                }
            }
            .padding(DesignTokens.cardPadding)
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
            .primaryTextVisibility()
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
