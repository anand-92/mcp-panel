import SwiftUI

/// A miniature server card rendered with the pending appearance settings, so glass,
/// transparency, and density sliders show their effect without closing Settings.
///
/// Sits on a checkerboard so translucency is actually visible: against an opaque
/// backdrop, a glass panel and a solid panel look nearly identical.
struct AppearancePreviewCard: View {
    let appearance: AppearanceSettings

    @Environment(\.themeColors) private var themeColors

    var body: some View {
        ZStack {
            CheckerboardBackground()

            card
                .padding(14)
        }
        .frame(height: 132)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(themeColors.borderColor, lineWidth: 1)
        )
        .accessibilityHidden(true)
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text("context7")
                    .font(DesignTokens.Typography.label)
                    .foregroundStyle(themeColors.primaryText)

                Spacer()

                Circle()
                    .fill(themeColors.successColor)
                    .frame(width: 7, height: 7)
            }

            Text("npx -y @upstash/context7-mcp")
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(themeColors.secondaryText)
                .lineLimit(1)

            Text("\"command\": \"npx\"")
                .font(DesignTokens.Typography.codeSmall)
                .foregroundStyle(themeColors.primaryAccent)
                .lineLimit(1)
                .padding(6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(surfaceFill)
                )
        }
        .padding(appearance.cardPadding)
        .frame(maxWidth: .infinity)
        // The preview must react to the *pending* settings, so it overrides the
        // environment its own glass modifier reads.
        .liquidGlass(shape: RoundedRectangle(cornerRadius: appearance.cornerRadius), interactive: false)
        .environment(\.appearance, appearance)
    }

    private var surfaceFill: Color {
        appearance.isGlassEnabled
            ? appearance.surface(themeColors.mainBackground)
            : themeColors.panelBackground
    }
}

// MARK: - Checkerboard

/// Alternating light/dark squares, the conventional way to show transparency.
private struct CheckerboardBackground: View {
    private let squareSize: CGFloat = 11

    var body: some View {
        Canvas { context, size in
            let columns = Int(size.width / squareSize) + 1
            let rows = Int(size.height / squareSize) + 1

            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.white.opacity(0.16)))

            for row in 0..<rows {
                for column in 0..<columns where (row + column).isMultiple(of: 2) {
                    let rect = CGRect(
                        x: CGFloat(column) * squareSize,
                        y: CGFloat(row) * squareSize,
                        width: squareSize,
                        height: squareSize
                    )
                    context.fill(Path(rect), with: .color(.black.opacity(0.28)))
                }
            }
        }
        .drawingGroup()
    }
}
