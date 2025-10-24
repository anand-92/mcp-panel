# MCP Server Manager - Swift Conversion Quick Reference

## 1. API METHODS INVENTORY (19 Total)

### Config File Operations (4)
| Method | Parameters | Returns | Purpose |
|--------|-----------|---------|---------|
| getConfigPath | configType?: string | Promise<string> | Get default config path (~/.claude.json) |
| selectConfigFile | - | Promise<{canceled, filePath?}> | Native file picker dialog |
| getConfig | path?: string | Promise<ConfigResponse> | Read config file and extract mcpServers |
| saveConfig | servers, configPath? | Promise<SaveResponse> | Update mcpServers section in file |

### Server CRUD (2)
| Method | Parameters | Returns | Purpose |
|--------|-----------|---------|---------|
| addServer | name, config, configPath? | Promise<SaveResponse> | Add single server to config |
| deleteServer | name, configPath? | Promise<SaveResponse> | Remove server from config |

### Profile Management (4)
| Method | Parameters | Returns | Purpose |
|--------|-----------|---------|---------|
| getProfiles | - | Promise<{success, profiles[]}> | List all saved profiles |
| getProfile | name | Promise<{success, servers}> or error | Read profile data |
| saveProfile | name, servers[] | Promise<SaveResponse> | Save profile (array of server names) |
| deleteProfile | name | Promise<SaveResponse> | Delete profile file |

### Global Configuration (2)
| Method | Parameters | Returns | Purpose |
|--------|-----------|---------|---------|
| getGlobalConfigs | - | Promise<{success, configs}> | Read app-level settings |
| saveGlobalConfigs | configs | Promise<SaveResponse> | Write app-level settings |

### Registry (1)
| Method | Parameters | Returns | Purpose |
|--------|-----------|---------|---------|
| fetchRegistry | options?: {cursor?, limit?, query?} | Promise<RegistryListResponse> | Fetch MCP server registry |

### Platform (1)
| Method | Parameters | Returns | Purpose |
|--------|-----------|---------|---------|
| getPlatform | - | string | Get platform identifier |

---

## 2. DATA MODELS SUMMARY

### ServerConfig
```
{
  command?: string
  args?: string[]
  cwd?: string
  env?: {[key]: string}
  transport?: {type: string, url?: string, headers?: {[key]: string}}
  remotes?: [{type: string, url: string, headers?: [...]}]
  [key]: any
}
```

### ServerModel
```
{
  name: string
  config: ServerConfig
  enabled: boolean
  updatedAt: number (timestamp)
  inConfigs: [boolean, boolean]
}
```

### SettingsState
```
{
  confirmDelete: boolean
  cyberpunkMode: boolean
  configPaths: [string, string]
  activeConfigIndex: 0 | 1
}
```

### Enums
```
ViewMode = "grid" | "list"
FilterMode = "all" | "active" | "disabled" | "recent"
```

---

## 3. UI COMPONENT TREE

```
App
├── Header
│   ├── Logo/Title
│   ├── Search Bar (Cmd+K shortcut)
│   ├── Config Switcher (Button1/Button2)
│   └── Settings Button
├── Layout (flex row)
│   ├── Sidebar (collapsible)
│   │   └── Quick Actions
│   │       ├── Explore MCPs
│   │       ├── New Server
│   │       ├── Import JSON
│   │       └── Export JSON
│   └── Main Content
│       ├── Toolbar
│       │   ├── View Toggle (Grid/Raw JSON)
│       │   ├── Filter Dropdown
│       │   ├── Toggle All Switch
│       │   ├── Save Button
│       │   └── Refresh Button
│       └── Content Panel
│           ├── ServerGrid (if grid mode)
│           │   └── ServerCard[] (responsive columns)
│           │       ├── Toggle
│           │       ├── Edit
│           │       ├── Delete
│           │       └── Context Menu
│           ├── RawJsonEditor (if list mode)
│           │   ├── Textarea
│           │   ├── Format Button
│           │   ├── Reset Button
│           │   └── Apply Button
│           └── EmptyState (if no servers)
├── Modals
│   ├── ServerModal
│   │   ├── Textarea for JSON
│   │   ├── Format Button
│   │   ├── Validate Button
│   │   └── Add Servers Button
│   ├── SettingsModal
│   │   ├── Config Path 1 (+ Browse)
│   │   ├── Config Path 2 (+ Browse)
│   │   ├── Confirm Delete Checkbox
│   │   ├── Cyberpunk Mode Checkbox
│   │   ├── Test Connection Button
│   │   └── Save Settings Button
│   ├── OnboardingModal
│   │   ├── Select Config File Button
│   │   └── Continue Button
│   └── ContextMenu
│       ├── Toggle Action
│       └── Delete Action
└── Overlays
    ├── LoadingOverlay
    └── Toast Notifications
```

---

## 4. KEY FEATURES IMPLEMENTATION REQUIREMENTS

### Dual Config Management
- Track 2 config file paths independently
- Switch active config (0 or 1)
- Each server can be in config 1, config 2, or both
- Use `inConfigs: [bool, bool]` to track presence
- Changes only save to active config

### Search & Filtering
- Fuzzy search by server name and config JSON
- Threshold: 0.3 for match sensitivity
- Combine with FilterMode:
  - "all": Show all servers
  - "active": Only in active config
  - "disabled": Not in active config
  - "recent": Sorted by timestamp descending

### Keyboard Shortcuts
| Shortcut | Action |
|----------|--------|
| Cmd+K / Ctrl+K | Focus search input |
| Cmd+N / Ctrl+N | Open "Add servers" modal |
| Cmd+S / Ctrl+S | Manual save |
| Cmd+R / Ctrl+R | Reload from files |
| ESC | Close modals/context menu |

### File Operations
**Import**:
- Accept JSON files with mcpServers property or flat server objects
- Validate all entries before importing
- Add to active config only
- Skip invalid entries

**Export**:
- Export enabled servers from active config
- Wrap in {mcpServers: {...}}
- Filename: mcp-servers-{configName}.json

### Server Validation
Valid if has:
- `command` string (stdio servers), OR
- `transport` object with type, OR
- `remotes` array with URLs

### Settings Persistence
Use UserDefaults equivalent to store:
- `mcp-settings`: {confirmDelete, cyberpunkMode}
- `mcp-configPath1`: First config path
- `mcp-configPath2`: Second config path
- `mcp-activeConfigIndex`: Current active index (0 or 1)
- `mcp-config-selected`: Onboarding completion flag
- `mcp-welcomed`: One-time welcome flag

---

## 5. FILE SYSTEM PATHS

```
~/.claude.json                          # Main config (default)
~/.settings.json                        # Secondary config (default)
~/.mcp-manager/                         # App data directory
  ├── profiles/                         # Saved profiles
  │   ├── profile1.json
  │   ├── profile2.json
  │   └── ...
  └── global-configs.json              # App-level settings
```

---

## 6. VALIDATION RULES

### Server Config
```
Valid = (command exists AND not empty) 
    OR (transport exists AND has type)
    OR (remotes exists AND not empty)
```

### JSON Import
- Auto-wrap incomplete objects: `{...}` → `{...}`
- Remove trailing commas: `,}` → `}`
- Parse and validate each entry
- Skip invalid entries (with count report)
- Check for duplicates (prevent additions)

### File Operations
- Missing files: Return empty config, don't create
- Parse errors: Report error message
- Permission errors: Report error message
- Success: Return full structure with metadata

---

## 7. NOTIFICATION TYPES

### Success (Green)
- "Server {name} added to {config}"
- "Server {name} removed from {config}"
- "Server {name} deleted"
- "Server {name} updated"
- "Configuration saved"
- "Servers loaded successfully"
- "JSON formatted successfully"
- "Settings updated"
- "Configuration exported"
- "Imported {count} server(s)"

### Error (Red)
- "Failed to load servers: {error}"
- "Config file not found"
- "Invalid JSON: {error}"
- "Invalid server configuration for {name}"
- "Server {name} already exists"
- "Failed to save servers: {error}"
- "No valid servers found in file"
- "Connection failed: {error}"

### Info/Status
- "Now modifying {configPath}"
- "Loading configuration…"

---

## 8. PLATFORM-SPECIFIC NOTES

### macOS/iOS (Swift)
- Use FileManager for file operations
- Use DocumentPickerViewController or NSSavePanel for file selection
- UserDefaults for preferences storage
- Use URLSession for registry API
- Dark mode support out of box
- Keyboard shortcuts via Keyboard shortcuts framework
- Notifications via local notifications

### Color Palette (Dark Theme)
```
Background: #0f172a (Slate-900)
Dark Base: #070b1f, #05060f (Slate-950)
Text: #e2e8f0 (Slate-100)
Primary: Sky-500 to Fuchsia-500 gradient
Accent: Cyan, Indigo
Success: Emerald-400
Error: Rose-400
Muted: Slate-400/600
```

### Cyberpunk Mode Colors
```
Background: Purple gradient (#090018 to #0b0142)
Text: #e2e8f0
Border: Cyan-400 with 30% opacity
Glow: Cyan-400 shadow effects
```

---

## 9. ERROR HANDLING PATTERNS

```
File not found (ENOENT)
  → Return empty config { success: true, servers: {} }

Parse error
  → Return { success: false, error: "JSON parse error..." }

Permission error
  → Return { success: false, error: "Permission denied..." }

Network error (registry)
  → Return { success: false, error: "Network request failed..." }

Invalid config
  → Reject with error message, show in UI

Validation failure
  → Prevent operation, show specific error
```

---

## 10. IMPLEMENTATION PRIORITY

### Phase 1 (Core)
- [ ] Data models and types
- [ ] File system abstraction (read/write JSON)
- [ ] API methods (config operations)
- [ ] Settings persistence
- [ ] Basic UI layout

### Phase 2 (Features)
- [ ] Server Grid view
- [ ] Modals (all 4 types)
- [ ] Search and filtering
- [ ] File import/export
- [ ] Keyboard shortcuts

### Phase 3 (Polish)
- [ ] Cyberpunk theme
- [ ] Notifications system
- [ ] Registry integration
- [ ] Animations and transitions
- [ ] Accessibility features

### Phase 4 (Optimization)
- [ ] Performance tuning
- [ ] Error recovery
- [ ] Testing coverage
- [ ] App Store submission prep

---

## Files Referenced

### Key Source Files
- `/renderer/src/App.tsx` - Main app logic and all UI components (2057 lines)
- `/renderer/src/api.ts` - API wrapper functions
- `/renderer/src/types.ts` - TypeScript type definitions
- `/renderer/src/registry.ts` - Registry types and fetch logic
- `/renderer/src/global.d.ts` - Window.api interface definition
- `/electron-main-ipc.js` - IPC handler implementations
- `/preload.js` - IPC bridge exposure
- `/server.js` - Express server with REST API equivalents

### Styles
- `/renderer/src/index.css` - Tailwind + custom CSS

