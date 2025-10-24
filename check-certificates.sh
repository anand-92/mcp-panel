#!/bin/bash

# Quick certificate checker for App Store builds

echo "🔍 Checking for App Store certificates..."
echo ""

echo "App Signing Certificates:"
security find-identity -v -p codesigning | grep "3rd Party Mac Developer Application" || echo "  ❌ Not found"

echo ""
echo "Installer Certificates:"
security find-identity -v -p codesigning | grep "3rd Party Mac Developer Installer" || echo "  ❌ Not found"

echo ""
echo "Developer ID Certificates (for direct distribution):"
security find-identity -v -p codesigning | grep "Developer ID" || echo "  ❌ Not found"

echo ""
echo "Provisioning Profile:"
if [ -f "embedded.provisionprofile" ]; then
    echo "  ✅ embedded.provisionprofile found"
else
    echo "  ❌ embedded.provisionprofile not found"
fi

echo ""
echo "💡 To install missing certificates:"
echo "   1. Go to https://developer.apple.com/account/resources/certificates/list"
echo "   2. Download your certificates"
echo "   3. Double-click to install in Keychain"
