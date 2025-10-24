#!/usr/bin/env swift
import Foundation
import AppKit

// List all available fonts and filter for Poppins and Crimson
let allFonts = NSFontManager.shared.availableFonts
let customFonts = allFonts.filter { $0.contains("Poppins") || $0.contains("Crimson") }

print("Available Poppins and Crimson Pro fonts:")
for font in customFonts.sorted() {
    print("  - \(font)")
}

if customFonts.isEmpty {
    print("No Poppins or Crimson Pro fonts found.")
    print("\nAll available font families (first 20):")
    let families = NSFontManager.shared.availableFontFamilies.prefix(20)
    for family in families {
        print("  - \(family)")
    }
}
