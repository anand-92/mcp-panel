import SwiftUI

struct HeaderView: View {
    @ObservedObject var viewModel: ServerViewModel
    @Binding var showSettings: Bool
    @Binding var showSidebar: Bool

    var body: some View {
        HStack(spacing: 16) {
            // Hamburger menu (mobile/compact)
            Button(action: { showSidebar.toggle() }) {
                Image(systemName: "line.3.horizontal")
                    .font(.scaled(.title2))
            }
            .buttonStyle(.plain)
            .help("Toggle Sidebar")

            // App title
            HStack(spacing: 4) {
                Text("⚡")
                Text("MCP Server Manager")
                    .font(.scaled(.title3))
                    .fontWeight(.bold)
                    .foregroundStyle(DesignTokens.primaryGradient)
            }

            Spacer()

            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)

                TextField("Search servers... (⌘F)", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                    .frame(width: 250)
                    .focusable(true)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )

            // Config switcher
            HStack(spacing: 8) {
                ConfigButton(
                    number: 1,
                    path: viewModel.settings.config1Path,
                    isActive: viewModel.settings.activeConfigIndex == 0,
                    action: {
                        viewModel.settings.activeConfigIndex = 0
                        viewModel.loadServers()
                    }
                )

                ConfigButton(
                    number: 2,
                    path: viewModel.settings.config2Path,
                    isActive: viewModel.settings.activeConfigIndex == 1,
                    action: {
                        viewModel.settings.activeConfigIndex = 1
                        viewModel.loadServers()
                    }
                )
            }

            // Settings button
            Button(action: { showSettings = true }) {
                Image(systemName: "gear")
                    .font(.scaled(.title3))
                    .foregroundColor(.white)
                    .padding(8)
                    .background(
                        Circle()
                            .fill(DesignTokens.primaryGradient)
                    )
            }
            .buttonStyle(.plain)
            .help("Settings")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Rectangle()
                .fill(Color.black.opacity(0.3))
                .blur(radius: 10)
        )
    }
}

struct ConfigButton: View {
    let number: Int
    let path: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)

                Text(shortPath(path))
                    .font(.scaled(.caption))
                    .lineLimit(1)

                Text("\(number)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 16, height: 16)
                    .background(Circle().fill(Color.blue))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isActive ? AnyShapeStyle(DesignTokens.primaryGradient) : AnyShapeStyle(Color.gray.opacity(0.3)))
            )
            .foregroundColor(.white)
        }
        .buttonStyle(.plain)
    }

    private func shortPath(_ path: String) -> String {
        let components = path.split(separator: "/")
        return String(components.last ?? "config")
    }
}
