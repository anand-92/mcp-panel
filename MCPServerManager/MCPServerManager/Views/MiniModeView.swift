import SwiftUI

struct MiniModeView: View {
    @ObservedObject var viewModel: ServerViewModel
    let onExpand: () -> Void
    @Environment(\.themeColors) private var themeColors
    @State private var searchText = ""

    private var filteredServers: [ServerModel] {
        if searchText.isEmpty {
            return viewModel.servers
        }
        return viewModel.servers.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private var activeConfigName: String {
        viewModel.settings.activeConfigIndex == 0 ? "Claude" : "Gemini"
    }

    private var otherConfigName: String {
        viewModel.settings.activeConfigIndex == 0 ? "Gemini" : "Claude"
    }

    var body: some View {
        VStack(spacing: 0) {
            miniHeader
            searchField
            serverList
        }
        .modifier(LiquidGlassModifier(shape: Rectangle(), fillColor: themeColors.sidebarBackground.opacity(0.5)))
    }

    // MARK: - Mini Header

    private var miniHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: "square.grid.2x2.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(themeColors.accentGradient)

            Text("MCP Servers")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(themeColors.primaryText)

            Spacer()

            configSwitchButton
            expandButton
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(themeColors.sidebarBackground.opacity(0.3))
    }

    private var configSwitchButton: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                viewModel.settings.activeConfigIndex = viewModel.settings.activeConfigIndex == 0 ? 1 : 0
            }
        } label: {
            Text(activeConfigName)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(themeColors.textOnAccent)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(themeColors.accentGradient))
        }
        .buttonStyle(.plain)
        .help("Switch to \(otherConfigName)")
    }

    private var expandButton: some View {
        Button(action: onExpand) {
            Image(systemName: "arrow.up.left.and.arrow.down.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(themeColors.primaryText)
                .padding(6)
                .background(
                    Circle()
                        .fill(themeColors.glassBackground)
                        .overlay(Circle().stroke(themeColors.borderColor, lineWidth: 1))
                )
        }
        .buttonStyle(.plain)
        .help("Expand to full view")
    }

    // MARK: - Search Field

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 11))
                .foregroundColor(themeColors.mutedText)

            TextField("Search...", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .foregroundColor(themeColors.primaryText)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(themeColors.glassBackground)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(themeColors.borderColor, lineWidth: 0.5))
        )
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }

    // MARK: - Server List

    private var serverList: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                ForEach(filteredServers) { server in
                    MiniServerRow(
                        server: server,
                        isEnabled: server.inConfigs[safe: viewModel.settings.activeConfigIndex] ?? false,
                        onToggle: { viewModel.toggleServer(server) }
                    )
                }
            }
            .padding(.horizontal, 6)
            .padding(.bottom, 8)
        }
    }
}

// MARK: - Mini Server Row

struct MiniServerRow: View {
    let server: ServerModel
    let isEnabled: Bool
    let onToggle: () -> Void

    @Environment(\.themeColors) private var themeColors
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 8) {
            statusDot
            serverNameLabel
            Spacer()
            toggleSwitch
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 6).fill(isHovering ? themeColors.glassBackground : Color.clear))
        .onHover { hover in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hover
            }
        }
    }

    private var statusDot: some View {
        Circle()
            .fill(isEnabled ? themeColors.successColor : themeColors.mutedText.opacity(0.5))
            .frame(width: 6, height: 6)
    }

    private var serverNameLabel: some View {
        Text(server.name)
            .font(.system(size: 12, weight: isEnabled ? .medium : .regular))
            .foregroundColor(isEnabled ? themeColors.primaryText : themeColors.mutedText)
            .lineLimit(1)
            .truncationMode(.tail)
    }

    private var toggleSwitch: some View {
        Button(action: onToggle) {
            ZStack {
                Capsule()
                    .fill(isEnabled ? themeColors.successColor : themeColors.glassBackground)
                    .frame(width: 32, height: 18)
                    .overlay(Capsule().stroke(isEnabled ? Color.clear : themeColors.borderColor, lineWidth: 0.5))

                Circle()
                    .fill(Color.white)
                    .frame(width: 14, height: 14)
                    .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 1)
                    .offset(x: isEnabled ? 7 : -7)
            }
        }
        .buttonStyle(.plain)
    }
}
