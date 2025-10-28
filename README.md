<div align="center">

<img src="app-icon.png" width="128" height="128" alt="MCP Server Manager Icon"/>

# MCP Server Manager

[![Download Latest DMG](https://img.shields.io/badge/Download-Latest%20DMG-blue?style=for-the-badge&logo=apple)](https://github.com/anand-92/mcp-panel/releases/latest)
[![GitHub release (latest by date)](https://img.shields.io/github/v/release/anand-92/mcp-panel?style=for-the-badge)](https://github.com/anand-92/mcp-panel/releases/latest)
[![Build Status](https://img.shields.io/github/actions/workflow/status/anand-92/mcp-panel/build-dmg.yml?branch=main&style=for-the-badge)](https://github.com/anand-92/mcp-panel/actions)

**[⬇️ Download MCP Server Manager for macOS](https://apps.apple.com/us/app/mcp-server-manager/id6753700883?mt=12)**

A native macOS application for managing Claude Code and Gemini CLI MCP server configurations, built with SwiftUI.

</div>

## ⚡ Features

- **🎯 MCP Registry Browser**: Browse and install servers from the official MCP registry with one click
- **📁 Dual Config Management**: Manage two separate config files simultaneously (perfect for Claude Code + Gemini CLI)
- **🎨 Adaptive Themes**: Three beautiful themes that auto-switch based on your config (Claude Code, Gemini CLI, or Default)
- **🖼️ Server Logos**: Automatically fetches and displays server icons from the web
- **⚡ Quick Actions Menu**: Fast access to common tasks - explore registry, add servers, import/export
- **✏️ Multiple View Modes**: Grid view with cards or raw JSON editor for power users
- **🔍 Search & Filtering**: Real-time search and filter by status (all/active/disabled/recent)
- **💾 Import/Export**: Bulk import/export server configurations
- **🪟 Window Transparency**: Adjustable window opacity with independent text visibility control
- **🔄 Auto-Updates**: Automatic updates for DMG builds (via Sparkle framework)
- **⚙️ Full Server Management**: Add, edit, delete, and toggle MCP servers with ease
- **⌨️ Keyboard Shortcuts**: Quick access to common actions
- **🚀 Native macOS**: Built with SwiftUI for optimal performance and battery life

## 📋 Requirements

- **macOS 13.0 (Ventura) or later**
- Xcode 15.0+ (for building from source)
- Swift 5.9+

## 🚀 Quick Start

### Install from App Store (Recommended)

Download from the [Mac App Store](https://apps.apple.com/us/app/mcp-server-manager/id6753700883?mt=12)

### Download DMG

Download the latest DMG from [GitHub Releases](https://github.com/anand-92/mcp-panel/releases/latest)

### Build from Source

#### Development Build

For local development and testing:

```bash
cd MCPServerManager
swift run                      # Run in development mode
swift build -c release         # Build release binary
```

#### Distribution Builds

The app supports two distribution methods:

**1️⃣ Mac App Store (recommended for public distribution)**

```bash
./build-appstore.sh
```

Creates a signed PKG file at `MCPServerManager/build-appstore/MCPServerManager-v2.0.0.pkg` ready for upload via Transporter.

Requirements:
- "3rd Party Mac Developer Application" certificate
- "3rd Party Mac Developer Installer" certificate
- `embedded.provisionprofile` in project root

[See detailed instructions →](DISTRIBUTION.md)

**2️⃣ Developer ID (for direct download/GitHub releases)**

Automated via GitHub Actions on push to main/swifty branches. Creates signed and notarized DMG files.

Manual build:
```bash
./build-and-sign-local.sh
```

#### Using Xcode

1. Generate Xcode project:
   ```bash
   cd MCPServerManager
   swift package generate-xcodeproj
   open MCPServerManager.xcodeproj
   ```

2. Product → Archive → Distribute App

## 📖 Usage

### First Launch

1. On first launch, you'll see the onboarding screen
2. Click "Select Config File" and navigate to your `~/.claude.json` file
3. Press **⌘⇧.** (Command+Shift+Period) to show hidden files if needed
4. Click "Continue" to start using the app

### MCP Registry Browser

1. Click the **Quick Actions** button (starburst icon) or click **"New Server"**
2. Switch to **"Browse Registry"** tab
3. Search or browse official MCP servers
4. Click on any server to view details and auto-populate the configuration
5. Click **"Add Server"** to install

### Managing Servers

- **Add Server**: Click "New Server" or press **⌘N**, then paste JSON or browse the registry
- **Edit Server**: Hover over a server card and click the edit button
- **Delete Server**: Click the trash icon on any server card (confirmation optional in settings)
- **Toggle Server**: Use the switch on each card to enable/disable for the active config
- **Toggle All**: Use the "Enable/Disable All" button in the toolbar

### Config Switching

- Click the config buttons (**1** or **2**) in the header to switch between configs
- Each server card shows badges indicating which configs include it (green badges with numbers)
- Perfect for managing Claude Code and Gemini CLI separately

### Search & Filter

- Click the search bar in the header to search
- Type to search server names and configurations in real-time
- Use the filter pills in the toolbar to show:
  - **All Servers**: Show everything
  - **Active Only**: Enabled in current config
  - **Disabled Only**: Not in current config
  - **Recently Modified**: Servers changed in the last 7 days

### View Modes

Toggle between two view modes using the picker in the toolbar:
- **Grid View**: Card-based layout with full server details and logos
- **Raw JSON**: Direct JSON editor for advanced users with syntax highlighting

### Import/Export

- **Import**: Click the Quick Actions button → "Import JSON" to bulk import server definitions
- **Export**: Click the Quick Actions button → "Export JSON" to download the current config as JSON

### Quick Actions Menu

Click the **Quick Actions** button (top-left starburst icon) for fast access to:
- **Explore New MCPs**: Opens the MCP Registry website
- **New Server**: Add a new server manually or from registry
- **Import JSON**: Bulk import server configurations
- **Export JSON**: Export all servers to a file

### Settings

Click the gear icon ⚙️ in the header to configure:
- **Config File Paths**: Set paths for Config 1 and Config 2 (with file browser)
- **Window Opacity**: Adjust window transparency (30%-100%)
- **Text Visibility Boost**: Control text brightness when window is translucent (0%-100%)
- **Confirm Delete**: Toggle delete confirmation dialogs
- **Fetch Server Logos**: Enable/disable automatic icon downloads
- **Test Connection**: Verify config file accessibility and see server count

## ⌨️ Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| **⌘N** | New server |
| **⌘R** | Refresh from config files |
| **⌘U** | Check for updates (DMG builds only) |

## 🎨 Design Philosophy

Native SwiftUI design with glassmorphic aesthetics:

- **Adaptive Themes**: Three beautiful themes that auto-switch based on your active config
  - **Claude Code Theme**: Dark with warm orange/cream accents
  - **Gemini CLI Theme**: Pitch black with vibrant blue/purple/cyan gradients (Ayu Dark inspired)
  - **Default Theme**: Deep blue with cyan/purple gradients (Cyberpunk style)
- **Glass Panels**: Frosted glass effect with subtle borders and blur
- **Window Transparency**: Adjustable opacity with smart text visibility boost
- **Smooth Animations**: Spring-based transitions throughout
- **Server Logos**: Beautiful circular avatars with gradient backgrounds

## 📁 Configuration Format

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

## 🏗️ Technical Details

Built with modern Swift and SwiftUI for native macOS performance:

- **Architecture**: MVVM (Model-View-ViewModel) pattern
- **UI Framework**: SwiftUI with custom components and modifiers
- **Theme System**: Three adaptive themes with auto-detection
- **Auto-Updates**: Sparkle framework integration (DMG builds)
- **File Access**: Security-scoped bookmarks for App Sandbox compliance
- **Icon Service**: Automatic logo fetching with caching
- **Registry Integration**: MCP GitHub registry API client

<details>
<summary>View Project Structure</summary>

```
MCPServerManager/
├── Models/                         # Data models
│   ├── ServerConfig.swift          # MCP server configuration
│   ├── ServerModel.swift           # In-memory server representation
│   ├── Settings.swift              # App settings
│   ├── Theme.swift                 # Theme system (3 themes)
│   └── RegistryServer.swift        # MCP Registry models
├── ViewModels/                     # Business logic
│   └── ServerViewModel.swift       # Main state management
├── Views/                          # UI components
│   ├── ContentView.swift           # Main app container
│   ├── HeaderView.swift            # Search & config switcher
│   ├── ServerGridView.swift        # Grid display
│   ├── ServerCardView.swift        # Server cards with logos
│   ├── RawJSONView.swift           # JSON editor
│   ├── Components/                 # Reusable UI
│   │   ├── GlassPanel.swift
│   │   ├── CustomToggleSwitch.swift
│   │   ├── ToastView.swift
│   │   ├── ToolbarView.swift
│   │   ├── QuickActionsMenu.swift
│   │   ├── ServerIconView.swift
│   │   └── BrowseRegistryView.swift
│   └── Modals/
│       ├── AddServerModal.swift     # Add/edit with registry browser
│       ├── SettingsModal.swift      # App preferences
│       └── OnboardingModal.swift    # First-run setup
├── Services/                       # Core services
│   ├── ConfigManager.swift         # JSON config I/O
│   ├── MCPRegistryService.swift    # Registry API client
│   ├── IconService.swift           # Logo fetching
│   ├── BookmarkManager.swift       # File access permissions
│   └── UpdateChecker.swift         # Sparkle updates
└── Utilities/                      # Helpers
    ├── Constants.swift             # Design tokens
    ├── Extensions.swift            # Swift extensions
    ├── FontManager.swift           # Custom fonts
    ├── DomainExtractor.swift       # Domain parsing
    └── ServerExtractor.swift       # JSON parsing
```

</details>

## 🐛 Troubleshooting

### Can't see hidden files in file picker
- Press **⌘⇧.** (Command+Shift+Period) to toggle hidden file visibility

### Config file not loading
- Check that the file path is correct in Settings
- Use the "Test Connection" button to verify
- Ensure the file has valid JSON syntax
- Check file permissions

### Servers not saving
- Check file permissions on your config file (`chmod 644 ~/.claude.json`)
- Make sure the config path exists
- Review Console.app for error messages (filter by "MCPServerManager")

### App won't launch
- Ensure you're running macOS 13.0 (Ventura) or later
- Try downloading a fresh copy from releases
- Check System Settings > Privacy & Security if you downloaded the DMG

### Updates not working
- Auto-updates only work for DMG builds (not App Store version)
- Check for updates manually with **⌘U** or from the app menu
- Make sure you have an internet connection
- App Store version updates through the Mac App Store automatically

## 🔄 Updates

MCP Server Manager supports automatic updates:

- **DMG builds** (from GitHub Releases): Auto-update via Sparkle framework
  - Check manually: **⌘U** or App Menu → "Check for Updates"
  - Updates download and install automatically in the background

- **App Store builds**: Auto-update through the Mac App Store
  - Updates are managed by macOS automatically
  - No manual checks needed

---

<details>
<summary><b>For Developers: Building & Distribution</b></summary>

### Quick Start

**Development build:**
```bash
cd MCPServerManager
swift run                      # Run in development mode
```

**Distribution builds:**
```bash
./build-appstore.sh            # Mac App Store PKG
./build-and-sign-local.sh      # Notarized DMG for direct download
```

### Automated CI/CD

Push to `main` or `swifty` branch and both builds happen automatically:

```bash
git push origin main
```

**What happens:**
- ✅ **DMG Build**: Signed, notarized, published as GitHub release with auto-update support
- ✅ **PKG Build**: Signed, auto-uploaded to App Store Connect

Both workflows run in parallel (~10 minutes).

### Distribution Channels

| Method | Build Script | Auto-Update | Distribution |
|--------|-------------|-------------|--------------|
| **App Store** | `build-appstore.sh` | Via App Store | Mac App Store |
| **Direct Download** | `build-and-sign-local.sh` | Via Sparkle | GitHub Releases |

### Requirements

**For Mac App Store:**
- "3rd Party Mac Developer Application" certificate
- "3rd Party Mac Developer Installer" certificate
- `embedded.provisionprofile` provisioning profile

**For Direct Download (DMG):**
- "Developer ID Application" certificate
- Apple Developer account for notarization
- `create-dmg` tool: `brew install create-dmg`

### GitHub Actions Setup

Required secrets (one-time setup):
- `MAC_APP_STORE_CERT`, `MAC_INSTALLER_CERT` (App Store)
- `MAC_CERTS` (Developer ID)
- `CERT_PASSWORD`, `APPLE_TEAM_ID`
- `APPLE_ID`, `APPLE_APP_SPECIFIC_PASSWORD`
- `SPARKLE_PRIVATE_KEY` (optional, for signed updates)

**Documentation:**
- [`SIMPLE_PUSH.md`](SIMPLE_PUSH.md) - Quick workflow guide
- [`WORKFLOWS_EXPLAINED.md`](WORKFLOWS_EXPLAINED.md) - Detailed comparison
- [`COPY_PASTE_SECRETS.md`](COPY_PASTE_SECRETS.md) - Exact secret values
- [`DO_THIS_NOW.md`](DO_THIS_NOW.md) - Step-by-step setup checklist

</details>

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

MIT License - see LICENSE file for details

## 🙏 Credits

Built with SwiftUI for macOS by [Nikhil Anand](https://github.com/nikhilanand)

**Technologies:**
- SwiftUI for native macOS UI
- [Sparkle](https://sparkle-project.org/) for automatic updates
- MCP GitHub Registry for server discovery

Icon design: MCP logo with gradient effects

## 🔗 Links

- [Mac App Store](https://apps.apple.com/us/app/mcp-server-manager/id6753700883?mt=12)
- [GitHub Releases](https://github.com/anand-92/mcp-panel/releases)
- [Report Issues](https://github.com/anand-92/mcp-panel/issues)
- [MCP Registry](https://lobehub.com/mcp) - Discover new MCP servers

---

**Made for Claude Code users who want a native macOS experience** 🚀
