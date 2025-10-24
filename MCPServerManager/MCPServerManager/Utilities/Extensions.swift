import Foundation
import SwiftUI

// MARK: - String Extensions

extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func shortPath() -> String {
        // Smart naming based on parent folder/filename
        if self.contains(".claude.json") {
            return "Claude Code"
        } else if self.contains("/.gemini/") || self.hasSuffix(".gemini.json") {
            return "Gemini CLI"
        }

        // Fallback to filename
        let components = self.split(separator: "/")
        return String(components.last ?? "")
    }
}

// MARK: - Date Extensions

extension Date {
    func timeAgo() -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.second, .minute, .hour, .day], from: self, to: now)

        if let day = components.day, day > 0 {
            return "\(day)d ago"
        } else if let hour = components.hour, hour > 0 {
            return "\(hour)h ago"
        } else if let minute = components.minute, minute > 0 {
            return "\(minute)m ago"
        } else {
            return "just now"
        }
    }
}

// MARK: - View Extensions

#if os(macOS)
extension NSTextField {
    open override var focusRingType: NSFocusRingType {
        get { .none }
        set { }
    }
}

// Window Opacity Modifier
struct WindowOpacityModifier: ViewModifier {
    let opacity: Double

    func body(content: Content) -> some View {
        content
            .background(WindowAccessor(opacity: opacity))
    }
}

struct WindowAccessor: NSViewRepresentable {
    let opacity: Double

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                window.alphaValue = CGFloat(opacity)
                window.isOpaque = opacity >= 1.0
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if let window = nsView.window {
            window.alphaValue = CGFloat(opacity)
            window.isOpaque = opacity >= 1.0
        }
    }
}

extension View {
    func windowOpacity(_ opacity: Double) -> some View {
        modifier(WindowOpacityModifier(opacity: opacity))
    }
}
#endif
