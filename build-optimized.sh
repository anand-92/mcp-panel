#!/bin/bash

echo "🔧 Optimizing MCP Server Manager for production..."

# Clean previous builds
echo "Cleaning previous builds..."
rm -rf dist
rm -rf node_modules

# Install production dependencies only
echo "Installing production dependencies..."
npm install --production --no-optional

# Remove unnecessary files
echo "Removing unnecessary files..."
find . -name "*.map" -delete
find . -name "*.test.js" -delete
find . -name "*.spec.js" -delete
find . -name ".DS_Store" -delete

# Install dev dependencies for building only
echo "Installing build tools..."
npm install --save-dev electron electron-builder

# Build the app
echo "Building optimized DMG..."
npm run build-mac

# Clean node_modules after build
echo "Cleaning up build dependencies..."
rm -rf node_modules

# Report sizes
echo ""
echo "✅ Build complete!"
echo "📊 DMG sizes:"
ls -lah dist/*.dmg

echo ""
echo "📦 App bundle size:"
du -sh dist/mac-arm64/*.app 2>/dev/null || du -sh dist/mac/*.app

echo ""
echo "🎉 Optimized build ready for distribution!"
