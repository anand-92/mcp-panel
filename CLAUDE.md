# CLAUDE.md

Guidance for Claude Code when working in this repository.

## ⚠️ CRITICAL: THIS IS FOR CLAUDE CODE, NOT CLAUDE DESKTOP ⚠️

**CLAUDE CODE** = The CLI tool for developers (uses ~/.claude.json config)
**CLAUDE DESKTOP** = The consumer desktop app (different product, different config)

THIS APP MANAGES MCP SERVERS FOR **CLAUDE CODE** AND **GEMINI CLI** ONLY.
NEVER mention "Claude Desktop" in any user-facing text, descriptions, or documentation.

## Project Overview

MCP Server Manager is a desktop + web companion for managing CLAUDE CODE and GEMINI CLI MCP server definitions. The project now uses a React + Tailwind renderer (Vite) that is shared between the Electron shell and an Express web host.

## Commands

### Development
```bash
npm install                    # Install dependencies
npm run dev:renderer           # Optional: start Vite dev server (http://localhost:5173)
npm run dev                    # Express API with nodemon (serves built assets if present)
VITE_DEV_SERVER_URL=... npm run electron  # Point Electron at the Vite dev server
```

### Running Bundled Builds
```bash
npm start                      # Build renderer then serve on http://localhost:3000
npm run electron               # Build renderer then launch Electron with local files
```

### Packaging
```bash
npm run build-mac              # Build renderer + macOS app bundles
npm run dist                   # Build renderer + cross-platform artifacts
```

## Architecture

- **Renderer**: React + Tailwind located in `renderer/src`. Built with Vite into `renderer/dist`.
- **Web Mode** (`server.js`): Express serves REST APIs and, when available, the static bundle from `renderer/dist`.
- **Electron Mode** (`electron-main-ipc.js`): Loads either the Vite dev server (`VITE_DEV_SERVER_URL`) or the static bundle. Uses IPC + `preload.js` to expose file-system helpers in `window.api`.
- **Config storage**: JSON manipulation happens entirely in the main/Electron process or Express routes; the renderer is UI only.

## Frontend Notes

- Primary entry point: `renderer/src/App.tsx`.
- State is managed with React hooks; notifications use Notyf; search uses Fuse.js.
- Styling is Tailwind-first with a light `index.css` overlay for shared tokens (including the cyberpunk mode helper classes).
- Renderer build output is consumed by both Electron and the Express server (`renderer/dist`).

## IPC / API Contracts

Key operations exposed through `window.api` / Express:
- `getConfig`, `saveConfig`, `addServer`, `deleteServer`
- Profile helpers: `getProfiles`, `saveProfile`, etc.
- Global config helpers: `getGlobalConfigs`, `saveGlobalConfigs`

All methods expect/return JSON objects shaped like Claude's `mcpServers` map.

## Important Files

- `renderer/src/App.tsx`: React application shell + state management
- `renderer/src/types.ts`: Shared renderer types
- `renderer/src/api.ts`: Wrapper for config operations (`getConfig`, `saveConfig`, `getConfigPath`, `testConfigPath`)
- `renderer/src/global.d.ts`: TypeScript definitions for full `window.api` interface (includes profiles, server CRUD, etc.)
- `electron-main-ipc.js`: Electron main process + IPC handlers
- `preload.js`: Secure bridge exposing IPC calls to the renderer
- `server.js`: Express API and static asset host for web mode

## Ports & Paths

- Web server default: `http://localhost:3000`
- Vite dev server default: `http://localhost:5173`
- Default Claude config path: `~/.claude.json`
- Profiles directory: `~/.mcp-manager/profiles`

## Development Tips

- When using the Vite dev server with Electron, set `VITE_DEV_SERVER_URL=http://localhost:5173` before launching Electron so it loads HMR-enabled assets.
- React build artifacts are required for both `npm start` and packaging. Run `npm run build:renderer` when modifying renderer code outside the dev server.
- The renderer assumes the `window.api` bridge exists; if running purely in the browser, mock these methods or run through the Express server.
