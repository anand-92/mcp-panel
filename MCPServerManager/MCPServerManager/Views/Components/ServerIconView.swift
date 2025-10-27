import SwiftUI
import AppKit

/// Circular avatar icon for server cards
struct ServerIconView: View {
    let server: ServerModel
    let size: CGFloat

    @State private var logoImage: NSImage?
    @State private var isLoading = true
    @Environment(\.themeColors) private var themeColors

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            themeColors.glassBackground.opacity(0.6),
                            themeColors.glassBackground.opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    Circle()
                        .stroke(themeColors.borderColor.opacity(0.3), lineWidth: 1)
                )

            // Icon content
            if let logoImage = logoImage {
                // Show fetched logo
                Image(nsImage: logoImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size * 0.6, height: size * 0.6)
                    .clipShape(Circle())
            } else if isLoading {
                // Show loading indicator
                ProgressView()
                    .scaleEffect(0.5)
                    .frame(width: size * 0.6, height: size * 0.6)
            } else {
                // Show SF Symbol fallback
                Image(systemName: IconService.shared.getFallbackSymbol(for: server.name))
                    .font(.system(size: size * 0.4))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                themeColors.primaryAccent,
                                themeColors.secondaryAccent
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        }
        .frame(width: size, height: size)
        .shadow(color: themeColors.primaryAccent.opacity(0.2), radius: 4, x: 0, y: 2)
        .task {
            await loadIcon()
        }
    }

    private func loadIcon() async {
        isLoading = true

        // Prefer registry image URL over fetched icons
        if let registryImageUrl = server.registryImageUrl,
           let url = URL(string: registryImageUrl) {
            #if DEBUG
            print("ServerIconView: Loading registry image for \(server.name): \(registryImageUrl)")
            #endif

            // Try to load image from registry URL
            if let (data, _) = try? await URLSession.shared.data(from: url),
               let image = NSImage(data: data) {
                logoImage = image
                isLoading = false
                return
            }

            #if DEBUG
            print("ServerIconView: Failed to load registry image, falling back to IconService")
            #endif
        }

        // Fall back to IconService if no registry image or if loading failed
        logoImage = await IconService.shared.loadIcon(for: server.name, domain: server.iconDomain)
        isLoading = false
    }
}

/// Preview helper
#if DEBUG
struct ServerIconView_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: 20) {
            ServerIconView(
                server: ServerModel(
                    name: "GitHub MCP",
                    config: ServerConfig(command: "npx", args: ["@modelcontextprotocol/server-github"])
                ),
                size: 40
            )

            ServerIconView(
                server: ServerModel(
                    name: "Chrome DevTools",
                    config: ServerConfig(command: "npx", args: ["mcp-server-chrome"])
                ),
                size: 40
            )

            ServerIconView(
                server: ServerModel(
                    name: "Unknown Server",
                    config: ServerConfig(command: "some-command")
                ),
                size: 40
            )
        }
        .padding()
        .background(Color.black)
    }
}
#endif
