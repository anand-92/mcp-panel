#!/bin/bash

echo "🚀 Building MCP Server Manager locally (no signing/notarization)..."

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
fi

# Build without code signing or notarization
echo "🔨 Building Mac application (unsigned)..."
CSC_IDENTITY_AUTO_DISCOVERY=false npx electron-builder --mac --publish never -c.mac.identity=null

echo "✅ Local build complete!"
echo "📂 The unsigned app is available in: dist/mac/"
echo ""
echo "⚠️  Note: This build is unsigned and not notarized"
echo "    - For local testing only"
echo "    - Will require security bypass to run"
echo "    - Use ./package-mac-signed.sh for distribution builds"