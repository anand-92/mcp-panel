# MCP Server Manager - Swift Conversion Requirements

## Comprehensive Feature & Functionality Analysis

### 1. CORE DATA MODELS & TYPES

#### 1.1 Server Configuration Types
- **ServerConfig**: Main configuration object for MCP servers with:
  - `command?: string` - Local command to start the server
  - `args?: string[]` - Command line arguments
  - `cwd?: string` - Current working directory
  - `env?: Record<string, string>` - Environment variables
  - `transport?: ServerTransportConfig` - Transport configuration (type, url, headers)
  - `remotes?: ServerRemoteConfig[]` - Multiple remote configurations
  - Generic support for additional unknown fields (`[key: string]: unknown`)

#### 1.2 Server Model & Display
- **ServerModel**: Runtime representation with metadata:
  - `name: string` - Server identifier
  - `config: ServerConfig` - The configuration
  - `enabled: boolean` - Enabled/disabled state (internal)
  - `updatedAt: number` - Timestamp of last modification
  - `inConfigs: [boolean, boolean]` - Presence in each config file

#### 1.3 Settings State
- **SettingsState**:
  - `confirmDelete: boolean` - Require confirmation before deleting servers
  - `cyberpunkMode: boolean` - Visual theme toggle
  - `configPaths: [string, string]` - Dual config file paths
  - `activeConfigIndex: 0 | 1` - Which config is currently active

#### 1.4 View & Filter Modes
- **ViewMode**: `'grid' | 'list'` - Display mode for servers
- **FilterMode**: `'all' | 'active' | 'disabled' | 'recent'` - Server filtering

#### 1.5 Registry Types (from registry.ts)
- **RegistryServer**: Server definition from the MCP registry
  - `name: string`
  - `description?: string`
  - `status?: string`
  - `version?: string`
  - `repository?: { url: string; source?: string }`
  - `packages?: RegistryPackage[]` - Installation packages
  - `remotes?: RegistryRemote[]` - Remote configurations
  - `_meta?: RegistryMeta` - Metadata including official registry info

- **RegistryPackage**:
  - `registryType: string`
  - `identifier: string`
  - `version?: string`
  - `registryBaseUrl?: string`
  - `transport?: RegistryPackageTransport`
  - `environmentVariables?: RegistryPackageEnvVariable[]`
  - `instructions?: string`

- **RegistryRemote**:
  - `type: string`
  - `url: string`
  - `headers?: RegistryRemoteHeader[]`

- **RegistryListResponse**:
  - `servers: RegistryServer[]`
  - `metadata?: { next_cursor?: string; count?: number }`

---

### 2. API/IPC INTERFACE (`window.api`)

#### 2.1 Config File Operations
- `getConfigPath(configType?: string): Promise<string>`
  - Returns default config path (e.g., `~/.claude.json`)

- `selectConfigFile(): Promise<{ canceled: boolean; filePath?: string }>`
  - Opens native file picker for config selection

- `getConfig(path?: string): Promise<ConfigResponse>`
  - Reads config file and extracts `mcpServers` section
  - Returns: `{ success, servers, fullConfig, isNew?, error? }`

- `saveConfig(servers: Record<string, ServerConfig>, configPath?: string): Promise<SaveResponse>`
  - Updates `mcpServers` section in config file
  - Preserves other config properties
  - Does NOT create new files

#### 2.2 Server CRUD Operations
- `addServer(name: string, config: ServerConfig, configPath?: string): Promise<SaveResponse>`
  - Adds single server to config

- `deleteServer(name: string, configPath?: string): Promise<SaveResponse>`
  - Removes server from config

#### 2.3 Profile Management
- `getProfiles(): Promise<{ success: boolean; profiles: string[] }>`
  - Lists all saved profiles from `~/.mcp-manager/profiles/`

- `getProfile(name: string): Promise<{ success: boolean; servers: Record<string, ServerConfig> } | { success: false; error: string }>`
  - Reads profile (JSON array of enabled server names)

- `saveProfile(name: string, servers: string[]): Promise<SaveResponse>`
  - Creates/updates profile with array of enabled server names
  - Saves to `~/.mcp-manager/profiles/{name}.json`

- `deleteProfile(name: string): Promise<SaveResponse>`
  - Removes profile file

#### 2.4 Global Configuration
- `getGlobalConfigs(): Promise<{ success: boolean; configs: Record<string, unknown>; error?: string }>`
  - Reads from `~/.mcp-manager/global-configs.json`

- `saveGlobalConfigs(configs: Record<string, unknown>): Promise<SaveResponse>`
  - Writes to `~/.mcp-manager/global-configs.json`
  - Creates directory structure if needed

#### 2.5 Registry Operations
- `fetchRegistry(options?: FetchRegistryOptions): Promise<RegistryListResponse>`
  - Fetches from `https://registry.modelcontextprotocol.io/v0/servers`
  - Options: `{ cursor?: string; limit?: number; query?: string }`
  - Returns paginated registry with server definitions

#### 2.6 Platform Information
- `getPlatform(): string`
  - Returns platform identifier (e.g., 'darwin', 'win32', 'linux')

---

### 3. BACKEND IMPLEMENTATION

#### 3.1 File System Operations
- **Default paths**:
  - Claude config: `~/.claude.json`
  - Settings config: `~/.settings.json`
  - Profiles directory: `~/.mcp-manager/profiles/`
  - Global configs: `~/.mcp-manager/global-configs.json`

- **Path expansion**: Support `~/` prefix expansion to home directory

- **File operations**:
  - Read JSON files with error handling
  - Parse `mcpServers` section from config objects
  - Preserve full config structure when writing (only update mcpServers)
  - Support dual config files simultaneously

#### 3.2 Dual Configuration Management
- Support two independent config files
- Track which servers are in each config via `inConfigs` array
- Active config index determines which file receives changes
- Each config can contain different servers
- Servers exist independently but can be in one or both configs

#### 3.3 Profile System
- Profiles store list of enabled server names (not full configs)
- Each profile is a separate JSON file
- Profiles are lightweight references to servers in main config

---

### 4. UI COMPONENTS & FEATURES

#### 4.1 Layout & Navigation
- **Header Component**:
  - Logo and app title with gradient styling
  - Search bar with keyboard shortcut (Cmd+K)
  - Config file switcher (two buttons for Config 1/2)
  - Status indicator (connected dot with config path)
  - Settings button

- **Sidebar Component** (mobile collapsible):
  - Quick actions section:
    - "Explore New MCPs" button (external link to registry)
    - "New Server" button
    - "Import JSON" button
    - "Export JSON" button
  - Sticky on desktop, collapsible on mobile

- **Main Content Area**:
  - Toolbar with view/filter controls
  - Content panel (grid or raw JSON view)

#### 4.2 Toolbar Features
- **View Mode Toggle**:
  - Grid view: Card-based display of servers
  - Raw JSON view: Full JSON editor

- **Filter Dropdown**:
  - All Servers
  - Active Only (in current config)
  - Disabled Only (not in current config)
  - Recently Modified

- **Server Status Toggle**:
  - "Toggle All" button with switch to enable/disable all servers

- **Action Buttons**:
  - Save: Manual config save trigger
  - Refresh: Reload from files
  - Tooltip feedback on all actions

#### 4.3 Server Grid View
- **Server Cards** (3 columns on desktop, responsive):
  - Server name (with truncation)
  - Configuration summary (command or remote URL)
  - Config presence badges (1, 2 indicators)
  - Toggle button for inclusion
  - Edit button (inline JSON editor)
  - Delete button
  - Context menu (right-click)

- **Inline Editing**:
  - Click to open inline JSON editor within card
  - Format JSON button
  - Save/Cancel buttons
  - Error display for invalid JSON

#### 4.4 Raw JSON Editor View
- Large textarea with monospace font
- Full JSON representation of all servers
- Syntax highlighting support
- **Buttons**:
  - Format JSON: Pretty-print with indentation
  - Reset to current: Discard unsaved changes
  - Apply changes: Save editor changes to state
- **Status indicators**:
  - "Unsaved edits" badge when dirty
  - Error display for invalid JSON
- **Search integration**: Text search highlights in editor

#### 4.5 Modals

##### Server Addition Modal
- Title: "Add servers" (Bulk add section)
- Large textarea for JSON input
- **Buttons**:
  - Format JSON: Pretty-print input
  - Validate: Check JSON validity
  - Cancel
  - Add servers: Bulk import
- **Features**:
  - Accepts partial JSON fragments
  - Auto-wraps `{...}` if needed
  - Removes trailing commas
  - Validates all entries before adding
  - Checks for duplicates
  - Adds to active config

##### Settings Modal
- Title: "Settings" (Preferences section)
- **Config Path Inputs** (both with Browse buttons):
  - Config Path 1: File picker integration
  - Config Path 2: File picker integration
  - Displays path with file picker dialog

- **Checkboxes**:
  - "Ask before deleting servers" - confirm delete toggle
  - "Enable cyberpunk mode" - theme toggle

- **Test Connection Button**:
  - Reads both config files
  - Reports server count for each
  - Shows "Testing..." state during operation

- **Buttons**:
  - Cancel
  - Save settings: Persists changes and reloads

##### Onboarding Modal (First Run)
- Title: "Welcome to MCP Server Manager"
- File selection guidance
- Shows: `~/.claude.json` as typical location
- Keyboard tip for showing hidden files (Cmd+Shift+.)
- Displays selected file path once chosen
- **Buttons**:
  - "Select Config File": Opens file picker
  - "Continue": Completes onboarding

##### Context Menu (Right-click)
- Positioned at cursor
- "Toggle" action (include/exclude server)
- "Delete" action (with confirm)
- Closes on click outside or ESC

#### 4.6 Empty State
- Icon/emoji display
- Message: "No servers configured yet"
- Call-to-action button: "Create Server"

#### 4.7 Loading State
- Animated spinner overlay
- Message: "Loading configuration…"
- Appears during initial load and refresh

#### 4.8 Notifications (Notyf)
- Success notifications (green):
  - Server added/removed/deleted
  - Configuration saved/loaded
  - JSON formatted
  - Settings updated
  - Export complete

- Error notifications (red):
  - Config not found/unreadable
  - Invalid JSON
  - Invalid server config
  - Save failures
  - Connection test failures

- Positioned: Bottom-right corner
- Auto-dismiss after 3 seconds
- With ripple animation effect

#### 4.9 Visual Features
- **Glass-morphism design**: Frosted glass panels with blur
- **Gradient buttons**: Sky-Indigo-Fuchsia gradient for primary actions
- **Cyberpunk mode**:
  - Purple/cyan gradient background
  - Enhanced glow effects on panels
  - Cyan borders and text accents
- **Dark theme**: Slate-950 base with lighter slate text
- **Status indicators**: 
  - Green dot for connected
  - Gray dot for disconnected
  - Config presence badges with numbers (1, 2)

---

### 5. STATE MANAGEMENT & PERSISTENCE

#### 5.1 Local Storage Keys
- `mcp-all-configs`: All servers (backup)
- `mcp-settings`: User settings (confirmDelete, cyberpunkMode)
- `mcp-configPath1`: First config file path
- `mcp-configPath2`: Second config file path
- `mcp-activeConfigIndex`: Currently active config (0 or 1)
- `mcp-config-selected`: Flag for onboarding completion
- `mcp-welcomed`: One-time welcome message flag

#### 5.2 State Updates & Syncing
- **Auto-sync**: Changes automatically saved to config files
- **Skip sync**: During bulk operations to prevent redundant writes
- **Manual save**: Explicit save button for full control
- **Dual sync**: Changes written to active config only
- **Conflict resolution**: 
  - Recent modifications override older values
  - `inConfigs` array tracks presence in each file
  - Servers can exist in local state but not be in any file config

#### 5.3 Runtime State
- Server map with metadata (enabled, updatedAt, inConfigs)
- Current view and filter state
- Search query (client-side fuzzy search with Fuse.js)
- Modal open/close states
- Raw editor dirty state and validation errors
- Context menu position and target
- Sidebar open state (mobile)

---

### 6. SEARCH & FILTERING

#### 6.1 Full-Text Search
- Uses Fuse.js for fuzzy matching
- Searches server names and full config JSON
- Threshold: 0.3 for match sensitivity
- Results filtered in real-time
- Combined with filter mode (active/disabled/recent)

#### 6.2 Search UI Integration
- Keyboard shortcut: Cmd+K to focus search
- Real-time filtering as user types
- Text search in raw JSON editor (highlight and scroll to match)
- Clear search to show all servers

---

### 7. KEYBOARD SHORTCUTS

- **Cmd/Ctrl+K**: Focus search input
- **Cmd/Ctrl+N**: Open "Add servers" modal
- **Cmd/Ctrl+S**: Manual save
- **Cmd/Ctrl+R**: Reload servers from files
- **ESC**: Close all modals and context menus

---

### 8. FILE IMPORT/EXPORT

#### 8.1 Import
- File picker for `.json` files
- Accepts full config objects with `mcpServers` property
- Accepts flat server object (server name -> config)
- Validates all entries before importing
- Skips invalid servers
- Adds to active config
- Shows count of imported servers

#### 8.2 Export
- Exports enabled servers from active config
- Wraps in `{ mcpServers: {...} }` structure
- Generates filename: `mcp-servers-{configName}.json`
- Triggers browser download

---

### 9. VALIDATION & ERROR HANDLING

#### 9.1 Server Config Validation
- **Valid configurations**:
  - Contains `command` string (stdio servers)
  - Contains `transport` object with `type` and optional `url`
  - Contains `remotes` array with URL entries
  - HTTP type with `url` field
  - Stdio type with `command` field

- **Invalid configurations**:
  - Empty strings
  - Missing required fields
  - Non-object/non-array types where expected

#### 9.2 JSON Validation
- Parse errors caught and reported
- Format validation for bulk import
- Fragment handling (auto-wrap in braces)
- Trailing comma cleanup

#### 9.3 File Operations
- Handle missing files (return empty config)
- Handle permission errors
- Handle parsing errors gracefully
- Prevent creation of new files (must exist first)

---

### 10. INITIALIZATION & LIFECYCLE

#### 10.1 App Startup
1. Load persisted settings from localStorage
2. Check onboarding flag
3. If first run: Show onboarding modal
4. If not first run: Load config paths
5. Fetch both config files in parallel
6. Merge servers from both configs
7. Set status indicator
8. Show welcome notification (once)
9. Mark app as ready

#### 10.2 Config Switching
- Switch `activeConfigIndex` (0 or 1)
- Update status indicator
- Show notification with new config name
- Reload servers to reflect changes
- Save new active index to localStorage

#### 10.3 Cleanup
- Cancel pending operations if unmounting
- Remove event listeners
- Close modals and context menus

---

### 11. SPECIAL FEATURES

#### 11.1 Multi-Config Support
- Two independent config files
- Servers can exist in one or both
- Toggle per-server inclusion in each config
- Active config gets all changes
- Can switch between configs easily
- Shows which configs contain each server

#### 11.2 Cyberpunk Mode
- CSS class toggle on body element
- Different color scheme (purple, cyan, magenta)
- Enhanced glow effects
- Preserved across sessions

#### 11.3 Server Metadata
- Track modification timestamps
- Recent filter sorts by update time
- Visual indication of config presence
- Enabled state (internal, not synced to file)

#### 11.4 Registry Integration
- Fetch official MCP server registry
- Pagination support with cursor
- Search capability
- Display server details and installation instructions
- Link to external registry browser

#### 11.5 Settings Persistence
- All user preferences saved to localStorage
- Config paths persisted
- Active config index remembered
- Settings reloaded on app start

---

### 12. RESPONSIVE DESIGN

- **Mobile**: Single column, collapsible sidebar
- **Tablet**: 2-column server grid
- **Desktop**: 3-column server grid, sticky sidebar
- **Breakpoints**: Tailwind (sm, md, lg, xl)
- **Touch-friendly**: Large tap targets, no hover-only features

---

### 13. ACCESSIBILITY FEATURES

- Semantic HTML structure
- ARIA labels on buttons
- Focus rings on interactive elements
- Keyboard navigation support
- Color contrast ratios
- Error messages linked to inputs
- Form labels associated with inputs

---

### 14. EXTERNAL DEPENDENCIES

#### JavaScript Libraries
- **fuse.js**: Fuzzy search
- **notyf**: Toast notifications
- **react**: UI framework
- **react-dom**: DOM rendering
- **express**: Backend server (web mode)
- **tailwindcss**: Utility CSS styling
- **tippy.js**: Tooltip positioning
- **animate.css**: Animation utilities

#### Frameworks
- **Electron** (desktop mode)
- **Express** (web server mode)
- **Vite** (build tool)
- **React 18** with hooks

---

### 15. CONFIGURATION FILES & PATHS

#### Default Locations
- `~/.claude.json` - Claude MCP servers configuration
- `~/.settings.json` - Optional secondary config
- `~/.mcp-manager/` - App data directory
- `~/.mcp-manager/profiles/` - Saved profiles
- `~/.mcp-manager/global-configs.json` - App-level settings

#### File Formats
- JSON with `mcpServers` object as primary section
- Preserves all other root-level properties
- Pretty-printed with 2-space indentation
- UTF-8 encoding

---

### 16. PERFORMANCE CONSIDERATIONS

- Search uses memoized Fuse index
- Server array sorted and memoized
- Filtered collection memoized
- Auto-sync debouncing via skipSync ref
- Lazy loading of profiles on demand
- Virtual scrolling not currently implemented (could be added)

---

### 17. ERROR RECOVERY

- Graceful fallback if API unavailable
- Fallback to default paths if resolution fails
- Empty config returned for missing files
- Validation errors prevent invalid data
- User-friendly error messages
- Retry capability on connection test

---

## Summary

This comprehensive feature list covers **all functionality** that must be replicated in the Swift conversion:
- 19 core API methods
- 5 major UI components + 7 modals
- Dual config file management
- Fuzzy search with filtering
- Keyboard shortcuts and gestures
- File import/export
- Server validation
- Profile management
- Comprehensive error handling
- Dark theme with cyberpunk mode
- Responsive mobile/tablet/desktop layout
- Registry integration
- Full state persistence
