//
//  ContentView.swift
//  MCP Panel
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            mainContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Notifications
            if let message = appState.notificationMessage {
                VStack {
                    Spacer()
                    NotificationBanner(message: message, type: appState.notificationType)
                        .padding()
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(), value: appState.notificationMessage)
            }
        }
        .sheet(isPresented: $appState.showServerModal) {
            ServerFormView(server: appState.editingServer)
                .environmentObject(appState)
        }
        .sheet(isPresented: $appState.showOnboarding) {
            OnboardingView()
                .environmentObject(appState)
        }
        .alert(item: Binding(
            get: { appState.error },
            set: { appState.error = $0 }
        )) { error in
            Alert(
                title: Text("Error"),
                message: Text(error.localizedDescription),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        if appState.isLoading {
            LoadingView()
        } else {
            VStack(spacing: 0) {
                // Header
                HeaderView()
                    .environmentObject(appState)

                Divider()

                // Main content area
                HStack(spacing: 0) {
                    // Sidebar
                    SidebarView()
                        .environmentObject(appState)
                        .frame(width: 250)

                    Divider()

                    // Main view based on view mode
                    mainView
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
    }

    @ViewBuilder
    private var mainView: some View {
        switch appState.settings.viewMode {
        case .grid:
            ServerGridView()
                .environmentObject(appState)
        case .list:
            ServerListView()
                .environmentObject(appState)
        case .json:
            RawJsonView()
                .environmentObject(appState)
        }
    }
}

// MARK: - Header View

struct HeaderView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack {
            // App title
            Text("MCP Panel")
                .font(.title2)
                .fontWeight(.bold)

            Spacer()

            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)

                TextField("Search servers...", text: $appState.searchQuery)
                    .textFieldStyle(.plain)
                    .frame(width: 250)

                if !appState.searchQuery.isEmpty {
                    Button(action: {
                        appState.searchQuery = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)

            // View mode toggle
            Picker("View Mode", selection: $appState.settings.viewMode) {
                ForEach(ViewMode.allCases, id: \.self) { mode in
                    Label(mode.displayName, systemImage: mode.iconName)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 200)
            .onChange(of: appState.settings.viewMode) { _ in
                appState.settings.save()
            }

            // Settings button
            Button(action: {
                appState.showSettings = true
            }) {
                Image(systemName: "gear")
            }
            .buttonStyle(.plain)

            // Add server button
            Button(action: {
                appState.editingServer = nil
                appState.showServerModal = true
            }) {
                Label("Add Server", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// MARK: - Sidebar View

struct SidebarView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Filter section
            VStack(alignment: .leading, spacing: 8) {
                Text("FILTER")
                    .font(.caption)
                    .foregroundColor(.secondary)

                ForEach(FilterMode.allCases, id: \.self) { mode in
                    Button(action: {
                        appState.settings.filterMode = mode
                        appState.settings.save()
                    }) {
                        HStack {
                            Text(mode.displayName)
                                .foregroundColor(appState.settings.filterMode == mode ? .primary : .secondary)

                            Spacer()

                            if appState.settings.filterMode == mode {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            Divider()

            // Stats section
            VStack(alignment: .leading, spacing: 8) {
                Text("STATISTICS")
                    .font(.caption)
                    .foregroundColor(.secondary)

                StatRow(label: "Total Servers", value: "\(appState.servers.count)")
                StatRow(label: "Enabled", value: "\(appState.servers.values.filter { $0.isEnabled }.count)")
                StatRow(label: "Disabled", value: "\(appState.servers.values.filter { !$0.isEnabled }.count)")

                if !appState.searchQuery.isEmpty {
                    StatRow(label: "Search Results", value: "\(appState.filteredServers.count)")
                }
            }

            Spacer()

            // Config path
            VStack(alignment: .leading, spacing: 4) {
                Text("CONFIG PATH")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(appState.settings.configPath)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding()
        .frame(maxHeight: .infinity, alignment: .topLeading)
    }
}

struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.caption)
    }
}

// MARK: - Loading View

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Loading configuration...")
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Notification Banner

struct NotificationBanner: View {
    let message: String
    let type: NotificationType

    var body: some View {
        HStack {
            Image(systemName: iconName)
                .foregroundColor(.white)

            Text(message)
                .foregroundColor(.white)
                .fontWeight(.medium)

            Spacer()
        }
        .padding()
        .background(type.color)
        .cornerRadius(10)
        .shadow(radius: 5)
    }

    private var iconName: String {
        switch type {
        case .info: return "info.circle.fill"
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.circle.fill"
        }
    }
}

// MARK: - Previews

#Preview {
    ContentView()
        .environmentObject(AppState())
        .frame(width: 1200, height: 800)
}
