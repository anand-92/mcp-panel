import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var viewModel = ServerViewModel()
    @State private var showSettings = false
    @State private var showAddServer = false
    @State private var showQuickActions = false
    @State private var showImporter = false
    @State private var showExporter = false

    var body: some View {
        ZStack {
            // Background - uses dynamic theme
            if #available(macOS 26.0, *) {
                // macOS 26: Allow window transparency to show through
                Color.clear
                    .ignoresSafeArea()
            } else {
                // macOS 13-25: Use gradient background
                viewModel.themeColors.backgroundGradient
                    .ignoresSafeArea()
            }

            VStack(spacing: 0) {
                // Header
                HeaderView(
                    viewModel: viewModel,
                    showSettings: $showSettings,
                    showAddServer: $showAddServer,
                    showQuickActions: $showQuickActions
                )

                // Toolbar
                ToolbarView(viewModel: viewModel)

                // Main content area - switches based on view mode
                Group {
                    switch viewModel.viewMode {
                    case .grid:
                        ServerGridView(viewModel: viewModel, showAddServer: $showAddServer)
                    case .list:
                        ServerListView(viewModel: viewModel, showAddServer: $showAddServer)
                    case .rawJSON:
                        // Show TOML editor for Codex, JSON editor for Claude/Gemini
                        if viewModel.settings.activeConfigIndex == 2 {
                            RawTOMLView(viewModel: viewModel)
                        } else {
                            RawJSONView(viewModel: viewModel)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // Toast notification - positioned to not block UI
            if viewModel.showToast {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        ToastView(message: viewModel.toastMessage, type: viewModel.toastType)
                            .padding(.trailing, 20)
                            .padding(.bottom, 80) // Keep away from bottom buttons
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.showToast)
                .allowsHitTesting(false) // Let clicks pass through
            }

            // Onboarding overlay
            if viewModel.showOnboarding {
                OnboardingModal(viewModel: viewModel)
                    .transition(.opacity)
            }

            // Loading overlay
            if viewModel.isLoading {
                ZStack {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .blur(radius: 10)

                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)

                        Text("Loading configuration...")
                            .font(DesignTokens.Typography.bodyLarge)
                    }
                    .padding(40)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(nsColor: .windowBackgroundColor))
                            .shadow(radius: 30)
                    )
                }
                .transition(.opacity)
            }

            // Quick Actions Menu - Floating overlay
            if showQuickActions {
                ZStack(alignment: .topLeading) {
                    // Backdrop with gradient
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0.7),
                            Color.black.opacity(0.5),
                            Color.black.opacity(0.3),
                            Color.black.opacity(0.0)
                        ]),
                        center: UnitPoint(x: 0.15, y: 0.15),
                        startRadius: 50,
                        endRadius: 1200
                    )
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showQuickActions = false
                        }
                    }

                    // Menu
                    QuickActionsMenu(
                        viewModel: viewModel,
                        showAddServer: $showAddServer,
                        showImporter: $showImporter,
                        showExporter: $showExporter,
                        isExpanded: $showQuickActions
                    )
                }
                .transition(.opacity)
            }

            // Settings Modal with dark backdrop
            if showSettings {
                ZStack {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .transition(.opacity)

                    SettingsModal(isPresented: $showSettings, viewModel: viewModel)
                }
                .transition(.opacity)
            }

            // Add Server Modal with dark backdrop - Codex gets its own separate modal
            if showAddServer {
                ZStack {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .transition(.opacity)

                    // UNIVERSE SEPARATION: Codex uses its own TOML-only modal
                    if viewModel.settings.activeConfigIndex == 2 {
                        AddCodexServerModal(isPresented: $showAddServer, viewModel: viewModel)
                    } else {
                        AddServerModal(isPresented: $showAddServer, viewModel: viewModel)
                    }
                }
                .transition(.opacity)
            }
        }
        .environment(\.themeColors, viewModel.themeColors)
        .environment(\.currentTheme, viewModel.currentTheme)
        .frame(minWidth: 900, minHeight: 600)
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.json],
            onCompletion: handleImport
        )
        .fileExporter(
            isPresented: $showExporter,
            document: JSONDocument(content: viewModel.exportServers()),
            contentType: .json,
            defaultFilename: "mcp-servers.json"
        ) { result in
            if case .success = result {
                // Success
            }
        }
    }

    private func handleImport(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            let accessing = url.startAccessingSecurityScopedResource()
            defer {
                if accessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            do {
                let data = try Data(contentsOf: url)
                if let jsonString = String(data: data, encoding: .utf8) {
                    _ = viewModel.addServers(from: jsonString)  // Discard validation result for file import
                }
            } catch {
                print("ERROR: Import error: \(error)")
            }
        case .failure(let error):
            print("ERROR: File picker error: \(error)")
        }
    }
}
