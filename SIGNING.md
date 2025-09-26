# Code Signing Setup for MCP Server Manager

## Local Development Signing

To sign the app locally on your Mac with your developer profile:

### Prerequisites
1. Apple Developer account enrolled in the Apple Developer Program
2. Valid Developer ID Application certificate in Keychain
3. Valid Developer ID Installer certificate (for DMG signing)

### Environment Variables
Set these environment variables before building:

```bash
# Your Apple ID email
export APPLE_ID="your-email@example.com"

# App-specific password (generate at appleid.apple.com)
export APPLE_APP_SPECIFIC_PASSWORD="xxxx-xxxx-xxxx-xxxx"

# Your Apple Developer Team ID (found in Apple Developer portal)
export APPLE_TEAM_ID="XXXXXXXXXX"

# Enable notarization
export NOTARIZE=true
```

### Building with Signing
```bash
npm run build-mac
```

The build process will:
1. Sign the app with your Developer ID certificate
2. Create a signed DMG
3. Notarize the app with Apple (requires internet connection)
4. Staple the notarization ticket to the DMG

### Verify Signing
```bash
# Check app signature
codesign -dv --verbose=4 "dist/mac/MCP Server Manager.app"

# Check notarization
spctl -a -vvv -t install "dist/mac/MCP Server Manager.app"

# Check DMG signature
codesign -dv --verbose=4 dist/*.dmg
```

## GitHub Actions Setup

To enable signing in GitHub Actions, add these secrets to your repository:

1. **MAC_CERTS**: Base64-encoded P12 certificate file
   ```bash
   base64 -i Certificates.p12 | pbcopy
   ```

2. **MAC_CERTS_PASSWORD**: Password for the P12 certificate

3. **APPLE_ID**: Your Apple ID email

4. **APPLE_APP_SPECIFIC_PASSWORD**: App-specific password from appleid.apple.com

5. **APPLE_TEAM_ID**: Your Apple Developer Team ID

### Export Certificate from Keychain
1. Open Keychain Access
2. Find your "Developer ID Application" certificate
3. Right-click → Export
4. Choose P12 format
5. Set a password (use this for MAC_CERTS_PASSWORD)
6. Convert to base64 and add to GitHub secrets

## Troubleshooting

### Certificate Not Found
- Ensure CSC_IDENTITY_AUTO_DISCOVERY is set to true
- Check certificate is in login keychain
- Verify certificate hasn't expired

### Notarization Failed
- Check app-specific password is valid
- Verify Team ID is correct
- Ensure internet connection is stable
- Review notarization log: `xcrun notarytool log`

### Users Still See "Unidentified Developer"
- Verify notarization succeeded
- Check stapling: `xcrun stapler validate "dist/*.dmg"`
- Ensure DMG was downloaded via HTTPS (not HTTP)