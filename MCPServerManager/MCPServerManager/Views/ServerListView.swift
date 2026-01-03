import SwiftUI

struct ServerListView: View {
    @ObservedObject var viewModel: ServerViewModel
    @Binding var showAddServer: Bool
    @Environment(\.themeColors) private var themeColors

    var body: some View {
        ScrollView {
            if viewModel.filteredServers.isEmpty {
                 EmptyStateView(onCreateServer: {
                    showAddServer = true
                })
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.filteredServers) { server in
                        ServerListRow(
                            server: server,
                            activeConfigIndex: viewModel.settings.activeConfigIndex,
                            onToggle: {
                                viewModel.toggleServer(server)
                            },
                            onTagToggle: { tag in
                                viewModel.toggleTag(tag, for: server)
                            }
                        )
                    }
                }
                .padding(20)
            }
        }
    }
}

struct ServerListRow: View {
    let server: ServerModel
    let activeConfigIndex: Int
    let onToggle: () -> Void
    let onTagToggle: (ServerTag) -> Void
    
    @Environment(\.themeColors) private var themeColors
    @State private var isHovering = false
    
    var isEnabled: Bool {
        server.inConfigs[safe: activeConfigIndex] ?? false
    }

    var body: some View {
        HStack(spacing: 16) {
             // Server Icon (Small)
            ServerIconView(
                server: server,
                size: 32,
                onCustomIconSelected: nil // Disable icon changing in list view for simplicity
            )
            
            // Name
            Text(server.name)
                .font(DesignTokens.Typography.bodyBold)
                .foregroundColor(isEnabled ? themeColors.primaryText : themeColors.mutedText)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Tags
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(ServerTag.allCases) { tag in
                        let isSelected = server.tags.contains(tag)
                        if isSelected {
                            TagListPill(tag: tag)
                        }
                    }
                }
            }
            .frame(maxWidth: 250) // Limit width for tags
            
            // Toggle
            CustomToggleSwitch(isOn: Binding(
                get: { isEnabled },
                set: { _ in onToggle() }
            ))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isEnabled ? themeColors.glassBackground : themeColors.glassBackground.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isEnabled ? themeColors.glassBorder : Color.clear, lineWidth: 1)
                )
        )
        .onHover { hover in
            isHovering = hover
        }
        .scaleEffect(isHovering ? 1.005 : 1.0)
        .animation(.spring(response: 0.3), value: isHovering)
    }
}

struct TagListPill: View {
    let tag: ServerTag
    @Environment(\.themeColors) private var themeColors

    var body: some View {
        Text(tag.rawValue)
            .font(DesignTokens.Typography.captionSmall)
            .foregroundColor(themeColors.textOnAccent)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(AnyShapeStyle(themeColors.accentGradient.opacity(0.8)))
            )
    }
}
