import SwiftUI
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
                }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1440, height: 900)
        .commands {
            CommandGroup(replacing: .newItem) {}

            // Window menu for reopening closed windows (required by App Store)
            CommandGroup(after: .windowList) {
                Button("Show Main Window") {
                    // Reopen the main window if it was closed
                    if let window = NSApp.windows.first {
                        window.makeKeyAndOrderFront(nil)
                        NSApp.activate(ignoringOtherApps: true)
                    }
                }
                .keyboardShortcut("0", modifiers: [.command])
            }

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
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Register custom fonts (Poppins & Crimson Pro)
        FontManager.registerFonts()

        // Make app key window and accept input
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}
