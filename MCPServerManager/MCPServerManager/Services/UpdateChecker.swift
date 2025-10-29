import Foundation
#if canImport(Sparkle)
import Sparkle
#endif

/// Service for handling app updates via Sparkle framework
class UpdateChecker: ObservableObject {
    static let shared = UpdateChecker()

    #if canImport(Sparkle)
    private var updaterController: SPUStandardUpdaterController?
    #endif

    /// Check if this is an App Store build
    /// App Store builds have an actual receipt file that exists
    var isAppStoreBuild: Bool {
        guard let receiptURL = Bundle.main.appStoreReceiptURL else {
            return false
        }
        // Check if the receipt file actually exists (not just the URL structure)
        return FileManager.default.fileExists(atPath: receiptURL.path)
    }

    /// Whether update checking is available (not an App Store build and Sparkle is available)
    var canCheckForUpdates: Bool {
        #if canImport(Sparkle)
        return !isAppStoreBuild
        #else
        return false
        #endif
    }

    private init() {
        // Only initialize Sparkle if not an App Store build and Sparkle is available
        #if canImport(Sparkle)
        if !isAppStoreBuild {
            setupSparkle()
        }
        #endif
    }

    #if canImport(Sparkle)
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
        guard canCheckForUpdates else {
            print("Cannot check for updates: App Store build or Sparkle not available")
            return
        }

        #if canImport(Sparkle)
        updaterController?.checkForUpdates(nil)
        #endif
    }

    /// Get the updater controller (for binding to menu items)
    #if canImport(Sparkle)
    var updater: SPUUpdater? {
        return updaterController?.updater
    }
    #else
    var updater: Any? {
        return nil
    }
    #endif
}
