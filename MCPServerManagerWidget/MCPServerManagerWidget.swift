import WidgetKit
import SwiftUI

/// Main entry point for the MCP Server Manager Widget
@main
struct MCPServerManagerWidgetBundle: WidgetBundle {
    var body: some Widget {
        MCPServerManagerWidget()
    }
}

struct MCPServerManagerWidget: Widget {
    let kind: String = "MCPServerManagerWidget"

    var body: some WidgetConfiguration {
        if #available(macOS 14.0, *) {
            return AppIntentConfiguration(
                kind: kind,
                intent: ConfigurationIntent.self,
                provider: WidgetProvider()
            ) { entry in
                MCPWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            }
            .configurationDisplayName("MCP Servers")
            .description("Quick toggle for your MCP servers")
            .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        } else {
            return StaticConfiguration(
                kind: kind,
                provider: WidgetProvider()
            ) { entry in
                MCPWidgetEntryView(entry: entry)
            }
            .configurationDisplayName("MCP Servers")
            .description("Quick toggle for your MCP servers")
            .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        }
    }
}

/// Widget entry containing server data
struct ServerEntry: TimelineEntry {
    let date: Date
    let servers: [WidgetServerModel]
    let configName: String
}

/// Simplified server model for widget display
struct WidgetServerModel: Identifiable {
    let id: UUID
    let name: String
    var isEnabled: Bool
}

/// Configuration intent for macOS 14+
@available(macOS 14.0, *)
struct ConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Configuration"
    static var description: IntentDescription = IntentDescription("Configure the widget")
}
