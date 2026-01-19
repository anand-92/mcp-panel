import SwiftUI

struct HeaderView: View {
    @ObservedObject var viewModel: ServerViewModel
    @Binding var showSettings: Bool
    @Binding var showAddServer: Bool
    @Binding var showQuickActions: Bool
    @Environment(\.themeColors) private var themeColors
    @State private var isPulsing = false

    var body: some View {
        HStack(spacing: 16) {
            QuickActionsButton(
                showQuickActions: $showQuickActions,
                isPulsing: $isPulsing,
                themeColors: themeColors
            )

            Text("MCP Server Manager")
                .font(DesignTokens.Typography.title3)
                .foregroundStyle(themeColors.accentGradient)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Spacer()

            SearchField(text: $viewModel.searchText)

            ConfigSwitcher(viewModel: viewModel)

            SettingsButton(showSettings: $showSettings, themeColors: themeColors)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .modifier(LiquidGlassModifier(shape: Rectangle(), fillColor: Color.black.opacity(0.3)))
    }
}

// MARK: - Search Field

private struct SearchField: View {
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search servers... (⌘F)", text: $text)
                .textFieldStyle(.plain)
                .focusable(true)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(minWidth: 100, maxWidth: 300)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - Config Switcher

private struct ConfigSwitcher: View {
    @ObservedObject var viewModel: ServerViewModel

    var body: some View {
        HStack(spacing: 8) {
            ConfigButton(
                path: viewModel.settings.config1Path,
                isActive: viewModel.settings.activeConfigIndex == 0
            ) {
                viewModel.settings.activeConfigIndex = 0
                viewModel.loadServers()
            }

            ConfigButton(
                path: viewModel.settings.config2Path,
                isActive: viewModel.settings.activeConfigIndex == 1
            ) {
                viewModel.settings.activeConfigIndex = 1
                viewModel.loadServers()
            }
        }
    }
}

// MARK: - Settings Button

private struct SettingsButton: View {
    @Binding var showSettings: Bool
    let themeColors: ThemeColors

    var body: some View {
        Button { showSettings = true } label: {
            Image(systemName: "gear")
                .font(DesignTokens.Typography.title3)
                .foregroundColor(Color(hex: "#1a1a1a"))
                .padding(8)
                .background(Circle().fill(themeColors.accentGradient))
        }
        .buttonStyle(.plain)
        .help("Settings")
    }
}

struct ConfigButton: View {
    let path: String
    let isActive: Bool
    let action: () -> Void
    @Environment(\.themeColors) private var themeColors

    private var backgroundStyle: AnyShapeStyle {
        if isActive {
            return AnyShapeStyle(themeColors.accentGradient)
        } else {
            return AnyShapeStyle(themeColors.glassBackground)
        }
    }

    private var textColor: Color {
        isActive ? Color(hex: "#1a1a1a") : themeColors.mutedText
    }

    var body: some View {
        Button(action: action) {
            Text(path.shortPath())
                .font(DesignTokens.Typography.label)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 16).fill(backgroundStyle))
                .foregroundColor(textColor)
        }
        .buttonStyle(.plain)
    }
}

struct QuickActionsButton: View {
    @Binding var showQuickActions: Bool
    @Binding var isPulsing: Bool
    let themeColors: ThemeColors

    private static let springAnimation = Animation.spring(response: 0.3, dampingFraction: 0.7)
    private static let pulseAnimation = Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)
    private static let pulseDuration: TimeInterval = 10

    private var iconName: String {
        showQuickActions ? "xmark" : "square.grid.2x2.fill"
    }

    private var iconColor: Color {
        showQuickActions ? Color(hex: "#1a1a1a") : themeColors.primaryText
    }

    private var backgroundStyle: AnyShapeStyle {
        if showQuickActions {
            return AnyShapeStyle(themeColors.accentGradient)
        } else {
            return AnyShapeStyle(Color.white.opacity(0.05))
        }
    }

    var body: some View {
        Button(action: handleTap) {
            ZStack(alignment: .topTrailing) {
                iconView
                indicatorDot
            }
        }
        .buttonStyle(.plain)
        .help("Quick Actions Menu")
        .onAppear(perform: startPulsing)
    }

    private var iconView: some View {
        Image(systemName: iconName)
            .font(DesignTokens.Typography.title3)
            .foregroundColor(iconColor)
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(backgroundStyle)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(themeColors.primaryAccent.opacity(isPulsing ? 0.3 : 0.1), lineWidth: 1)
                    )
            )
            .scaleEffect(isPulsing ? 1.05 : 1.0)
            .shadow(color: themeColors.primaryAccent.opacity(isPulsing ? 0.3 : 0.0), radius: isPulsing ? 8 : 0)
            .rotationEffect(.degrees(showQuickActions ? 90 : 0))
            .animation(Self.springAnimation, value: showQuickActions)
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
        withAnimation(Self.springAnimation) {
            showQuickActions.toggle()
        }
        isPulsing = false
    }

    private func startPulsing() {
        withAnimation(Self.pulseAnimation) {
            isPulsing = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + Self.pulseDuration) {
            withAnimation { isPulsing = false }
        }
    }
}
