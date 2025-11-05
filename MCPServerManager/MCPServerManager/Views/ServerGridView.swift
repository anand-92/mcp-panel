import SwiftUI

struct ServerGridView: View {
    @ObservedObject var viewModel: ServerViewModel
    @Binding var showAddServer: Bool

    var body: some View {
        ScrollView {
            if viewModel.filteredServers.isEmpty {
                EmptyStateView(onCreateServer: {
                    showAddServer = true
                })
            } else {
                LazyVGrid(columns: GridConfiguration.columns, spacing: DesignTokens.gridSpacing) {
                    ForEach(viewModel.filteredServers) { server in
                        ServerCardView(
                            server: server,
                            activeConfigIndex: $viewModel.settings.activeConfigIndex,
                            confirmDelete: $viewModel.settings.confirmDelete,
                            blurJSONPreviews: $viewModel.settings.blurJSONPreviews,
                            onToggle: {
                                viewModel.toggleServer(server)
                            },
                            onDelete: {
                                viewModel.deleteServer(server)
                            },
                            onUpdate: { json in
                                return viewModel.updateServer(server, with: json)
                            },
                            onUpdateForced: { json in
                                return viewModel.updateServerForced(server, with: json)
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
    @Environment(\.themeColors) private var themeColors

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "server.rack")
                .font(DesignTokens.Typography.display)
                .foregroundColor(.secondary)
                .padding(30)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.05))
                )

            Text("No servers configured yet")
                .font(DesignTokens.Typography.title2)

            Text("Add your first MCP server to get started")
                .font(DesignTokens.Typography.body)
                .foregroundColor(.secondary)

            Button(action: onCreateServer) {
                Text("Add Server")
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(themeColors.accentGradient)
                    )
                    .foregroundColor(Color(hex: "#0b0e14"))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
}
