#!/bin/bash
set -e

# Create proper installer DMG using create-dmg tool
# Usage: ./create-dmg.sh <path-to-app> <output-name>

APP_PATH="$1"
OUTPUT_NAME="${2:-MCP-Server-Manager.dmg}"
VOLUME_NAME="MCP Server Manager"

if [ -z "$APP_PATH" ]; then
    echo "Usage: $0 <path-to-app> [output-name.dmg]"
    exit 1
fi

if [ ! -d "$APP_PATH" ]; then
    echo "Error: App not found at $APP_PATH"
    exit 1
fi

echo "📀 Creating installer DMG using create-dmg..."

# Remove existing DMG if it exists
rm -f "$OUTPUT_NAME"

# Use create-dmg tool (battle-tested, used by thousands of apps)
create-dmg \
  --volname "$VOLUME_NAME" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 100 \
  --icon "MCP-Server-Manager.app" 175 190 \
  --hide-extension "MCP-Server-Manager.app" \
  --app-drop-link 425 190 \
  "$OUTPUT_NAME" \
  "$APP_PATH"

echo "✅ DMG created successfully: $OUTPUT_NAME"
