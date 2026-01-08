# Changelog

All notable changes to MCP Server Manager will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Added
- **Mini Mode** - Super compact view for quick server toggling. Click "Mini" button (⇧⌘M) to shrink window to a minimal server list with on/off toggles. Click the Claude/Gemini badge to switch configs. Perfect for keeping the app accessible while working.
- **Responsive Toolbar** - Toolbar now gracefully adapts when window is narrowed. Buttons collapse to icon-only mode using `ViewThatFits`, with tooltips for discoverability.
- **Server List View** - New compact list view mode for better density when managing many servers. Toggle between Grid, List, and Raw JSON modes.
- Server tags (UI, Backend, Creativity, Dev Ops, Advanced) with per-server tagging and bulk enable by tag.

### Removed
- **Codex Support** - Completely removed Codex configuration support. The app now focuses on Claude Code and Gemini CLI only (both use JSON format). Removed TOMLKit dependency, TOML parsing/writing, third config path, and all Codex-specific UI components.

### Fixed
- **Critical: macOS 26 Launch Crash** - Fixed fatal crash on app startup caused by `Bundle.module` assertion failure when SPM resource bundle is missing. Replaced direct `Bundle.module` access with safe bundle lookup that gracefully handles missing resources without crashing.
- **Critical: Missing Resource Bundle in Builds** - Fixed GitHub Actions workflows (build-dmg.yml and build-appstore.yml) to copy the SPM resource bundle (`MCPServerManager_MCPServerManager.bundle`) containing fonts to the app's Resources folder. This was the root cause of the crash - the bundle was never being included in distributed builds.
- **Flexible Configuration** - Updated `ServerConfig` to support unlimited custom fields (e.g., `enabled_tools`, `startup_timeout_sec`, `enabled`), preserving all data in the configuration file.
- **Font Loading** - Enhanced font registration to robustly search for custom fonts in both development (SPM) and release (.app) environments, fixing missing font issues in local builds.

## [3.0.0] - 2025-11-26

### Added
- **Codex Configuration Support** - Full support for third config file with complete universe isolation. Manage Codex servers separately with dedicated UI, TOML file format support, and zero cross-contamination with Claude Code or Gemini CLI configs. Servers remain locked to their creation universe forever
- **TOML Display & Editing** - Codex servers now properly display and edit as TOML format (not JSON). Includes dedicated RawTOMLView component and TOML-aware ServerCardView previews

### Changed
- **App Store Readiness** - Updated app icon with black background for better visibility and App Store compliance. Optimized build scripts for App Store submission.

### Fixed
- **TOML File Selection** - Config file picker now accepts both .json and .toml files, allowing selection of Codex config files
- **Critical: Codex TOML Rendering** - Fixed major bug where Codex servers (stored as TOML) were incorrectly displayed and edited as JSON. All Codex UI components now use native TOML format with proper parsing and serialization
- **Critical: TOML Conversion Logic** - Centralized TOML utilities to fix build errors and code duplication. Proper TOMLValueConvertible unwrapping and TOMLArray handling
- **Critical: Codex Inline Editing** - Disabled inline editing for Codex servers to prevent JSON parser errors on TOML data. Users must use Raw TOML editor for Codex
- **Critical: Codex Add Server Bug** - Fixed "Added 0 servers" issue. Changed TOML parsing to expect `[mcp_servers]` (snake_case) which is more idiomatic for TOML configs
- **Swift 6 Concurrency** - Resolved main actor isolation issues in regex handling to prevent runtime warnings and potential crashes. Optimized concurrency model for better stability.
- **App Store Build Resources** - Fixed build script to correctly embed the resource bundle (containing fonts and assets) into the App Store package, resolving issues with missing custom fonts.
- **Font Registration** - Updated font manager to use standard `Bundle.module` access and explicitly register Crimson Pro fonts, ensuring correct typography in both Debug and Release builds.

---

## [2.0.3] - 2025-11-22

### Added
- **Custom Icon Personalization** - Click any server icon to upload custom images (PNG, JPG, SVG). Icons persist across restarts with smart validation (10MB max, 2048×2048px)
- **12 Professional Themes** - Choose from Nord, Dracula, Solarized Dark/Light, Monokai Pro, One Dark, GitHub Dark, Tokyo Night, Catppuccin Mocha, Gruvbox, Material Palenight, plus Auto mode
- **JSON Preview Blur** - Toggle blur effect for privacy during screen sharing. Automatically disables when editing
- **Force Save Option** - Override validation for custom MCP configurations with detailed error messages
- **HTTP-Based MCP Servers** - Support for GitHub Copilot format with httpUrl and custom headers fields
- **Server-Sent Events (SSE)** - Full support for SSE transport type and streaming servers

### Changed
- **Settings Modal Layout** - Redesigned settings interface with organized sections (Configuration, Appearance, Privacy & Security, Network). Added visual icons, better spacing, and card-based grouping for improved readability and navigation
- **Apple Liquid Glass Implementation** - Fully implemented Apple's native Liquid Glass design language with intelligent fallback support. On macOS 26 (Tahoe) and later, the app uses the new `.glassEffect()` modifier for authentic translucent materials that reflect and refract surroundings. On macOS 13-25, the app gracefully falls back to traditional glass morphism. Removed custom transparency sliders in Settings - the system now handles all glass effects automatically based on OS version.

### Fixed
- **Sparkle Update Installation** - Fixed "An error occurred while launching the installer" by disabling app sandboxing for DMG builds. Sparkle's installer requires non-sandboxed environment to properly replace the app bundle. Removed SUEnableInstallerLauncherService flag as it's only needed for sandboxed apps
- **Registry Browser Decoding** - Fixed "Browse Registry" failing to load servers due to strict header field requirements. Made APIHeader.name and APIHeader.value optional to handle servers with missing or incomplete header definitions
- **Sparkle Update Verification** - Added SUPublicEDKey to Info.plist to fix "error occurred in retrieving update information" when checking for updates
- **App Window Behavior** - Removed problematic "Show Main Window" menu item. App now quits when window is closed (standard single-window app behavior). This fixes App Store compliance issues.
- **Custom Icon Picker** - Fixed non-functional icon click by replacing SwiftUI fileImporter with native NSOpenPanel
- **Registry API Update** - Updated to correct GitHub MCP registry endpoint (api.mcp.github.com/v0/servers)
- **Sparkle Update Feed** - Corrected SUFeedURL to point to proper GitHub repository
- **Icon Visibility** - Increased icon fill from 60% to 90% for better visibility
- Permission errors when saving config files (removed atomic writes)
- Security-scoped bookmark write failures
- Better error handling throughout the app

---

## [2.0.2] - 2025-10-27

### Added ✨
- **MCP Registry Browser** - Browse and install servers from the official MCP registry with one click
- **Adaptive Themes** - Three beautiful themes that auto-switch based on your config (Claude Code, Gemini CLI, Default)
- **Server Logos** - Automatically fetches and displays server icons from the web
- **Quick Actions Menu** - Fast access to common tasks (explore registry, add servers, import/export)
- **Auto-Update System** - Sparkle framework integration for automatic updates (DMG builds)
- Sparkle update framework with release notes display

### Changed 🔧
- Enhanced JSON editor with better syntax highlighting and validation
- Improved search and filtering capabilities across server configurations
- Better error handling and user feedback throughout the app
- Performance optimizations for large config files

### Fixed 🐛
- Fixed config file reading issues on first launch
- Resolved server toggle state synchronization problems
- Improved stability when managing multiple configs simultaneously
- Fixed issues with hidden file visibility in file picker

---

## [2.0.0] - 2025-10-15

### Added
- Initial public release
- Dual config management (Claude Code + Gemini CLI)
- Grid view with server cards
- Raw JSON editor
- Search and filtering
- Import/export functionality
- Native macOS app built with SwiftUI

---

## How to Use This Changelog

When preparing a new release:

1. Move items from `[Unreleased]` to a new version section
2. Update the version number and date
3. Commit the changes
4. The GitHub workflow will automatically use these notes in:
   - Sparkle update dialog (shown to users)
   - GitHub release page
   - Update notifications

### Categories

- **Added** ✨ - New features
- **Changed** 🔧 - Changes to existing functionality
- **Deprecated** ⚠️ - Soon-to-be removed features
- **Removed** 🗑️ - Now removed features
- **Fixed** 🐛 - Bug fixes
- **Security** 🔒 - Security improvements
