import SwiftUI

// Font scale environment key
private struct FontScaleKey: EnvironmentKey {
    static let defaultValue: CGFloat = 1.5
}

extension EnvironmentValues {
    var fontScale: CGFloat {
        get { self[FontScaleKey.self] }
        set { self[FontScaleKey.self] = newValue }
    }
}

// View modifier to scale fonts
struct ScaledFont: ViewModifier {
    @Environment(\.fontScale) var scale

    func body(content: Content) -> some View {
        content
            .transformEnvironment(\.font) { font in
                if let currentFont = font {
                    font = currentFont
                }
            }
    }
}

extension View {
    func scaledFont() -> some View {
        modifier(ScaledFont())
    }
}
