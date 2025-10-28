# MCP Server Manager

<div align="center">

[![Download Latest DMG](https://img.shields.io/badge/Download-Latest%20DMG-blue?style=for-the-badge&logo=apple)](https://github.com/anand-92/mcp-panel/releases/latest)
[![GitHub release (latest by date)](https://img.shields.io/github/v/release/anand-92/mcp-panel?style=for-the-badge)](https://github.com/anand-92/mcp-panel/releases/latest)
[![Build Status](https://img.shields.io/github/actions/workflow/status/anand-92/mcp-panel/build-dmg.yml?branch=main&style=for-the-badge)](https://github.com/anand-92/mcp-panel/actions)

**[⬇️ Download MCP Server Manager for macOS](https://apps.apple.com/us/app/mcp-server-manager/id6753700883?mt=12)**

</div>

A native macOS application for managing Claude Code and Gemini CLI MCP server configurations, built with SwiftUI.

## ⚡ Features

- **Dual Config Management**: Manage two separate config files simultaneously (perfect for Claude Code + Gemini CLI)
- **Server CRUD Operations**: Add, edit, delete, and toggle MCP servers with ease
- **Multiple View Modes**: Grid view with cards, list view, and raw JSON editor
- **Search & Filtering**: Real-time fuzzy search and filter by status (active/disabled/recent)
- **Import/Export**: Bulk import/export server configurations
- **Cyberpunk Mode**: Optional neon-themed UI for extra flair 💜
- **Native macOS**: Built with SwiftUI for optimal performance and battery life
- **Keyboard Shortcuts**: Full keyboard navigation support

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

### Managing Servers

- **Add Server**: Click "New Server" in the sidebar or press **⌘N**
- **Edit Server**: Hover over a server card and click the edit button
- **Delete Server**: Click the trash icon on any server card (confirmation optional in settings)
- **Toggle Server**: Use the switch on each card to enable/disable for the active config
- **Toggle All**: Use the "Enable/Disable All" button in the toolbar

### Config Switching

- Click the config buttons (**1** or **2**) in the header to switch between configs
- Each server card shows badges indicating which configs include it (green badges with numbers)
- Perfect for managing Claude Code and Gemini CLI separately

### Search & Filter

- Press **⌘F** to focus the search bar
- Type to search server names and configurations (fuzzy search enabled)
- Use the filter dropdown to show:
  - **All Servers**: Show everything
  - **Active Only**: Enabled in current config
  - **Disabled Only**: Not in current config
  - **Recently Modified**: Servers changed in the last 7 days

### View Modes

Toggle between three view modes using the picker in the toolbar:
- **Grid View**: Card-based layout with full details
- **List View**: Compact list format
- **Raw JSON**: Direct JSON editor for advanced users

### Import/Export

- **Import**: Click "Import JSON" in the sidebar to bulk import server definitions
- **Export**: Click "Export JSON" to download the current config as JSON

### Settings

Click the gear icon ⚙️ in the header to configure:
- Config file paths (Config 1 and Config 2)
- Confirmation dialogs (enable/disable delete confirmations)
- Cyberpunk Mode (extra neon flair)
- Test config file connections

## ⌨️ Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| **⌘N** | New server |
| **⌘F** | Focus search |
| **⌘R** | Refresh from config files |
| **⌘S** | Manual save (auto-saves by default) |
| **Escape** | Close modals |

## 🎨 Design Philosophy

Native SwiftUI design with glassmorphic aesthetics:

- **Dark Theme**: Deep blue/purple gradients
- **Glass Panels**: Frosted glass effect with subtle borders
- **Smooth Animations**: Spring-based transitions throughout
- **Cyberpunk Mode**: Optional neon cyan accents and enhanced glow effects

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

## 🏗️ Project Structure

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
│   │   ├── RawJSONView.swift
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
│       ├── Extensions.swift
│       └── FontScale.swift
└── Package.swift
```

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

## 🚢 Distribution & CI/CD

### ✨ Simplified Workflow

**Just push to `main` or `swifty` branch and both builds happen automatically:**

```bash
git add .
git commit -m "Your changes"
git push origin swifty
```

**What happens automatically:**
- ✅ **DMG Build**: Signed, notarized, published as GitHub release (public)
- ✅ **PKG Build**: Signed, auto-uploaded to App Store Connect (private)

Both workflows run in parallel and complete in ~10 minutes.

See [`SIMPLE_PUSH.md`](SIMPLE_PUSH.md) for details.

---

### Two Workflows Explained

#### Developer ID Workflow (`.github/workflows/build-dmg.yml`)
- **Triggers**: Push to main/swifty branches, tags starting with `v*`
- **Output**: Signed and notarized DMG for direct download
- **Creates**: Public GitHub Releases with DMG artifact
- **Use case**: Public downloads, beta testing

#### App Store Workflow (`.github/workflows/build-appstore.yml`)
- **Triggers**: Push to main/swifty branches, tags starting with `appstore-v*`, manual dispatch
- **Output**: Signed PKG for Mac App Store submission
- **Auto-uploads**: To App Store Connect (configurable)
- **Artifacts**: Available in Actions for 90 days (private)
- **Use case**: App Store submissions

---

### First Time Setup

Before your first push, add 6 GitHub Secrets (one-time setup):
- See [`COPY_PASTE_SECRETS.md`](COPY_PASTE_SECRETS.md) for exact values
- See [`DO_THIS_NOW.md`](DO_THIS_NOW.md) for step-by-step checklist

**Required secrets:**
- `MAC_APP_STORE_CERT`, `MAC_INSTALLER_CERT`
- `CERT_PASSWORD`, `APPLE_TEAM_ID`
- `APPLE_ID`, `APPLE_APP_SPECIFIC_PASSWORD`

---

### Advanced Options

**Create release with specific version tag:**
```bash
# Public DMG release
git tag v2.0.0
git push origin v2.0.0

# App Store PKG (auto-uploads)
git tag appstore-v2.0.0
git push origin appstore-v2.0.0
```

**Manual workflow trigger (disable auto-upload):**

1. Go to [GitHub Actions](https://github.com/anand-92/mcp-panel/actions)
2. Select "Build for Mac App Store"
3. Click "Run workflow"
4. Uncheck "Upload to App Store Connect" box
5. PKG artifact created but not uploaded

---

**Documentation:**
- [`SIMPLE_PUSH.md`](SIMPLE_PUSH.md) - TL;DR simple workflow
- [`WORKFLOWS_EXPLAINED.md`](WORKFLOWS_EXPLAINED.md) - Detailed comparison
- [`COPY_PASTE_SECRETS.md`](COPY_PASTE_SECRETS.md) - Exact secret values
- [`DO_THIS_NOW.md`](DO_THIS_NOW.md) - Step-by-step setup
- [`SECURITY_NOTE.md`](SECURITY_NOTE.md) - Why PKGs are private

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

Icon design: MCP logo with gradient effects

## 🔗 Links

- [Mac App Store](https://apps.apple.com/us/app/mcp-server-manager/id6753700883?mt=12)
- [GitHub Releases](https://github.com/anand-92/mcp-panel/releases)
- [Report Issues](https://github.com/anand-92/mcp-panel/issues)
- [MCP Registry](https://lobehub.com/mcp) - Discover new MCP servers

---

**Made for Claude Code users who want a native macOS experience** 🚀
