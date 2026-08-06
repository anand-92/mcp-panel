import Foundation
#if canImport(Sparkle)
import Sparkle
#endif

/// Service for handling app updates via Sparkle framework
@MainActor
class UpdateChecker: ObservableObject {
    static let shared = UpdateChecker()

    #if canImport(Sparkle)
    private var updaterController: SPUStandardUpdaterController?
    #endif

    /// Check if this is an App Store build
    /// App Store builds have an actual receipt file that exists
    ///
    /// Probes the bundle's fixed receipt location rather than `appStoreReceiptURL`,
    /// which macOS 15 deprecated in favour of StoreKit's `AppTransaction`. Only the
    /// receipt's presence matters here, so pulling in StoreKit would be overkill.
    var isAppStoreBuild: Bool {
        let receiptURL = Bundle.main.bundleURL
            .appendingPathComponent("Contents/_MASReceipt/receipt")
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
        #if canImport(Sparkle)
        // Only initialize Sparkle if not an App Store build and Sparkle is available
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
