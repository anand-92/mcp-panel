# App Store Review Instructions for MCP Server Manager

Thank you for reviewing MCP Server Manager. This document provides everything needed for a complete review.

## Quick Start

1. **Launch the application**
2. **When prompted for a config file**, use the sample config provided below
3. The app will load and display all sample MCP server configurations

## Sample Config File

A pre-configured sample file is included: `sample-config-for-review.json`

**To use it:**
- When the app asks for a config file location, navigate to and select `sample-config-for-review.json`
- Or create a file at `~/.claude.json` with the contents from `sample-config-for-review.json`

**The sample config includes:**
- 15 different MCP server configurations
- Various server types: filesystem, databases, APIs, utilities
- Different configuration patterns (command-based, environment variables, arguments)
- Demonstrates all app features: add, edit, delete, enable/disable, search, profiles

## Features to Test

### 1. Server Management
- **View servers**: Grid and list view modes
- **Search**: Type in the search bar to filter servers
- **Enable/Disable**: Toggle switches for each server
- **Add Server**: Click "+ New Server" to add a configuration
- **Edit Server**: Click any server card to edit its configuration
- **Delete Server**: Remove servers (with optional confirmation)

### 2. Server Configuration
- **Command**: Set the executable command
- **Arguments**: Add/remove command arguments
- **Environment Variables**: Set environment variables
- **Working Directory**: Configure the working directory

### 3. Profiles
- **Create Profile**: Save current server configuration as a profile
- **Load Profile**: Switch between different configuration profiles
- **Export/Import**: Share configurations across devices

### 4. Settings
- **Cyberpunk Mode**: Toggle visual theme
- **Delete Confirmation**: Configure deletion warnings
- **Config Path**: View and change the config file location

### 5. Global Configuration
- Access global settings like keyboard shortcuts

## Sample Config Content

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/Users/reviewers/Documents"],
      "env": {
        "NODE_ENV": "production"
      }
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_example_token_12345"
      }
    },
    "brave-search": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-brave-search"],
      "env": {
        "BRAVE_API_KEY": "BSA_example_key_67890"
      }
    },
    "memory": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory"]
    },
    "sqlite": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sqlite", "--db-path", "/tmp/test.db"]
    }
  }
}
```

## What This App Does

MCP Server Manager is a configuration manager for Model Context Protocol (MCP) servers. It provides a GUI to:

- Manage MCP server definitions stored in `~/.claude.json`
- Edit server configurations without manually editing JSON
- Enable/disable servers quickly
- Organize servers with profiles
- Search and filter servers
- Export/import configurations

## No Network Access Required

This app operates entirely locally:
- No account creation needed
- No server communication
- All data stored in local JSON files
- Privacy-focused design

## Support

- Developer: Nikhil Anand
- Email: nik.anand.1998@gmail.com
- Privacy Policy: [Included in app bundle]

## Notes

- The sample config includes placeholder API keys/tokens that are non-functional
- The app manages JSON configuration files and does not execute MCP servers itself
- All features are accessible without additional downloads or installations
