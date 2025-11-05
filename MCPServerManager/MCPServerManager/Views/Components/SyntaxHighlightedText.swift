import SwiftUI

struct SyntaxHighlightedText: View {
    let jsonString: String
    @State private var highlightedText: AttributedString = AttributedString()

    var body: some View {
        Text(highlightedText)
            .font(DesignTokens.Typography.code)
            .frame(maxWidth: .infinity, alignment: .leading)
            .textSelection(.enabled)
            .onAppear {
                highlightedText = highlightJSON(jsonString)
            }
            .onChange(of: jsonString) { newValue in
                highlightedText = highlightJSON(newValue)
            }
    }

    private func highlightJSON(_ text: String) -> AttributedString {
        var attributed = AttributedString(text)

        // Define colors for syntax highlighting
        let keyColor = Color.cyan
        let stringColor = Color(hex: "#98C379") // Green
        let numberColor = Color(hex: "#D19A66") // Orange
        let boolColor = Color(hex: "#C678DD") // Purple
        let nullColor = Color(hex: "#E06C75") // Red
        let bracketColor = Color(hex: "#ABB2BF") // Gray

        // Patterns for different JSON elements
        let patterns: [(String, Color)] = [
            // Keys (strings followed by colon)
            ("\"[^\"]*\"(?=\\s*:)", keyColor),
            // String values (strings not followed by colon)
            (":\\s*\"[^\"]*\"", stringColor),
            // Numbers
            (":\\s*-?\\d+\\.?\\d*", numberColor),
            // Booleans
            ("\\b(true|false)\\b", boolColor),
            // Null
            ("\\bnull\\b", nullColor),
        ]

        for (pattern, color) in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let nsString = text as NSString
                let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))

                for match in matches {
                    if let range = Range(match.range, in: text) {
                        if let attributedRange = Range(range, in: attributed) {
                            attributed[attributedRange].foregroundColor = color
                        }
                    }
                }
            }
        }

        // Color brackets separately
        for (index, character) in text.enumerated() {
            if ["{", "}", "[", "]", ":", ","].contains(character) {
                if let stringIndex = text.index(text.startIndex, offsetBy: index, limitedBy: text.endIndex),
                   let range = Range(stringIndex...stringIndex, in: attributed) {
                    attributed[range].foregroundColor = bracketColor
                }
            }
        }

        return attributed
    }
}
