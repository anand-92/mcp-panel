#!/bin/bash
set -e

# Create proper installer DMG with Applications symlink
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

echo "📀 Creating installer DMG..."

# Create a temporary directory for DMG contents
DMG_TEMP=$(mktemp -d)
echo "  Using temp directory: $DMG_TEMP"

# Copy the app to temp directory
echo "  Copying app..."
cp -R "$APP_PATH" "$DMG_TEMP/"

# Create Applications symlink
echo "  Creating Applications symlink..."
ln -s /Applications "$DMG_TEMP/Applications"

# Create a temporary writable DMG
TEMP_DMG=$(mktemp -u).dmg
echo "  Creating temporary DMG..."
hdiutil create -volname "$VOLUME_NAME" -srcfolder "$DMG_TEMP" -ov -format UDRW "$TEMP_DMG"

# Mount the temporary DMG
echo "  Mounting DMG..."
MOUNT_DIR=$(hdiutil attach "$TEMP_DMG" | grep Volumes | awk '{print $3}')

# Set window properties using AppleScript
echo "  Configuring window layout..."
sleep 2  # Wait for Finder to recognize the volume

osascript <<EOF
tell application "Finder"
    tell disk "$VOLUME_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {400, 100, 920, 440}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 100
        set position of item "MCP Server Manager.app" of container window to {130, 150}
        set position of item "Applications" of container window to {390, 150}
        close
        open
        update without registering applications
        delay 2
    end tell
end tell
EOF

# Unmount the temporary DMG
echo "  Unmounting temporary DMG..."
hdiutil detach "$MOUNT_DIR"

# Convert to compressed read-only DMG
echo "  Compressing final DMG..."
hdiutil convert "$TEMP_DMG" -format UDZO -o "$OUTPUT_NAME"

# Clean up
echo "  Cleaning up..."
rm -rf "$DMG_TEMP"
rm -f "$TEMP_DMG"

echo "✅ DMG created successfully: $OUTPUT_NAME"
