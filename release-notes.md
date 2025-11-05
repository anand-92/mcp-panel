## 🚀 What's New

### Added
- **Custom Icon Personalization** - Click any server icon to upload custom images (PNG, JPG, SVG). Icons persist across restarts with smart validation (10MB max, 2048×2048px)
- **12 Professional Themes** - Choose from Nord, Dracula, Solarized Dark/Light, Monokai Pro, One Dark, GitHub Dark, Tokyo Night, Catppuccin Mocha, Gruvbox, Material Palenight, plus Auto mode
- **JSON Preview Blur** - Toggle blur effect for privacy during screen sharing. Automatically disables when editing
- **Force Save Option** - Override validation for custom MCP configurations with detailed error messages
- **HTTP-Based MCP Servers** - Support for GitHub Copilot format with httpUrl and custom headers fields
- **Server-Sent Events (SSE)** - Full support for SSE transport type and streaming servers
### Changed
- Nothing yet
### Fixed
- **Custom Icon Picker** - Fixed non-functional icon click by replacing SwiftUI fileImporter with native NSOpenPanel
- **Registry API Update** - Updated to correct GitHub MCP registry endpoint (api.mcp.github.com/v0/servers)
- **Sparkle Update Feed** - Corrected SUFeedURL to point to proper GitHub repository
- **Icon Visibility** - Increased icon fill from 60% to 90% for better visibility
- Permission errors when saving config files (removed atomic writes)
- Security-scoped bookmark write failures
- Better error handling throughout the app

---
