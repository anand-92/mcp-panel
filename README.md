# MCP Server Manager

<div align="center">

[![Download Latest DMG](https://img.shields.io/badge/Download-Latest%20DMG-blue?style=for-the-badge&logo=apple)](https://github.com/nikhilanand/mcp-panel/releases/download/latest/MCP-Server-Manager.dmg)
[![GitHub release (latest by date)](https://img.shields.io/github/v/release/nikhilanand/mcp-panel?style=for-the-badge)](https://github.com/nikhilanand/mcp-panel/releases)
[![Build Status](https://img.shields.io/github/actions/workflow/status/nikhilanand/mcp-panel/build-dmg.yml?branch=main&style=for-the-badge)](https://github.com/nikhilanand/mcp-panel/actions)

**[⬇️ Download MCP Server Manager for macOS](https://github.com/nikhilanand/mcp-panel/releases/download/latest/MCP-Server-Manager.dmg)**

</div>

A lightweight local desktop application for managing MCP (Model Context Protocol) servers in your Claude configuration file.

## Features

- **View & Manage Servers**: See all configured MCP servers with their current settings
- **Enable/Disable Servers**: Toggle servers on/off without losing their configuration
- **Add New Servers**: Easily add new MCP servers with JSON configuration
- **Edit Configurations**: Modify existing server settings
- **Profile Management**: Save and load different server configurations as profiles
- **Custom Config Path**: Support for custom Claude config file locations (defaults to `~/.claude.json`)

## Installation

1. Clone or download this repository:
```bash
git clone <repository-url>
cd mcp-panel
```

2. Install dependencies:
```bash
npm install
```

## Usage

Start the application:
```bash
npm start
```

This will:
1. Start the local server on port 3000
2. Automatically open your default browser to `http://localhost:3000`

## How to Use

### Managing Servers

- **View Servers**: All active MCP servers are displayed as cards
- **Toggle On/Off**: Use the switch to enable/disable servers
- **Add Server**: Click "+ Add Server" and enter the server name and JSON configuration
- **Edit Server**: Click "Edit" on any server card to modify its configuration
- **Delete Server**: Click "Delete" to remove a server completely

### Using Profiles

Profiles let you save and switch between different server configurations:

1. **Save a Profile**:
   - Configure your servers as desired
   - Click "Save Current as Profile"
   - Enter a profile name
   - Click "Save"

2. **Load a Profile**:
   - Select a profile from the dropdown
   - Click "Load Profile"
   - Your servers will be updated to match the profile

3. **Delete a Profile**:
   - Select the profile to delete
   - Click "Delete Profile"

### Custom Config Path

If your Claude config is not at the default location (`~/.claude.json`):
1. Click the ⚙️ Settings button
2. Enter your custom config file path
3. Click "Save"

## Server Configuration Format

When adding or editing a server, use JSON format like:

```json
{
  "command": "npx",
  "args": ["@example/mcp-server", "start"]
}
```

Or for Docker-based servers:
```json
{
  "command": "docker",
  "args": ["run", "mcp-server-image"]
}
```

## File Structure

- `renderer/src/App.tsx` – React UI shell and state management
- `renderer/src/components/` – Reusable Tailwind-styled UI components
- `renderer/src/index.css` – Global Tailwind layers and custom tokens
- `server.js` – Express backend handling file operations and API routes
- `electron-main-ipc.js` – Electron main process and IPC handlers
- Profiles stored in: `~/.mcp-manager/profiles/`

## Notes

- The app modifies only the outermost `mcpServers` object in your Claude config
- All other configuration settings are preserved
- Profiles are stored locally in your home directory
- Changes are saved immediately to the config file

## Troubleshooting

- **Can't find config file**: Check Settings to ensure the correct path is set
- **Server won't enable**: Ensure the JSON configuration is valid
- **Port already in use**: Another application may be using port 3000. Stop it or modify the PORT in server.js

## License

MIT
