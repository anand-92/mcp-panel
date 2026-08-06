import SwiftUI
import UniformTypeIdentifiers

struct OnboardingModal: View {
    @ObservedObject var viewModel: ServerViewModel
    @Environment(\.themeColors) private var themeColors

    @State private var selectedPath: String = ""
    @State private var showBookmarkAlert: Bool = false
    @State private var bookmarkAlertMessage: String = ""
    @State private var selectionError: String = ""

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

                    Text("Welcome to MCP Panel")
                        .font(DesignTokens.Typography.title1)

                    Text("Manage MCP servers for Claude Code, Factory Droid, and compatible apps")
                        .font(DesignTokens.Typography.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                // Info panel
                VStack(spacing: 12) {
                    Text("Choose the configuration you want MCP Panel to manage:")
                        .font(DesignTokens.Typography.body)
                        .multilineTextAlignment(.center)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Claude Code: ~/.claude.json")
                        Text("Standard MCP: folder containing mcp.json")
                    }
                    .font(DesignTokens.Typography.codeLarge)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.black.opacity(0.3))
                        )

                    Text("If you don't see hidden files, press ⌘⇧. (Command+Shift+Period)")
                        .font(DesignTokens.Typography.bodySmall)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
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
                            .foregroundStyle(.green)

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

                if !selectionError.isEmpty {
                    Text(selectionError)
                        .font(DesignTokens.Typography.bodySmall)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                // Buttons
                VStack(spacing: 12) {
                    Button(action: selectFile) {
                        Text("Select Claude Code Config File")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(themeColors.accentGradient)
                            )
                            .foregroundStyle(Color(hex: "#0b0e14"))
                    }
                    .buttonStyle(.plain)

                    Button(action: selectMCPConfigFolder) {
                        Text("Select mcp.json Folder")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(themeColors.accentGradient)
                            )
                            .foregroundStyle(Color(hex: "#0b0e14"))
                    }
                    .buttonStyle(.plain)

                    if !selectedPath.isEmpty {
                        Button(action: {
                            viewModel.completeOnboarding(configPath: selectedPath)
                        }, label: {
                            Text("Continue")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.green)
                                )
                                .foregroundStyle(.white)
                        })
                        .buttonStyle(.plain)
                    }
                }

                // Footer
                Text("This app only reads and writes to your config files. No data is sent anywhere.")
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(32)
            .frame(width: 550)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(nsColor: .windowBackgroundColor))
            )
            .themedShadow(radius: 40)
        }
        .alert("Bookmark Storage Failed", isPresented: $showBookmarkAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(bookmarkAlertMessage)
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
        panel.message = "Select your Claude Code config file (usually ~/.claude.json)"

        if panel.runModal() == .OK, let url = panel.url {
            do {
                try ConfigManager.shared.storeBookmarkForConfigFile(url: url, path: url.path)
                selectedPath = url.path.replacingOccurrences(of: NSHomeDirectory(), with: "~")
                selectionError = ""
            } catch {
                bookmarkAlertMessage = """
                    Failed to create persistent access to the selected file. \
                    The app may not be able to access this file after restart.

                    Error: \(error.localizedDescription)

                    Please try selecting the file again.
                    """
                showBookmarkAlert = true
            }
        }
    }

    private func selectMCPConfigFolder() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.showsHiddenFiles = true
        panel.directoryURL = FileManager.default.homeDirectoryForCurrentUser
        panel.message = "Select the folder containing mcp.json"

        guard panel.runModal() == .OK, let directoryURL = panel.url else { return }

        let configURL = directoryURL.appendingPathComponent("mcp.json")
        guard FileManager.default.fileExists(atPath: configURL.path) else {
            selectionError = "The selected folder does not contain an mcp.json file."
            return
        }

        do {
            try ConfigManager.shared.storeBookmarkForConfigDirectory(
                url: directoryURL,
                configPath: configURL.path
            )
            selectedPath = configURL.path.replacingOccurrences(of: NSHomeDirectory(), with: "~")
            selectionError = ""
        } catch {
            bookmarkAlertMessage = """
                Failed to create persistent access to the selected folder. \
                The app may not be able to access mcp.json after restart.

                Error: \(error.localizedDescription)

                Please try selecting the folder again.
                """
            showBookmarkAlert = true
        }
    }
}
