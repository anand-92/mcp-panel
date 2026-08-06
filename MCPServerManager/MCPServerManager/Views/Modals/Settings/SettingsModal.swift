import SwiftUI
import UniformTypeIdentifiers

// MARK: - Settings Tab

enum SettingsTab: String, CaseIterable, Identifiable {
    case general = "General"
    case theme = "Theme"
    case glass = "Glass"
    case layout = "Layout"
    case motion = "Motion"
    case advanced = "Advanced"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .general: return "gearshape.fill"
        case .theme: return "paintpalette.fill"
        case .glass: return "circle.hexagongrid.fill"
        case .layout: return "square.resize"
        case .motion: return "wand.and.rays"
        case .advanced: return "wrench.and.screwdriver.fill"
        }
    }

    var description: String {
        switch self {
        case .general: return "Configs, startup & behavior"
        case .theme: return "Colors & color scheme"
        case .glass: return "Liquid Glass & transparency"
        case .layout: return "Density, spacing & text"
        case .motion: return "Animation & hover effects"
        case .advanced: return "Network & diagnostics"
        }
    }
}

// MARK: - Settings Modal

/// Settings apply the moment you change them, so there is no Save button; the footer
/// offers Done plus a reset for the appearance preferences.
struct SettingsModal: View {
    @Binding var isPresented: Bool
    @ObservedObject var viewModel: ServerViewModel

    @Environment(\.themeColors) private var themeColors
    @Environment(\.appearance) private var appearance

    @State private var selectedTab: SettingsTab = .general
    @State private var selectedTheme: AppTheme = .claudeCode
    @State private var showBookmarkAlert = false
    @State private var bookmarkAlertMessage = ""

    /// Writes straight through to the view model so every edit is live and persisted.
    private var appearanceBinding: Binding<AppearanceSettings> {
        Binding(
            get: { viewModel.settings.appearance },
            set: { newValue in
                viewModel.settings.appearance = newValue
                viewModel.persistSettings()
            }
        )
    }

    var body: some View {
        HStack(spacing: 0) {
            sidebarView

            Rectangle()
                .fill(themeColors.borderColor.opacity(0.5))
                .frame(width: 1)

            VStack(spacing: 0) {
                contentHeader
                Divider().opacity(0.5)
                contentBody
                Divider().opacity(0.5)
                footerView
            }
        }
        .frame(width: 820, height: 620)
        .liquidGlass(shape: RoundedRectangle(cornerRadius: appearance.cornerRadius))
        .themedShadow(color: .black.opacity(0.4), radius: 40, y: 20)
        .onAppear {
            selectedTheme = viewModel.currentTheme
        }
        .alert("Bookmark Storage Failed", isPresented: $showBookmarkAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(bookmarkAlertMessage)
        }
    }

    // MARK: - Sidebar

    private var sidebarView: some View {
        VStack(spacing: 8) {
            VStack(spacing: 8) {
                Image(nsImage: AppIcon.image)
                    .resizable()
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                Text(AppConstants.appName)
                    .font(DesignTokens.Typography.title3)
                    .foregroundStyle(themeColors.primaryText)
            }
            .padding(.top, 24)
            .padding(.bottom, 16)

            VStack(spacing: 4) {
                ForEach(SettingsTab.allCases) { tab in
                    SidebarTabButton(
                        tab: tab,
                        isSelected: selectedTab == tab,
                        action: {
                            withAnimation(appearance.motion(.easeInOut(duration: 0.2))) {
                                selectedTab = tab
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 12)

            Spacer()

            Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(themeColors.mutedText)
                .padding(.bottom, 16)
        }
        .frame(width: 190)
        .background(appearance.surface(themeColors.sidebarBackground, base: 0.5))
    }

    // MARK: - Header

    private var contentHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(selectedTab.rawValue)
                    .font(DesignTokens.Typography.title2)
                    .foregroundStyle(themeColors.primaryText)

                Text(selectedTab.description)
                    .font(DesignTokens.Typography.bodySmall)
                    .foregroundStyle(themeColors.secondaryText)
            }

            Spacer()

            Button(action: { isPresented = false }, label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(themeColors.mutedText)
            })
            .buttonStyle(.plain)
            .contentShape(Circle())
            .keyboardShortcut(.escape, modifiers: [])
            .accessibilityLabel("Close settings")
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    // MARK: - Body

    private var contentBody: some View {
        ScrollView {
            tabContent
                .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .general:
            SettingsGeneralTab(viewModel: viewModel, onSelectConfigFile: selectConfigFile)
        case .theme:
            SettingsThemeTab(
                appearance: appearanceBinding,
                selectedTheme: $selectedTheme,
                onThemeSelected: applyTheme
            )
        case .glass:
            SettingsGlassTab(appearance: appearanceBinding)
        case .layout:
            SettingsLayoutTab(appearance: appearanceBinding)
        case .motion:
            SettingsMotionTab(appearance: appearanceBinding)
        case .advanced:
            SettingsAdvancedTab(viewModel: viewModel)
        }
    }

    // MARK: - Footer

    private var footerView: some View {
        HStack(spacing: 12) {
            Button(action: resetAppearance) {
                Text("Reset Appearance")
                    .font(DesignTokens.Typography.bodySmall)
                    .foregroundStyle(themeColors.mutedText)
            }
            .buttonStyle(.plain)
            .help("Restore every theme, glass, layout, text, and motion setting to its default")

            Spacer()

            Text("Changes apply immediately")
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(themeColors.mutedText)

            Button("Done") {
                isPresented = false
            }
            .buttonStyle(.borderedProminent)
            .tint(themeColors.primaryAccent)
            .controlSize(.regular)
            .keyboardShortcut(.return, modifiers: [])
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    // MARK: - Actions

    private func applyTheme(_ theme: AppTheme) {
        selectedTheme = theme
        viewModel.settings.overrideTheme = theme.rawValue
        viewModel.persistSettings()
    }

    private func resetAppearance() {
        withAnimation(appearance.motion(.easeInOut(duration: 0.2))) {
            viewModel.settings.appearance = .default
            viewModel.settings.overrideTheme = nil
            selectedTheme = .claudeCode
        }
        viewModel.persistSettings()
    }

    private func selectConfigFile(completion: @escaping (String) -> Void) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [UTType.json]
        panel.showsHiddenFiles = true
        panel.message = "Select a config file to manage MCP servers"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            try ConfigManager.shared.storeBookmarkForConfigFile(url: url, path: url.path)
            completion(url.path.replacingOccurrences(of: NSHomeDirectory(), with: "~"))
        } catch {
            bookmarkAlertMessage = """
                Failed to create persistent access to the selected file. \
                The app may not be able to access this file after restart.

                Error: \(error.localizedDescription)
                """
            showBookmarkAlert = true
        }
    }
}

// MARK: - Sidebar Tab Button

private struct SidebarTabButton: View {
    let tab: SettingsTab
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.themeColors) private var themeColors
    @Environment(\.appearance) private var appearance
    @State private var hovering = false

    private var isHovered: Bool { appearance.hoverEffects && hovering }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: tab.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(isSelected ? themeColors.primaryAccent : themeColors.secondaryText)
                    .frame(width: 20)

                Text(tab.rawValue)
                    .font(DesignTokens.Typography.label)
                    .foregroundStyle(isSelected ? themeColors.primaryText : themeColors.secondaryText)

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? themeColors.selectionColor : (isHovered ? themeColors.glassBackground : Color.clear))
            )
            .contentShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .onHover { isHovering in
            hovering = isHovering
        }
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}
