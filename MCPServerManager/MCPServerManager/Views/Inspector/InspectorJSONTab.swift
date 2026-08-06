import SwiftUI

/// Full-height JSON editor for the selected server, editing the named entry so the
/// top-level key can be renamed (same contract as the inline card editor).
struct InspectorJSONTab: View {
    let server: ServerModel
    @Binding var text: String
    @Binding var isDirty: Bool
    let onSave: () -> Void
    let onRevert: () -> Void

    @Environment(\.themeColors) private var themeColors
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        VStack(spacing: 0) {
            JSONCodeEditor(
                text: $text,
                themeColors: themeColors,
                reduceTransparency: reduceTransparency
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(themeColors.borderColor, lineWidth: 1)
            )
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .frame(maxHeight: .infinity)

            HStack(spacing: 8) {
                EditorButton(
                    title: "Format",
                    icon: "text.alignleft",
                    style: .secondary,
                    themeColors: themeColors,
                    action: { text = JSONFormatter.prettyPrinted(text) ?? text }
                )

                if isDirty {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(themeColors.warningColor)
                            .frame(width: 7, height: 7)
                        Text("Unsaved edits")
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(themeColors.warningColor)
                    }
                    .padding(.leading, 4)
                }

                Spacer()

                EditorButton(
                    title: "Revert",
                    style: .secondary,
                    themeColors: themeColors,
                    isEnabled: isDirty,
                    action: onRevert
                )

                EditorButton(
                    title: "Save",
                    icon: "checkmark",
                    style: .primary,
                    themeColors: themeColors,
                    isEnabled: isDirty,
                    action: onSave
                )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .onChange(of: text) { newValue in
            isDirty = newValue != server.namedConfigJSON
        }
    }
}
