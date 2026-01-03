# CLAUDE.md

Quick reference for Claude Code when working on MCP Server Manager.

## ⚠️ CRITICAL CONTEXT

**What this app does:** Native macOS app for managing MCP server configs for **CLAUDE CODE** and **GEMINI CLI**
**NOT for:** Claude Desktop (different product, different config files)
**Tech stack:** SwiftUI + Swift Package Manager, macOS 13.0+ only
**No backend:** Direct filesystem manipulation, no server

## Config File Support (Dual Config System)

```
Config 1: ~/.claude.json  (Claude Code) - JSON only
Config 2: ~/.settings.json (Gemini CLI) - JSON only
```

**How Servers Are Shared:**
- **Claude ↔ Gemini:** Servers with same name are **merged and shared** (identical JSON syntax). Toggle states are independent via `inConfigs[0]` and `inConfigs[1]`

**File Format Detection:** `ConfigFormat.swift` ensures valid JSON format.

## Architecture & Key Files

```
Models/
  - ServerModel.swift      # sourceUniverse locks servers to config (0=Claude, 1=Gemini)
  - ServerConfig.swift     # MCP server structure (stdio/http/sse transport)
  - ConfigFormat.swift     # JSON validation
  - Settings.swift         # config1Path, config2Path

ViewModels/
  - ServerViewModel.swift  # All business logic, mergeConfigs(), syncToConfigs()

Services/
  - ConfigManager.swift    # File I/O for JSON, security-scoped bookmarks

Views/Modals/
  - AddServerModal.swift       # For Claude Code & Gemini CLI (JSON, has registry browser)
  - SettingsModal.swift        # Manages the 2 config paths
```

## Important Features

**Custom Icons:** `~/Library/Application Support/MCPServerManager/CustomIcons/`, UUID filenames, 10MB/2048px max
**12 Themes:** Auto mode detects from active config, or manual override in Settings
**Force Save:** Override validation for experimental MCP configs
**Extended MCP:** Supports stdio, HTTP (httpUrl + headers), SSE transport

## 🚨 CHANGELOG WORKFLOW (CRITICAL)

**ALWAYS update CHANGELOG.md with code changes!** Pre-commit hook will remind you.

### The System
1. Add changes to `[Unreleased]` section in CHANGELOG.md
2. Push to main → GitHub Actions runs `extract-changelog.sh`
3. Script extracts `[Unreleased]` → generates HTML (Sparkle) + Markdown (GitHub release)
4. Users see changelog in update dialog

### After Each Release
**MUST move `[Unreleased]` to versioned section** (e.g., `[2.0.4] - 2025-11-22`) to prevent showing duplicate notes to users!

### Pre-Commit Hook
```bash
cp .githooks/pre-commit .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit
```
Warns when committing code without updating CHANGELOG.md.

## Git Commit Process

**Only commit when user explicitly asks!** Follow these steps:

1. Run `git status`, `git diff`, `git log` in parallel
2. Draft commit message (focus on "why" not "what")
3. Add untracked files if needed
4. Commit with footer:
```
🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```
5. If pre-commit hook modifies files, verify authorship before amending
6. Never use --no-verify, --force, or skip hooks unless explicitly requested

## PR Creation Process

1. Run `git status`, `git diff`, `git log [base-branch]...HEAD` to see ALL commits
2. Draft PR summary analyzing ALL changes (not just latest commit)
3. Push with `-u` flag if needed
4. Create PR:
```bash
gh pr create --title "..." --body "$(cat <<'EOF'
## Summary
- Bullet points

## Test plan
- Checklist

EOF
)"
```

## Development Commands

```bash
cd MCPServerManager
swift run                    # Run app
swift build -c release       # Build release binary
```

## Design System

- **Apple Liquid Glass:** Auto-adopts on macOS 26+, graceful fallback for 13-25
- **Theme System:** 12 themes (Nord, Dracula, etc.) via `AppTheme` enum
- **Font Scaling:** 1.5x applied via `.scaled()` extension
- **Glass Panels:** All UI uses `LiquidGlassModifier`

## Common Mistakes to Avoid

❌ Mentioning "Claude Desktop" in user-facing text
❌ Forgetting to update CHANGELOG.md
❌ Thinking Claude/Gemini are separate (they share servers by name!)
❌ Committing without user approval
❌ Creating new files when editing existing ones works
❌ Using bash for file operations (use Read/Edit/Write tools instead)

## Quick Facts

- **No file watching:** Manual refresh (⌘R) needed for external config changes
- **No backups:** Users manage their own
- **Security bookmarks:** Required for file access persistence
- **Settings storage:** UserDefaults via @AppStorage
- **Icon priority:** Custom > Registry > IconService > SF Symbol
