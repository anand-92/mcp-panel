import SwiftUI

struct ServerCardView: View {
    let server: ServerModel
    @Binding var activeConfigIndex: Int
    @State private var isEditing = false
    @State private var editedJSON: String = ""
    @State private var isHovering = false

    let onToggle: () -> Void
    let onDelete: () -> Void
    let onUpdate: (String) -> Void

    var body: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack(alignment: .top) {
                    Text(server.name)
                        .font(.headline)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 4) {
                        ConfigBadge(number: 1, isActive: server.isInConfig1, isCurrentConfig: activeConfigIndex == 0)
                        ConfigBadge(number: 2, isActive: server.isInConfig2, isCurrentConfig: activeConfigIndex == 1)
                    }
                }

                // Config summary
                Text(server.config.summary)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                // JSON preview or editor
                if isEditing {
                    VStack(alignment: .trailing, spacing: 8) {
                        TextEditor(text: $editedJSON)
                            .font(.system(.caption, design: .monospaced))
                            .frame(height: 120)
                            .scrollContentBackground(.hidden)
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(8)
                            .focusable(true)

                        HStack {
                            Button("Format") {
                                editedJSON = formatJSON(editedJSON)
                            }
                            .buttonStyle(.bordered)

                            Spacer()

                            Button("Cancel") {
                                isEditing = false
                            }
                            .buttonStyle(.bordered)

                            Button("Save") {
                                onUpdate(editedJSON)
                                isEditing = false
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .controlSize(.small)
                    }
                } else {
                    ZStack(alignment: .topTrailing) {
                        ScrollView {
                            Text(server.configJSON)
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(8)
                        }
                        .frame(height: 120)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(8)

                        if isHovering {
                            Button(action: {
                                editedJSON = server.configJSON
                                isEditing = true
                            }) {
                                Image(systemName: "pencil")
                                    .font(.caption)
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

                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
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
            .font(.system(size: 10, weight: .bold))
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
