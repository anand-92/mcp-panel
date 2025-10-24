import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ServerViewModel()
    @State private var showSettings = false
    @State private var showAddServer = false
    @State private var showSidebar = true

    var body: some View {
        ZStack {
            // Background
            (viewModel.settings.cyberpunkMode ?
                DesignTokens.cyberpunkBackgroundGradient :
                DesignTokens.backgroundGradient)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HeaderView(
                    viewModel: viewModel,
                    showSettings: $showSettings,
                    showSidebar: $showSidebar
                )

                // Toolbar
                ToolbarView(viewModel: viewModel)

                // Main content
                HStack(spacing: 0) {
                    // Sidebar
                    if showSidebar {
                        SidebarView(
                            viewModel: viewModel,
                            showAddServer: $showAddServer
                        )
                        .padding(.leading, 20)
                        .padding(.vertical, 20)
                        .transition(.move(edge: .leading).combined(with: .opacity))
                    }

                    // Server grid
                    ServerGridView(viewModel: viewModel)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }

            // Toast notification
            if viewModel.showToast {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        ToastView(message: viewModel.toastMessage, type: viewModel.toastType)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .animation(.spring(), value: viewModel.showToast)
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
                            .font(.headline)
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
        }
        .environment(\.cyberpunkMode, viewModel.settings.cyberpunkMode)
        .sheet(isPresented: $showSettings) {
            SettingsModal(isPresented: $showSettings, viewModel: viewModel)
        }
        .sheet(isPresented: $showAddServer) {
            AddServerModal(isPresented: $showAddServer, viewModel: viewModel)
        }
        .frame(minWidth: 900, minHeight: 600)
    }
}

#Preview {
    ContentView()
}
