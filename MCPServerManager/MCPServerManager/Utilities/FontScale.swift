import SwiftUI

// Global font scale - multiply all font sizes by this
let globalFontScale: CGFloat = 1.5

extension Font {
    // Scale system fonts
    static func scaled(_ style: TextStyle, design: Design = .default) -> Font {
        switch style {
        case .largeTitle: return .system(size: 34 * globalFontScale, weight: .regular, design: design)
        case .title: return .system(size: 28 * globalFontScale, weight: .regular, design: design)
        case .title2: return .system(size: 22 * globalFontScale, weight: .regular, design: design)
        case .title3: return .system(size: 20 * globalFontScale, weight: .regular, design: design)
        case .headline: return .system(size: 17 * globalFontScale, weight: .semibold, design: design)
        case .body: return .system(size: 17 * globalFontScale, weight: .regular, design: design)
        case .callout: return .system(size: 16 * globalFontScale, weight: .regular, design: design)
        case .subheadline: return .system(size: 15 * globalFontScale, weight: .regular, design: design)
        case .footnote: return .system(size: 13 * globalFontScale, weight: .regular, design: design)
        case .caption: return .system(size: 12 * globalFontScale, weight: .regular, design: design)
        case .caption2: return .system(size: 11 * globalFontScale, weight: .regular, design: design)
        @unknown default: return .system(size: 17 * globalFontScale, weight: .regular, design: design)
        }
    }

    // Scale custom size fonts
    static func scaledSystem(size: CGFloat, weight: Weight = .regular, design: Design = .default) -> Font {
        return .system(size: size * globalFontScale, weight: weight, design: design)
    }
}
