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

                    // Setup menu bar controller with shared view model
                    appDelegate.setupMenuBarIfNeeded()
                }
                .task {
                    // Apply Liquid Glass to window background (with slight delay to ensure window is ready)
                    try? await Task.sleep(for: .milliseconds(100))
                    await MainActor.run {
                        if let window = NSApp.windows.first {
                            if #available(macOS 26.0, *) {
                                window.isOpaque = false
                                window.backgroundColor = .clear
                                window.titlebarAppearsTransparent = true
                            }
                        }
                    }
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

        // Show menu bar icon early if enabled (popover will be set up later with viewModel)
        if settings.menuBarModeEnabled {
            Task { @MainActor in
                if menuBarController == nil {
                    menuBarController = MenuBarController()
                }
                menuBarController?.showMenuBarIcon()
            }
        }

        NSApp.activate(ignoringOtherApps: true)

        // Sync launch at login with saved setting
        syncLaunchAtLogin()

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
    /// Returns true if successful, false if failed
    @discardableResult
    func updateLaunchAtLogin(enabled: Bool) -> Bool {
        if #available(macOS 13.0, *) {
            do {
                let currentStatus = SMAppService.mainApp.status
                if enabled {
                    if currentStatus == .enabled || currentStatus == .requiresApproval {
                        return true // Already enabled
                    }
                    try SMAppService.mainApp.register()
                    let updatedStatus = SMAppService.mainApp.status
                    return updatedStatus == .enabled || updatedStatus == .requiresApproval
                } else {
                    if currentStatus != .notRegistered {
                        try SMAppService.mainApp.unregister()
                    }
                    return true
                }
            } catch {
                #if DEBUG
                print("Failed to update launch at login: \(error)")
                #endif
                return false
            }
        }
        return false
    }

    /// Check if launch at login is enabled
    func isLaunchAtLoginEnabled() -> Bool {
        if #available(macOS 13.0, *) {
            let status = SMAppService.mainApp.status
            return status == .enabled || status == .requiresApproval
        }
        return false
    }

    /// Check if launch at login requires user approval
    func launchAtLoginRequiresApproval() -> Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .requiresApproval
        }
        return false
    }

    /// Try to sync launch at login with saved setting
    func syncLaunchAtLogin() {
        let savedSetting = UserDefaults.standard.appSettings.launchAtLogin
        let systemState = isLaunchAtLoginEnabled()

        if savedSetting != systemState {
            #if DEBUG
            print("Launch at login mismatch - saved: \(savedSetting), system: \(systemState). Attempting to sync...")
            #endif
            updateLaunchAtLogin(enabled: savedSetting)
        }
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
        // Read pending toggle from shared UserDefaults (sandboxed apps can't receive userInfo)
        guard let defaults = UserDefaults(suiteName: "group.com.anand-92.mcp-panel"),
              let pendingToggle = defaults.dictionary(forKey: "pendingServerToggle"),
              let serverIDString = pendingToggle["serverID"] as? String,
              let serverID = UUID(uuidString: serverIDString),
              let newState = pendingToggle["newState"] as? Bool else {
            #if DEBUG
            print("Widget toggle: No pending toggle found or invalid data")
            #endif
            return
        }

        // Clear the pending toggle
        defaults.removeObject(forKey: "pendingServerToggle")
        defaults.synchronize()

        #if DEBUG
        print("Widget toggled server: \(serverID), new state: \(newState)")
        #endif

        // The actual toggle will be handled by the ServerViewModel
        // which listens to this notification
        NotificationCenter.default.post(
            name: NSNotification.Name("WidgetServerToggled"),
            object: nil,
            userInfo: [
                "serverID": serverID,
                "newState": newState
            ]
        )
    }
}
