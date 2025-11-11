# Entitlements Configuration

This project uses **two separate entitlement files** for different distribution methods:

## Files

### 1. `entitlements.plist` - DMG Distribution (Direct Download)
**Used for:** GitHub releases, direct downloads, and Sparkle auto-updates

**Key Features:**
- **Sandboxing: DISABLED** (`com.apple.security.app-sandbox = false`)
- Allows Sparkle auto-updater to work properly
- Hardened Runtime enabled for notarization
- Network access for downloads and MCP registry
- User file access for config files

**Why no sandbox?**
Sparkle's installer needs to replace the app bundle in `/Applications`, which requires elevated privileges that don't work in a sandboxed environment. The installer would fail with "An error occurred while launching the installer" if sandboxed.

### 2. `appstore.entitlements` - Mac App Store Distribution
**Used for:** App Store and TestFlight builds

**Key Features:**
- **Sandboxing: REQUIRED** (`com.apple.security.app-sandbox = true`)
- Apple requires sandboxing for all App Store apps
- Security-scoped bookmarks for persistent file access
- Network client access
- User-selected file read/write

**Why sandbox?**
Apple requires all App Store apps to be sandboxed for security. App Store apps use Apple's built-in update mechanism instead of Sparkle.

## Build System Usage

### DMG Builds (`.github/workflows/build-dmg.yml`)
```bash
codesign --force --sign "Developer ID Application: ..." \
  --entitlements ../entitlements.plist \
  --options runtime \
  MCPServerManager.app
```

### App Store Builds (`build-appstore.sh`)
```bash
codesign --force --sign "Apple Distribution: ..." \
  --entitlements ../appstore.entitlements \
  MCPServerManager.app
```

## Key Differences Summary

| Feature | DMG (`entitlements.plist`) | App Store (`appstore.entitlements`) |
|---------|---------------------------|-----------------------------------|
| Sandboxing | ❌ Disabled | ✅ Required |
| Sparkle Updates | ✅ Works | ❌ Not included |
| Distribution | Direct download | App Store only |
| Code Signing | Developer ID Application | Apple Distribution |
| Notarization | Required | Not needed |

## Troubleshooting

**"An error occurred while launching the installer"**
- This means the app is sandboxed but trying to use Sparkle updates
- DMG builds should use `entitlements.plist` (no sandbox)
- App Store builds should not include Sparkle framework

**"Security-scoped bookmark failed"**
- Check that the correct entitlements file is being used
- DMG builds need `com.apple.security.files.user-selected.read-write`
- App Store builds need `com.apple.security.files.bookmarks.app-scope`

## Important Notes

⚠️ **Never use `appstore.entitlements` for DMG builds** - Sparkle won't work
⚠️ **Never use `entitlements.plist` for App Store builds** - Apple will reject it
⚠️ **Never include Sparkle in App Store builds** - Use separate build scripts
