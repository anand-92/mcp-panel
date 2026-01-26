import AppKit
import SwiftUI

/// Manages the menu bar status item and popover for quick server access
@MainActor
class MenuBarController: NSObject {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private weak var viewModel: ServerViewModel?
    private var eventMonitor: Any?

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
    }

    /// Show the menu bar icon
    func showMenuBarIcon() {
        guard statusItem == nil else { return }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "server.rack", accessibilityDescription: "MCP Servers")
            button.image?.isTemplate = true
            button.action = #selector(togglePopover)
            button.target = self
        }

        setupPopover()
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

    // MARK: - Popover Management

    private func setupPopover() {
        popover = NSPopover()
        popover?.behavior = .transient
        popover?.animates = true
        popover?.contentSize = NSSize(width: 280, height: 400)
        updatePopoverContent()
    }

    private func updatePopoverContent() {
        guard let viewModel = viewModel else { return }

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
        guard let popover = popover, let button = statusItem?.button else { return }

        if popover.isShown {
            closePopover()
        } else {
            viewModel?.loadServers()
            updatePopoverContent()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            addEventMonitor()
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
        NSApp.activate(ignoringOtherApps: true)
        NSApp.windows.first?.makeKeyAndOrderFront(nil)
    }

    private func refreshServers() {
        viewModel?.loadServers()
    }
}
