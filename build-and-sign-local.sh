#!/bin/bash
set -e

# ============================================
# Local Build, Sign, Notarize Script
# ============================================
# This mirrors the GitHub Actions workflow but runs locally
# Requires: Certificates.p12 and valid Apple Developer credentials

echo "🔨 Building Swift App..."
cd MCPServerManager
swift build -c release

echo "📦 Creating .app bundle..."
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
    <string>com.nikhilanand.mcpservermanager</string>
    <key>CFBundleName</key>
    <string>MCP Server Manager</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>2.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

echo "✍️  Code signing..."
cd build

# Import certificate to keychain
# NOTE: You'll need to set your certificate password if it has one
# security import ../Certificates.p12 -k ~/Library/Keychains/login.keychain-db -P "YOUR_PASSWORD" -T /usr/bin/codesign

# Sign the app
codesign --deep --force --verify --verbose \
  --sign "Developer ID Application: Your Name (TEAM_ID)" \
  --options runtime \
  --entitlements ../../build/entitlements.mac.plist \
  MCP-Server-Manager.app

# Verify signature
echo "✅ Verifying signature..."
codesign --verify --deep --strict --verbose=2 MCP-Server-Manager.app
spctl --assess --type execute --verbose=4 MCP-Server-Manager.app

echo "📮 Notarizing with Apple..."
# Create zip for notarization
ditto -c -k --keepParent MCP-Server-Manager.app MCP-Server-Manager.zip

# Submit for notarization
# You'll need to create an app-specific password at https://appleid.apple.com
xcrun notarytool submit MCP-Server-Manager.zip \
  --apple-id "your-apple-id@example.com" \
  --password "your-app-specific-password" \
  --team-id "YOUR_TEAM_ID" \
  --wait

# Staple the notarization ticket
echo "📌 Stapling notarization..."
xcrun stapler staple MCP-Server-Manager.app

# Verify notarization
echo "✅ Verifying notarization..."
spctl --assess -vv --type install MCP-Server-Manager.app

echo "💿 Creating DMG..."
hdiutil create -volname "MCP Server Manager" \
  -srcfolder MCP-Server-Manager.app \
  -ov -format UDZO \
  MCP-Server-Manager.dmg

echo "✅ Done! DMG created at: MCPServerManager/build/MCP-Server-Manager.dmg"
echo ""
echo "To test: open MCP-Server-Manager.dmg"
