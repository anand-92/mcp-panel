# CLAUDE.md

Guidance for Claude Code when working in this repository.

## ⚠️ CRITICAL: THIS IS FOR CLAUDE CODE, NOT CLAUDE DESKTOP ⚠️

**CLAUDE CODE** = The CLI tool for developers (uses ~/.claude.json config)
**CLAUDE DESKTOP** = The consumer desktop app (different product, different config)

THIS APP MANAGES MCP SERVERS FOR **CLAUDE CODE** AND **GEMINI CLI** ONLY.
NEVER mention "Claude Desktop" in any user-facing text, descriptions, or documentation.

## Project Overview

MCP Server Manager is a native macOS application for managing CLAUDE CODE and GEMINI CLI MCP server definitions. The app is built entirely with SwiftUI and uses Swift Package Manager.

## Commands

### Development

```bash
cd MCPServerManager
swift run                      # Run the app in development mode
swift build -c release         # Build release binary
```

### Building for Distribution

```bash
cd MCPServerManager
swift build -c release

# Create .app bundle manually or use Xcode
swift package generate-xcodeproj
open MCPServerManager.xcodeproj
# Then Product > Archive in Xcode
```

## Architecture

- **SwiftUI App**: Native macOS application using SwiftUI framework
- **Config Management**: Direct JSON file manipulation via `ConfigManager.swift`
- **Dual Config Support**: Can manage two separate config files simultaneously (perfect for Claude Code + Gemini CLI)
- **No Backend**: All operations happen directly on the user's filesystem
- **Settings Storage**: User preferences stored via `@AppStorage` in UserDefaults

## Project Structure

```
MCPServerManager/
├── MCPServerManager/
│   ├── MCPServerManagerApp.swift      # App entry point
│   ├── Models/                        # Data models
│   │   ├── ServerConfig.swift         # MCP server config structure
│   │   ├── ServerModel.swift          # In-memory server representation
│   │   └── Settings.swift             # App settings model
│   ├── ViewModels/                    # Business logic
│   │   └── ServerViewModel.swift      # Main state management
│   ├── Views/                         # UI components
│   │   ├── ContentView.swift          # Main app container
│   │   ├── HeaderView.swift           # Top bar with search & settings
│   │   ├── SidebarView.swift          # Left sidebar navigation
│   │   ├── ServerGridView.swift       # Grid view of server cards
│   │   ├── ServerCardView.swift       # Individual server card
│   │   ├── RawJSONView.swift          # JSON editor view
│   │   ├── Components/
│   │   │   ├── GlassPanel.swift       # Reusable glass panel
│   │   │   ├── CustomToggleSwitch.swift # Toggle switch component
│   │   │   ├── ToastView.swift        # Toast notifications
│   │   │   └── ToolbarView.swift      # Main toolbar
│   │   └── Modals/
│   │       ├── AddServerModal.swift   # Add/edit server dialog
│   │       ├── SettingsModal.swift    # Settings dialog
│   │       └── OnboardingModal.swift  # First-run onboarding
│   ├── Services/                      # File I/O and config management
│   │   └── ConfigManager.swift        # JSON config file operations
│   └── Utilities/                     # Helpers and extensions
│       ├── Constants.swift            # App constants & design tokens
│       ├── Extensions.swift           # Swift extensions
│       └── FontScale.swift            # Font scaling utilities
└── Package.swift                      # Swift package manifest
```

## Key Files

- **`MCPServerManagerApp.swift`**: App lifecycle and window setup
- **`ServerViewModel.swift`**: Core business logic, state management, and config operations
- **`ConfigManager.swift`**: All file I/O operations for reading/writing JSON configs
- **`Constants.swift`**: Design tokens (colors, gradients, spacing)
- **`ContentView.swift`**: Main app layout and view coordination

## Design System

The app uses a consistent design system defined in `Utilities/Constants.swift`:

- **Primary Gradient**: Cyan → Blue → Purple gradient used throughout
- **Glass Morphism**: Semi-transparent panels with blur effects
- **Color Palette**: Dark theme with deep blue/purple gradients
- **Cyberpunk Mode**: Optional neon cyan accents and enhanced glows
- **Font Scaling**: 1.5x scaling applied to all text for better readability

### Text Visibility Boost

The app includes an independent text visibility control that maintains text readability when the window becomes translucent:

- **Window Opacity**: Controls overall window transparency (30%-100%)
- **Text Visibility Boost**: Controls how much text resists becoming transparent (0%-100%)
  - 0% = Text fades proportionally with window
  - 50% = Text maintains moderate visibility (default)
  - 100% = Text stays at maximum brightness

**Implementation Details:**
- Settings stored in `AppSettings.textVisibilityBoost` (Models/Settings.swift)
- UI controls in Settings modal with real-time preview
- View modifiers available for applying boost to text elements:
  - `.primaryTextVisibility()` - For main text elements
  - `.secondaryTextVisibility()` - For secondary text (0.7 opacity baseline)
  - `.mutedTextVisibility()` - For muted text (0.5 opacity baseline)
  - `.textVisibilityBoost(baseOpacity:)` - Custom opacity baseline

**Example Usage:**
```swift
Text("Server Name")
    .font(DesignTokens.Typography.title)
    .foregroundColor(themeColors.primaryText)
    .primaryTextVisibility()  // Apply boost for better visibility

Text("Description")
    .font(DesignTokens.Typography.body)
    .foregroundColor(themeColors.secondaryText)
    .secondaryTextVisibility()  // Apply boost with secondary baseline
```

**Algorithm:**
```
textOpacityBoost = (1.0 - windowOpacity) × textVisibilityBoost
brightnessIncrease = textOpacityBoost × 0.4 (up to 40% brighter)
glowRadius = textOpacityBoost × 6.0 (up to 6pt glow)
```

The modifier applies two effects to compensate for window translucency:
1. **Brightness increase** - Makes text brighter to maintain contrast
2. **White glow/shadow** - Adds subtle halo effect for better visibility

When window opacity is 30% and boost is 50%:
- Boost = (1.0 - 0.3) × 0.5 = 0.35
- Brightness = +14% (0.35 × 0.4)
- Glow radius = 2.1pt (0.35 × 6.0)

When window opacity is 30% and boost is 100%:
- Boost = (1.0 - 0.3) × 1.0 = 0.7
- Brightness = +28% (0.7 × 0.4)
- Glow radius = 4.2pt (0.7 × 6.0)

## Config File Management

- **Default Claude config path**: `~/.claude.json`
- **Default Gemini config path**: `~/.settings.json` (configurable)
- **Dual config support**: Users can manage two configs simultaneously
- **Config format**: Standard MCP server JSON format
- **Operations**: Read, write, add servers, delete servers, toggle servers
- **Backup**: App does not create backups - users should manage their own

## Development Tips

- **Live Preview**: Use Xcode's SwiftUI previews for rapid UI iteration
- **State Management**: All state flows through `ServerViewModel` using `@Published` properties
- **File I/O**: All file operations go through `ConfigManager` to ensure consistency
- **Testing Config**: Use `sample-config-for-review.json` in the root for testing
- **Debugging**: Use Console.app and filter by "MCPServerManager" to see logs
- **Font Sizes**: All fonts use the `.scaled()` extension for 1.5x scaling

## Important Notes

- This is a **macOS-only** application (no cross-platform support)
- Requires **macOS 13.0 (Ventura)** or later
- Uses **Swift 5.9+** and **SwiftUI** exclusively
- No web version or Electron wrapper
- Direct filesystem access (no server/backend)
- Settings stored in UserDefaults
- No automatic config backups (user responsibility)

## SwiftUI Patterns Used

- **MVVM Architecture**: Models, ViewModels, Views separation
- **Combine Framework**: For reactive state management via `@Published`
- **@StateObject/@ObservedObject**: For view-level state binding
- **@AppStorage**: For persisting user preferences
- **Custom Modifiers**: Reusable view modifiers for consistent styling
- **Sheet/Alert Modifiers**: For modal presentations

## 🚨 IMPORTANT: Changelog & Release Notes Workflow

### **ALWAYS UPDATE CHANGELOG.MD WHEN MAKING CHANGES**

This app uses an **automated release notes system** that flows from CHANGELOG.md to Sparkle updates and GitHub releases.

### How It Works

1. **Edit `CHANGELOG.md`** - Add your changes to the `[Unreleased]` section
2. **Push to main** - GitHub Actions automatically:
   - Runs `extract-changelog.sh` to extract `[Unreleased]` content
   - Generates HTML for Sparkle update dialog
   - Generates Markdown for GitHub release page
   - Includes release notes in the DMG update

3. **Users see it** - When Sparkle checks for updates, users see:
   - Your changelog in a beautiful HTML dialog
   - All the features, changes, and fixes you documented

### CHANGELOG.md Format

```markdown
## [Unreleased]

### Added
- **Feature Name** - Description with details
- **Another Feature** - More details

### Changed
- Updated something important

### Fixed
- Bug fix description
- Another fix
```

### Important Rules

1. ✅ **ALWAYS add new features to `[Unreleased]`** when you implement them
2. ✅ Use **bold text** for feature names: `**Feature Name**`
3. ✅ Keep descriptions concise but informative
4. ✅ Organize by category: Added, Changed, Fixed, Security, etc.
5. ❌ **DON'T** edit the hardcoded release notes in `.github/workflows/build-dmg.yml`
6. ❌ **DON'T** forget to update CHANGELOG.md - users won't know what changed!

### Where Updates Appear

- **Sparkle Dialog**: Users see the HTML version when updating via Sparkle
- **GitHub Release**: The markdown version appears on the release page
- **App Store**: Manually copy from CHANGELOG.md to App Store Connect

### Files Involved

- `CHANGELOG.md` - **THIS IS THE SOURCE OF TRUTH**
- `extract-changelog.sh` - Extracts `[Unreleased]` and generates HTML/Markdown
- `.github/workflows/build-dmg.yml` - Runs the extraction during builds
- Generated files (automatic):
  - `release-notes.html` - For Sparkle dialog
  - `release-notes.md` - For GitHub releases
  - `MCP-Server-Manager-v*.html` - Uploaded to GitHub releases

### Example Workflow

```bash
# 1. Make changes to the app
# 2. Update CHANGELOG.md
# 3. Commit everything together
git add .
git commit -m "Add custom icons feature"
git push

# GitHub Actions will automatically:
# - Extract your changelog
# - Build the DMG
# - Create release with notes
# - Users see your changelog in Sparkle!
```

### Troubleshooting

- **Users don't see release notes?** Check that HTML file matches DMG name pattern
- **HTML looks broken?** Test with `bash extract-changelog.sh CHANGELOG.md test.html test.md`
- **Want to preview?** Open the generated HTML in a browser

## Building & Distributing

### Local Development
```bash
cd MCPServerManager
swift run
```

### Release Build
```bash
cd MCPServerManager
swift build -c release
# Binary will be at: .build/release/MCPServerManager
```

### Xcode Distribution
```bash
cd MCPServerManager
swift package generate-xcodeproj
open MCPServerManager.xcodeproj
# Product > Archive > Distribute App
```

### Code Signing
- Certificates should be in root: `Certificates.p12` and `embedded.provisionprofile`
- GitHub Actions workflow handles signing/notarization automatically
- See `.github/workflows/build-dmg.yml` for CI/CD setup

## Common Tasks

### Adding a New View
1. Create view file in `Views/` or `Views/Components/`
2. Use `@ObservedObject var viewModel: ServerViewModel` for state access
3. Apply glass panel styling with `GlassPanel()` component
4. Add to navigation in `ContentView.swift` or `SidebarView.swift`

### Modifying Design Tokens
- Edit `Utilities/Constants.swift`
- Update `DesignTokens` enum
- Changes apply app-wide automatically

### Adding New Settings
1. Add property to `Models/Settings.swift`
2. Add UI control in `Views/Modals/SettingsModal.swift`
3. Bind to `@AppStorage` for persistence
4. Access via `viewModel.settings` throughout app

### Debugging File I/O
- Check `Services/ConfigManager.swift` for all file operations
- Use `print()` statements or Console.app logs
- Test with sample config: `sample-config-for-review.json`

## Known Limitations

- **macOS Only**: No Windows/Linux support (SwiftUI limitation)
- **No Profiles**: Unlike Electron version, no profile save/load feature yet
- **No File Watching**: Config changes outside the app require manual refresh (⌘R)
- **No Web Hosting**: Pure desktop app, no Express server

## Future Enhancements

Potential features to add:
- Profile management (save/load server configurations)
- File watching for auto-reload on external changes
- Drag-and-drop server reordering
- Server health checking/validation
- More export formats (YAML, TOML)
- iCloud sync for settings
