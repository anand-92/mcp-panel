import WidgetKit
import SwiftUI

/// Timeline provider for the MCP Server Manager Widget
struct WidgetProvider: TimelineProvider {
    typealias Entry = ServerEntry

    /// App Group identifier for accessing shared data
    private let suiteName = "group.com.anand-92.mcp-panel"
    private let widgetServersKey = "widgetServers"
    private let currentThemeKey = "currentTheme"

    func placeholder(in context: Context) -> ServerEntry {
        ServerEntry(
            date: Date(),
            servers: [
                WidgetServerModel(id: UUID(), name: "example-server", isEnabled: true),
                WidgetServerModel(id: UUID(), name: "another-server", isEnabled: false)
            ],
            configName: "Claude",
            themeName: "claudeCode"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ServerEntry) -> Void) {
        let entry = createEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ServerEntry>) -> Void) {
        let entry = createEntry()

        // Refresh every 15 minutes or when data changes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func createEntry() -> ServerEntry {
        let servers = loadWidgetServers()
        let configName = servers.first.map { $0.configIndex == 0 ? "Claude" : "Gemini" } ?? "Claude"
        let themeName = loadTheme()

        return ServerEntry(
            date: Date(),
            servers: servers.map { WidgetServerModel(id: $0.id, name: $0.name, isEnabled: $0.isEnabled) },
            configName: configName,
            themeName: themeName
        )
    }

    private func loadTheme() -> String {
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            return "claudeCode"
        }
        return defaults.string(forKey: currentThemeKey) ?? "claudeCode"
    }

    private func loadWidgetServers() -> [SharedWidgetServer] {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let data = defaults.data(forKey: widgetServersKey) else {
            return []
        }

        do {
            return try JSONDecoder().decode([SharedWidgetServer].self, from: data)
        } catch {
            return []
        }
    }
}

/// Shared widget server model (must match SharedDataManager.WidgetServer)
struct SharedWidgetServer: Codable, Identifiable {
    let id: UUID
    let name: String
    var isEnabled: Bool
    let configIndex: Int
}

