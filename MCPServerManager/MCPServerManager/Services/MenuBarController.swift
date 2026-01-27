import AppKit
import SwiftUI

/// Manages the menu bar status item and popover for quick server access
@MainActor
class MenuBarController: NSObject {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private weak var viewModel: ServerViewModel?
    private var eventMonitor: Any?
    
    // Public property to check status
    var hasStatusItem: Bool { statusItem != nil }

    override init() {
        super.init()
    }

    /// Clean up resources - called manually before releasing
    func cleanup() {
        removeEventMonitor()
    }

    // MARK: - Setup

    /// Initialize the menu bar controller with a view model
    func setup(with viewModel: ServerViewModel) {
        self.viewModel = viewModel
        
        // If we already have a status item but no popover, set it up now
        if statusItem != nil && popover == nil {
            setupPopover()
        }
        
        // If we have a popover, update its content with the new view model
        if popover != nil {
            updatePopoverContent()
        }
        
        print("MenuBarController setup with viewModel containing \(viewModel.servers.count) servers")
    }

    /// Show the menu bar icon
    func showMenuBarIcon() {
        guard statusItem == nil else { 
            print("📍 MenuBar: Status item already exists, skipping creation")
            return 
        }

        print("📍 MenuBar: Creating status item...")
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            print("📍 MenuBar: Setting up button with server.rack icon...")
            button.image = NSImage(systemSymbolName: "server.rack", accessibilityDescription: "MCP Servers")
            button.image?.isTemplate = true
            button.action = #selector(togglePopover)
            button.target = self
            print("📍 MenuBar: Button setup complete")
        } else {
            print("❌ MenuBar: Failed to get button from status item")
        }

        print("📍 MenuBar: Setting up popover...")
        setupPopover()
        print("✅ MenuBar: Show menu bar icon complete")
    }

    /// Hide the menu bar icon
    func hideMenuBarIcon() {
        if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
            statusItem = nil
        }
        popover?.close()
        popover = nil
        removeEventMonitor()
    }

    /// Update visibility based on settings
    func updateVisibility(enabled: Bool) {
        if enabled {
            showMenuBarIcon()
        } else {
            hideMenuBarIcon()
        }
    }
    
    /// Refresh the popover content (useful when servers change)
    func refreshPopoverContent() {
        guard viewModel != nil, popover != nil else { return }
        updatePopoverContent()
    }

    // MARK: - Popover Management

    private func setupPopover() {
        popover = NSPopover()
        popover?.behavior = .transient
        popover?.animates = true
        popover?.contentSize = NSSize(width: 280, height: 400)
        updatePopoverContent()
    }

    private func updatePopoverContent() {
        guard let viewModel = viewModel else {
            print("MenuBar: Cannot update popover content - no view model")
            return
        }

        print("MenuBar: Updating popover content with \(viewModel.servers.count) servers")

        let popoverView = MenuBarPopoverView(
            viewModel: viewModel,
            onOpenApp: { [weak self] in self?.openMainApp() },
            onRefresh: { [weak self] in self?.refreshServers() }
        )
        .environment(\.themeColors, viewModel.themeColors)
        .environment(\.currentTheme, viewModel.currentTheme)

        popover?.contentViewController = NSHostingController(rootView: popoverView)
    }

    @objc private func togglePopover() {
        guard let button = statusItem?.button else { return }

        // If no viewModel yet, just open the main app
        guard let viewModel = viewModel else {
            print("No viewModel available, opening main app")
            openMainApp()
            return
        }

        // Ensure popover exists and is properly configured
        if popover == nil {
            setupPopover()
        }

        guard let popover = popover else {
            print("Failed to create popover")
            return
        }

        if popover.isShown {
            closePopover()
        } else {
            // Refresh data before showing
            viewModel.loadServers()
            updatePopoverContent()
            
            // Show the popover
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            addEventMonitor()
            
            print("Popover shown with \(viewModel.servers.count) servers")
        }
    }

    private func closePopover() {
        popover?.performClose(nil)
        removeEventMonitor()
    }

    // MARK: - Event Monitoring

    private func addEventMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            if self?.popover?.isShown == true {
                self?.closePopover()
            }
        }
    }

    private func removeEventMonitor() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    // MARK: - Actions

    private func openMainApp() {
        closePopover()
        
        // Temporarily change activation policy to .regular so window can become key
        NSApp.setActivationPolicy(.regular)
        
        // Activate the app and bring window to front
        NSApp.activate(ignoringOtherApps: true)
        
        // Find and show the main window (excluding menu bar windows)
        if let window = NSApp.windows.first(where: { window in
            // Skip status bar windows and other system windows
            return window.className != "NSStatusBarWindow" && 
                   window.className != "_NSPopoverWindow"
        }) {
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
        } else {
            // Fallback: just use the first available window
            NSApp.windows.first?.makeKeyAndOrderFront(nil)
        }
        
        print("📱 Opened main app window")
    }

    private func refreshServers() {
        viewModel?.loadServers()
    }
}
