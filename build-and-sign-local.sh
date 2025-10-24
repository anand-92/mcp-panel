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
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
</dict>
</plist>
EOF

# Copy app icon
echo "🎨 Adding app icon..."
cp icons/AppIcon.icns build/MCP-Server-Manager.app/Contents/Resources/AppIcon.icns

echo "✍️  Code signing..."
cd build

# Certificate is already in keychain, no need to import
# If you need to import it again, use: security import ../../Certificates.p12

# Sign the app
codesign --deep --force --verify --verbose \
  --sign "Developer ID Application: Nikhil Anand (NW6B3R27LQ)" \
  --options runtime \
  --entitlements ../../build/entitlements.mac.plist \
  MCP-Server-Manager.app

# Verify signature
echo "✅ Verifying signature..."
codesign --verify --deep --strict --verbose=2 MCP-Server-Manager.app
spctl --assess --type execute --verbose=4 MCP-Server-Manager.app || echo "(Expected: will show as rejected until notarized)"

echo "📮 Notarizing with Apple..."
# Create zip for notarization
ditto -c -k --keepParent MCP-Server-Manager.app MCP-Server-Manager.zip

# Submit for notarization
xcrun notarytool submit MCP-Server-Manager.zip \
  --apple-id "nik.anand.1998@gmail.com" \
  --password "rihd-rlll-nbhd-lzes" \
  --team-id "NW6B3R27LQ" \
  --wait

# Staple the notarization ticket
echo "📌 Stapling notarization..."
xcrun stapler staple MCP-Server-Manager.app

# Verify notarization
echo "✅ Verifying notarization..."
spctl --assess -vv --type install MCP-Server-Manager.app

echo "💿 Creating installer DMG..."
cd ..
bash ../create-dmg.sh build/MCP-Server-Manager.app build/MCP-Server-Manager.dmg
cd build

echo "✅ Done! DMG created at: MCPServerManager/build/MCP-Server-Manager.dmg"
echo ""
echo "To test: open MCP-Server-Manager.dmg"
