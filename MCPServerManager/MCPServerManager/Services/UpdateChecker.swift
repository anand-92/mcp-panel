import Foundation
#if !APPSTORE
import Sparkle
#endif

/// Service for handling app updates via Sparkle framework
class UpdateChecker: ObservableObject {
    static let shared = UpdateChecker()

    #if !APPSTORE
    private var updaterController: SPUStandardUpdaterController?
    #endif

    /// Whether update checking is available (not an App Store build)
    var canCheckForUpdates: Bool {
        #if APPSTORE
        return false
        #else
        return true
        #endif
    }

    private init() {
        #if !APPSTORE
        setupSparkle()
        #endif
    }

    #if !APPSTORE
    private func setupSparkle() {
        // Initialize Sparkle updater controller
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }
    #endif

    /// Manually check for updates
    func checkForUpdates() {
        #if !APPSTORE
        updaterController?.checkForUpdates(nil)
        #else
        print("Cannot check for updates: App Store build")
        #endif
    }

    #if !APPSTORE
    /// Get the updater controller (for binding to menu items)
    var updater: SPUUpdater? {
        return updaterController?.updater
    }
    #endif
}
