#!/bin/bash

echo "🚀 Building MCP Server Manager for macOS..."

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
fi

# Install electron dependencies
echo "📦 Installing Electron dependencies..."
npm install --save-dev electron electron-builder

# Build the Mac app
echo "🔨 Building Mac application..."
npm run build-mac

echo "✅ Build complete!"
echo "📂 The app is available in: dist/mac/"
echo ""
echo "To distribute the app:"
echo "1. The .dmg file in dist/ can be shared directly"
echo "2. Users can drag the app to their Applications folder"
echo "3. First run may require right-click → Open due to macOS security"