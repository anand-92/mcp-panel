import SwiftUI

/// Main-actor storage for the appearance settings currently in effect.
///
/// `DesignTokens` exposes fonts and spacing as plain static values used from ~100 call
/// sites that have no view context (and from `NSViewRepresentable` code that can't read
/// the environment). Those tokens read this holder so a settings change re-renders the
/// whole app without every call site having to thread the settings through.
///
/// `ContentView` is the single writer: it publishes the *resolved* settings (accessibility
/// preferences already folded in) here and into `\.appearance` at the same time.
@MainActor
enum AppearanceRuntime {
    private(set) static var current: AppearanceSettings = .default

    /// Publish newly resolved settings. Returns `true` when the value actually changed,
    /// so callers can skip redundant window/menu-bar refreshes.
    @discardableResult
    static func update(_ settings: AppearanceSettings) -> Bool {
        guard current != settings else { return false }
        current = settings
        return true
    }
}
