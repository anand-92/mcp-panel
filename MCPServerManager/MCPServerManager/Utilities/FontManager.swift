import SwiftUI
import CoreText

/// Manages custom font registration for the app
/// Call FontManager.registerFonts() at app startup to load Poppins and Crimson Pro
enum FontManager {

    /// Register all custom fonts from the Resources/Fonts directory
    static func registerFonts() {
        let fontNames = [
            "Poppins-Regular.ttf",
            "Poppins-Medium.ttf",
            "Poppins-SemiBold.ttf",
            "Poppins-Bold.ttf",
            "CrimsonPro-Regular.ttf",
            "CrimsonPro-Variable.ttf"
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
        let fontName = filename.replacingOccurrences(of: ".ttf", with: "")
        var fontURL: URL?

        // 1. Try Bundle.module (Standard SPM)
        if let url = Bundle.module.url(forResource: fontName, withExtension: "ttf") {
            fontURL = url
        }
        // 2. Try Bundle.main (App Bundle root resources)
        else if let url = Bundle.main.url(forResource: fontName, withExtension: "ttf") {
            fontURL = url
        }
        // 3. Try explicit path to bundle inside Resources (App Store build structure)
        else if let resourcePath = Bundle.main.resourceURL,
                let bundleURL = try? FileManager.default.contentsOfDirectory(at: resourcePath, includingPropertiesForKeys: nil)
                    .first(where: { $0.lastPathComponent.contains("MCPServerManager_MCPServerManager.bundle") }) {
            
            let specificBundle = Bundle(url: bundleURL)
            if let url = specificBundle?.url(forResource: fontName, withExtension: "ttf") {
                fontURL = url
            }
        }

        guard let foundURL = fontURL else {
            print("⚠️ Could not find font file: \(filename)")
            print("   Bundle path: \(Bundle.main.bundlePath)")
            return
        }

        registerFontFromURL(foundURL, filename: filename)
    }

    /// Register font from URL
    private static func registerFontFromURL(_ url: URL, filename: String) {
        var error: Unmanaged<CFError>?

        guard CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) else {
            if let error = error?.takeRetainedValue() {
                // kCTFontManagerErrorAlreadyRegistered = 105
                let nsError = error as Error as NSError
                if nsError.code != 105 {
                    print("⚠️ Failed to register font \(filename): \(error)")
                }
            }
            return
        }

        print("✅ Registered font: \(filename)")
    }

    /// List all available fonts (debug helper)
    private static func listAvailableFonts() {
        let available = NSFontManager.shared.availableFonts
        let poppins = available.filter { $0.contains("Poppins") }
        let crimson = available.filter { $0.contains("Crimson") }

        if !poppins.isEmpty {
            print("   Poppins variants:", poppins.joined(separator: ", "))
        } else {
            print("   ⚠️ No Poppins fonts found in system!")
        }
        
        if !crimson.isEmpty {
            print("   Crimson variants:", crimson.joined(separator: ", "))
        } else {
            print("   ⚠️ No Crimson fonts found in system!")
        }
    }
}
