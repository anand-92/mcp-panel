import SwiftUI
import UniformTypeIdentifiers

struct QuickActionsMenu: View {
    @ObservedObject var viewModel: ServerViewModel
    @Binding var showAddServer: Bool
    @Binding var showImporter: Bool
    @Binding var showExporter: Bool
    @Binding var isExpanded: Bool
    @Environment(\.themeColors) private var themeColors

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Explore New MCPs
            QuickActionButton(
                icon: "star.fill",
                title: "Explore New MCPs",
                color: themeColors.secondaryAccent,
                action: {
                    openRegistry()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isExpanded = false
                    }
                }
            )

            // New Server
            QuickActionButton(
                icon: "plus.circle.fill",
                title: "New Server",
                color: themeColors.successColor,
                action: {
                    showAddServer = true
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isExpanded = false
                    }
                }
            )

            // Import JSON
            QuickActionButton(
                icon: "arrow.down.doc.fill",
                title: "Import JSON",
                color: themeColors.primaryAccent,
                action: {
                    showImporter = true
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isExpanded = false
                    }
                }
            )

            // Export JSON
            QuickActionButton(
                icon: "arrow.up.doc.fill",
                title: "Export JSON",
                color: themeColors.warningColor,
                action: {
                    showExporter = true
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isExpanded = false
                    }
                }
            )
        }
        .frame(width: 220, alignment: .leading)
        .padding(.top, 60)
        .padding(.leading, 14)
    }

    private func openRegistry() {
        if let url = URL(string: AppConstants.mcpRegistryURL) {
            NSWorkspace.shared.open(url)
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    @Environment(\.themeColors) private var themeColors

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(color)
                            .shadow(color: color.opacity(0.4), radius: 8, x: 0, y: 4)
                    )

                Text(title)
                    .font(DesignTokens.Typography.label)
                    .foregroundColor(themeColors.primaryText)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
        }
        .buttonStyle(.plain)
    }
}
