# MCP Panel - Native macOS Swift

A native macOS application for managing Claude MCP (Model Context Protocol) server configurations. This is a complete Swift rewrite of the original Electron-based MCP Server Manager, designed specifically for macOS with SwiftUI.

## Features

All features from the original Electron app have been preserved:

### Core Functionality
- ✅ **Config Management**: Read and write Claude MCP server configurations (`~/.claude.json`)
- ✅ **Server CRUD**: Add, edit, delete, duplicate, enable/disable servers
- ✅ **Profile System**: Save and load different server configurations
- ✅ **Global Config**: Support for secondary global configuration file
- ✅ **Import/Export**: Import and export configuration files

### UI Features
- ✅ **Multiple View Modes**: Grid, List, and Raw JSON views
- ✅ **Advanced Search**: Fuzzy search across all server fields (ID, command, args, env)
- ✅ **Smart Filtering**: Filter by all/enabled/disabled servers
- ✅ **Live Validation**: Real-time validation of server configurations
- ✅ **Toast Notifications**: User feedback for all operations
- ✅ **Onboarding**: First-run experience for new users

### Technical Features
- ✅ **Auto-save**: Optional automatic saving of changes
- ✅ **Keyboard Shortcuts**: Full keyboard navigation support
- ✅ **Context Menus**: Right-click menus for quick actions
- ✅ **Settings Persistence**: User preferences saved via UserDefaults
- ✅ **Error Handling**: Comprehensive error handling and user feedback

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode 15.0 or later
- Swift 5.9 or later

## Building the App

### Option 1: Using Xcode (Recommended)

1. Open the project:
   ```bash
   cd MCPPanel
   open MCPPanel.xcodeproj
   ```

2. In Xcode:
   - Select the "MCPPanel" scheme
   - Choose "My Mac" as the destination
   - Click the Play button (⌘R) to build and run

### Option 2: Command Line

Build for development:
```bash
cd MCPPanel
xcodebuild -project MCPPanel.xcodeproj -scheme MCPPanel -configuration Debug
```

Build for release:
```bash
xcodebuild -project MCPPanel.xcodeproj -scheme MCPPanel -configuration Release
```

The built app will be located at:
```
build/Release/MCPPanel.app
```

### Option 3: Build Script

Create a simple build script:

```bash
#!/bin/bash
# build.sh

cd MCPPanel
xcodebuild -project MCPPanel.xcodeproj \
           -scheme MCPPanel \
           -configuration Release \
           -derivedDataPath ./build

echo "Build complete! App location:"
echo "./build/Build/Products/Release/MCPPanel.app"
```

Make it executable and run:
```bash
chmod +x build.sh
./build.sh
```

## Installation

After building:

1. Locate the built app at `build/Release/MCPPanel.app`
2. Drag it to your Applications folder
3. Launch from Spotlight or Applications

## Usage

### First Launch

On first launch, the app will show an onboarding screen explaining:
- How to use the app
- Where the configuration files are located
- Key features

### Managing Servers

**Add a new server:**
1. Click the "+" button or press ⌘N
2. Fill in server details:
   - Server ID (unique identifier)
   - Command (executable path or command)
   - Arguments (optional)
   - Environment variables (optional)
   - Always allow tools (optional)
3. Click "Add Server"

**Edit a server:**
- Click the edit (pencil) icon on a server card
- Or right-click and select "Edit"
- Or press Enter when a server is selected

**Delete a server:**
- Click the trash icon
- Or right-click and select "Delete"

**Enable/Disable a server:**
- Click the play/pause icon
- Or right-click and select "Enable/Disable"

### View Modes

Switch between view modes using the segmented control in the header:

- **Grid View**: Card-based layout showing server details
- **List View**: Compact list layout
- **Raw JSON**: Edit the configuration as JSON directly

### Search and Filter

**Search:**
- Click the search field or press ⌘F
- Type to search across server IDs, commands, args, and environment variables
- Clear with ⌘⇧K

**Filter:**
- Use the sidebar to filter by:
  - All Servers
  - Enabled Only
  - Disabled Only

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| ⌘N | New Server |
| ⌘R | Reload Config |
| ⌘F | Focus Search |
| ⌘⇧K | Clear Search |
| ⌘⇧I | Import Config |
| ⌘⇧E | Export Config |
| ⌘⇧T | Toggle View Mode |
| ⌘, | Settings |

### Settings

Access settings via ⌘, or the menu bar:

**General:**
- Set Claude config path (default: `~/.claude.json`)
- Set global config path (optional)
- Enable/disable auto-save

**Search:**
- Enable/disable fuzzy search
- View search scope information

## Configuration Files

### Default Paths

- **Claude Config**: `~/.claude.json`
- **Global Config**: `~/.claude-global.json` (optional)
- **Profiles**: `~/.mcp-manager/profiles/`
- **App Settings**: Stored in macOS UserDefaults

### Config File Format

The app reads and writes standard Claude MCP configuration files:

```json
{
  "mcpServers": {
    "server-name": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-example"],
      "env": {
        "ENV_VAR": "value"
      },
      "disabled": false,
      "alwaysAllow": ["tool1", "tool2"]
    }
  }
}
```

## Architecture

The app is structured in layers:

### Models
- `ServerConfig.swift` - Server configuration data model
- `Settings.swift` - App settings and preferences
- `Profile.swift` - Profile data model
- `AppState.swift` - Main app state management (Observable)

### Services
- `FileSystemService.swift` - File I/O operations
- `ConfigService.swift` - Configuration management (Actor)
- `ValidationService.swift` - Server validation logic
- `SearchService.swift` - Fuzzy search implementation

### Views
- `ContentView.swift` - Main app container
- `ServerListView.swift` - List and grid views
- `ServerFormView.swift` - Add/edit server modal
- `SettingsView.swift` - Settings modal
- `OnboardingView.swift` - First-run experience
- `RawJsonView.swift` - JSON editor

## Comparison with Electron Version

| Feature | Electron | Swift Native |
|---------|----------|--------------|
| App Size | ~200 MB | ~5 MB |
| Memory Usage | ~150 MB | ~30 MB |
| Launch Time | 2-3 sec | <1 sec |
| Native Feel | ⚠️ | ✅ |
| macOS Integration | ⚠️ | ✅ |
| Energy Efficiency | ⚠️ | ✅ |
| All Features | ✅ | ✅ |

## Development

### Project Structure

```
MCPPanel/
├── MCPPanel.xcodeproj/        # Xcode project file
└── MCPPanel/
    ├── App/
    │   ├── MCPPanelApp.swift  # App entry point
    │   ├── Info.plist         # App metadata
    │   └── MCPPanel.entitlements
    ├── Models/                # Data models
    ├── Services/              # Business logic
    ├── Views/                 # SwiftUI views
    └── Resources/             # Assets
```

### Key Design Decisions

1. **SwiftUI**: Modern declarative UI framework
2. **Actor-based Config Service**: Thread-safe configuration management
3. **ObservableObject App State**: Centralized state management
4. **UserDefaults**: Persistent settings storage
5. **No third-party dependencies**: Pure Swift/SwiftUI implementation

### Adding New Features

1. **Models**: Add data structures in `Models/`
2. **Services**: Add business logic in `Services/`
3. **Views**: Create SwiftUI views in `Views/`
4. **State**: Update `AppState.swift` for new state

## Troubleshooting

### Build Issues

**"Command line tools not found":**
```bash
xcode-select --install
```

**"Signing certificate not found":**
- In Xcode, go to Signing & Capabilities
- Set Team to "None" or your Apple Developer account

### Runtime Issues

**"App is damaged and can't be opened":**
```bash
xattr -cr /path/to/MCPPanel.app
```

**Config file not loading:**
- Check Settings to verify config path
- Ensure file exists and is valid JSON
- Check file permissions

**App crashes on launch:**
- Check Console.app for crash logs
- Verify macOS version (13.0+)
- Try deleting app preferences:
  ```bash
  defaults delete com.mcppanel.app
  ```

## Contributing

This is a native macOS Swift rewrite. To contribute:

1. Ensure all existing features remain functional
2. Follow Swift/SwiftUI best practices
3. Test on multiple macOS versions (13.0+)
4. Update this README for new features

## Migration from Electron Version

The Swift version uses the same configuration file format, so no migration is needed. Simply:

1. Build and install the Swift app
2. Launch it - it will read your existing `~/.claude.json`
3. All your servers will appear immediately

You can use both versions side-by-side as they share the same config file.

## License

Same license as the original Electron-based MCP Server Manager.

## Acknowledgments

Native Swift rewrite of the Electron-based MCP Server Manager, preserving all functionality while providing a native macOS experience.
