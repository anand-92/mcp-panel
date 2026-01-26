# MCP Server Manager Widget

macOS WidgetKit extension for quick MCP server toggling.

## Setup Instructions

Since Swift Package Manager doesn't natively support App Extensions, this widget needs to be added as a separate Xcode target.

### Option A: Add Widget Target to Existing Project

1. Open the project in Xcode
2. File → New → Target → Widget Extension
3. Name it `MCPServerManagerWidget`
4. Bundle ID: `com.anand-92.mcp-panel.widget`
5. Replace generated files with files from this directory

### Option B: Create Separate Xcode Project

1. Create a new Xcode project for the widget
2. Add files from this directory
3. Configure App Groups: `group.com.anand-92.mcp-panel`
4. Embed widget in main app bundle

## App Groups Configuration

Both the main app and widget must be configured with the same App Group:

**App Group ID:** `group.com.anand-92.mcp-panel`

### Main App Entitlements

Add to `MCPServerManager.entitlements`:
```xml
<key>com.apple.security.application-groups</key>
<array>
    <string>group.com.anand-92.mcp-panel</string>
</array>
```

### Widget Entitlements

The widget entitlements are already configured in `MCPServerManagerWidget.entitlements`.

## Features

- **Small Widget:** 2 servers, vertical list
- **Medium Widget:** 4 servers, 2-column grid
- **Large Widget:** 8 servers, 2-column grid
- **Interactive Toggles:** macOS 14+ only (uses App Intents)
- **Cross-process sync:** Uses DistributedNotificationCenter

## Requirements

- macOS 13.0+ for basic widget display
- macOS 14.0+ for interactive toggles (Button/Toggle with App Intents)

## Files

| File | Purpose |
|------|---------|
| `MCPServerManagerWidget.swift` | Widget entry point and configuration |
| `WidgetProvider.swift` | Timeline provider for widget data |
| `WidgetViews.swift` | SwiftUI views for all widget sizes |
| `ServerToggleIntent.swift` | App Intent for interactive toggles (macOS 14+) |
| `Info.plist` | Widget extension metadata |
| `MCPServerManagerWidget.entitlements` | App Groups entitlements |

## Data Flow

```
Main App                          Widget
   │                                 │
   ├── ServerViewModel ──────────────┤
   │   toggleShowInWidget()          │
   │         │                       │
   │         ▼                       │
   │   syncToWidget() ───────────────┤
   │         │                       │
   │         ▼                       │
   │   SharedDataManager ────────────┤
   │   (App Groups UserDefaults)     │
   │                                 │
   │         ◄──────────────── WidgetProvider
   │                          loadWidgetServers()
   │                                 │
   │         ◄──────────────── ServerToggleIntent
   │   (DistributedNotification)     │ (macOS 14+)
   │                                 │
   └─────────────────────────────────┘
```
