# App Store Crash Fix - Complete Solution

## Problem

The app was crashing immediately on launch during Apple's review process with the error:

```
Library not loaded: @rpath/Sparkle.framework/Versions/B/Sparkle
Reason: image not found
Termination Reason: Namespace DYLD, Code 1, Library missing
```

**Root Cause:** Apple's App Store does not allow third-party update mechanisms like Sparkle. Apps distributed through the App Store must use Apple's update system. The binary was being compiled WITH Sparkle linked, but the framework was not being included in the app bundle, causing a dyld crash at runtime.

## Why Previous Attempts Failed

### Attempt 1: Conditional Compilation Flags Only (`-D APPSTORE`)
**Problem:** Swift compilation flags like `-Xswiftc -D -Xswiftc APPSTORE` only affect Swift source code compilation. They do NOT affect Swift Package Manager's dependency resolution. The Package.swift file is evaluated BEFORE compilation, so Sparkle.framework was still being downloaded, linked into the binary, and creating a dyld dependency.

**Result:** Binary still had `@rpath/Sparkle.framework/Versions/B/Sparkle` dependency even though the code was guarded. ❌

### Attempt 2: Runtime Detection Only
**Problem:** Checking for App Store receipt at runtime doesn't prevent the framework from being linked at compile time.

**Result:** Binary still crashes at launch before any runtime code executes. ❌

## The Correct Solution

### Strategy: Dual Package.swift Approach

We maintain TWO Package.swift files:

1. **`Package.swift`** - Standard version WITH Sparkle (for DMG builds)
2. **`Package.swift.appstore`** - App Store version WITHOUT Sparkle

The build process swaps Package.swift BEFORE building, ensuring:
- ✅ Sparkle is never downloaded for App Store builds
- ✅ Sparkle is never linked into the binary
- ✅ No dyld dependency created
- ✅ No runtime crash

### Implementation Details

#### 1. Package.swift.appstore (NEW FILE)
```swift
// NO Sparkle dependency
dependencies: [
    // NO Sparkle for App Store builds - Apple provides update mechanism
],
targets: [
    .executableTarget(
        dependencies: [
            // NO Sparkle dependency
        ],
        ...
    )
]
```

#### 2. Swift Files - `#if canImport(Sparkle)` Guards

**UpdateChecker.swift:**
- All Sparkle imports wrapped in `#if canImport(Sparkle)`
- `canCheckForUpdates` returns `false` when Sparkle unavailable
- All Sparkle-dependent code conditionally compiled

**MCPServerManagerApp.swift:**
- Sparkle import wrapped in `#if canImport(Sparkle)`
- "Check for Updates" menu item only appears when `canCheckForUpdates` is true

#### 3. Build Process Changes

**GitHub Actions (`.github/workflows/build-appstore.yml`):**
```bash
# Swap Package.swift before build
cp Package.swift Package.swift.backup
cp Package.swift.appstore Package.swift

# Build (no Sparkle will be resolved)
swift build -c release

# Restore original Package.swift
mv Package.swift.backup Package.swift

# Verify no Sparkle dependency
if otool -L .build/release/MCPServerManager | grep -i Sparkle; then
  echo "ERROR: Sparkle linked!"
  exit 1
fi
```

**Local Build Script (`build-appstore.sh`):**
Same approach - swap Package.swift before building, restore after.

## Distribution Channels

| Build Type | Sparkle | Updates Via | Build Method |
|------------|---------|-------------|--------------|
| **App Store** | ❌ No | Mac App Store | Package.swift.appstore |
| **DMG (Direct)** | ✅ Yes | Sparkle Auto-Update | Package.swift (standard) |

## Verification Commands

### Verify App Store Build Has No Sparkle:
```bash
./build-appstore.sh
otool -L MCPServerManager/build-appstore/MCP\ Server\ Manager.app/Contents/MacOS/MCPServerManager | grep Sparkle
# Should return nothing (exit code 1)
```

### Verify DMG Build Has Sparkle:
```bash
cd MCPServerManager && swift build -c release
otool -L .build/release/MCPServerManager | grep Sparkle
# Should show: @rpath/Sparkle.framework/Versions/B/Sparkle
```

## Testing Checklist

### App Store Build Testing:
- [x] Binary builds without errors
- [x] `otool -L` shows no Sparkle dependency
- [x] App launches successfully
- [x] No "Check for Updates" menu item visible
- [x] All core functionality works
- [x] No crash on launch

### DMG Build Testing:
- [x] Binary builds without errors
- [x] `otool -L` shows Sparkle dependency
- [x] App launches successfully
- [x] "Check for Updates" menu item visible
- [x] Update checking works
- [x] All core functionality works

## Files Modified

1. **NEW:** `MCPServerManager/Package.swift.appstore` - App Store package manifest
2. **MODIFIED:** `MCPServerManager/MCPServerManager/Services/UpdateChecker.swift` - Added `#if canImport(Sparkle)` guards
3. **MODIFIED:** `MCPServerManager/MCPServerManager/MCPServerManagerApp.swift` - Added `#if canImport(Sparkle)` guards
4. **MODIFIED:** `.github/workflows/build-appstore.yml` - Added Package.swift swap and verification
5. **MODIFIED:** `build-appstore.sh` - Added Package.swift swap and verification
6. **NEW:** `APPSTORE_CRASH_FIX.md` - This documentation

## Next Steps

1. ✅ Push changes to repository
2. ✅ GitHub Actions will automatically build and upload to App Store Connect
3. 📱 Submit the new build for review
4. 🎉 App should pass review without crashes

## Technical Deep Dive

### Why Package.swift Swapping Works

Swift Package Manager resolves dependencies in this order:

```
1. Parse Package.swift → Resolve dependencies → Download packages
2. Compile Swift source files
3. Link binary with resolved dependencies
```

Compilation flags affect step 2, but dependency resolution happens in step 1. By swapping Package.swift BEFORE building, we ensure Sparkle is never resolved in step 1, thus never linked in step 3.

### Why `#if canImport(Sparkle)` is Better Than `#if !APPSTORE`

- **`canImport(Sparkle)`** - True if Sparkle package is available
- **`!APPSTORE`** - True if APPSTORE flag is not set

The `canImport` approach is more robust because it directly checks for Sparkle's presence, regardless of how the build was configured. If someone forgets to set the APPSTORE flag, the code still works correctly.

---

**Fixed by:** Dual Package.swift approach with canImport guards
**Date:** October 29, 2025
**Build version:** v2.1.64+
**Status:** ✅ Ready for App Store submission
