import AppKit
import SwiftUI

// MARK: - Custom Menu Bar Panel

/// A custom NSPanel that supports transparency and vibrancy for menu bar dropdowns
class MenuBarPanel: NSPanel {
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: [.nonactivatingPanel, .fullSizeContentView], backing: backingStoreType, defer: flag)

        // Hide title bar completely
        titlebarAppearsTransparent = true
        titleVisibility = .hidden

        // Make window background transparent for vibrancy
        isOpaque = false
        backgroundColor = .clear

        // Float above other windows like a popover
        level = .popUpMenu
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // Don't show in dock or app switcher
        hidesOnDeactivate = false

        // IMPORTANT: Don't ignore mouse events - capture them for scrolling
        ignoresMouseEvents = false
    }

    // Allow the panel to become key without activating the app
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    // Accept mouse moved events for proper hover/scroll handling
    override var acceptsMouseMovedEvents: Bool {
        get { true }
        set { }
    }
}

// MARK: - Menu Bar Controller

/// Manages the menu bar status item and panel for quick server access
@MainActor
class MenuBarController: NSObject {
    private var statusItem: NSStatusItem?
    private var panel: MenuBarPanel?
    private weak var viewModel: ServerViewModel?
    private var eventMonitor: Any?
    private var localEventMonitor: Any?

    // Public property to check status
    var hasStatusItem: Bool { statusItem != nil }

    private let panelSize = NSSize(width: 280, height: 400)

    override init() {
        super.init()
    }

    /// Clean up resources - called manually before releasing
    func cleanup() {
        removeEventMonitors()
    }

    // MARK: - Setup

    /// Initialize the menu bar controller with a view model
    func setup(with viewModel: ServerViewModel) {
        self.viewModel = viewModel

        // If we already have a status item but no panel, set it up now
        if statusItem != nil && panel == nil {
            setupPanel()
        }

        // If we have a panel, update its content with the new view model
        if panel != nil {
            updatePanelContent()
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
            print("📍 MenuBar: Setting up button with app icon...")
            // Use app icon resized for menu bar
            let appIcon = AppIcon.image
            let resizedIcon = NSImage(size: NSSize(width: 18, height: 18))
            resizedIcon.lockFocus()
            appIcon.draw(in: NSRect(x: 0, y: 0, width: 18, height: 18),
                        from: NSRect(origin: .zero, size: appIcon.size),
                        operation: .sourceOver,
                        fraction: 1.0)
            resizedIcon.unlockFocus()
            button.image = resizedIcon
            button.action = #selector(togglePanel)
            button.target = self
            print("📍 MenuBar: Button setup complete")
        } else {
            print("❌ MenuBar: Failed to get button from status item")
        }

        print("📍 MenuBar: Setting up panel...")
        setupPanel()
        print("✅ MenuBar: Show menu bar icon complete")
    }

    /// Hide the menu bar icon
    func hideMenuBarIcon() {
        if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
            statusItem = nil
        }
        closePanel()
        panel = nil
    }

    /// Update visibility based on settings
    func updateVisibility(enabled: Bool) {
        if enabled {
            showMenuBarIcon()
        } else {
            hideMenuBarIcon()
        }
    }

    /// Refresh the panel content (useful when servers change)
    func refreshPopoverContent() {
        guard viewModel != nil, panel != nil else { return }
        updatePanelContent()
    }

    // MARK: - Panel Management

    private func setupPanel() {
        panel = MenuBarPanel(
            contentRect: NSRect(origin: .zero, size: panelSize),
            styleMask: [],
            backing: .buffered,
            defer: false
        )
        updatePanelContent()
    }

    private func updatePanelContent() {
        guard let viewModel = viewModel, let panel = panel else {
            print("MenuBar: Cannot update panel content - no view model or panel")
            return
        }

        print("MenuBar: Updating panel content with \(viewModel.servers.count) servers")

        let panelView = MenuBarPopoverView(
            viewModel: viewModel,
            onOpenApp: { [weak self] in self?.openMainApp() },
            onRefresh: { [weak self] in self?.refreshServers() }
        )
        .environment(\.themeColors, viewModel.themeColors)
        .environment(\.currentTheme, viewModel.currentTheme)

        let hostingView = NSHostingView(rootView: panelView)
        hostingView.autoresizingMask = [.width, .height]
        panel.contentView = hostingView
    }

    @objc private func togglePanel() {
        guard let button = statusItem?.button else { return }

        // If no viewModel yet, just open the main app
        guard let viewModel = viewModel else {
            print("No viewModel available, opening main app")
            openMainApp()
            return
        }

        // Ensure panel exists and is properly configured
        if panel == nil {
            setupPanel()
        }

        guard let panel = panel else {
            print("Failed to create panel")
            return
        }

        if panel.isVisible {
            closePanel()
        } else {
            // Refresh data before showing
            viewModel.loadServers()
            updatePanelContent()

            // Calculate position below the status item
            if let buttonWindow = button.window {
                let buttonRect = button.convert(button.bounds, to: nil)
                let screenRect = buttonWindow.convertToScreen(buttonRect)

                // Position panel centered below the button
                let x = screenRect.midX - (panelSize.width / 2)
                let y = screenRect.minY - panelSize.height - 4 // 4px gap

                panel.setFrameOrigin(NSPoint(x: x, y: y))
            }

            // Show the panel
            panel.makeKeyAndOrderFront(nil)
            addEventMonitors()

            print("Panel shown with \(viewModel.servers.count) servers")
        }
    }

    private func closePanel() {
        panel?.orderOut(nil)
        removeEventMonitors()
    }

    // MARK: - Event Monitoring

    private func addEventMonitors() {
        // Global monitor for clicks outside the app
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.closePanel()
        }

        // Local monitor for clicks inside the app but outside the panel
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self, let panel = self.panel else { return event }

            // If click is on the status item button, let togglePanel handle it
            if let button = self.statusItem?.button,
               let buttonWindow = button.window,
               event.window == buttonWindow {
                return event
            }

            // If click is outside the panel, close it
            if event.window != panel {
                self.closePanel()
            }

            return event
        }
    }

    private func removeEventMonitors() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
            localEventMonitor = nil
        }
    }

    // MARK: - Actions

    private func openMainApp() {
        closePanel()

        // Temporarily change activation policy to .regular so window can become key
        NSApp.setActivationPolicy(.regular)

        // Activate the app and bring window to front
        NSApp.activate(ignoringOtherApps: true)

        // Find and show the main window (excluding menu bar windows)
        if let window = NSApp.windows.first(where: { window in
            // Skip status bar windows and panel windows
            return window.className != "NSStatusBarWindow" &&
                   !(window is MenuBarPanel)
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
