import SwiftUI
import ServiceManagement
#if canImport(Sparkle)
import Sparkle
#endif

@main
struct MCPServerManagerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var updateChecker = UpdateChecker.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .onAppear {
                    // Ensure window accepts keyboard input
                    NSApp.activate(ignoringOtherApps: true)

                    // Apply Liquid Glass to window background
                    if let window = NSApp.windows.first {
                        if #available(macOS 26.0, *) {
                            window.isOpaque = false
                            window.backgroundColor = .clear
                            window.titlebarAppearsTransparent = true
                        }
                    }

                    // Setup menu bar controller with shared view model
                    appDelegate.setupMenuBarIfNeeded()
                }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1440, height: 900)
        .commands {
            CommandGroup(replacing: .newItem) {}

            // Only show "Check for Updates" for non-App Store builds
            if updateChecker.canCheckForUpdates {
                CommandGroup(after: .appInfo) {
                    Button("Check for Updates...") {
                        updateChecker.checkForUpdates()
                    }
                    .keyboardShortcut("U", modifiers: [.command])
                }
            }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var menuBarController: MenuBarController?
    private var widgetNotificationObserver: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Register custom fonts (Poppins & Crimson Pro)
        FontManager.registerFonts()

        // Load settings to check menu bar mode
        let settings = UserDefaults.standard.appSettings

        // Set activation policy based on settings
        if settings.menuBarModeEnabled && settings.hideDockIconInMenuBarMode {
            NSApp.setActivationPolicy(.accessory)
        } else {
            NSApp.setActivationPolicy(.regular)
        }

        NSApp.activate(ignoringOtherApps: true)

        // Setup widget notification listener
        setupWidgetNotificationListener()
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Remove notification observer
        if let observer = widgetNotificationObserver {
            DistributedNotificationCenter.default().removeObserver(observer)
        }
    }

    // Keep app alive when window closed if menu bar mode is enabled
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        let settings = UserDefaults.standard.appSettings
        return !settings.menuBarModeEnabled
    }

    // MARK: - Menu Bar Setup

    /// Setup menu bar controller if needed (called after view model is available)
    @MainActor
    func setupMenuBarIfNeeded() {
        let settings = UserDefaults.standard.appSettings
        guard settings.menuBarModeEnabled else { return }

        // Find the shared view model from ContentView
        // We'll need to pass it from the view hierarchy
        // For now, create a minimal setup
        if menuBarController == nil {
            menuBarController = MenuBarController()
        }
    }

    /// Update menu bar with view model (called from ContentView)
    @MainActor
    func setupMenuBar(with viewModel: ServerViewModel) {
        let settings = viewModel.settings
        updateMenuBarMode(
            enabled: settings.menuBarModeEnabled,
            hideDock: settings.hideDockIconInMenuBarMode,
            viewModel: viewModel
        )
    }

    /// Update menu bar visibility (called when settings change)
    @MainActor
    func updateMenuBarMode(enabled: Bool, hideDock: Bool, viewModel: ServerViewModel) {
        if enabled {
            if menuBarController == nil {
                menuBarController = MenuBarController()
            }
            menuBarController?.setup(with: viewModel)
            menuBarController?.showMenuBarIcon()
            NSApp.setActivationPolicy(hideDock ? .accessory : .regular)
        } else {
            menuBarController?.cleanup()
            menuBarController?.hideMenuBarIcon()
            menuBarController = nil
            NSApp.setActivationPolicy(.regular)
        }
    }

    // MARK: - Launch at Login

    /// Update launch at login setting
    func updateLaunchAtLogin(enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                #if DEBUG
                print("Failed to update launch at login: \(error)")
                #endif
            }
        }
    }

    /// Check if launch at login is enabled
    func isLaunchAtLoginEnabled() -> Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        }
        return false
    }

    // MARK: - Widget Notification Handling

    private func setupWidgetNotificationListener() {
        widgetNotificationObserver = DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name(SharedDataManager.serverToggledNotificationName),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleWidgetServerToggle(notification)
        }
    }

    private func handleWidgetServerToggle(_ notification: Notification) {
        guard let parsed = SharedDataManager.parseServerToggledNotification(notification) else {
            return
        }

        // Find the view model and update the server
        // This will be called from the widget when a server is toggled
        #if DEBUG
        print("Widget toggled server: \(parsed.serverID), new state: \(parsed.newState)")
        #endif

        // The actual toggle will be handled by the ServerViewModel
        // which listens to this notification
        NotificationCenter.default.post(
            name: NSNotification.Name("WidgetServerToggled"),
            object: nil,
            userInfo: [
                "serverID": parsed.serverID,
                "newState": parsed.newState
            ]
        )
    }
}
