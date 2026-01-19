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
        .padding(.vertical, 12)
        .modifier(LiquidGlassModifier(shape: Rectangle(), fillColor: themeColors.sidebarBackground.opacity(0.5)))
    }

    @ViewBuilder
    private func toolbarContent(compact: Bool) -> some View {
        HStack(spacing: compact ? 8 : 16) {
            viewModeToggle(compact: compact)
            filterPills(compact: compact)
            Spacer()
            rightSideActions(compact: compact)
        }
    }

    // MARK: - View Mode Toggle

    @ViewBuilder
    private func viewModeToggle(compact: Bool) -> some View {
        HStack(spacing: 0) {
            ForEach(ViewMode.allCases, id: \.self) { mode in
                viewModeButton(mode: mode, compact: compact)
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(themeColors.glassBackground)
                .overlay(Capsule().stroke(themeColors.borderColor, lineWidth: 1))
        )
    }

    @ViewBuilder
    private func viewModeButton(mode: ViewMode, compact: Bool) -> some View {
        let isSelected = viewModel.viewMode == mode

        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                viewModel.viewMode = mode
            }
        } label: {
            HStack(spacing: compact ? 0 : 6) {
                Image(systemName: mode.icon)
                    .font(.system(size: 14, weight: .semibold))
                if !compact {
                    Text(mode.displayName)
                        .font(DesignTokens.Typography.label)
                }
            }
            .foregroundColor(isSelected ? Color(hex: "#1a1a1a") : themeColors.mutedText)
            .padding(.horizontal, compact ? 10 : 16)
            .padding(.vertical, 8)
            .background {
                if isSelected {
                    Capsule()
                        .fill(themeColors.accentGradient)
                        .shadow(color: themeColors.primaryAccent.opacity(0.5), radius: 8, x: 0, y: 2)
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
        HStack(spacing: compact ? 4 : 6) {
            ForEach(FilterMode.allCases, id: \.self) { mode in
                filterPillButton(mode: mode, compact: compact)
            }
        }
    }

    @ViewBuilder
    private func filterPillButton(mode: FilterMode, compact: Bool) -> some View {
        let isSelected = viewModel.filterMode == mode

        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                viewModel.filterMode = mode
            }
        } label: {
            HStack(spacing: compact ? 0 : 6) {
                Image(systemName: mode.icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(isSelected ? themeColors.accentGradient : themeColors.mutedText.asGradient)

                if !compact {
                    Text(mode.label)
                        .font(DesignTokens.Typography.labelSmall)
                        .foregroundColor(isSelected ? themeColors.primaryText : themeColors.secondaryText)
                }
            }
            .padding(.horizontal, compact ? 8 : 12)
            .padding(.vertical, 6)
            .background { filterPillBackground(isSelected: isSelected) }
        }
        .buttonStyle(.plain)
        .help(compact ? mode.label : "")
    }

    @ViewBuilder
    private func filterPillBackground(isSelected: Bool) -> some View {
        if isSelected {
            Capsule()
                .fill(themeColors.primaryAccent.opacity(0.15))
                .overlay(Capsule().stroke(themeColors.primaryAccent.opacity(0.4), lineWidth: 1))
                .shadow(color: themeColors.primaryAccent.opacity(0.3), radius: 6, x: 0, y: 2)
        } else {
            Capsule()
                .fill(themeColors.glassBackground)
                .overlay(Capsule().stroke(themeColors.borderColor, lineWidth: 0.5))
        }
    }

    // MARK: - Right Side Actions

    @ViewBuilder
    private func rightSideActions(compact: Bool) -> some View {
        enableByTagMenu(compact: compact)
        toggleAllButton(compact: compact)
        refreshButton(compact: compact)

        if let onMiniMode = onMiniMode {
            miniModeButton(action: onMiniMode, compact: compact)
        }
    }

    @ViewBuilder
    private func enableByTagMenu(compact: Bool) -> some View {
        Menu {
            ForEach(ServerTag.allCases) { tag in
                let count = viewModel.taggedServersCount(for: tag)
                Button { viewModel.enableServers(with: tag) } label: {
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
            .modifier(GlassButtonStyle(compact: compact))
        }
        .buttonStyle(.plain)
        .help(compact ? "Enable Tag" : "")
    }

    @ViewBuilder
    private func toggleAllButton(compact: Bool) -> some View {
        let allEnabled = viewModel.servers.allSatisfy {
            $0.inConfigs[safe: viewModel.settings.activeConfigIndex] ?? false
        }

        Button {
            viewModel.toggleAllServers(!allEnabled)
        } label: {
            HStack(spacing: 8) {
                if !compact {
                    Text(allEnabled ? "Disable All" : "Enable All")
                        .font(DesignTokens.Typography.label)
                        .foregroundColor(themeColors.primaryText)
                }

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
        .help(compact ? (allEnabled ? "Disable All" : "Enable All") : "")
    }

    @ViewBuilder
    private func refreshButton(compact: Bool) -> some View {
        Button { viewModel.syncToConfigs() } label: {
            HStack(spacing: compact ? 0 : 6) {
                Image(systemName: "arrow.clockwise")
                if !compact {
                    Text("Refresh")
                }
            }
            .foregroundColor(themeColors.primaryText)
            .modifier(GlassButtonStyle(compact: compact))
        }
        .buttonStyle(.plain)
        .keyboardShortcut("r", modifiers: .command)
        .help(compact ? "Refresh (Cmd+R)" : "")
    }

    @ViewBuilder
    private func miniModeButton(action: @escaping () -> Void, compact: Bool) -> some View {
        Button(action: action) {
            HStack(spacing: compact ? 0 : 6) {
                Image(systemName: "arrow.down.right.and.arrow.up.left")
                if !compact {
                    Text("Mini")
                }
            }
            .foregroundColor(themeColors.primaryText)
            .modifier(GlassButtonStyle(compact: compact))
        }
        .buttonStyle(.plain)
        .keyboardShortcut("m", modifiers: [.command, .shift])
        .help(compact ? "Mini Mode (Shift+Cmd+M)" : "Compact view")
    }
}

// MARK: - Reusable Glass Button Style

private struct GlassButtonStyle: ViewModifier {
    let compact: Bool
    @Environment(\.themeColors) private var themeColors

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, compact ? 8 : 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(themeColors.glassBackground)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(themeColors.borderColor, lineWidth: 1))
            )
    }
}

// MARK: - Color Extension for Gradient Conversion

private extension Color {
    var asGradient: LinearGradient {
        LinearGradient(colors: [self], startPoint: .leading, endPoint: .trailing)
    }
}
