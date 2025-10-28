# Release Notes Guide

This guide explains how release notes work in MCP Server Manager and how to customize them.

## 🎯 What Users See

When a new update is available, users will see:

1. **Update notification** in the app (⌘U or automatic check)
2. **Sparkle update dialog** with:
   - Version number
   - Beautifully formatted HTML release notes
   - Download size and update button

The release notes are displayed in a native macOS window with:
- Apple system fonts
- Proper styling and spacing
- Bullet points for features, improvements, and bug fixes
- "NEW" badges for major features
- Version and build information

## 📝 How It Works

The system uses **two sources** for release notes:

### 1. **Sparkle Update Dialog** (What users see in-app)
- Source: `build-dmg.yml` workflow → "Generate Release Notes HTML" step
- Format: HTML file with inline CSS
- Location: Embedded in appcast.xml and uploaded as separate HTML file
- Updates: Automatically on every push to `main` or `swifty`

### 2. **GitHub Release Page** (What users see on GitHub)
- Source: `build-dmg.yml` workflow → "Create or Update Release" step
- Format: Markdown
- Location: GitHub Releases page
- Updates: Automatically on every push

### 3. **CHANGELOG.md** (Optional reference)
- Source: Manual editing in repository
- Format: Markdown
- Purpose: Historical record and easy reference for updating workflows
- **Note:** Not automatically used by workflows - you must manually sync

## ✏️ How to Customize Release Notes

### Option 1: Edit the Workflow (Quick Updates)

For quick changes to release notes, edit the workflow files directly:

**For Sparkle (in-app updates):**
```bash
# Edit this file
.github/workflows/build-dmg.yml

# Find the "Generate Release Notes HTML" step (around line 244)
# Edit the HTML content between NOTES_EOF markers
```

**For GitHub Releases:**
```bash
# Edit this file
.github/workflows/build-dmg.yml

# Find the "Create or Update Release" step (around line 481)
# Edit the 'body:' section with your markdown content
```

### Option 2: Maintain CHANGELOG.md (Best Practice)

For better organization, maintain `CHANGELOG.md`:

1. **Add new changes to `[Unreleased]` section** as you work:
   ```markdown
   ## [Unreleased]

   ### Added
   - New server validation feature
   - Support for custom themes

   ### Fixed
   - Bug in config parser
   ```

2. **Before release, move to a new version section:**
   ```markdown
   ## [2.1.0] - 2025-02-01

   ### Added
   - New server validation feature
   - Support for custom themes

   ### Fixed
   - Bug in config parser
   ```

3. **Copy the content to both workflow locations**:
   - Update HTML in "Generate Release Notes HTML" step
   - Update Markdown in "Create or Update Release" step

4. **Commit and push** - the workflows will use your new notes

## 🎨 HTML Release Notes Template

The HTML template supports:

```html
<h3>✨ New Features</h3>
<ul>
  <li><strong>Feature Name</strong> <span class="new-badge">New</span> - Description</li>
  <li><strong>Another Feature</strong> - Description</li>
</ul>

<h3>🔧 Improvements</h3>
<ul>
  <li>Improvement description</li>
</ul>

<h3>🐛 Bug Fixes</h3>
<ul>
  <li>Bug fix description</li>
</ul>
```

### Available CSS Classes

- `.new-badge` - Blue badge that says "NEW"
- `.highlight` - Code highlighting for technical terms

## 🚀 Release Process

### Automatic Releases (Current Setup)

Every push to `main` or `swifty`:
1. Workflow builds DMG
2. Generates HTML release notes
3. Creates appcast.xml with embedded notes
4. Uploads to GitHub Releases with "latest" tag
5. Users get notified of updates automatically

### Manual Version Releases

For specific version releases:

```bash
# Update CHANGELOG.md with final notes
vim CHANGELOG.md

# Update workflow files with the same notes
vim .github/workflows/build-dmg.yml

# Commit changes
git add CHANGELOG.md .github/workflows/build-dmg.yml
git commit -m "Update release notes for v2.1.0"

# Create and push version tag
git tag v2.1.0
git push origin v2.1.0
```

This creates a permanent release with those notes.

## 📊 Files Involved

| File | Purpose | Format | Auto-updated? |
|------|---------|--------|---------------|
| `.github/workflows/build-dmg.yml` | Build automation + release notes generation | YAML with embedded HTML/Markdown | No - manual edit |
| `CHANGELOG.md` | Human-readable history | Markdown | No - manual edit |
| `build/release-notes.html` | Generated HTML for Sparkle | HTML | Yes - by workflow |
| `build/appcast.xml` | Sparkle update feed | XML | Yes - by workflow |
| GitHub Release body | Release notes on GitHub | Markdown | Yes - by workflow |

## 🎯 Best Practices

1. **Keep CHANGELOG.md updated** as you develop
2. **Before each release:**
   - Review and finalize CHANGELOG.md
   - Sync changes to workflow files
   - Test the HTML rendering locally if needed
3. **Use consistent format:**
   - Always use ✨ Added, 🔧 Changed, 🐛 Fixed categories
   - Write from user perspective ("You can now..." vs "Added feature...")
   - Keep bullet points concise (1-2 lines max)
4. **Version numbering:**
   - Use semantic versioning (MAJOR.MINOR.PATCH)
   - Update version in workflow if changing major/minor

## 🧪 Testing Release Notes

To preview how release notes will look:

### Test HTML Locally
```bash
# Create a test HTML file
cat > test-release-notes.html << 'EOF'
[paste HTML from workflow]
EOF

# Open in browser
open test-release-notes.html
```

### Test Full Update Flow
```bash
# Build locally
./build-and-sign-local.sh

# Check the generated appcast.xml
cat MCPServerManager/build/appcast.xml

# Look for <sparkle:releaseNotesLink> or <description> with CDATA
```

## 📚 Examples

### Example 1: Bug Fix Release

```markdown
## [2.0.3] - 2025-02-05

### Fixed 🐛
- Fixed crash when deleting servers with long names
- Resolved memory leak in icon loading service
- Corrected window positioning on external displays
```

### Example 2: Feature Release

```markdown
## [2.1.0] - 2025-02-15

### Added ✨
- **Dark Mode Toggle** <span class="new-badge">New</span> - Switch between light and dark themes
- **Keyboard Navigation** - Navigate servers with arrow keys
- **Bulk Operations** - Select and toggle multiple servers at once

### Changed 🔧
- Improved server card animations
- Faster config file parsing (2x speed improvement)

### Fixed 🐛
- Fixed search not working with special characters
```

## ❓ Troubleshooting

**Release notes not showing in Sparkle:**
- Check appcast.xml was generated and uploaded
- Verify `<sparkle:releaseNotesLink>` or `<description>` tag exists
- Ensure HTML is properly escaped in CDATA section

**HTML formatting looks broken:**
- Validate HTML syntax
- Check CSS is included in `<style>` tag
- Test HTML file directly in browser

**Users not getting updates:**
- Verify SUFeedURL in Info.plist points to correct appcast.xml
- Check GitHub release "latest" tag exists
- Confirm appcast.xml is publicly accessible

## 🔗 Resources

- [Sparkle Documentation](https://sparkle-project.org/)
- [Keep a Changelog](https://keepachangelog.com/)
- [Semantic Versioning](https://semver.org/)
- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
