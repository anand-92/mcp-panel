import SwiftUI

/// Split view: a dense server list with inline enable switches on the left, and a
/// tabbed detail pane for the selected server on the right.
///
/// Complements the grid — the list keeps quick-toggling one click away while the
/// detail pane gives configuration, environment and health the room a card can't.
struct ServerInspectorView: View {
    @ObservedObject var viewModel: ServerViewModel
    @Binding var showAddServer: Bool

    @Environment(\.themeColors) private var themeColors

    @State private var selectedID: UUID?
    @State private var activeTab: InspectorTab = .overview

    // JSON tab state
    @State private var jsonText: String = ""
    @State private var isJSONDirty = false
    @State private var showForceAlert = false
    @State private var invalidReason: String = ""
    @State private var pendingConfig: ServerConfig?

    // Environment tab state
    @State private var environmentDraft = EnvironmentDraft()

    // Unsaved-changes guard
    @State private var pendingSelectionID: UUID?
    @State private var showDiscardAlert = false

    @State private var showDeleteAlert = false

    enum InspectorTab: String, CaseIterable, Identifiable {
        case overview
        case json
        case environment

        var id: String { rawValue }

        var title: String {
            switch self {
            case .overview: return "Overview"
            case .json: return "JSON"
            case .environment: return "Environment"
            }
        }
    }

    var body: some View {
        Group {
            if viewModel.filteredServers.isEmpty {
                EmptyStateView(onCreateServer: { showAddServer = true })
            } else {
                HStack(spacing: 0) {
                    sidebar
                    Divider().opacity(0.4)
                    detailPane
                }
            }
        }
        .onAppear(perform: syncSelection)
        .onChange(of: viewModel.filteredServers.map(\.id)) { _ in
            syncSelection()
        }
        .alert("Discard unsaved changes?", isPresented: $showDiscardAlert) {
            Button("Keep Editing", role: .cancel) {
                pendingSelectionID = nil
            }
            Button("Discard", role: .destructive) {
                if let pendingSelectionID {
                    applySelection(pendingSelectionID)
                }
                pendingSelectionID = nil
            }
        } message: {
            Text("You have unsaved edits for this server. Switching servers will discard them.")
        }
        .alert("Invalid Server Configuration", isPresented: $showForceAlert) {
            Button("Cancel", role: .cancel) { clearForceAlertState() }
            Button("Force Save") { forceSaveJSON() }
        } message: {
            Text("This server has validation errors:\n\n\(invalidReason)\n\n"
                + "Do you want to force save anyway? This will override all validations.")
        }
        .alert("Delete Server", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) { deleteSelected() }
        } message: {
            Text("Are you sure you want to delete '\(selectedServer?.name ?? "")'?")
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(viewModel.filteredServers) { server in
                        InspectorSidebarRow(
                            server: server,
                            healthStatus: viewModel.healthStatus(for: server),
                            isSelected: server.id == selectedID,
                            onSelect: { requestSelection(server.id) },
                            onToggle: { viewModel.toggleServer(server) }
                        )
                    }
                }
                .padding(8)
            }

            Divider().opacity(0.3)

            HStack(spacing: 6) {
                Text(enabledSummary)
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(themeColors.mutedText)
                    .lineLimit(1)

                Spacer(minLength: 4)

                Button {
                    showAddServer = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(themeColors.primaryAccent)
                }
                .buttonStyle(.plain)
                .help("Add server (⌘N)")
                .accessibilityLabel("Add server")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .frame(width: 240)
        .background(themeColors.mainBackground.opacity(0.3))
    }

    private var enabledSummary: String {
        let enabled = viewModel.filteredServers.filter(\.enabled).count
        return "\(enabled) of \(viewModel.filteredServers.count) enabled"
    }

    // MARK: - Detail Pane

    @ViewBuilder
    private var detailPane: some View {
        if let server = selectedServer {
            VStack(spacing: 0) {
                detailHeader(for: server)
                Divider().opacity(0.3)
                tabContent(for: server)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            VStack(spacing: 10) {
                Image(systemName: "sidebar.left")
                    .font(.system(size: 32))
                    .foregroundColor(themeColors.mutedText)
                Text("Select a server")
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(themeColors.secondaryText)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func detailHeader(for server: ServerModel) -> some View {
        HStack(spacing: 12) {
            HStack(spacing: 4) {
                ForEach(InspectorTab.allCases) { tab in
                    tabButton(tab)
                }
            }

            Spacer(minLength: 8)

            CustomToggleSwitch(
                isOn: Binding(
                    get: { server.enabled },
                    set: { _ in viewModel.toggleServer(server) }
                )
            )
            .accessibilityLabel(server.enabled ? "Disable \(server.name)" : "Enable \(server.name)")

            Button {
                showDeleteAlert = viewModel.settings.confirmDelete
                if !viewModel.settings.confirmDelete {
                    deleteSelected()
                }
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 12))
                    .foregroundColor(themeColors.errorColor)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Delete \(server.name)")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    private func tabButton(_ tab: InspectorTab) -> some View {
        let isActive = activeTab == tab

        return Button {
            activeTab = tab
        } label: {
            Text(tab.title)
                .font(DesignTokens.Typography.labelSmall)
                .foregroundColor(isActive ? themeColors.textOnAccent : themeColors.mutedText)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 7)
                        .fill(isActive ? AnyShapeStyle(themeColors.accentGradient) : AnyShapeStyle(Color.clear))
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func tabContent(for server: ServerModel) -> some View {
        switch activeTab {
        case .overview:
            InspectorOverviewTab(
                server: server,
                healthStatus: viewModel.healthStatus(for: server),
                onTagToggle: { viewModel.toggleTag($0, for: server) },
                onCheckHealth: { viewModel.checkHealth(for: server) },
                onCustomIconSelected: { viewModel.updateCustomIcon(for: server, result: $0) }
            )
        case .json:
            InspectorJSONTab(
                server: server,
                text: $jsonText,
                isDirty: $isJSONDirty,
                onSave: { saveJSON(for: server) },
                onRevert: { loadEditorState(for: server) }
            )
        case .environment:
            InspectorEnvironmentTab(
                server: server,
                draft: $environmentDraft,
                onSave: { saveEnvironment(for: server) },
                onRevert: { environmentDraft = EnvironmentDraft(config: server.config) }
            )
        }
    }

    // MARK: - Selection

    private var selectedServer: ServerModel? {
        guard let selectedID else { return nil }
        return viewModel.filteredServers.first { $0.id == selectedID }
    }

    private var hasUnsavedEdits: Bool {
        isJSONDirty || environmentDraft.isDirty
    }

    /// Keep the selection valid as filters, search and external reloads change the list.
    private func syncSelection() {
        let servers = viewModel.filteredServers
        guard !servers.isEmpty else {
            selectedID = nil
            return
        }
        if let selectedID, servers.contains(where: { $0.id == selectedID }) {
            // The selected server may have been rewritten on disk; refresh editor state
            // only when the user has nothing in flight.
            if !hasUnsavedEdits, let server = servers.first(where: { $0.id == selectedID }) {
                loadEditorState(for: server)
            }
            return
        }
        applySelection(servers[0].id)
    }

    private func requestSelection(_ id: UUID) {
        guard id != selectedID else { return }
        if hasUnsavedEdits {
            pendingSelectionID = id
            showDiscardAlert = true
            return
        }
        applySelection(id)
    }

    private func applySelection(_ id: UUID) {
        selectedID = id
        if let server = viewModel.filteredServers.first(where: { $0.id == id }) {
            loadEditorState(for: server)
        }
    }

    private func loadEditorState(for server: ServerModel) {
        jsonText = server.namedConfigJSON
        isJSONDirty = false
        environmentDraft = EnvironmentDraft(config: server.config)
    }

    // MARK: - Saving

    private func saveJSON(for server: ServerModel) {
        let result = viewModel.updateServer(server, with: jsonText)
        if result.success {
            isJSONDirty = false
            // A rename re-keys the server, so re-resolve state from the stored model.
            if let updated = viewModel.servers.first(where: { $0.id == server.id }) {
                loadEditorState(for: updated)
            }
        } else if let reason = result.invalidReason {
            invalidReason = reason
            pendingConfig = result.config
            showForceAlert = true
        }
    }

    private func forceSaveJSON() {
        guard let server = selectedServer, let config = pendingConfig else {
            clearForceAlertState()
            return
        }
        if viewModel.updateServerForced(server, config: config) {
            isJSONDirty = false
            if let updated = viewModel.servers.first(where: { $0.id == server.id }) {
                loadEditorState(for: updated)
            }
        }
        clearForceAlertState()
    }

    private func clearForceAlertState() {
        showForceAlert = false
        pendingConfig = nil
        invalidReason = ""
    }

    private func saveEnvironment(for server: ServerModel) {
        let updatedConfig = environmentDraft.applied(to: server.config)
        guard viewModel.updateServerForced(server, config: updatedConfig) else { return }
        if let updated = viewModel.servers.first(where: { $0.id == server.id }) {
            loadEditorState(for: updated)
        }
    }

    private func deleteSelected() {
        guard let server = selectedServer else { return }
        selectedID = nil
        viewModel.deleteServer(server)
        syncSelection()
    }
}
