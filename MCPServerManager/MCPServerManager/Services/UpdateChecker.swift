import Foundation
import Sparkle

/// Service for handling app updates via Sparkle framework
class UpdateChecker: ObservableObject {
    static let shared = UpdateChecker()

    private var updaterController: SPUStandardUpdaterController?

    /// Check if this is an App Store build
    /// App Store builds have an actual receipt file that exists
    var isAppStoreBuild: Bool {
        guard let receiptURL = Bundle.main.appStoreReceiptURL else {
            return false
        }
        // Check if the receipt file actually exists (not just the URL structure)
        return FileManager.default.fileExists(atPath: receiptURL.path)
    }

    /// Whether update checking is available (not an App Store build)
    var canCheckForUpdates: Bool {
        return !isAppStoreBuild
    }

    private init() {
        // Only initialize Sparkle if not an App Store build
        if !isAppStoreBuild {
            setupSparkle()
        }
    }

    private func setupSparkle() {
        // Initialize Sparkle updater controller
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }

    /// Manually check for updates
    func checkForUpdates() {
        guard canCheckForUpdates else {
            print("Cannot check for updates: App Store build")
            return
        }

        updaterController?.checkForUpdates(nil)
    }

    /// Get the updater controller (for binding to menu items)
    var updater: SPUUpdater? {
        return updaterController?.updater
    }
}
