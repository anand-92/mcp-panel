# Building MCP Server Manager as a Mac App

## Quick Build (For Developers)

1. **Install Electron dependencies:**
```bash
npm install --save-dev electron electron-builder
```

2. **Test the Electron app locally:**
```bash
npm run electron
```

3. **Build the Mac app:**
```bash
./build.sh
```
Or directly:
```bash
npm run build-mac
```

## Distribution

After building, you'll find in the `dist` folder:
- **MCP Server Manager.app** - The Mac application
- **MCP Server Manager-1.0.0.dmg** - Disk image for distribution

## For End Users

### Option 1: DMG File (Easiest)
1. Download the `.dmg` file
2. Double-click to open
3. Drag "MCP Server Manager" to Applications folder
4. First time running: Right-click → Open (due to macOS security)

### Option 2: Direct App
1. Download the `.app` file
2. Move to Applications folder
3. First time running: Right-click → Open

## Creating a Signed App (Optional, for wider distribution)

To avoid the security warning, you'd need:
1. Apple Developer account ($99/year)
2. Code signing certificate
3. Notarization process

For personal/small-scale use, the unsigned app works fine with the right-click → Open method.

## Alternative: Simple Script Distribution

For the simplest distribution without Electron, create a command file:

**mcp-manager.command:**
```bash
#!/bin/bash
cd "$(dirname "$0")"
npm start
```

Users can:
1. Download the project
2. Run `npm install` once
3. Double-click `mcp-manager.command` to launch

## Icon Notes

- Current icon is a placeholder SVG
- For production, convert to .icns format:
  - Use an online converter
  - Or ImageMagick + iconutil on Mac
- Place the .icns file in `assets/icon.icns`