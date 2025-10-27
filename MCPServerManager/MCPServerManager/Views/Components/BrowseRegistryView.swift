import SwiftUI

struct BrowseRegistryView: View {
    @ObservedObject var registryService = MCPRegistryService.shared
    @Environment(\.themeColors) private var themeColors

    @State private var servers: [RegistryServer] = []
    @State private var searchText: String = ""
    @State private var errorMessage: String = ""
    @State private var isInitialLoad: Bool = true

    let onSelectServer: (RegistryServer) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)

                TextField("Search servers...", text: $searchText)
                    .font(DesignTokens.Typography.body)
                    .textFieldStyle(.plain)

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.black.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 12)

            Divider()
                .padding(.horizontal, 24)

            // Server list
            if registryService.isLoading && isInitialLoad {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Loading servers from registry...")
                        .font(DesignTokens.Typography.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if !errorMessage.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.orange)
                    Text(errorMessage)
                        .font(DesignTokens.Typography.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Retry") {
                        loadServers()
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(themeColors.accentGradient)
                    )
                }
                .padding(24)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredServers.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text(searchText.isEmpty ? "No servers available" : "No servers match '\(searchText)'")
                        .font(DesignTokens.Typography.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredServers) { server in
                            ServerRow(server: server) {
                                onSelectServer(server)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                }
            }
        }
        .task {
            if isInitialLoad {
                loadServers()
            }
        }
    }

    // MARK: - Computed Properties

    private var filteredServers: [RegistryServer] {
        if searchText.isEmpty {
            return servers
        }

        return servers.filter { server in
            server.name.localizedCaseInsensitiveContains(searchText) ||
            server.description.localizedCaseInsensitiveContains(searchText) ||
            server.config.command?.localizedCaseInsensitiveContains(searchText) == true
        }
    }

    // MARK: - Private Methods

    private func loadServers() {
        errorMessage = ""
        Task {
            do {
                servers = try await registryService.fetchServers()
                isInitialLoad = false
            } catch {
                errorMessage = "Failed to load servers: \(error.localizedDescription)"
                isInitialLoad = false
                #if DEBUG
                print("BrowseRegistryView: Error loading servers - \(error)")
                #endif
            }
        }
    }
}

// MARK: - Server Row

struct ServerRow: View {
    let server: RegistryServer
    let onSelect: () -> Void

    @Environment(\.themeColors) private var themeColors

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .top, spacing: 12) {
                // Icon placeholder
                Circle()
                    .fill(themeColors.accentGradient.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(server.displayName.prefix(1).uppercased())
                            .font(DesignTokens.Typography.title3)
                            .foregroundColor(themeColors.primaryAccent)
                    )

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(server.displayName)
                        .font(DesignTokens.Typography.title3)
                        .foregroundColor(.primary)

                    Text(server.description)
                        .font(DesignTokens.Typography.bodySmall)
                        .foregroundColor(.secondary)
                        .lineLimit(2)

                    if let command = server.config.command {
                        HStack(spacing: 4) {
                            Image(systemName: "terminal")
                                .font(.system(size: 10))
                            Text(commandPreview(command, args: server.config.args))
                                .font(DesignTokens.Typography.codeSmall)
                        }
                        .foregroundColor(.secondary.opacity(0.7))
                        .padding(.top, 2)
                    }
                }

                Spacer()

                // Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary.opacity(0.5))
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }

    private func commandPreview(_ command: String, args: [String]?) -> String {
        var preview = command

        if let args = args, !args.isEmpty {
            let argsPreview = args.prefix(2).joined(separator: " ")
            preview += " \(argsPreview)"
            if args.count > 2 {
                preview += "..."
            }
        }

        return preview
    }
}
