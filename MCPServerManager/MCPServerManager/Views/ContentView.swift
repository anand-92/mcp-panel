import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ServerViewModel()
    @State private var showSettings = false
    @State private var showAddServer = false
    @State private var showQuickActions = false

    var body: some View {
        ZStack {
            // Background - uses dynamic theme
            viewModel.themeColors.backgroundGradient
                .ignoresSafeArea()

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
                    if viewModel.viewMode == .grid {
                        ServerGridView(viewModel: viewModel)
                    } else {
                        RawJSONView(viewModel: viewModel)
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
        .windowOpacity(viewModel.settings.windowOpacity)
        .frame(minWidth: 900, minHeight: 600)
    }
}

#Preview {
    ContentView()
}
