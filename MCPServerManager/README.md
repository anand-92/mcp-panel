# MCP Server Manager - Swift Edition

A native macOS application for managing Claude Code and Gemini CLI MCP server configurations, built with SwiftUI.

## Features

- **Dual Config Management**: Manage two separate config files simultaneously
- **Server CRUD Operations**: Add, edit, delete, and toggle MCP servers
- **Multiple View Modes**: Grid view and raw JSON editor
- **Search & Filtering**: Real-time fuzzy search and filter by status
- **Import/Export**: Bulk import/export server configurations
- **Cyberpunk Mode**: Optional neon-themed UI
- **Native macOS**: Built with SwiftUI for optimal performance

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode 15.0 or later (for building from source)
- Swift 5.9 or later

## Building from Source

### Using Xcode

1. Open Terminal and navigate to the MCPServerManager directory
2. Generate an Xcode project:
   ```bash
   swift package generate-xcodeproj
   ```
3. Open `MCPServerManager.xcodeproj` in Xcode
4. Select the "MCPServerManager" scheme
5. Build and run (⌘R)

### Using Swift Package Manager

Build from the command line:
```bash
cd MCPServerManager
swift build -c release
```

Run the app:
```bash
swift run
```

## Project Structure

```
MCPServerManager/
├── MCPServerManager/
│   ├── MCPServerManagerApp.swift      # App entry point
│   ├── Models/                        # Data models
│   │   ├── ServerConfig.swift
│   │   ├── ServerModel.swift
│   │   └── Settings.swift
│   ├── ViewModels/                    # Business logic
│   │   └── ServerViewModel.swift
│   ├── Views/                         # UI components
│   │   ├── ContentView.swift          # Main view
│   │   ├── HeaderView.swift
│   │   ├── SidebarView.swift
│   │   ├── ServerGridView.swift
│   │   ├── ServerCardView.swift
│   │   ├── Components/
│   │   │   ├── GlassPanel.swift
│   │   │   ├── CustomToggleSwitch.swift
│   │   │   ├── ToastView.swift
│   │   │   └── ToolbarView.swift
│   │   └── Modals/
│   │       ├── AddServerModal.swift
│   │       ├── SettingsModal.swift
│   │       └── OnboardingModal.swift
│   ├── Services/                      # File I/O and config management
│   │   └── ConfigManager.swift
│   └── Utilities/                     # Helpers and extensions
│       ├── Constants.swift
│       └── Extensions.swift
└── Package.swift
```

## Usage

### First Launch

1. On first launch, you'll see the onboarding screen
2. Click "Select Config File" and navigate to your `~/.claude.json` file
3. Press ⌘⇧. (Command+Shift+Period) to show hidden files if needed
4. Click "Continue" to start using the app

### Managing Servers

- **Add Server**: Click "New Server" in the sidebar or press ⌘N
- **Edit Server**: Hover over a server card and click the edit button
- **Delete Server**: Click the trash icon on any server card
- **Toggle Server**: Use the switch on each card to enable/disable for the active config
- **Toggle All**: Use the "Enable/Disable All" button in the toolbar

### Config Switching

- Click the config buttons (1 or 2) in the header to switch between configs
- Each server card shows badges indicating which configs include it

### Search & Filter

- Press ⌘F to focus the search bar
- Type to search server names and configurations
- Use the filter dropdown to show:
  - All Servers
  - Active Only (enabled in current config)
  - Disabled Only (not in current config)
  - Recently Modified

### Import/Export

- **Import**: Click "Import JSON" in the sidebar to import server definitions
- **Export**: Click "Export JSON" to download the current config

### Settings

- Click the gear icon in the header to open settings
- Configure config file paths
- Toggle confirmation dialogs
- Enable Cyberpunk Mode for extra neon flair
- Test config file connections

## Keyboard Shortcuts

- **⌘N**: New server
- **⌘F**: Focus search
- **⌘R**: Refresh from config files
- **⌘S**: Manual save (auto-saves by default)
- **Escape**: Close modals

## Design Philosophy

The Swift version maintains the same glassmorphic design aesthetic as the original Electron app:

- **Dark Theme**: Deep blue/purple gradients
- **Glass Panels**: Frosted glass effect with subtle borders
- **Smooth Animations**: Spring-based transitions
- **Cyberpunk Mode**: Optional neon cyan accents and enhanced glow effects

## Improvements Over Electron Version

1. **Native Performance**: No Electron overhead, faster startup and lower memory usage
2. **macOS Integration**: Native file pickers, keyboard shortcuts, and window management
3. **Better Memory Management**: Swift's ARC for efficient resource usage
4. **Type Safety**: SwiftUI and Swift's type system prevent many runtime errors
5. **Smaller Bundle Size**: Native binary vs. Electron + Chromium

## Configuration Format

The app manages `.claude.json` files with the following structure:

```json
{
  "mcpServers": {
    "server-name": {
      "command": "node",
      "args": ["path/to/server.js"],
      "env": {
        "API_KEY": "your-key"
      }
    }
  }
}
```

Supports both stdio and HTTP transport types.

## Troubleshooting

### Can't see hidden files in file picker
- Press ⌘⇧. (Command+Shift+Period) to toggle hidden file visibility

### Config file not loading
- Check that the file path is correct in Settings
- Use the "Test Connection" button to verify
- Ensure the file has valid JSON syntax

### Servers not saving
- Check file permissions on your config file
- Make sure the config path exists
- Review Console.app for error messages

## License

MIT License - see the root project LICENSE file

## Contributing

This is a Swift reimplementation of the original Electron-based MCP Server Manager. Both versions share the same functionality and design principles.

## Credits

Built with SwiftUI for macOS
Icon design: MCP logo with gradients
Original concept: Electron version by Nikhil Anand
