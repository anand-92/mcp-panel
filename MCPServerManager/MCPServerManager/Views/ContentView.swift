import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var viewModel = ServerViewModel()
    @State private var showSettings = false
    @State private var showAddServer = false
    @State private var showQuickActions = false
    @State private var showImporter = false
    @State private var showExporter = false
    @State private var miniMode = false
    @State private var previousWindowFrame: NSRect?

    // Mini mode dimensions
    private let miniModeWidth: CGFloat = 280
    private let miniModeHeight: CGFloat = 500

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

            if miniMode {
                // Mini mode view
                MiniModeView(viewModel: viewModel, onExpand: exitMiniMode)
            } else {
                // Normal mode
                VStack(spacing: 0) {
                    // Header
                    HeaderView(
                        viewModel: viewModel,
                        showSettings: $showSettings,
                        showAddServer: $showAddServer,
                        showQuickActions: $showQuickActions
                    )

                    // Toolbar with mini mode toggle
                    ToolbarView(viewModel: viewModel, onMiniMode: enterMiniMode)

                    // Main content area - switches based on view mode
                    Group {
                        switch viewModel.viewMode {
                        case .grid:
                            ServerGridView(viewModel: viewModel, showAddServer: $showAddServer)
                        case .list:
                            ServerListView(viewModel: viewModel, showAddServer: $showAddServer)
                        case .rawJSON:
                            RawJSONView(viewModel: viewModel)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
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

            // Add Server Modal with dark backdrop
            if showAddServer {
                ZStack {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .transition(.opacity)

                    AddServerModal(isPresented: $showAddServer, viewModel: viewModel)
                }
                .transition(.opacity)
            }
        }
        .environment(\.themeColors, viewModel.themeColors)
        .environment(\.currentTheme, viewModel.currentTheme)
        .frame(
            minWidth: miniMode ? miniModeWidth : 900,
            maxWidth: miniMode ? miniModeWidth : .infinity,
            minHeight: miniMode ? 300 : 600,
            maxHeight: miniMode ? .infinity : .infinity
        )
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

    // MARK: - Mini Mode

    private func enterMiniMode() {
        guard let window = NSApp.windows.first else { return }

        // Save current frame to restore later
        previousWindowFrame = window.frame

        // Calculate new position (keep top-right corner in same place)
        let currentFrame = window.frame
        let newWidth = miniModeWidth
        let newHeight = miniModeHeight
        let newX = currentFrame.maxX - newWidth
        let newY = currentFrame.maxY - newHeight

        // Update state first (no animation) so frame constraints allow smaller size
        miniMode = true

        // Defer window resize to next run loop to avoid constraint conflicts on macOS 26
        DispatchQueue.main.async {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.35
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                window.animator().setFrame(NSRect(x: newX, y: newY, width: newWidth, height: newHeight), display: true)
            }
        }
    }

    private func exitMiniMode() {
        guard let window = NSApp.windows.first else { return }

        // Determine target frame
        let targetFrame: NSRect
        if let savedFrame = previousWindowFrame {
            targetFrame = savedFrame
        } else {
            // Default to a sensible size if no saved frame
            let screen = NSScreen.main ?? NSScreen.screens.first!
            let defaultWidth: CGFloat = 1200
            let defaultHeight: CGFloat = 800
            let x = (screen.frame.width - defaultWidth) / 2
            let y = (screen.frame.height - defaultHeight) / 2
            targetFrame = NSRect(x: x, y: y, width: defaultWidth, height: defaultHeight)
        }

        // Update state first (no animation) so frame constraints allow larger size
        miniMode = false

        // Clear saved frame
        previousWindowFrame = nil

        // Defer window resize to next run loop to avoid constraint conflicts on macOS 26
        DispatchQueue.main.async {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.35
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                window.animator().setFrame(targetFrame, display: true)
            }
        }
    }
}
