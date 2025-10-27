import SwiftUI

struct ToolbarView: View {
    @ObservedObject var viewModel: ServerViewModel
    @Namespace private var namespace
    @Environment(\.themeColors) private var themeColors

    var body: some View {
        HStack(spacing: 16) {
            // Custom sliding pill view toggle
            HStack(spacing: 0) {
                ForEach(ViewMode.allCases, id: \.self) { mode in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewModel.viewMode = mode
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: mode == .grid ? "square.grid.2x2" : "curlybraces")
                                .font(.system(size: 14, weight: .semibold))
                            Text(mode.displayName)
                                .font(DesignTokens.Typography.label)
                        }
                        .foregroundColor(viewModel.viewMode == mode ? Color(hex: "#1a1a1a") : themeColors.mutedText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            ZStack {
                                if viewModel.viewMode == mode {
                                    Capsule()
                                        .fill(themeColors.accentGradient)
                                        .shadow(color: themeColors.primaryAccent.opacity(0.5), radius: 8, x: 0, y: 2)
                                        .matchedGeometryEffect(id: "viewModePill", in: namespace)
                                }
                            }
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
            .background(
                Capsule()
                    .fill(themeColors.glassLayer3)
                    .overlay(
                        Capsule()
                            .stroke(themeColors.borderLayer2, lineWidth: 1)
                    )
            )

            // Compact filter pills
            HStack(spacing: 6) {
                ForEach(FilterMode.allCases, id: \.self) { mode in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewModel.filterMode = mode
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: iconForFilter(mode))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(
                                    viewModel.filterMode == mode ?
                                    themeColors.accentGradient :
                                    LinearGradient(
                                        colors: [themeColors.mutedText, themeColors.mutedText],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )

                            Text(labelForFilter(mode))
                                .font(DesignTokens.Typography.labelSmall)
                                .foregroundColor(viewModel.filterMode == mode ? themeColors.primaryText : themeColors.secondaryText)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            ZStack {
                                if viewModel.filterMode == mode {
                                    Capsule()
                                        .fill(themeColors.primaryAccent.opacity(0.15))
                                        .overlay(
                                            Capsule()
                                                .stroke(themeColors.primaryAccent.opacity(0.4), lineWidth: 1)
                                        )
                                        .shadow(color: themeColors.primaryAccent.opacity(0.3), radius: 6, x: 0, y: 2)
                                } else {
                                    Capsule()
                                        .fill(themeColors.glassLayer2)
                                        .overlay(
                                            Capsule()
                                                .stroke(themeColors.borderLayer1, lineWidth: 0.5)
                                        )
                                }
                            }
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()

            // Toggle all servers
            Button(action: {
                let allEnabled = viewModel.servers.allSatisfy {
                    $0.inConfigs[safe: viewModel.settings.activeConfigIndex] ?? false
                }
                print("DEBUG: Toggle All clicked, currently allEnabled: \(allEnabled), will set to: \(!allEnabled)")
                viewModel.toggleAllServers(!allEnabled)
            }) {
                let allEnabled = viewModel.servers.allSatisfy {
                    $0.inConfigs[safe: viewModel.settings.activeConfigIndex] ?? false
                }
                HStack(spacing: 8) {
                    Text(allEnabled ? "Disable All" : "Enable All")
                        .font(DesignTokens.Typography.label)
                        .foregroundColor(themeColors.primaryText)

                    // Visual indicator only - the button wrapper handles the action
                    ZStack {
                        Capsule()
                            .fill(allEnabled ? AnyShapeStyle(themeColors.successColor) : AnyShapeStyle(themeColors.glassLayer2))
                            .overlay(
                                Capsule()
                                    .stroke(allEnabled ? Color.clear : themeColors.borderLayer1, lineWidth: 1)
                            )
                            .frame(width: 44, height: 24)

                        Circle()
                            .fill(themeColors.primaryText)
                            .frame(width: 20, height: 20)
                            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                            .offset(x: allEnabled ? 10 : -10)
                    }
                }
            }
            .buttonStyle(.plain)

            // Save button
            Button(action: { viewModel.syncToConfigs() }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                    Text("Refresh")
                }
                .foregroundColor(themeColors.primaryText)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(themeColors.glassLayer2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(themeColors.borderLayer1, lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
            .keyboardShortcut("r", modifiers: .command)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Rectangle()
                .fill(themeColors.glassLayer3)
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 3)
        )
    }

    // Helper function to get icon for filter mode
    private func iconForFilter(_ mode: FilterMode) -> String {
        switch mode {
        case .all:
            return "square.stack.3d.up.fill"
        case .active:
            return "checkmark.circle.fill"
        case .disabled:
            return "circle.slash"
        case .recent:
            return "clock.arrow.circlepath"
        }
    }

    // Helper function to get short label for filter mode
    private func labelForFilter(_ mode: FilterMode) -> String {
        switch mode {
        case .all:
            return "All"
        case .active:
            return "Active"
        case .disabled:
            return "Disabled"
        case .recent:
            return "Recent"
        }
    }
}
