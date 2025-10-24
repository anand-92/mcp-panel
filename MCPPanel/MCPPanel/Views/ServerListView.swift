//
//  ServerListView.swift
//  MCP Panel
//

import SwiftUI

struct ServerListView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if appState.filteredServers.isEmpty {
                EmptyStateView()
            } else {
                List {
                    ForEach(appState.filteredServers) { server in
                        ServerRow(server: server)
                            .environmentObject(appState)
                            .contextMenu {
                                ServerContextMenu(server: server)
                                    .environmentObject(appState)
                            }
                    }
                }
                .listStyle(.inset)
            }
        }
    }
}

struct ServerRow: View {
    @EnvironmentObject var appState: AppState
    let server: ServerConfig

    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(server.isEnabled ? Color.green : Color.gray)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 4) {
                // Server name
                Text(server.id)
                    .font(.headline)

                // Command
                Text(server.command)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                // Details
                HStack(spacing: 8) {
                    if let args = server.args, !args.isEmpty {
                        Label("\(args.count) args", systemImage: "list.bullet")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    if let env = server.env, !env.isEmpty {
                        Label("\(env.count) env", systemImage: "square.grid.2x2")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    if server.hasValidationErrors {
                        Label("Errors", systemImage: "exclamationmark.triangle")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
            }

            Spacer()

            // Action buttons
            HStack(spacing: 8) {
                Button(action: {
                    Task {
                        await appState.toggleServerEnabled(id: server.id)
                    }
                }) {
                    Image(systemName: server.isEnabled ? "pause.circle" : "play.circle")
                        .foregroundColor(server.isEnabled ? .orange : .green)
                }
                .buttonStyle(.plain)

                Button(action: {
                    appState.editingServer = server
                    appState.showServerModal = true
                }) {
                    Image(systemName: "pencil.circle")
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)

                Button(action: {
                    Task {
                        await appState.deleteServer(id: server.id)
                    }
                }) {
                    Image(systemName: "trash.circle")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Server Grid View

struct ServerGridView: View {
    @EnvironmentObject var appState: AppState

    let columns = [
        GridItem(.adaptive(minimum: 300, maximum: 400), spacing: 16)
    ]

    var body: some View {
        Group {
            if appState.filteredServers.isEmpty {
                EmptyStateView()
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(appState.filteredServers) { server in
                            ServerCard(server: server)
                                .environmentObject(appState)
                                .contextMenu {
                                    ServerContextMenu(server: server)
                                        .environmentObject(appState)
                                }
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

struct ServerCard: View {
    @EnvironmentObject var appState: AppState
    let server: ServerConfig

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Circle()
                    .fill(server.isEnabled ? Color.green : Color.gray)
                    .frame(width: 12, height: 12)

                Text(server.id)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                if server.hasValidationErrors {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                }
            }

            Divider()

            // Command
            VStack(alignment: .leading, spacing: 4) {
                Text("Command")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(server.command)
                    .font(.body)
                    .lineLimit(2)
            }

            // Args
            if let args = server.args, !args.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Arguments (\(args.count))")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(args.joined(separator: ", "))
                        .font(.caption)
                        .lineLimit(2)
                }
            }

            // Environment
            if let env = server.env, !env.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Environment (\(env.count))")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(env.keys.joined(separator: ", "))
                        .font(.caption)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Actions
            HStack {
                Button(action: {
                    Task {
                        await appState.toggleServerEnabled(id: server.id)
                    }
                }) {
                    Label(server.isEnabled ? "Disable" : "Enable",
                          systemImage: server.isEnabled ? "pause.circle" : "play.circle")
                }
                .buttonStyle(.bordered)

                Spacer()

                Button(action: {
                    appState.editingServer = server
                    appState.showServerModal = true
                }) {
                    Image(systemName: "pencil")
                }
                .buttonStyle(.bordered)

                Button(action: {
                    Task {
                        await appState.deleteServer(id: server.id)
                    }
                }) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(server.isEnabled ? Color.green.opacity(0.3) : Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Context Menu

struct ServerContextMenu: View {
    @EnvironmentObject var appState: AppState
    let server: ServerConfig

    var body: some View {
        Button(action: {
            appState.editingServer = server
            appState.showServerModal = true
        }) {
            Label("Edit", systemImage: "pencil")
        }

        Button(action: {
            Task {
                await appState.duplicateServer(id: server.id)
            }
        }) {
            Label("Duplicate", systemImage: "doc.on.doc")
        }

        Button(action: {
            Task {
                await appState.toggleServerEnabled(id: server.id)
            }
        }) {
            Label(server.isEnabled ? "Disable" : "Enable",
                  systemImage: server.isEnabled ? "pause.circle" : "play.circle")
        }

        Divider()

        Button(action: {
            Task {
                await appState.deleteServer(id: server.id)
            }
        }) {
            Label("Delete", systemImage: "trash")
        }
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text(emptyMessage)
                .font(.title2)
                .foregroundColor(.secondary)

            if appState.servers.isEmpty {
                Button(action: {
                    appState.editingServer = nil
                    appState.showServerModal = true
                }) {
                    Label("Add Your First Server", systemImage: "plus.circle")
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button(action: {
                    appState.searchQuery = ""
                    appState.settings.filterMode = .all
                }) {
                    Label("Clear Filters", systemImage: "xmark.circle")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyMessage: String {
        if !appState.searchQuery.isEmpty {
            return "No servers match '\(appState.searchQuery)'"
        } else if appState.settings.filterMode != .all {
            return "No \(appState.settings.filterMode.rawValue) servers"
        } else {
            return "No servers configured"
        }
    }
}

// MARK: - Previews

#Preview("List View") {
    ServerListView()
        .environmentObject(AppState())
        .frame(width: 800, height: 600)
}

#Preview("Grid View") {
    ServerGridView()
        .environmentObject(AppState())
        .frame(width: 800, height: 600)
}
