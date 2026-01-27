import AppIntents
import WidgetKit

/// App Intent for toggling server state from the widget (macOS 14+)
@available(macOS 14.0, *)
struct ServerToggleIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle MCP Server"
    static var description: IntentDescription = IntentDescription("Toggle an MCP server on or off")

    @Parameter(title: "Server ID")
    var serverID: String

    @Parameter(title: "New State")
    var newState: Bool

    init() {
        self.serverID = ""
        self.newState = false
    }

    init(serverID: String, newState: Bool) {
        self.serverID = serverID
        self.newState = newState
    }

    func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: serverID) else {
            return .result()
        }

        // Update the server state in shared storage
        updateServerState(serverID: uuid, newState: newState)

        // Post notification to main app
        postNotificationToMainApp(serverID: uuid, newState: newState)

        // Reload widget timeline
        WidgetCenter.shared.reloadAllTimelines()

        return .result()
    }

    // MARK: - Private Helpers

    private let suiteName = "group.com.anand-92.mcp-panel"
    private let widgetServersKey = "widgetServers"

    private func updateServerState(serverID: UUID, newState: Bool) {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let data = defaults.data(forKey: widgetServersKey) else {
            return
        }

        do {
            var servers = try JSONDecoder().decode([SharedWidgetServerForIntent].self, from: data)

            if let index = servers.firstIndex(where: { $0.id == serverID }) {
                servers[index].isEnabled = newState
                let updatedData = try JSONEncoder().encode(servers)
                defaults.set(updatedData, forKey: widgetServersKey)
                defaults.synchronize()
            }
        } catch {
            // Failed to update, ignore silently
        }
    }

    private func postNotificationToMainApp(serverID: UUID, newState: Bool) {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return }

        // Store pending toggle in shared UserDefaults (sandboxed apps can't pass userInfo)
        let pendingToggle: [String: Any] = [
            "serverID": serverID.uuidString,
            "newState": newState,
            "timestamp": Date().timeIntervalSince1970
        ]
        defaults.set(pendingToggle, forKey: "pendingServerToggle")
        defaults.synchronize()

        // Post notification WITHOUT userInfo (sandboxed apps can't receive it)
        DistributedNotificationCenter.default().postNotificationName(
            NSNotification.Name("MCPServerToggled"),
            object: nil,
            userInfo: nil,
            deliverImmediately: true
        )
    }
}

/// Shared widget server model for intent (must match SharedDataManager.WidgetServer)
@available(macOS 14.0, *)
private struct SharedWidgetServerForIntent: Codable, Identifiable {
    let id: UUID
    let name: String
    var isEnabled: Bool
    let configIndex: Int
}
