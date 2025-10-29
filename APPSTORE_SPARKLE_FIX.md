# App Store Crash Fix - Sparkle Framework Removal

## Problem
The app was crashing immediately on App Store builds with the error:
```
Library not loaded: @rpath/Sparkle.framework/Versions/B/Sparkle
Termination Reason: Namespace DYLD, Code 1, Library missing
```

Apple's App Store doesn't allow third-party update mechanisms like Sparkle since they provide their own update system through the App Store.

## Solution
We've implemented **conditional compilation** to completely exclude Sparkle from App Store builds while keeping it for DMG builds.

## Changes Made

### 1. **UpdateChecker.swift** - Conditional Compilation
- Wrapped all Sparkle imports and code with `#if !APPSTORE` directives
- App Store builds now return `canCheckForUpdates = false` at compile time
- No runtime dependency on Sparkle framework

### 2. **MCPServerManagerApp.swift** - Conditional Menu Item
- Wrapped Sparkle import with `#if !APPSTORE`
- "Check for Updates" menu item only appears in DMG builds

### 3. **build-appstore.yml** - GitHub Actions Workflow
- Added `-Xswiftc -D -Xswiftc APPSTORE` flags to `swift build` command
- Removed Sparkle.framework copying step (no longer needed)
- App Store builds now compile without Sparkle dependency

### 4. **build-appstore.sh** - Local Build Script
- Added APPSTORE compilation flag for local testing
- Ensures local builds match CI/CD behavior

## Testing

### App Store Build (No Sparkle)
```bash
cd MCPServerManager
swift build -c release -Xswiftc -D -Xswiftc APPSTORE
# Binary has NO dependency on Sparkle.framework
```

### DMG Build (With Sparkle)
```bash
cd MCPServerManager
swift build -c release
# Binary includes Sparkle for auto-updates
```

## Distribution Channels

| Build Type | Sparkle | Updates Via | Build Flag |
|------------|---------|-------------|------------|
| **App Store** | ❌ No | Mac App Store | `-D APPSTORE` |
| **DMG (Direct)** | ✅ Yes | Sparkle Auto-Update | (none) |

## Verification

To verify the App Store build has no Sparkle dependency:
```bash
./build-appstore.sh
otool -L MCPServerManager/build-appstore/MCP\ Server\ Manager.app/Contents/MacOS/MCPServerManager | grep Sparkle
# Should return nothing
```

## Next Steps

1. ✅ Push changes to trigger new App Store build
2. ✅ GitHub Actions will build and upload to App Store Connect
3. 📱 Submit the new build for review
4. 🎉 App should no longer crash on launch

---

**Fixed by:** Conditional compilation with `APPSTORE` flag  
**Date:** October 29, 2025  
**Build affected:** v2.1.63+

