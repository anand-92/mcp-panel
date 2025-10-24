import SwiftUI

struct ServerGridView: View {
    @ObservedObject var viewModel: ServerViewModel

    var body: some View {
        ScrollView {
            if viewModel.filteredServers.isEmpty {
                EmptyStateView(onCreateServer: {})
            } else {
                LazyVGrid(columns: GridConfiguration.columns, spacing: DesignTokens.gridSpacing) {
                    ForEach(viewModel.filteredServers) { server in
                        ServerCardView(
                            server: server,
                            activeConfigIndex: $viewModel.settings.activeConfigIndex,
                            onToggle: {
                                viewModel.toggleServer(server)
                            },
                            onDelete: {
                                viewModel.deleteServer(server)
                            },
                            onUpdate: { json in
                                viewModel.updateServer(server, with: json)
                            }
                        )
                    }
                }
                .padding(20)
            }
        }
    }
}

struct EmptyStateView: View {
    let onCreateServer: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "server.rack")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
                .padding(30)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.05))
                )

            Text("No servers configured yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Add your first MCP server to get started")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Button(action: onCreateServer) {
                Text("Create Server")
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(DesignTokens.primaryGradient)
                    )
                    .foregroundColor(.white)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
}
