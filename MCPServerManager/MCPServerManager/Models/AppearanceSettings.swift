import SwiftUI

// MARK: - Option Protocol

/// A named appearance choice rendered by the segmented controls in Settings.
protocol AppearanceOption: Hashable, Sendable, CaseIterable where AllCases: RandomAccessCollection {
    var displayName: String { get }
    var icon: String { get }
    var summary: String { get }
}

// MARK: - Appearance Mode

/// Which color scheme the app renders in.
enum AppearanceMode: String, Codable, AppearanceOption {
    case system
    case light
    case dark

    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }

    var summary: String {
        switch self {
        case .system: return "Follow macOS"
        case .light: return "Always light"
        case .dark: return "Always dark"
        }
    }

    /// `nil` means "follow the system setting".
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    /// AppKit counterpart, for the window chrome and the menu bar popover, which
    /// `preferredColorScheme` doesn't reach.
    var nsAppearance: NSAppearance? {
        switch self {
        case .system: return nil
        case .light: return NSAppearance(named: .aqua)
        case .dark: return NSAppearance(named: .darkAqua)
        }
    }
}

// MARK: - Glass Style

/// How much Liquid Glass the app applies to panels, cards, and modals.
enum GlassStyleOption: String, Codable, AppearanceOption {
    case regular
    case clear
    case off

    var displayName: String {
        switch self {
        case .regular: return "Regular"
        case .clear: return "Clear"
        case .off: return "Off"
        }
    }

    var icon: String {
        switch self {
        case .regular: return "circle.righthalf.filled"
        case .clear: return "circle.dotted"
        case .off: return "square.fill"
        }
    }

    var summary: String {
        switch self {
        case .regular: return "Frosted, the macOS default"
        case .clear: return "Barely-there, see-through glass"
        case .off: return "Solid panels, no translucency"
        }
    }
}

// MARK: - Layout Density

/// Preset spacing bundles for the card grid and panels.
enum LayoutDensity: String, Codable, AppearanceOption {
    case compact
    case standard
    case comfortable

    var displayName: String {
        switch self {
        case .compact: return "Compact"
        case .standard: return "Default"
        case .comfortable: return "Comfortable"
        }
    }

    var icon: String {
        switch self {
        case .compact: return "rectangle.compress.vertical"
        case .standard: return "rectangle.grid.2x2"
        case .comfortable: return "rectangle.expand.vertical"
        }
    }

    var summary: String {
        switch self {
        case .compact: return "Tighter spacing, more servers on screen"
        case .standard: return "The balanced default"
        case .comfortable: return "Roomier cards with generous padding"
        }
    }

    var metrics: LayoutMetrics {
        switch self {
        case .compact:
            return LayoutMetrics(cornerRadius: 10, cardPadding: 12, gridSpacing: 10, minCardWidth: 340)
        case .standard:
            return LayoutMetrics(cornerRadius: 16, cardPadding: 16, gridSpacing: 16, minCardWidth: 400)
        case .comfortable:
            return LayoutMetrics(cornerRadius: 22, cardPadding: 22, gridSpacing: 24, minCardWidth: 480)
        }
    }
}

/// The four spacing values a `LayoutDensity` preset writes.
struct LayoutMetrics: Equatable, Sendable {
    let cornerRadius: Double
    let cardPadding: Double
    let gridSpacing: Double
    let minCardWidth: Double
}

// MARK: - Text Size

/// Global text scale applied to every `DesignTokens.Typography` entry.
enum TextSizeOption: String, Codable, AppearanceOption {
    case small
    case standard
    case large
    case extraLarge

    var displayName: String {
        switch self {
        case .small: return "Small"
        case .standard: return "Default"
        case .large: return "Large"
        case .extraLarge: return "X-Large"
        }
    }

    var icon: String {
        switch self {
        case .small: return "textformat.size.smaller"
        case .standard: return "textformat.size"
        case .large: return "textformat.size.larger"
        case .extraLarge: return "textformat"
        }
    }

    var summary: String {
        switch self {
        case .small: return "Fit more on screen"
        case .standard: return "Standard text size"
        case .large: return "Easier to read"
        case .extraLarge: return "Largest text"
        }
    }

    var scale: Double {
        switch self {
        case .small: return 0.9
        case .standard: return 1.0
        case .large: return 1.12
        case .extraLarge: return 1.25
        }
    }
}

// MARK: - UI Font

/// Which typeface the interface uses for labels, titles, and buttons.
enum UIFontOption: String, Codable, AppearanceOption {
    case poppins
    case system
    case serif

    var displayName: String {
        switch self {
        case .poppins: return "Poppins"
        case .system: return "System"
        case .serif: return "Crimson"
        }
    }

    var icon: String {
        switch self {
        case .poppins: return "textformat.alt"
        case .system: return "menubar.rectangle"
        case .serif: return "textformat.abc.dottedunderline"
        }
    }

    var summary: String {
        switch self {
        case .poppins: return "The bundled geometric sans"
        case .system: return "San Francisco, matches macOS"
        case .serif: return "The bundled reading serif"
        }
    }
}

// MARK: - Motion Level

/// How lively the app's transitions and hover animations feel.
enum MotionLevel: String, Codable, AppearanceOption {
    case off
    case subtle
    case standard
    case playful

    var displayName: String {
        switch self {
        case .off: return "Off"
        case .subtle: return "Subtle"
        case .standard: return "Default"
        case .playful: return "Playful"
        }
    }

    var icon: String {
        switch self {
        case .off: return "pause.circle"
        case .subtle: return "wind"
        case .standard: return "play.circle"
        case .playful: return "sparkles"
        }
    }

    var summary: String {
        switch self {
        case .off: return "No animation at all"
        case .subtle: return "Quick and understated"
        case .standard: return "The balanced default"
        case .playful: return "Slower, bouncier springs"
        }
    }

    var isEnabled: Bool { self != .off }

    /// Multiplier passed to `Animation.speed(_:)`; above 1 is faster.
    var speed: Double {
        switch self {
        case .off: return 1
        case .subtle: return 1.6
        case .standard: return 1
        case .playful: return 0.75
        }
    }
}

// MARK: - Appearance Settings

/// Every user-facing look-and-feel preference. Persisted inside `AppSettings` and
/// applied live: `ContentView` resolves it against the accessibility environment and
/// publishes it through `\.appearance` and `AppearanceRuntime`.
struct AppearanceSettings: Codable, Equatable, Sendable {
    /// Surface alpha the app was designed around; user values scale relative to it.
    static let referenceSurfaceOpacity: Double = 0.55

    static let opacityRange: ClosedRange<Double> = 0...1
    static let cornerRadiusRange: ClosedRange<Double> = 0...28
    static let cardPaddingRange: ClosedRange<Double> = 8...32
    static let gridSpacingRange: ClosedRange<Double> = 4...36
    static let minCardWidthRange: ClosedRange<Double> = 300...620
    static let codeFontSizeRange: ClosedRange<Double> = 9...20
    static let jsonBlurRange: ClosedRange<Double> = 2...20

    // Theme
    var appearanceMode: AppearanceMode = .dark

    // Glass
    var glassStyle: GlassStyleOption = .regular
    var tintGlassWithAccent: Bool = false
    var interactiveGlass: Bool = true
    var respectReduceTransparency: Bool = true

    // Transparency
    var surfaceOpacity: Double = Self.referenceSurfaceOpacity
    var windowBackgroundOpacity: Double = 0

    // Layout
    var cornerRadius: Double = LayoutDensity.standard.metrics.cornerRadius
    var cardPadding: Double = LayoutDensity.standard.metrics.cardPadding
    var gridSpacing: Double = LayoutDensity.standard.metrics.gridSpacing
    var minCardWidth: Double = LayoutDensity.standard.metrics.minCardWidth

    // Text
    var textSize: TextSizeOption = .standard
    var uiFont: UIFontOption = .poppins
    var codeFontSize: Double = 13

    // Motion
    var motionLevel: MotionLevel = .standard
    var hoverEffects: Bool = true
    var respectReduceMotion: Bool = true

    // Effects
    var shadowsEnabled: Bool = true
    var jsonBlurStrength: Double = 8

    static let `default` = AppearanceSettings()

    // MARK: - Derived Values

    var isGlassEnabled: Bool { glassStyle != .off }

    /// The preset matching the current spacing values, or `nil` when they've been
    /// customized with the individual sliders.
    var matchedDensity: LayoutDensity? {
        LayoutDensity.allCases.first { $0.metrics == currentMetrics }
    }

    var currentMetrics: LayoutMetrics {
        LayoutMetrics(
            cornerRadius: cornerRadius,
            cardPadding: cardPadding,
            gridSpacing: gridSpacing,
            minCardWidth: minCardWidth
        )
    }

    mutating func apply(_ density: LayoutDensity) {
        let metrics = density.metrics
        cornerRadius = metrics.cornerRadius
        cardPadding = metrics.cardPadding
        gridSpacing = metrics.gridSpacing
        minCardWidth = metrics.minCardWidth
    }

    /// Scales a design-time surface alpha by the user's surface-opacity preference.
    /// `base` is the alpha that surface uses at the default setting, so the relative
    /// depth between panels, toolbars, and code surfaces survives the adjustment.
    func surfaceAlpha(base: Double) -> Double {
        guard Self.referenceSurfaceOpacity > 0 else { return base }
        return min(1, base * (surfaceOpacity / Self.referenceSurfaceOpacity))
    }

    /// A translucent version of `color` honoring the surface-opacity preference.
    func surface(_ color: Color, base: Double = Self.referenceSurfaceOpacity) -> Color {
        color.opacity(surfaceAlpha(base: base))
    }

    /// The animation to use for an interaction, or `nil` when motion is disabled.
    func motion(_ animation: Animation) -> Animation? {
        guard motionLevel.isEnabled else { return nil }
        return animation.speed(motionLevel.speed)
    }

    /// Shadow radius and opacity collapse to zero when shadows are turned off.
    func shadowOpacity(_ opacity: Double) -> Double {
        shadowsEnabled ? opacity : 0
    }

    func shadowRadius(_ radius: Double) -> Double {
        shadowsEnabled ? radius : 0
    }

    /// Folds the accessibility preferences into a concrete set of values, so views
    /// downstream never have to re-check Reduce Transparency or Reduce Motion.
    func resolved(reduceTransparency: Bool, reduceMotion: Bool) -> AppearanceSettings {
        var resolved = self
        if respectReduceTransparency && reduceTransparency {
            resolved.glassStyle = .off
            resolved.surfaceOpacity = 1
            resolved.windowBackgroundOpacity = 1
            resolved.tintGlassWithAccent = false
        }
        if respectReduceMotion && reduceMotion {
            resolved.motionLevel = .off
            resolved.hoverEffects = false
        }
        return resolved
    }

    // MARK: - Codable

    // Decoded field-by-field so a settings blob written by an older (or newer) build
    // never fails to decode and silently resets every appearance preference.
    enum CodingKeys: String, CodingKey {
        case appearanceMode, glassStyle, tintGlassWithAccent, interactiveGlass, respectReduceTransparency
        case surfaceOpacity, windowBackgroundOpacity
        case cornerRadius, cardPadding, gridSpacing, minCardWidth
        case textSize, uiFont, codeFontSize
        case motionLevel, hoverEffects, respectReduceMotion
        case shadowsEnabled, jsonBlurStrength
    }

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let fallback = AppearanceSettings()

        func decode<T: Decodable>(_ key: CodingKeys, _ fallbackValue: T) -> T {
            guard let decoded = try? container.decodeIfPresent(T.self, forKey: key) else {
                return fallbackValue
            }
            return decoded ?? fallbackValue
        }

        appearanceMode = decode(.appearanceMode, fallback.appearanceMode)
        glassStyle = decode(.glassStyle, fallback.glassStyle)
        tintGlassWithAccent = decode(.tintGlassWithAccent, fallback.tintGlassWithAccent)
        interactiveGlass = decode(.interactiveGlass, fallback.interactiveGlass)
        respectReduceTransparency = decode(.respectReduceTransparency, fallback.respectReduceTransparency)
        surfaceOpacity = decode(.surfaceOpacity, fallback.surfaceOpacity)
        windowBackgroundOpacity = decode(.windowBackgroundOpacity, fallback.windowBackgroundOpacity)
        cornerRadius = decode(.cornerRadius, fallback.cornerRadius)
        cardPadding = decode(.cardPadding, fallback.cardPadding)
        gridSpacing = decode(.gridSpacing, fallback.gridSpacing)
        minCardWidth = decode(.minCardWidth, fallback.minCardWidth)
        textSize = decode(.textSize, fallback.textSize)
        uiFont = decode(.uiFont, fallback.uiFont)
        codeFontSize = decode(.codeFontSize, fallback.codeFontSize)
        motionLevel = decode(.motionLevel, fallback.motionLevel)
        hoverEffects = decode(.hoverEffects, fallback.hoverEffects)
        respectReduceMotion = decode(.respectReduceMotion, fallback.respectReduceMotion)
        shadowsEnabled = decode(.shadowsEnabled, fallback.shadowsEnabled)
        jsonBlurStrength = decode(.jsonBlurStrength, fallback.jsonBlurStrength)
    }
}

// MARK: - Environment

private struct AppearanceKey: EnvironmentKey {
    static let defaultValue: AppearanceSettings = .default
}

extension EnvironmentValues {
    /// The resolved appearance settings, with accessibility preferences already folded in.
    var appearance: AppearanceSettings {
        get { self[AppearanceKey.self] }
        set { self[AppearanceKey.self] = newValue }
    }
}
