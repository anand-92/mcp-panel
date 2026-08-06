import SwiftUI

/// Read-only summary of the selected server: transport details, tags, health and timestamps.
struct InspectorOverviewTab: View {
    let server: ServerModel
    let healthStatus: ServerHealthStatus
    let onTagToggle: (ServerTag) -> Void
    let onCheckHealth: () -> Void
    let onCustomIconSelected: (Result<String, Error>) -> Void

    @Environment(\.themeColors) private var themeColors

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                identitySection
                Divider().opacity(0.3)
                detailSection
                Divider().opacity(0.3)
                tagSection
                Divider().opacity(0.3)
                healthSection
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Identity

    private var identitySection: some View {
        HStack(alignment: .top, spacing: 14) {
            ServerIconView(
                server: server,
                size: 52,
                onCustomIconSelected: onCustomIconSelected
            )

            VStack(alignment: .leading, spacing: 6) {
                Text(server.name)
                    .font(DesignTokens.Typography.title2)
                    .foregroundStyle(themeColors.primaryText)
                    .lineLimit(2)

                Text(server.config.summary)
                    .font(DesignTokens.Typography.bodySmall)
                    .foregroundStyle(themeColors.secondaryText)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }

    // MARK: - Details

    private var detailSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            InspectorSectionLabel(text: "Configuration")

            InspectorDetailRow(label: "Transport") {
                TransportBadge(label: server.config.transportLabel, themeColors: themeColors)
            }

            if let command = server.config.command, !command.isEmpty {
                InspectorDetailRow(label: "Command") {
                    InspectorMonoText(text: command)
                }
            }

            if let args = server.config.args, !args.isEmpty {
                InspectorDetailRow(label: "Arguments") {
                    InspectorMonoText(text: args.joined(separator: " "))
                }
            }

            if let endpoint = endpointURL {
                InspectorDetailRow(label: "Endpoint") {
                    InspectorMonoText(text: endpoint)
                }
            }

            if let cwd = server.config.cwd, !cwd.isEmpty {
                InspectorDetailRow(label: "Directory") {
                    InspectorMonoText(text: cwd)
                }
            }

            InspectorDetailRow(label: "Updated") {
                Text(relativeUpdatedAt)
                    .font(DesignTokens.Typography.labelSmall)
                    .foregroundStyle(themeColors.secondaryText)
            }
        }
    }

    private var endpointURL: String? {
        if let url = server.config.url, !url.isEmpty { return url }
        if let httpUrl = server.config.httpUrl, !httpUrl.isEmpty { return httpUrl }
        if let transportURL = server.config.transport?.url, !transportURL.isEmpty { return transportURL }
        return server.config.remotes?.first?.url
    }

    private var relativeUpdatedAt: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: server.updatedAt, relativeTo: Date())
    }

    // MARK: - Tags

    private var tagSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            InspectorSectionLabel(text: "Tags")

            // Wrapping row: 5 tags at ~90 pt each need to reflow in a narrow pane.
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 92, maximum: 160), spacing: 6, alignment: .leading)],
                alignment: .leading,
                spacing: 6
            ) {
                ForEach(ServerTag.allCases) { tag in
                    InspectorTagToggle(
                        tag: tag,
                        isOn: server.tags.contains(tag),
                        action: { onTagToggle(tag) }
                    )
                }
            }
        }
    }

    // MARK: - Health

    private var healthSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            InspectorSectionLabel(text: "Health")

            HStack(spacing: 10) {
                HealthStatusIndicator(status: healthStatus, themeColors: themeColors)

                Text(healthStatus.message)
                    .font(DesignTokens.Typography.labelSmall)
                    .foregroundStyle(themeColors.secondaryText)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 8)

                EditorButton(
                    title: "Check",
                    icon: "checkmark.shield",
                    style: .secondary,
                    themeColors: themeColors,
                    isEnabled: healthStatus != .checking,
                    action: onCheckHealth
                )
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(themeColors.glassBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(themeColors.borderColor, lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - Building Blocks

struct InspectorSectionLabel: View {
    let text: String
    @Environment(\.themeColors) private var themeColors

    var body: some View {
        Text(text.uppercased())
            .font(DesignTokens.Typography.captionSmall)
            .tracking(1.2)
            .foregroundStyle(themeColors.mutedText)
    }
}

private struct InspectorDetailRow<Content: View>: View {
    let label: String
    @ViewBuilder let content: Content

    @Environment(\.themeColors) private var themeColors

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(label)
                .font(DesignTokens.Typography.labelSmall)
                .foregroundStyle(themeColors.mutedText)
                .frame(width: 78, alignment: .leading)

            content

            Spacer(minLength: 0)
        }
    }
}

private struct InspectorMonoText: View {
    let text: String
    @Environment(\.themeColors) private var themeColors

    var body: some View {
        Text(text)
            .font(DesignTokens.Typography.codeSmall)
            .foregroundStyle(themeColors.primaryText)
            .textSelection(.enabled)
            .lineLimit(3)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct InspectorTagToggle: View {
    let tag: ServerTag
    let isOn: Bool
    let action: () -> Void

    @Environment(\.themeColors) private var themeColors

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 10, weight: .semibold))
                Text(tag.rawValue)
                    .font(DesignTokens.Typography.caption)
                    .lineLimit(1)
            }
            .foregroundStyle(isOn ? themeColors.textOnAccent : themeColors.secondaryText)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Capsule()
                    .fill(isOn ? AnyShapeStyle(themeColors.accentGradient) : AnyShapeStyle(themeColors.glassBackground))
                    .overlay(
                        Capsule()
                            .stroke(isOn ? Color.clear : themeColors.borderColor, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(isOn ? "Remove" : "Add") tag \(tag.rawValue)")
    }
}
