import SwiftUI
import UniformTypeIdentifiers

struct OnboardingModal: View {
    @ObservedObject var viewModel: ServerViewModel
    @Environment(\.themeColors) private var themeColors

    @State private var selectedPath: String = ""
    @State private var showingFilePicker = false

    var body: some View {
        ZStack {
            // Backdrop
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .blur(radius: 10)

            // Modal
            VStack(spacing: 24) {
                // Welcome
                VStack(spacing: 12) {
                    Text("⚡")
                        .font(DesignTokens.Typography.hero)

                    Text("Welcome to MCP Server Manager")
                        .font(DesignTokens.Typography.title1)

                    Text("Manage your Claude Code MCP servers with ease")
                        .font(DesignTokens.Typography.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                // Info panel
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                            .font(DesignTokens.Typography.title3)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your Claude Code config is typically located at:")
                                .font(DesignTokens.Typography.body)

                            Text("~/.claude.json")
                                .font(DesignTokens.Typography.codeLarge)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.black.opacity(0.3))
                                )

                            Text("If you don't see hidden files, press ⌘⇧. (Command+Shift+Period)")
                                .font(DesignTokens.Typography.bodySmall)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                )

                // Selected file
                if !selectedPath.isEmpty {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)

                        Text(selectedPath)
                            .font(DesignTokens.Typography.body)
                            .lineLimit(1)

                        Spacer()
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.green.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
                            )
                    )
                }

                // Buttons
                VStack(spacing: 12) {
                    Button(action: selectFile) {
                        Text("Select Config File")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(themeColors.accentGradient)
                            )
                            .foregroundColor(themeColors.primaryText)
                    }
                    .buttonStyle(.plain)

                    if !selectedPath.isEmpty {
                        Button(action: {
                            viewModel.completeOnboarding(configPath: selectedPath)
                        }) {
                            Text("Continue")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.green)
                                )
                                .foregroundColor(.white)
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Footer
                Text("This app only reads and writes to your config files. No data is sent anywhere.")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(32)
            .frame(width: 550)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(nsColor: .windowBackgroundColor))
            )
            .shadow(radius: 40)
        }
    }

    private func selectFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [UTType.json]
        panel.showsHiddenFiles = true
        panel.directoryURL = FileManager.default.homeDirectoryForCurrentUser

        if panel.runModal() == .OK, let url = panel.url {
            selectedPath = url.path.replacingOccurrences(of: NSHomeDirectory(), with: "~")
        }
    }
}
