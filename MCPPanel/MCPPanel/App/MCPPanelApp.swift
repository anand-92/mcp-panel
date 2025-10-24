//
//  MCPPanelApp.swift
//  MCP Panel
//
//  Native macOS Swift version of MCP Server Manager
//

import SwiftUI

@main
struct MCPPanelApp: App {
    @StateObject private var appState = AppState()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .frame(minWidth: 900, minHeight: 600)
                .onAppear {
                    // Load initial configuration
                    Task {
                        await appState.loadConfig()
                    }
                }
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Server") {
                    appState.showServerModal = true
                }
                .keyboardShortcut("n", modifiers: .command)
            }

            CommandGroup(after: .newItem) {
                Button("Import Config...") {
                    appState.importConfig()
                }
                .keyboardShortcut("i", modifiers: [.command, .shift])

                Button("Export Config...") {
                    appState.exportConfig()
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])

                Divider()

                Button("Reload Config") {
                    Task {
                        await appState.loadConfig()
                    }
                }
                .keyboardShortcut("r", modifiers: .command)
            }

            CommandGroup(after: .sidebar) {
                Button("Settings...") {
                    appState.showSettings = true
                }
                .keyboardShortcut(",", modifiers: .command)

                Divider()

                Button("Toggle View Mode") {
                    appState.toggleViewMode()
                }
                .keyboardShortcut("t", modifiers: [.command, .shift])
            }

            // Search menu
            CommandMenu("Search") {
                Button("Focus Search") {
                    appState.focusSearch.toggle()
                }
                .keyboardShortcut("f", modifiers: .command)

                Button("Clear Search") {
                    appState.searchQuery = ""
                }
                .keyboardShortcut("k", modifiers: [.command, .shift])
            }
        }

        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
