# Changelog

All notable changes to MCP Server Manager will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Added
- **Custom Icon Personalization** - Click any server icon to upload custom images (PNG, JPG, SVG). Icons persist across restarts with smart validation (10MB max, 2048×2048px)
- **12 Professional Themes** - Choose from Nord, Dracula, Solarized Dark/Light, Monokai Pro, One Dark, GitHub Dark, Tokyo Night, Catppuccin Mocha, Gruvbox, Material Palenight, plus Auto mode
- **JSON Preview Blur** - Toggle blur effect for privacy during screen sharing. Automatically disables when editing
- **Force Save Option** - Override validation for custom MCP configurations with detailed error messages
- **HTTP-Based MCP Servers** - Support for GitHub Copilot format with httpUrl and custom headers fields
- **Server-Sent Events (SSE)** - Full support for SSE transport type and streaming servers

### Changed
- **Apple Liquid Glass Adoption** - Transitioned to Apple's native Liquid Glass design language (macOS 26+) for enhanced visual depth and system integration. Removed custom transparency controls in favor of automatic system-provided materials that seamlessly integrate with macOS Tahoe's design standards.

### Fixed
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
