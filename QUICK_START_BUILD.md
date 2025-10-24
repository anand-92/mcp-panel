# Quick Start: Building & Distributing

## 🎯 TL;DR - Single Command Builds

### For App Store Submission
```bash
./build-appstore.sh
```
Output: `MCPServerManager/build-appstore/MCPServerManager-v2.0.0.pkg`

Upload via **Transporter.app** or:
```bash
xcrun altool --upload-app -f [PKG_FILE] -t macos -u [APPLE_ID] -p [APP_PASSWORD]
```

### For Direct Distribution (DMG)
Push to GitHub and let Actions handle it:
```bash
git tag v2.0.0
git push origin v2.0.0
```

---

## 📋 Prerequisites Checklist

### App Store Build
- [ ] "3rd Party Mac Developer Application" certificate installed
- [ ] "3rd Party Mac Developer Installer" certificate installed ⚠️ **YOU NEED THIS**
- [ ] `embedded.provisionprofile` in project root ✅ (you have this)
- [ ] App Store Connect account access

### Developer ID Build (DMG)
- [ ] "Developer ID Application" certificate installed ✅ (you have this)
- [ ] `Certificates.p12` in project root ✅ (you have this)
- [ ] GitHub Secrets configured for CI/CD

---

## 🚀 Quickest Path to App Store

### Step 1: Get Missing Certificate (5 minutes)
1. Go to [Apple Developer Certificates](https://developer.apple.com/account/resources/certificates/list)
2. Click **+** to create new certificate
3. Select **"Mac Installer Distribution"**
4. Download and double-click to install

### Step 2: Verify Setup (30 seconds)
```bash
./check-certificates.sh
```

Should show:
- ✅ 3rd Party Mac Developer Application
- ✅ 3rd Party Mac Developer Installer (this is what you're missing)
- ✅ embedded.provisionprofile

### Step 3: Build (2 minutes)
```bash
./build-appstore.sh
```

### Step 4: Upload (5-10 minutes)
1. Open **Transporter.app**
2. Drag and drop the PKG file
3. Wait for upload
4. Check App Store Connect for processing

**Total Time: ~15 minutes**

---

## 🤖 Automated Builds (GitHub Actions)

### One-Time Setup (10 minutes)

1. Export certificates to .p12:
   ```bash
   # In Keychain Access, export each certificate
   # Save as: mac_app_store_cert.p12
   # Save as: mac_installer_cert.p12
   ```

2. Convert to base64:
   ```bash
   base64 -i mac_app_store_cert.p12 | pbcopy
   # Paste into GitHub secret: MAC_APP_STORE_CERT

   base64 -i mac_installer_cert.p12 | pbcopy
   # Paste into GitHub secret: MAC_INSTALLER_CERT
   ```

3. Add remaining secrets:
   - `CERT_PASSWORD` (your .p12 password)
   - `APPLE_ID` (your developer email)
   - `APPLE_APP_SPECIFIC_PASSWORD` (generate at appleid.apple.com)
   - `APPLE_TEAM_ID` (e.g., NW6B3R27LQ)

[Full instructions →](GITHUB_SECRETS.md)

### Trigger Builds

**Manual:**
1. GitHub → Actions → "Build for Mac App Store"
2. Click "Run workflow"
3. Download artifact when complete

**Tag-based:**
```bash
git tag appstore-v2.0.0
git push origin appstore-v2.0.0
```

---

## 📊 Build Comparison

| Feature | App Store (PKG) | Developer ID (DMG) |
|---------|----------------|-------------------|
| **Command** | `./build-appstore.sh` | Auto via GitHub Actions |
| **Output** | `.pkg` | `.dmg` |
| **Time** | ~2 min | ~5-10 min |
| **Notarization** | Not needed | Required |
| **Sandbox** | Required | Optional |
| **Distribution** | App Store only | Anywhere |
| **Auto Updates** | Via App Store | Manual |

---

## 🔧 Troubleshooting

### "No signing identity found"
```bash
# Check what you have:
./check-certificates.sh

# Install missing certificates from:
# https://developer.apple.com/account/resources/certificates/list
```

### Build succeeds but upload fails
- Check Bundle ID matches App Store Connect
- Verify version number hasn't been used before
- Ensure certificates haven't expired

### GitHub Actions fails
- Check GitHub Secrets are correct
- Verify certificate .p12 files aren't password-protected (or password is in secrets)
- Review workflow logs for specific errors

---

## 📚 Full Documentation

- [DISTRIBUTION.md](DISTRIBUTION.md) - Comprehensive distribution guide
- [GITHUB_SECRETS.md](GITHUB_SECRETS.md) - CI/CD secrets setup
- [README.md](README.md) - Complete project documentation

---

## 💡 Best Practices

1. **Version Numbers**: Increment for each submission
   - Update in `build-appstore.sh` before building
   - Use semantic versioning (2.0.0 → 2.0.1)

2. **Testing Before Submission**:
   ```bash
   # Build locally first
   ./build-appstore.sh

   # Install and test
   open MCPServerManager/build-appstore/MCPServerManager-v2.0.0.pkg
   ```

3. **Backup Strategy**:
   - Keep certificates in Keychain Access
   - Export .p12 backups to secure location (not git!)
   - Store GitHub Secrets properly

4. **Release Cadence**:
   - Use GitHub for beta/test builds (DMG)
   - Use App Store for stable releases (PKG)
   - Tag releases consistently

---

## 🎯 Your Next Steps

Since you already have an App Store listing:

1. **Get the installer certificate** (5 min)
   - Download "Mac Installer Distribution" from Apple Developer
   - Install by double-clicking

2. **Run the build** (2 min)
   ```bash
   ./build-appstore.sh
   ```

3. **Upload to App Store** (10 min)
   - Open Transporter
   - Drag PKG file
   - Wait for processing

4. **Submit for review**
   - Go to App Store Connect
   - Fill in "What's New"
   - Submit for review

**You're ready! 🚀**
