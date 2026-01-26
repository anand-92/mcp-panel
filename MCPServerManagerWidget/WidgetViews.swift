import SwiftUI
import WidgetKit
import AppIntents

/// Main entry view for the widget
struct MCPWidgetEntryView: View {
    var entry: ServerEntry

    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget (2 servers)

struct SmallWidgetView: View {
    let entry: ServerEntry

    private var displayServers: [WidgetServerModel] {
        Array(entry.servers.prefix(2))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerView

            if displayServers.isEmpty {
                emptyStateView
            } else {
                ForEach(displayServers) { server in
                    WidgetServerRow(server: server, compact: true)
                }
            }

            Spacer()
        }
        .padding(12)
    }

    private var headerView: some View {
        HStack {
            Image(systemName: "server.rack")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.accentColor)

            Text("MCP")
                .font(.system(size: 12, weight: .semibold))

            Spacer()

            Text(entry.configName)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 4) {
            Image(systemName: "server.rack")
                .font(.system(size: 20))
                .foregroundColor(.secondary)

            Text("No servers")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Medium Widget (4 servers in 2x2 grid)

struct MediumWidgetView: View {
    let entry: ServerEntry

    private var displayServers: [WidgetServerModel] {
        Array(entry.servers.prefix(4))
    }

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerView

            if displayServers.isEmpty {
                emptyStateView
            } else {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(displayServers) { server in
                        WidgetServerRow(server: server, compact: false)
                    }
                }
            }

            Spacer()
        }
        .padding(12)
    }

    private var headerView: some View {
        HStack {
            Image(systemName: "server.rack")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.accentColor)

            Text("MCP Servers")
                .font(.system(size: 14, weight: .semibold))

            Spacer()

            Text(entry.configName)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "server.rack")
                .font(.system(size: 24))
                .foregroundColor(.secondary)

            Text("No servers configured")
                .font(.system(size: 12))
                .foregroundColor(.secondary)

            Text("Add servers in the app")
                .font(.system(size: 10))
                .foregroundColor(.secondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Large Widget (8 servers in 2x4 grid)

struct LargeWidgetView: View {
    let entry: ServerEntry

    private var displayServers: [WidgetServerModel] {
        Array(entry.servers.prefix(8))
    }

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerView

            if displayServers.isEmpty {
                emptyStateView
            } else {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(displayServers) { server in
                        WidgetServerRow(server: server, compact: false)
                    }
                }
            }

            Spacer()
        }
        .padding(16)
    }

    private var headerView: some View {
        HStack {
            Image(systemName: "server.rack")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.accentColor)

            Text("MCP Servers")
                .font(.system(size: 16, weight: .semibold))

            Spacer()

            Text(entry.configName)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "server.rack")
                .font(.system(size: 32))
                .foregroundColor(.secondary)

            Text("No servers configured")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)

            Text("Open MCP Server Manager to add servers,\nthen mark them for widget display")
                .font(.system(size: 12))
                .foregroundColor(.secondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Server Row

struct WidgetServerRow: View {
    let server: WidgetServerModel
    let compact: Bool

    var body: some View {
        if #available(macOS 14.0, *) {
            interactiveRow
        } else {
            staticRow
        }
    }

    @available(macOS 14.0, *)
    private var interactiveRow: some View {
        Button(intent: ServerToggleIntent(serverID: server.id.uuidString, newState: !server.isEnabled)) {
            rowContent
        }
        .buttonStyle(.plain)
    }

    private var staticRow: some View {
        rowContent
    }

    private var rowContent: some View {
        HStack(spacing: compact ? 6 : 8) {
            Circle()
                .fill(server.isEnabled ? Color.green : Color.gray.opacity(0.5))
                .frame(width: compact ? 6 : 8, height: compact ? 6 : 8)

            Text(server.name)
                .font(.system(size: compact ? 11 : 12, weight: server.isEnabled ? .medium : .regular))
                .foregroundColor(server.isEnabled ? .primary : .secondary)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer()

            Image(systemName: server.isEnabled ? "checkmark.circle.fill" : "circle")
                .font(.system(size: compact ? 12 : 14))
                .foregroundColor(server.isEnabled ? .green : .secondary)
        }
        .padding(.horizontal, compact ? 8 : 10)
        .padding(.vertical, compact ? 6 : 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.primary.opacity(0.05))
        )
    }
}

// MARK: - Previews

struct MCPWidgetEntryView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleServers = [
            WidgetServerModel(id: UUID(), name: "filesystem", isEnabled: true),
            WidgetServerModel(id: UUID(), name: "github", isEnabled: true),
            WidgetServerModel(id: UUID(), name: "slack", isEnabled: false),
            WidgetServerModel(id: UUID(), name: "notion", isEnabled: true)
        ]

        let entry = ServerEntry(date: Date(), servers: sampleServers, configName: "Claude")

        Group {
            MCPWidgetEntryView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Small")

            MCPWidgetEntryView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("Medium")

            MCPWidgetEntryView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .systemLarge))
                .previewDisplayName("Large")
        }
    }
}
