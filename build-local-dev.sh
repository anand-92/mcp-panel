#!/bin/bash
set -e

# ============================================
# Local Development Build Script
# ============================================
# Builds a signed .app bundle for local testing
# No notarization needed - just local signing

echo "🛑 Killing existing app..."
pkill -9 MCPServerManager 2>/dev/null || true

echo "🔨 Building Swift app..."
cd MCPServerManager
swift build -c release

echo "📦 Creating .app bundle..."
rm -rf build/MCP-Server-Manager.app
mkdir -p build/MCP-Server-Manager.app/Contents/MacOS
mkdir -p build/MCP-Server-Manager.app/Contents/Resources

# Copy binary
cp .build/release/MCPServerManager build/MCP-Server-Manager.app/Contents/MacOS/

# Create Info.plist
cat > build/MCP-Server-Manager.app/Contents/Info.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>MCPServerManager</string>
    <key>CFBundleIdentifier</key>
    <string>com.mcpmanager.app</string>
    <key>CFBundleName</key>
    <string>MCP Server Manager</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>2.0.2-dev</string>
    <key>CFBundleVersion</key>
    <string>999</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
</dict>
</plist>
EOF

# Copy app icon if it exists
if [ -f ../icons/AppIcon.icns ]; then
    echo "🎨 Adding app icon..."
    cp ../icons/AppIcon.icns build/MCP-Server-Manager.app/Contents/Resources/AppIcon.icns
fi

# Copy Swift Resource Bundle (Crucial for Fonts!)
echo "📂 Copying resource bundle..."
if [ -d ".build/release/MCPServerManager_MCPServerManager.bundle" ]; then
    cp -r .build/release/MCPServerManager_MCPServerManager.bundle build/MCP-Server-Manager.app/Contents/Resources/
    echo "✅ Copied resource bundle"
else
    echo "⚠️ Resource bundle not found! Fonts may be missing."
fi

echo "✍️  Code signing..."
cd build

# Sign the app with local dev entitlements (non-sandboxed)
codesign --deep --force --verify --verbose \
  --sign "Developer ID Application: Nikhil Anand (NW6B3R27LQ)" \
  --options runtime \
  --entitlements ../../build/entitlements.mac.plist \
  MCP-Server-Manager.app

# Verify signature
echo "✅ Verifying signature..."
codesign --verify --deep --strict --verbose=2 MCP-Server-Manager.app

echo ""
echo "✅ Done! App built at: MCPServerManager/build/MCP-Server-Manager.app"
echo ""
echo "🚀 To run: open MCPServerManager/build/MCP-Server-Manager.app"
echo ""

# Auto-launch if requested
if [ "$1" == "--launch" ]; then
    echo "🚀 Launching app..."
    open MCP-Server-Manager.app
fi
