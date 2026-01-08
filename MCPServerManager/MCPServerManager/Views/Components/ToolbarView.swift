import SwiftUI

struct ToolbarView: View {
    @ObservedObject var viewModel: ServerViewModel
    var onMiniMode: (() -> Void)? = nil
    @Namespace private var namespace
    @Environment(\.themeColors) private var themeColors

    var body: some View {
        ViewThatFits(in: .horizontal) {
            // Full width layout with all labels
            toolbarContent(compact: false)

            // Compact layout with icons only
            toolbarContent(compact: true)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .modifier(LiquidGlassModifier(shape: Rectangle(), fillColor: themeColors.sidebarBackground.opacity(0.5)))
    }

    @ViewBuilder
    private func toolbarContent(compact: Bool) -> some View {
        HStack(spacing: compact ? 8 : 16) {
            // View mode toggle
            viewModeToggle(compact: compact)

            // Filter pills
            filterPills(compact: compact)

            Spacer()

            // Right side actions
            rightSideActions(compact: compact)
        }
    }

    // MARK: - View Mode Toggle
    @ViewBuilder
    private func viewModeToggle(compact: Bool) -> some View {
        HStack(spacing: 0) {
            ForEach(ViewMode.allCases, id: \.self) { mode in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.viewMode = mode
                    }
                }) {
                    HStack(spacing: compact ? 0 : 6) {
                        Image(systemName: iconForViewMode(mode))
                            .font(.system(size: 14, weight: .semibold))
                        if !compact {
                            Text(mode.displayName)
                                .font(DesignTokens.Typography.label)
                        }
                    }
                    .foregroundColor(viewModel.viewMode == mode ? Color(hex: "#1a1a1a") : themeColors.mutedText)
                    .padding(.horizontal, compact ? 10 : 16)
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
                .help(compact ? mode.displayName : "")
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(themeColors.glassBackground)
                .overlay(
                    Capsule()
                        .stroke(themeColors.borderColor, lineWidth: 1)
                )
        )
    }

    // MARK: - Filter Pills
    @ViewBuilder
    private func filterPills(compact: Bool) -> some View {
        HStack(spacing: compact ? 4 : 6) {
            ForEach(FilterMode.allCases, id: \.self) { mode in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.filterMode = mode
                    }
                }) {
                    HStack(spacing: compact ? 0 : 6) {
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

                        if !compact {
                            Text(labelForFilter(mode))
                                .font(DesignTokens.Typography.labelSmall)
                                .foregroundColor(viewModel.filterMode == mode ? themeColors.primaryText : themeColors.secondaryText)
                        }
                    }
                    .padding(.horizontal, compact ? 8 : 12)
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
                                    .fill(themeColors.glassBackground)
                                    .overlay(
                                        Capsule()
                                            .stroke(themeColors.borderColor, lineWidth: 0.5)
                                    )
                            }
                        }
                    )
                }
                .buttonStyle(.plain)
                .help(compact ? labelForFilter(mode) : "")
            }
        }
    }

    // MARK: - Right Side Actions
    @ViewBuilder
    private func rightSideActions(compact: Bool) -> some View {
        // Enable servers by tag
        Menu {
            ForEach(ServerTag.allCases) { tag in
                let count = viewModel.taggedServersCount(for: tag)
                Button(action: { viewModel.enableServers(with: tag) }) {
                    Text(count > 0 ? "\(tag.rawValue) (\(count))" : tag.rawValue)
                }
                .disabled(count == 0)
            }
        } label: {
            HStack(spacing: compact ? 0 : 6) {
                Image(systemName: "tag")
                if !compact {
                    Text("Enable Tag")
                }
            }
            .font(DesignTokens.Typography.label)
            .foregroundColor(themeColors.primaryText)
            .padding(.horizontal, compact ? 8 : 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(themeColors.glassBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(themeColors.borderColor, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .help(compact ? "Enable Tag" : "")

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
                if !compact {
                    Text(allEnabled ? "Disable All" : "Enable All")
                        .font(DesignTokens.Typography.label)
                        .foregroundColor(themeColors.primaryText)
                }

                // Visual indicator only - the button wrapper handles the action
                ZStack {
                    Capsule()
                        .fill(allEnabled ? AnyShapeStyle(themeColors.successColor) : AnyShapeStyle(themeColors.glassBackground))
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
        .help(compact ? (viewModel.servers.allSatisfy { $0.inConfigs[safe: viewModel.settings.activeConfigIndex] ?? false } ? "Disable All" : "Enable All") : "")

        // Refresh button
        Button(action: { viewModel.syncToConfigs() }) {
            HStack(spacing: compact ? 0 : 6) {
                Image(systemName: "arrow.clockwise")
                if !compact {
                    Text("Refresh")
                }
            }
            .foregroundColor(themeColors.primaryText)
            .padding(.horizontal, compact ? 8 : 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(themeColors.glassBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(themeColors.borderColor, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .keyboardShortcut("r", modifiers: .command)
        .help(compact ? "Refresh (⌘R)" : "")

        // Mini mode button
        if let onMiniMode = onMiniMode {
            Button(action: onMiniMode) {
                HStack(spacing: compact ? 0 : 6) {
                    Image(systemName: "arrow.down.right.and.arrow.up.left")
                    if !compact {
                        Text("Mini")
                    }
                }
                .foregroundColor(themeColors.primaryText)
                .padding(.horizontal, compact ? 8 : 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(themeColors.glassBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(themeColors.borderColor, lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
            .keyboardShortcut("m", modifiers: [.command, .shift])
            .help(compact ? "Mini Mode (⇧⌘M)" : "Compact view")
        }
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

    // Helper function to get icon for view mode
    private func iconForViewMode(_ mode: ViewMode) -> String {
        switch mode {
        case .grid: return "square.grid.2x2"
        case .list: return "list.bullet"
        case .rawJSON: return "curlybraces"
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
