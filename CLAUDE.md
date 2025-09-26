# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MCP Server Manager is a desktop application for managing Model Context Protocol (MCP) servers in Claude configuration files. It operates in two modes:
1. **Web mode**: Express server serving a web interface
2. **Electron mode**: Native desktop app using IPC for file operations

## Commands

### Development
```bash
npm install              # Install dependencies
npm start               # Run web version (Express server on port 3000)
npm run electron        # Run Electron desktop app
npm run dev            # Run with nodemon for auto-reload
```

### Building
```bash
npm run build-mac      # Build macOS .app and .dmg
./build.sh             # Alternative build script with setup
```

### Quick Launch
```bash
./mcp-manager.command  # Double-click launcher for end users
```

## Architecture

### Dual-Mode Operation
The app supports both web and Electron modes with shared UI code:

- **Web Mode** (`npm start`): Uses `server.js` with Express API endpoints
- **Electron Mode** (`npm run electron`): Uses `electron-main-ipc.js` with IPC handlers
- **Runtime Detection**: `app-electron.js` checks `window.api` to determine mode and routes calls appropriately

### File Operations
All config file operations target the outermost `mcpServers` object in JSON files:
- Default path: `~/.claude.json`
- Preserves all other JSON content
- Profiles stored in: `~/.mcp-manager/profiles/`

### IPC Architecture (Electron)
- **Main Process**: `electron-main-ipc.js` handles file I/O via IPC
- **Preload Script**: `preload.js` exposes secure API via contextBridge
- **Renderer**: Accesses file system through `window.api` methods

### Frontend Structure
- **UI**: Dark mode design with sidebar layout
- **State**: Managed in `currentServers` object
- **Rendering**: Dynamic card generation with syntax-highlighted JSON
- **Validation**: JSON parsing before save operations

## Key Implementation Details

### Server Toggle Logic
Servers can be disabled (set to null) without deletion, preserving configuration for re-enabling.

### Profile System
Profiles are complete snapshots of the `mcpServers` object, stored as separate JSON files.

### CSS Architecture
`style-dark.css` uses CSS variables for theming, making color changes centralized.

### JSON Syntax Highlighting
Custom regex-based highlighting in `syntaxHighlightJSON()` function for better readability.

## Important Files

- `electron-main-ipc.js`: Electron main process with IPC handlers
- `server.js`: Express server for web mode
- `app-electron.js`: Frontend logic with dual-mode support
- `preload.js`: Electron security bridge
- `public/style-dark.css`: Dark theme styling

## Port Configuration
Default port 3000 can be modified in `server.js` if conflicts occur.