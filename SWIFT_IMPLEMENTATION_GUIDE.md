# MCP Server Manager - Swift Implementation Guide

## Architecture Overview

The MCP Server Manager Swift version should follow this architecture:

```
┌─────────────────────────────────────────────────────────────┐
│                         UI Layer                            │
│  (SwiftUI Views / ViewControllers)                         │
├─────────────────────────────────────────────────────────────┤
│                     State Management                        │
│  (ObservableObject / @State / @StateObject)                │
├─────────────────────────────────────────────────────────────┤
│                      Service Layer                          │
│  (ConfigManager, ServerManager, RegistryClient)            │
├─────────────────────────────────────────────────────────────┤
│                    File System Layer                        │
│  (FileManager abstraction, JSON encoding/decoding)         │
├─────────────────────────────────────────────────────────────┤
│                     Network Layer                           │
│  (URLSession for registry API)                             │
└─────────────────────────────────────────────────────────────┘
```

## Layer Responsibilities

### UI Layer (SwiftUI)
- Main App view
- Header view with search
- Sidebar view
- Server grid/list views
- All modal views
- Navigation and state binding

### State Management
- MainViewModel (central state container)
  - servers: [ServerModel]
  - settings: SettingsState
  - viewMode: ViewMode
  - filterMode: FilterMode
  - searchQuery: String
  - loadingState: LoadingState

### Service Layer
Each service handles specific domain logic:

**ConfigManager**
- Load/save config files
- Parse mcpServers section
- Handle dual config logic
- File system operations

**ServerManager**
- CRUD operations for servers
- Validation logic
- Search/filter logic
- Sync to config files

**ProfileManager**
- List profiles
- Load/save profiles
- Delete profiles
- Profile file operations

**RegistryClient**
- Fetch from registry API
- Handle pagination
- Parse registry responses
- Format registry data

### File System Layer
- FileManager wrapper
- Path expansion (~/ handling)
- JSON encoding/decoding
- Directory creation
- Error handling

### Network Layer
- URLSession configuration
- Registry API requests
- Error handling
- Timeout management

---

## Data Models (Swift Structures)

```swift
// MARK: - Core Models

struct ServerConfig: Codable {
    var command: String?
    var args: [String]?
    var cwd: String?
    var env: [String: String]?
    var transport: ServerTransportConfig?
    var remotes: [ServerRemoteConfig]?
    // Support additional unknown fields
}

struct ServerModel: Identifiable {
    let id: String  // Same as name
    var name: String
    var config: ServerConfig
    var enabled: Bool
    var updatedAt: TimeInterval
    var inConfigs: (Bool, Bool)
}

struct SettingsState: Codable {
    var confirmDelete: Bool = true
    var cyberpunkMode: Bool = false
    var configPaths: (String, String)
    var activeConfigIndex: Int = 0
}

// MARK: - API Response Models

struct ConfigResponse: Decodable {
    let success: Bool
    let servers: [String: ServerConfig]
    let fullConfig: ConfigFile?
    let isNew: Bool?
    let error: String?
}

struct SaveResponse: Decodable {
    let success: Bool
    let error: String?
}

// MARK: - Enums

enum ViewMode: String {
    case grid
    case list
}

enum FilterMode: String {
    case all
    case active
    case disabled
    case recent
}

enum LoadingState {
    case idle
    case loading
    case error(String)
}
```

---

## MainViewModel Implementation Structure

```swift
class MainViewModel: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var servers: [ServerModel] = []
    @Published var settings: SettingsState
    @Published var viewMode: ViewMode = .grid
    @Published var filterMode: FilterMode = .all
    @Published var searchQuery: String = ""
    @Published var loadingState: LoadingState = .idle
    @Published var selectedServer: ServerModel? = nil
    
    // MARK: - Modal States
    @Published var showServerModal = false
    @Published var showSettingsModal = false
    @Published var showOnboarding = false
    @Published var serverModalJSON = ""
    
    // MARK: - Private Properties
    private let configManager: ConfigManager
    private let serverManager: ServerManager
    private let registryClient: RegistryClient
    
    // MARK: - Computed Properties
    var filteredServers: [ServerModel] {
        var result = servers
        
        // Apply filter
        switch filterMode {
        case .all:
            break
        case .active:
            result = result.filter { $0.inConfigs.0 == (settings.activeConfigIndex == 0) || 
                                               $0.inConfigs.1 == (settings.activeConfigIndex == 1) }
        case .disabled:
            result = result.filter { !($0.inConfigs.0 == (settings.activeConfigIndex == 0) || 
                                       $0.inConfigs.1 == (settings.activeConfigIndex == 1)) }
        case .recent:
            result.sort { $0.updatedAt > $1.updatedAt }
        }
        
        // Apply search
        if !searchQuery.isEmpty {
            result = result.filter { $0.name.lowercased().contains(searchQuery.lowercased()) }
        }
        
        return result
    }
    
    // MARK: - Initialization
    override init() {
        self.configManager = ConfigManager()
        self.serverManager = ServerManager(configManager: configManager)
        self.registryClient = RegistryClient()
        self.settings = SettingsState(
            configPaths: ("~/.claude.json", "~/.settings.json"),
            activeConfigIndex: 0
        )
        super.init()
        
        loadSettings()
    }
    
    // MARK: - Initialization Methods
    func loadSettings() {
        // Load from UserDefaults
    }
    
    func saveSettings() {
        // Save to UserDefaults
    }
    
    // MARK: - Server Operations
    func addServer(_ name: String, config: ServerConfig) async throws {
        try await serverManager.addServer(name, config: config, 
                                         to: settings.configPaths.0)
        await loadServers()
    }
    
    func deleteServer(_ name: String) async throws {
        try await serverManager.deleteServer(name,
                                            from: settings.configPaths.0)
        await loadServers()
    }
    
    func toggleServer(_ name: String) {
        // Update server's inConfigs array
    }
    
    // MARK: - File Operations
    func loadServers() async {
        loadingState = .loading
        do {
            let config1 = try await configManager.loadConfig(from: settings.configPaths.0)
            let config2 = try await configManager.loadConfig(from: settings.configPaths.1)
            
            // Merge servers from both configs
            servers = mergeServers(config1.servers, config2.servers)
            loadingState = .idle
        } catch {
            loadingState = .error(error.localizedDescription)
        }
    }
    
    func saveServers() async {
        do {
            let configServers = servers.reduce(into: [String: ServerConfig]()) { dict, server in
                if (settings.activeConfigIndex == 0 && server.inConfigs.0) ||
                   (settings.activeConfigIndex == 1 && server.inConfigs.1) {
                    dict[server.name] = server.config
                }
            }
            try await configManager.saveConfig(configServers,
                                              to: settings.configPaths.0)
        } catch {
            // Show error notification
        }
    }
    
    // MARK: - Import/Export
    func importServers(from file: URL) async throws {
        // Parse JSON file and import
    }
    
    func exportServers(to file: URL) async throws {
        // Export current servers to JSON file
    }
    
    // MARK: - Registry
    func fetchRegistry(query: String? = nil) async throws -> [RegistryServer] {
        return try await registryClient.fetch(query: query)
    }
}
```

---

## Service Layer Implementation

### ConfigManager
```swift
class ConfigManager {
    private let fileManager: FileManager
    
    func loadConfig(from path: String) async throws -> ConfigFile {
        let expandedPath = expandPath(path)
        let data = try Data(contentsOf: URL(fileURLWithPath: expandedPath))
        let config = try JSONDecoder().decode(ConfigFile.self, from: data)
        return config
    }
    
    func saveConfig(_ servers: [String: ServerConfig], 
                   to path: String) async throws {
        let expandedPath = expandPath(path)
        // Load existing config to preserve other properties
        var config = try loadConfig(from: path)
        config.mcpServers = servers
        
        let data = try JSONEncoder().encode(config)
        try data.write(to: URL(fileURLWithPath: expandedPath))
    }
    
    private func expandPath(_ path: String) -> String {
        if path.hasPrefix("~/") {
            return NSHomeDirectory() + "/" + path.dropFirst(2)
        }
        return path
    }
}
```

### ServerManager
```swift
class ServerManager {
    private let configManager: ConfigManager
    
    func addServer(_ name: String, config: ServerConfig, to path: String) async throws {
        var configFile = try await configManager.loadConfig(from: path)
        configFile.mcpServers[name] = config
        try await configManager.saveConfig(configFile.mcpServers, to: path)
    }
    
    func deleteServer(_ name: String, from path: String) async throws {
        var configFile = try await configManager.loadConfig(from: path)
        configFile.mcpServers.removeValue(forKey: name)
        try await configManager.saveConfig(configFile.mcpServers, to: path)
    }
    
    func validateServer(_ config: ServerConfig) -> Bool {
        return (config.command != nil && !(config.command?.isEmpty ?? true)) ||
               (config.transport != nil) ||
               (config.remotes != nil && !(config.remotes?.isEmpty ?? true))
    }
}
```

---

## View Hierarchy (SwiftUI)

### Root View
```swift
struct ContentView: View {
    @StateObject var viewModel = MainViewModel()
    
    var body: some View {
        ZStack {
            if viewModel.showOnboarding {
                OnboardingView()
                    .environmentObject(viewModel)
            } else {
                MainView()
                    .environmentObject(viewModel)
            }
            
            if case .loading = viewModel.loadingState {
                LoadingOverlay()
            }
        }
        .onAppear {
            Task {
                await viewModel.loadServers()
            }
        }
    }
}
```

### Main View Components
```swift
struct MainView: View {
    @EnvironmentObject var viewModel: MainViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            HeaderView()
                .environmentObject(viewModel)
            
            HStack(spacing: 0) {
                if !UIDevice.current.userInterfaceIdiom.isPhone {
                    SidebarView()
                        .environmentObject(viewModel)
                }
                
                VStack(spacing: 0) {
                    ToolbarView()
                        .environmentObject(viewModel)
                    
                    ContentView()
                        .environmentObject(viewModel)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .sheet(isPresented: $viewModel.showServerModal) {
            ServerModalView()
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $viewModel.showSettingsModal) {
            SettingsModalView()
                .environmentObject(viewModel)
        }
    }
}
```

---

## File Organization

```
Sources/
├── App/
│   ├── MCPServerManagerApp.swift
│   └── ContentView.swift
├── Models/
│   ├── ServerConfig.swift
│   ├── ServerModel.swift
│   ├── SettingsState.swift
│   └── APIModels.swift
├── ViewModels/
│   └── MainViewModel.swift
├── Views/
│   ├── MainView.swift
│   ├── HeaderView.swift
│   ├── SidebarView.swift
│   ├── ToolbarView.swift
│   ├── ServerGridView.swift
│   ├── ServerCardView.swift
│   ├── RawJsonEditorView.swift
│   ├── EmptyStateView.swift
│   ├── LoadingOverlayView.swift
│   ├── ServerModalView.swift
│   ├── SettingsModalView.swift
│   ├── OnboardingModalView.swift
│   └── ContextMenuView.swift
├── Services/
│   ├── ConfigManager.swift
│   ├── ServerManager.swift
│   ├── ProfileManager.swift
│   └── RegistryClient.swift
├── Utilities/
│   ├── FileSystemHelper.swift
│   ├── JSONHelper.swift
│   ├── ValidationHelper.swift
│   └── NotificationManager.swift
└── Extensions/
    ├── URL+Extensions.swift
    ├── String+Extensions.swift
    └── Color+Extensions.swift
```

---

## Key Implementation Considerations

### 1. Async/Await Usage
- Use Swift's async/await for all file operations
- Network requests should be async
- Use `@MainActor` for UI updates

### 2. Error Handling
- Use custom error types (ServerManagerError, ConfigError, etc.)
- Propagate errors to UI as notifications
- Implement graceful degradation

### 3. State Management
- Use `@StateObject` for root view models
- Use `@EnvironmentObject` to pass down
- Minimize prop drilling with environment
- Consider using Combine for complex state

### 4. File Operations
- Wrap FileManager calls
- Handle path expansion consistently
- Provide fallback paths
- Log file operations for debugging

### 5. JSON Encoding/Decoding
- Use `Codable` protocol
- Handle unknown fields with custom CodingKeys
- Provide default values for optional fields
- Test edge cases

### 6. Search Implementation
- Use local filtering (no external library needed)
- Filter on display name and JSON string representation
- Support substring and fuzzy matching
- Cache search results

### 7. Notifications
- Create a notification manager service
- Use NSNotification or custom delegates
- Implement toast notifications
- Auto-dismiss after timeout

### 8. Keyboard Shortcuts
- Register with NSEvent or UIKeyboardShortcut
- Map Cmd+K, Cmd+N, Cmd+S, Cmd+R
- Handle ESC for modals
- Ensure shortcuts don't conflict

### 9. Theme Support
- Use environment values for colors
- Support light/dark mode
- Implement cyberpunk mode toggle
- Store theme preference

### 10. Testing Strategy
- Unit tests for managers
- Mock file system operations
- Test JSON encoding/decoding
- UI snapshot tests

---

## Common Pitfalls to Avoid

1. **Threading Issues**
   - Always update UI on main thread
   - Use `@MainActor` appropriately
   - Handle background file operations

2. **Memory Management**
   - Avoid retain cycles in closures
   - Use `[weak self]` in completion handlers
   - Clean up observers and listeners

3. **State Synchronization**
   - Keep local state and files in sync
   - Handle concurrent modifications
   - Implement conflict resolution

4. **Path Handling**
   - Always expand `~/` paths
   - Use `FileManager.default.urls(for:in:)`
   - Handle both absolute and relative paths

5. **JSON Safety**
   - Validate all incoming JSON
   - Handle unknown fields gracefully
   - Implement proper error messages

6. **Performance**
   - Don't block main thread
   - Cache computed properties
   - Implement efficient search
   - Use lazy loading where appropriate

---

## Testing Checklist

- [ ] Config file read/write
- [ ] Dual config management
- [ ] Server validation
- [ ] JSON import/export
- [ ] Search and filtering
- [ ] Keyboard shortcuts
- [ ] File picker integration
- [ ] Settings persistence
- [ ] Profile management
- [ ] Registry API integration
- [ ] Error handling
- [ ] UI responsiveness

---

## Deployment Considerations

### macOS
- Code signing requirements
- Entitlements (file access)
- Sandboxing implications
- Notarization process

### App Store
- Privacy policy required
- Limited file access
- No external utilities
- Review guidelines compliance

---

## Reference Implementation

Use the JavaScript version as reference for:
- Logic flows and algorithms
- Validation rules
- Error handling patterns
- UI component structure
- Data merging logic

But adapt for Swift idioms:
- Use native types and structures
- Follow Swift naming conventions
- Use SwiftUI patterns
- Leverage Swift type safety

