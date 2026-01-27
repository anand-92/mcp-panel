import SwiftUI

struct ToolbarView: View {
    @ObservedObject var viewModel: ServerViewModel
    var onMiniMode: (() -> Void)? = nil
    @Namespace private var namespace
    @Environment(\.themeColors) private var themeColors

    var body: some View {
        ViewThatFits(in: .horizontal) {
            toolbarContent(compact: false)
            toolbarContent(compact: true)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(
            Rectangle()
                .fill(themeColors.mainBackground.opacity(0.5))
                .overlay(
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [themeColors.borderColor.opacity(0.3), Color.clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 1),
                    alignment: .top
                )
        )
    }

    @ViewBuilder
    private func toolbarContent(compact: Bool) -> some View {
        HStack(spacing: compact ? 12 : 16) {
            // Left: View Mode Toggle
            viewModeToggle(compact: compact)

            // Separator
            Divider()
                .frame(height: 24)
                .opacity(0.3)

            // Center: Filter Pills
            filterPills(compact: compact)

            Spacer()

            // Right: Actions
            rightSideActions(compact: compact)
        }
    }

    // MARK: - View Mode Toggle

    @ViewBuilder
    private func viewModeToggle(compact: Bool) -> some View {
        HStack(spacing: 2) {
            ForEach(ViewMode.allCases, id: \.self) { mode in
                viewModeButton(mode: mode, compact: compact)
            }
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(themeColors.glassBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(themeColors.borderColor, lineWidth: 1)
                )
        )
    }

    @ViewBuilder
    private func viewModeButton(mode: ViewMode, compact: Bool) -> some View {
        let isSelected = viewModel.viewMode == mode

        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                viewModel.viewMode = mode
            }
        } label: {
            HStack(spacing: compact ? 0 : 6) {
                Image(systemName: mode.icon)
                    .font(.system(size: 13, weight: .medium))
                if !compact {
                    Text(mode.displayName)
                        .font(DesignTokens.Typography.labelSmall)
                }
            }
            .foregroundColor(isSelected ? themeColors.textOnAccent : themeColors.mutedText)
            .padding(.horizontal, compact ? 10 : 14)
            .padding(.vertical, 6)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(themeColors.accentGradient)
                        .shadow(color: themeColors.primaryAccent.opacity(0.3), radius: 4, x: 0, y: 2)
                        .matchedGeometryEffect(id: "viewModePill", in: namespace)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(compact ? mode.displayName : "")
    }

    // MARK: - Filter Pills

    @ViewBuilder
    private func filterPills(compact: Bool) -> some View {
        HStack(spacing: 6) {
            ForEach(FilterMode.allCases, id: \.self) { mode in
                filterPillButton(mode: mode, compact: compact)
            }
        }
    }

    @ViewBuilder
    private func filterPillButton(mode: FilterMode, compact: Bool) -> some View {
        let isSelected = viewModel.filterMode == mode
        let count = filterCount(for: mode)

        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                viewModel.filterMode = mode
            }
        } label: {
            HStack(spacing: 6) {
                Circle()
                    .fill(filterColor(for: mode, isSelected: isSelected))
                    .frame(width: 8, height: 8)

                // Always show label text - never hide it
                Text(mode.label)
                    .font(DesignTokens.Typography.labelSmall)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)

                // Only show count badge in non-compact mode
                if !compact && count > 0 {
                    Text("\(count)")
                        .font(DesignTokens.Typography.captionSmall)
                        .foregroundColor(isSelected ? themeColors.primaryAccent : themeColors.mutedText)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? themeColors.primaryAccent.opacity(0.15) : themeColors.glassBackground)
                        )
                }
            }
            .foregroundColor(isSelected ? themeColors.primaryText : themeColors.secondaryText)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? themeColors.primaryAccent.opacity(0.1) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? themeColors.primaryAccent.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
            }
        }
        .buttonStyle(.plain)
    }

    private func filterColor(for mode: FilterMode, isSelected: Bool) -> Color {
        switch mode {
        case .all:
            return isSelected ? themeColors.primaryAccent : themeColors.mutedText
        case .active:
            return themeColors.successColor
        case .disabled:
            return themeColors.errorColor
        case .recent:
            return themeColors.warningColor
        }
    }

    private func filterCount(for mode: FilterMode) -> Int {
        let activeIndex = viewModel.settings.activeConfigIndex
        switch mode {
        case .all:
            return viewModel.servers.count
        case .active:
            return viewModel.servers.filter { $0.inConfigs[safe: activeIndex] ?? false }.count
        case .disabled:
            return viewModel.servers.filter { !($0.inConfigs[safe: activeIndex] ?? false) }.count
        case .recent:
            // Recent count - servers modified in last 24 hours (simplified)
            return 0
        }
    }

    // MARK: - Right Side Actions

    @ViewBuilder
    private func rightSideActions(compact: Bool) -> some View {
        HStack(spacing: compact ? 8 : 10) {
            enableByTagMenu(compact: compact)
            toggleAllButton(compact: compact)
            refreshButton(compact: compact)

            if let onMiniMode = onMiniMode {
                miniModeButton(action: onMiniMode, compact: compact)
            }
        }
    }

    @ViewBuilder
    private func enableByTagMenu(compact: Bool) -> some View {
        Menu {
            ForEach(ServerTag.allCases) { tag in
                let count = viewModel.taggedServersCount(for: tag)
                Button { viewModel.enableServers(with: tag) } label: {
                    Label {
                        Text(count > 0 ? "\(tag.rawValue) (\(count))" : tag.rawValue)
                    } icon: {
                        Image(systemName: "tag.fill")
                    }
                }
                .disabled(count == 0)
            }
        } label: {
            HStack(spacing: compact ? 0 : 6) {
                Image(systemName: "tag")
                    .font(.system(size: 13, weight: .medium))
                if !compact {
                    Text("Tags")
                        .font(DesignTokens.Typography.labelSmall)
                }
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .bold))
                    .opacity(0.6)
            }
            .modifier(ToolbarButtonStyle(compact: compact))
        }
        .buttonStyle(.plain)
        .help(compact ? "Enable by Tag" : "")
    }

    @ViewBuilder
    private func toggleAllButton(compact: Bool) -> some View {
        let allEnabled = viewModel.servers.allSatisfy {
            $0.inConfigs[safe: viewModel.settings.activeConfigIndex] ?? false
        }

        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                viewModel.toggleAllServers(!allEnabled)
            }
        } label: {
            HStack(spacing: 8) {
                if !compact {
                    Text(allEnabled ? "All Off" : "All On")
                        .font(DesignTokens.Typography.labelSmall)
                        .foregroundColor(themeColors.primaryText)
                }

                // Modern toggle switch
                ZStack {
                    Capsule()
                        .fill(allEnabled ? themeColors.successColor : themeColors.glassBackground)
                        .overlay(
                            Capsule()
                                .stroke(allEnabled ? Color.clear : themeColors.borderColor, lineWidth: 1)
                        )
                        .frame(width: 40, height: 22)

                    Circle()
                        .fill(Color.white)
                        .frame(width: 16, height: 16)
                        .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
                        .offset(x: allEnabled ? 9 : -9)
                }
            }
            .padding(.horizontal, compact ? 6 : 10)
            .padding(.vertical, 4)
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
        .help(compact ? (allEnabled ? "Disable All" : "Enable All") : "")
    }

    @ViewBuilder
    private func refreshButton(compact: Bool) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                viewModel.syncToConfigs()
            }
        } label: {
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 13, weight: .medium))
                .modifier(ToolbarIconButtonStyle())
        }
        .buttonStyle(.plain)
        .keyboardShortcut("r", modifiers: .command)
        .help("Refresh (⌘R)")
    }

    @ViewBuilder
    private func miniModeButton(action: @escaping () -> Void, compact: Bool) -> some View {
        Button(action: action) {
            Image(systemName: "rectangle.compress.vertical")
                .font(.system(size: 13, weight: .medium))
                .modifier(ToolbarIconButtonStyle())
        }
        .buttonStyle(.plain)
        .keyboardShortcut("m", modifiers: [.command, .shift])
        .help("Mini Mode (⇧⌘M)")
    }
}

// MARK: - Toolbar Button Styles

private struct ToolbarButtonStyle: ViewModifier {
    let compact: Bool
    @Environment(\.themeColors) private var themeColors
    @State private var isHovered = false

    func body(content: Content) -> some View {
        content
            .foregroundColor(isHovered ? themeColors.primaryAccent : themeColors.primaryText)
            .padding(.horizontal, compact ? 8 : 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(themeColors.glassBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isHovered ? themeColors.primaryAccent.opacity(0.3) : themeColors.borderColor, lineWidth: 1)
                    )
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovered = hovering
                }
            }
    }
}

private struct ToolbarIconButtonStyle: ViewModifier {
    @Environment(\.themeColors) private var themeColors
    @State private var isHovered = false

    func body(content: Content) -> some View {
        content
            .foregroundColor(isHovered ? themeColors.primaryAccent : themeColors.secondaryText)
            .frame(width: 32, height: 32)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(themeColors.glassBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isHovered ? themeColors.primaryAccent.opacity(0.3) : themeColors.borderColor, lineWidth: 1)
                    )
            )
            .scaleEffect(isHovered ? 1.05 : 1.0)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovered = hovering
                }
            }
    }
}

// MARK: - Color Extension for Gradient Conversion

private extension Color {
    var asGradient: LinearGradient {
        LinearGradient(colors: [self], startPoint: .leading, endPoint: .trailing)
    }
}
