import SwiftUI

struct HeaderView: View {
    @ObservedObject var viewModel: ServerViewModel
    @Binding var showSettings: Bool
    @Binding var showAddServer: Bool
    @Binding var showQuickActions: Bool
    @Environment(\.themeColors) private var themeColors
    @State private var isPulsing = true

    var body: some View {
        HStack(spacing: 16) {
            // Quick Actions Button - Enhanced discoverability
            QuickActionsButton(
                showQuickActions: $showQuickActions,
                isPulsing: $isPulsing,
                themeColors: themeColors
            )

            // App title
            Text("MCP Server Manager")
                .font(DesignTokens.Typography.title3)
                .foregroundStyle(themeColors.accentGradient)

            Spacer()

            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)

                TextField("Search servers... (⌘F)", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
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
                    path: viewModel.settings.config1Path,
                    isActive: viewModel.settings.activeConfigIndex == 0,
                    action: {
                        viewModel.settings.activeConfigIndex = 0
                        viewModel.loadServers()
                    }
                )

                ConfigButton(
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
                    .font(DesignTokens.Typography.title3)
                    .foregroundColor(Color(hex: "#1a1a1a"))
                    .padding(8)
                    .background(
                        Circle()
                            .fill(themeColors.accentGradient)
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
    let path: String
    let isActive: Bool
    let action: () -> Void
    @Environment(\.themeColors) private var themeColors

    var body: some View {
        Button(action: action) {
            Text(path.shortPath())
                .font(DesignTokens.Typography.label)
                .lineLimit(1)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isActive ? AnyShapeStyle(themeColors.accentGradient) : AnyShapeStyle(themeColors.glassBackground))
                )
                .foregroundColor(isActive ? Color(hex: "#1a1a1a") : themeColors.mutedText)
        }
        .buttonStyle(.plain)
    }
}

struct QuickActionsButton: View {
    @Binding var showQuickActions: Bool
    @Binding var isPulsing: Bool
    let themeColors: ThemeColors

    var body: some View {
        Button(action: handleTap) {
            buttonContent
        }
        .buttonStyle(.plain)
        .help("Quick Actions Menu • Add, Import & Export")
        .onAppear(perform: startPulsing)
    }

    private var buttonContent: some View {
        ZStack(alignment: .topTrailing) {
            iconView
            indicatorDot
        }
    }

    private var iconView: some View {
        let iconName = showQuickActions ? "xmark" : "square.grid.2x2.fill"
        let foregroundColor = showQuickActions ? Color(hex: "#1a1a1a") : themeColors.primaryText
        let borderOpacity = isPulsing ? 0.3 : 0.1
        let scale = isPulsing ? 1.05 : 1.0
        let shadowOpacity = isPulsing ? 0.3 : 0.0

        return Image(systemName: iconName)
            .font(DesignTokens.Typography.title3)
            .foregroundColor(foregroundColor)
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(showQuickActions ? AnyShapeStyle(themeColors.accentGradient) : AnyShapeStyle(Color.white.opacity(0.05)))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(themeColors.primaryAccent.opacity(borderOpacity), lineWidth: 1)
                    )
            )
            .scaleEffect(scale)
            .shadow(color: themeColors.primaryAccent.opacity(shadowOpacity), radius: isPulsing ? 8 : 0)
            .rotationEffect(.degrees(showQuickActions ? 90 : 0))
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showQuickActions)
    }

    @ViewBuilder
    private var indicatorDot: some View {
        if !showQuickActions && isPulsing {
            Circle()
                .fill(themeColors.primaryAccent)
                .frame(width: 6, height: 6)
                .offset(x: 2, y: -2)
        }
    }

    private func handleTap() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            showQuickActions.toggle()
        }
        isPulsing = false
    }

    private func startPulsing() {
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            isPulsing = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            withAnimation {
                isPulsing = false
            }
        }
    }
}
