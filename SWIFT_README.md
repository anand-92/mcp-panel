# Swift Version Available! 🎉

This repository now includes a **native Swift/SwiftUI macOS app** alongside the original Electron version!

## Quick Start

### Electron Version (Original)
```bash
npm install
npm start              # Web mode (http://localhost:3000)
npm run electron       # Desktop app
```

### Swift Version (New!) ⚡
```bash
cd MCPServerManager
swift run
```

## Why Two Versions?

Both versions have the same features and design, but different strengths:

### 🌐 Electron Version
- ✅ Cross-platform (Windows, macOS, Linux)
- ✅ Easier to modify (React/TypeScript)
- ✅ Web-based deployment option
- ✅ Larger community and libraries
- ⚠️ Larger bundle (~150MB)
- ⚠️ Higher memory usage (~200-300MB)

### ⚡ Swift Version
- ✅ Native macOS performance
- ✅ Much smaller bundle (~5-10MB)
- ✅ Lower memory usage (~50-80MB)
- ✅ Faster startup (<1 second)
- ✅ Better battery life
- ✅ Mac App Store ready
- ⚠️ macOS only
- ⚠️ SwiftUI learning curve

## Feature Comparison

| Feature | Electron | Swift |
|---------|----------|-------|
| Dual config management | ✅ | ✅ |
| Server CRUD | ✅ | ✅ |
| Grid & List views | ✅ | ✅ |
| Search & Filtering | ✅ | ✅ |
| Import/Export | ✅ | ✅ |
| Cyberpunk mode | ✅ | ✅ |
| Settings | ✅ | ✅ |
| Onboarding | ✅ | ✅ |
| Profiles | ✅ | 🚧 Future |
| Web hosting | ✅ | ❌ |
| File watching | ✅ | 🚧 Future |

## Which Version Should I Use?

### Choose Electron if you:
- Need Windows or Linux support
- Want to deploy as a web app
- Prefer React/TypeScript
- Need profile features now

### Choose Swift if you:
- Only need macOS
- Want better performance
- Prefer native apps
- Care about bundle size/memory

## Repository Structure

```
mcp-panel/
├── renderer/           # Electron React app
├── server.js           # Express server
├── electron-main-ipc.js # Electron main process
├── MCPServerManager/    # 🆕 Swift macOS app
│   ├── MCPServerManager/
│   │   ├── Views/
│   │   ├── Models/
│   │   └── Services/
│   └── Package.swift
└── README.md
```

## Documentation

- **[Electron README](./README.md)** - Original app documentation
- **[Swift README](./MCPServerManager/README.md)** - Swift app guide
- **[Migration Guide](./MCPServerManager/MIGRATION_GUIDE.md)** - Detailed comparison

## Config File Compatibility

Both versions use the same `~/.claude.json` format, so you can switch between them freely!

## Building from Source

### Electron
```bash
npm run build-mac      # macOS app
npm run dist           # All platforms
```

### Swift
```bash
cd MCPServerManager
swift build -c release
```

Or open in Xcode:
```bash
cd MCPServerManager
swift package generate-xcodeproj
open MCPServerManager.xcodeproj
```

## Contributing

Both versions accept contributions!

- **Electron**: Submit PRs to the main branch
- **Swift**: Submit PRs to the `swifty` branch or main branch

## License

MIT License - Both versions

## Credits

- **Original Electron App**: Nikhil Anand
- **Swift Port**: Built with SwiftUI on the `swifty` branch
- **Icon**: MCP logo with gradient effects

---

**Try both versions and use what works best for you!** 🚀
