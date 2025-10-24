import SwiftUI
import CoreText

// Extension to access SPM resource bundle
extension Bundle {
    static var resources: Bundle? {
        // For SPM, the resource bundle has a specific name pattern
        let bundleName = "MCPServerManager_MCPServerManager"

        // Try to find the bundle in common locations
        if let bundlePath = Bundle.main.path(forResource: bundleName, ofType: "bundle"),
           let bundle = Bundle(path: bundlePath) {
            return bundle
        }

        // Fallback to main bundle
        return Bundle.main
    }
}

/// Manages custom font registration for the app
/// Call FontManager.registerFonts() at app startup to load Poppins
enum FontManager {

    /// Register all custom fonts from the Resources/Fonts directory
    static func registerFonts() {
        let fontNames = [
            "Poppins-Regular.ttf",
            "Poppins-Medium.ttf",
            "Poppins-SemiBold.ttf",
            "Poppins-Bold.ttf"
        ]

        for fontName in fontNames {
            registerFont(filename: fontName)
        }

        #if DEBUG
        // Print all registered fonts to verify they loaded
        print("📝 Registered custom fonts:")
        listAvailableFonts()
        #endif
    }

    /// Register a single font file
    private static func registerFont(filename: String) {
        // For Swift Package Manager, resources are in a separate bundle
        let fontName = filename.replacingOccurrences(of: ".ttf", with: "")

        // Try to find the font in the resource bundle
        guard let resourceBundle = Bundle.resources,
              let fontURL = resourceBundle.url(forResource: fontName, withExtension: "ttf") else {
            print("⚠️ Could not find font file: \(filename)")
            print("   Resource bundle: \(Bundle.resources?.bundlePath ?? "not found")")
            return
        }

        registerFontFromURL(fontURL, filename: filename)
    }

    /// Register font from URL
    private static func registerFontFromURL(_ url: URL, filename: String) {
        var error: Unmanaged<CFError>?

        guard CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) else {
            if let error = error?.takeRetainedValue() {
                print("⚠️ Failed to register font \(filename): \(error)")
            }
            return
        }

        print("✅ Registered font: \(filename)")
    }

    /// List all available fonts (debug helper)
    private static func listAvailableFonts() {
        let poppinsFonts = NSFontManager.shared.availableFonts.filter { $0.contains("Poppins") }

        if !poppinsFonts.isEmpty {
            print("   Poppins variants:", poppinsFonts.joined(separator: ", "))
        } else {
            print("   ⚠️ No Poppins fonts found in system!")
        }
    }
}
