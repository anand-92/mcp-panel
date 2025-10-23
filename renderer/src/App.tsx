import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import type { ChangeEvent, MouseEvent as ReactMouseEvent, RefObject } from 'react';
import Fuse from 'fuse.js';
import { Notyf } from 'notyf';
import { fetchConfig, getConfigPath, saveConfig, testConfigPath } from './api';
import type { FilterMode, ServerConfig, ServerModel, SettingsState, ViewMode } from './types';
const DEFAULT_SETTINGS: SettingsState = { confirmDelete: true, cyberpunkMode: false };
const DEFAULT_CLAUDE_CONFIG_PATH = '~/.claude.json';
const DEFAULT_CONFIG_PATH = DEFAULT_CLAUDE_CONFIG_PATH;

interface StatusState {
  connected: boolean;
  message: string;
}

type ServerMap = Record<string, ServerModel>;
type ContextMenuState = { visible: boolean; x: number; y: number; server?: ServerModel };

const parseJSON = <T,>(value: string | null, fallback: T): T => {
  if (!value) {
    return fallback;
  }

  try {
    return JSON.parse(value) as T;
  } catch (error) {
    console.warn('Failed to parse JSON from local storage', error);
    return fallback;
  }
};

const buildServerMapFromLocal = (
  configs: Record<string, ServerConfig>
): ServerMap => {
  const now = Date.now();
  return Object.entries(configs).reduce<ServerMap>((acc, [name, config]) => {
    acc[name] = {
      name,
      config,
      enabled: false,
      updatedAt: now
    };
    return acc;
  }, {});
};

const mergeLocalWithRemote = (local: ServerMap, remote: Record<string, ServerConfig>): ServerMap => {
  const now = Date.now();
  const merged: ServerMap = {};

  Object.values(local).forEach(server => {
    merged[server.name] = { ...server, enabled: false };
  });

  Object.entries(remote).forEach(([name, config]) => {
    const existing = merged[name];
    merged[name] = {
      name,
      config,
      enabled: true,
      updatedAt: existing?.updatedAt ?? now
    };
  });

  return merged;
};

const toEnabledServerConfigs = (map: ServerMap): Record<string, ServerConfig> => {
  return Object.entries(map).reduce<Record<string, ServerConfig>>((acc, [name, server]) => {
    if (server.enabled) {
      acc[name] = server.config;
    }
    return acc;
  }, {});
};

const toAllServerConfigs = (map: ServerMap): Record<string, ServerConfig> => {
  return Object.entries(map).reduce<Record<string, ServerConfig>>((acc, [name, server]) => {
    acc[name] = server.config;
    return acc;
  }, {});
};

const serializeServers = (map: ServerMap): Record<string, Omit<ServerModel, 'name'>> => {
  return Object.entries(map).reduce<Record<string, Omit<ServerModel, 'name'>>>((acc, [name, server]) => {
    acc[name] = {
      config: server.config,
      enabled: server.enabled,
      updatedAt: server.updatedAt
    };
    return acc;
  }, {});
};

const shortPath = (value: string): string => {
  if (!value) return '';
  const normalized = value.replace(/\\/g, '/');
  const parts = normalized.split('/');
  return parts[parts.length - 1] || normalized;
};

const formatJsonString = (value: string): string => JSON.stringify(JSON.parse(value), null, 2);

const formatUrlHost = (value: string): string => {
  try {
    const parsed = new URL(value);
    return parsed.host;
  } catch (error) {
    console.warn('Failed to parse remote URL', error);
    return value;
  }
};

const summarizeServerConfig = (config: ServerConfig): string => {
  if (config.command && config.command.trim().length > 0) {
    return config.command.trim();
  }

  if (config.transport && typeof config.transport === 'object') {
    const transport = config.transport as { type?: string; url?: string };
    const type = typeof transport.type === 'string' ? transport.type : 'remote';
    const url = typeof transport.url === 'string' ? formatUrlHost(transport.url) : 'custom endpoint';
    return `Remote ${type} → ${url}`;
  }

  if (Array.isArray((config as Record<string, unknown>).remotes)) {
    const remotes = (config as { remotes?: Array<{ type?: string; url?: string }> }).remotes ?? [];
    if (remotes.length > 0) {
      const remote = remotes[0];
      const type = remote?.type ?? 'remote';
      const url = remote?.url ? formatUrlHost(remote.url) : 'custom endpoint';
      return `Remote ${type} → ${url}`;
    }
  }

  return 'Custom server configuration';
};

const isValidServerConfig = (config: unknown): config is ServerConfig => {
  if (!config || typeof config !== 'object') {
    return false;
  }

  const candidate = config as Record<string, unknown>;

  // Check for stdio-type servers (with type field)
  if (candidate.type === 'stdio') {
    return typeof candidate.command === 'string' && candidate.command.trim().length > 0;
  }

  // Check for HTTP-type servers (with type and url fields)
  if (candidate.type === 'http') {
    return typeof candidate.url === 'string' && candidate.url.trim().length > 0;
  }

  // Check for standard command-based servers (without type field)
  const hasCommand = typeof candidate.command === 'string' && candidate.command.trim().length > 0;
  const hasTransport = candidate.transport && typeof candidate.transport === 'object';
  const hasRemotes = Array.isArray(candidate.remotes) && candidate.remotes.length > 0;

  return hasCommand || Boolean(hasTransport) || hasRemotes;
};

const extractServerEntries = (raw: string): Record<string, ServerConfig> => {
  let normalized = raw.trim();

  // Handle JSON fragments: if it doesn't start with {, try wrapping it
  if (!normalized.startsWith('{')) {
    normalized = `{${normalized}}`;
  }

  // Remove trailing commas before closing braces (common copy-paste issue)
  normalized = normalized.replace(/,(\s*[}\]])/g, '$1');

  const parsed = JSON.parse(normalized);

  if (parsed && typeof parsed === 'object' && !Array.isArray(parsed)) {
    if ('mcpServers' in parsed && typeof (parsed as Record<string, unknown>).mcpServers === 'object') {
      return (parsed as { mcpServers: Record<string, ServerConfig> }).mcpServers;
    }

    const entries = parsed as Record<string, ServerConfig>;
    const keys = Object.keys(entries);

    if (keys.length === 0) {
      throw new Error('No server entries found');
    }

    return entries;
  }

  throw new Error('Invalid format: expected server configuration object');
};

const App = (): JSX.Element => {
  const notyfRef = useRef<Notyf | null>(null);
  if (!notyfRef.current && typeof window !== 'undefined') {
    notyfRef.current = new Notyf({
      duration: 3000,
      ripple: true,
      position: { x: 'right', y: 'bottom' }
    });
  }

  const [servers, setServers] = useState<ServerMap>({});
  const [configPath, setConfigPath] = useState<string>(DEFAULT_CONFIG_PATH);
  const [settings, setSettings] = useState<SettingsState>(DEFAULT_SETTINGS);
  const [status, setStatus] = useState<StatusState>({ connected: false, message: 'Connecting...' });
  const [loading, setLoading] = useState<boolean>(true);
  const [viewMode, setViewMode] = useState<ViewMode>('grid');
  const [filter, setFilter] = useState<FilterMode>('all');
  const [searchQuery, setSearchQuery] = useState('');
  const [isServerModalOpen, setServerModalOpen] = useState(false);
  const [serverModalJson, setServerModalJson] = useState('');
  const [isSettingsModalOpen, setSettingsModalOpen] = useState(false);
  const [settingsDraft, setSettingsDraft] = useState({
    configPath: DEFAULT_CLAUDE_CONFIG_PATH,
    confirmDelete: true,
    cyberpunkMode: false
  });
  const [isTestingConnection, setTestingConnection] = useState(false);
  const [contextMenu, setContextMenu] = useState<ContextMenuState>({ visible: false, x: 0, y: 0 });
  const [sidebarOpen, setSidebarOpen] = useState(true);
  const [ready, setReady] = useState(false);
  const [showOnboarding, setShowOnboarding] = useState(false);
  const [rawEditorValue, setRawEditorValue] = useState('');
  const [rawEditorDirty, setRawEditorDirty] = useState(false);
  const [rawEditorError, setRawEditorError] = useState<string | null>(null);

  const searchInputRef = useRef<HTMLInputElement | null>(null);
  const fileInputRef = useRef<HTMLInputElement | null>(null);
  const skipSyncRef = useRef(false);
  const previousViewModeRef = useRef<ViewMode>('grid');
  const rawEditorRef = useRef<HTMLTextAreaElement | null>(null);

  const serverArray = useMemo(() => {
    return Object.values(servers).sort((a, b) => a.name.localeCompare(b.name));
  }, [servers]);

  const fuse = useMemo(() => {
    if (serverArray.length === 0) return null;
    const dataset = serverArray.map(server => ({
      ...server,
      configString: JSON.stringify(server.config)
    }));
    return new Fuse(dataset, {
      keys: ['name', 'configString'],
      threshold: 0.3
    });
  }, [serverArray]);

  const filteredServers = useMemo(() => {
    let collection = serverArray;

    if (filter === 'active') {
      collection = collection.filter(server => server.enabled);
    } else if (filter === 'disabled') {
      collection = collection.filter(server => !server.enabled);
    } else if (filter === 'recent') {
      collection = [...collection].sort((a, b) => b.updatedAt - a.updatedAt);
    }

    if (searchQuery.trim() && fuse) {
      const names = new Set(fuse.search(searchQuery.trim()).map(result => result.item.name));
      collection = collection.filter(server => names.has(server.name));
    }

    return collection;
  }, [serverArray, filter, searchQuery, fuse]);

  const persistLocal = useCallback((map: ServerMap) => {
    localStorage.setItem('mcp-all-configs', JSON.stringify(toAllServerConfigs(map)));
  }, []);

  const syncServers = useCallback(async (map: ServerMap) => {
    try {
      await saveConfig(toEnabledServerConfigs(map), configPath);
      setStatus({ connected: true, message: shortPath(configPath) });
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      notyfRef.current?.error(`Failed to save servers: ${message}`);
      setStatus({ connected: false, message: 'Save failed' });
    }
  }, [configPath]);

  useEffect(() => {
    let cancelled = false;

    const initialize = async () => {
      try {
        setLoading(true);
        setStatus({ connected: false, message: 'Connecting...' });

        const storedSettings = parseJSON<SettingsState>(localStorage.getItem('mcp-settings'), DEFAULT_SETTINGS);
        if (!cancelled) {
          setSettings({ ...DEFAULT_SETTINGS, ...storedSettings });
        }

        // Check if user has explicitly selected config file before
        const hasSelectedFile = localStorage.getItem('mcp-config-selected');
        if (!hasSelectedFile) {
          // First run - show onboarding
          if (!cancelled) {
            setLoading(false);
            setShowOnboarding(true);
          }
          return;
        }

        const storedConfigPath = localStorage.getItem('mcp-configPath');
        let resolvedPath = storedConfigPath;

        if (!resolvedPath) {
          try {
            resolvedPath = await getConfigPath();
          } catch (error) {
            console.warn('Failed to resolve config path from bridge', error);
            resolvedPath = DEFAULT_CONFIG_PATH;
          }
        }

        const localConfigs = parseJSON<Record<string, ServerConfig>>(localStorage.getItem('mcp-all-configs'), {});
        const localMap = buildServerMapFromLocal(localConfigs);

        if (!cancelled) {
          skipSyncRef.current = true;
          setServers(localMap);
          setConfigPath(resolvedPath ?? DEFAULT_CONFIG_PATH);
        }

        try {
          const response = await fetchConfig(resolvedPath ?? DEFAULT_CONFIG_PATH);
          const remoteServers = response.servers ?? {};
          const merged = mergeLocalWithRemote(localMap, remoteServers);
          if (!cancelled) {
            skipSyncRef.current = true;
            setServers(merged);
            setStatus({ connected: true, message: shortPath(resolvedPath ?? DEFAULT_CONFIG_PATH) });
          }
        } catch (error) {
          const message = error instanceof Error ? error.message : String(error);
          if (!cancelled) {
            notyfRef.current?.error(`Failed to load servers: ${message}`);
            setStatus({ connected: false, message: 'Config error' });
          }
        }

        if (!cancelled && !localStorage.getItem('mcp-welcomed')) {
          notyfRef.current?.success('Welcome to MCP Server Manager!');
          localStorage.setItem('mcp-welcomed', 'true');
        }
      } finally {
        if (!cancelled) {
          setLoading(false);
          setReady(true);
        }
      }
    };

    void initialize();

    return () => {
      cancelled = true;
    };
  }, []);

  useEffect(() => {
    document.body.classList.toggle('cyberpunk', settings.cyberpunkMode);
  }, [settings.cyberpunkMode]);

  useEffect(() => {
    if (!ready) return;
    localStorage.setItem('mcp-settings', JSON.stringify(settings));
  }, [settings, ready]);

  useEffect(() => {
    if (!ready) return;
    localStorage.setItem('mcp-configPath', configPath);
  }, [configPath, ready]);

  useEffect(() => {
    if (!ready) return;
    if (skipSyncRef.current) {
      skipSyncRef.current = false;
      return;
    }

    persistLocal(servers);
    void syncServers(servers);
  }, [servers, ready, persistLocal, syncServers]);

  useEffect(() => {
    if (!contextMenu.visible) return;

    const handleClose = () => setContextMenu({ visible: false, x: 0, y: 0 });
    window.addEventListener('click', handleClose, { once: true });
    window.addEventListener('contextmenu', handleClose, { once: true });
    return () => {
      window.removeEventListener('click', handleClose);
      window.removeEventListener('contextmenu', handleClose);
    };
  }, [contextMenu.visible]);

  useEffect(() => {
    if (viewMode === 'list' && previousViewModeRef.current !== 'list') {
      const serialized = JSON.stringify(serializeServers(servers), null, 2);
      setRawEditorValue(serialized);
      setRawEditorDirty(false);
      setRawEditorError(null);
    }
    previousViewModeRef.current = viewMode;
  }, [viewMode, servers]);

  useEffect(() => {
    if (viewMode !== 'list') return;
    if (rawEditorDirty) return;
    const serialized = JSON.stringify(serializeServers(servers), null, 2);
    setRawEditorValue(serialized);
  }, [viewMode, servers, rawEditorDirty]);

  useEffect(() => {
    if (viewMode !== 'list') return;
    const query = searchQuery.trim();
    const editor = rawEditorRef.current;
    if (!editor) return;

    if (!query) {
      return;
    }

    const haystack = rawEditorValue.toLowerCase();
    const needle = query.toLowerCase();
    const index = haystack.indexOf(needle);
    if (index === -1) return;

    const end = index + query.length;

    requestAnimationFrame(() => {
      const previousActive = document.activeElement as HTMLElement | null;
      const searchInput = searchInputRef.current;

      editor.focus();
      editor.setSelectionRange(index, end);

      const before = rawEditorValue.slice(0, index);
      const lineCount = before.split('\n').length;
      const computed = window.getComputedStyle(editor);
      const lineHeight = parseFloat(computed.lineHeight || '20') || 20;
      const paddingTop = parseFloat(computed.paddingTop || '0');
      const targetScroll = Math.max(0, (lineCount - 2) * lineHeight - paddingTop);
      editor.scrollTop = targetScroll;

      if (previousActive && previousActive !== editor) {
        previousActive.focus();
        if (searchInput && previousActive === searchInput) {
          const length = searchInput.value.length;
          searchInput.setSelectionRange(length, length);
        }
      }
    });
  }, [viewMode, searchQuery, rawEditorValue]);

  const loadServers = useCallback(async ({ silent = false, path }: { silent?: boolean; path?: string } = {}) => {
    const targetPath = path ?? configPath;
    setLoading(true);
    setStatus({ connected: false, message: 'Loading...' });

    try {
      const response = await fetchConfig(targetPath);
      const remoteServers = response.servers ?? {};

      skipSyncRef.current = true;
      setServers(prev => {
        const next: ServerMap = {};
        const now = Date.now();

        Object.values(prev).forEach(server => {
          next[server.name] = { ...server, enabled: false };
        });

        Object.entries(remoteServers).forEach(([name, config]) => {
          const existing = next[name];
          next[name] = {
            name,
            config,
            enabled: true,
            updatedAt: existing?.updatedAt ?? now
          };
        });

        return next;
      });

      setStatus({ connected: true, message: shortPath(targetPath) });
      if (!silent) {
        notyfRef.current?.success('Servers loaded successfully');
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      notyfRef.current?.error(`Failed to load servers: ${message}`);
      setStatus({ connected: false, message: 'Config error' });
    } finally {
      setLoading(false);
    }
  }, [configPath]);

  useEffect(() => {
    if (isSettingsModalOpen) {
      setSettingsDraft({
        configPath,
        confirmDelete: settings.confirmDelete,
        cyberpunkMode: settings.cyberpunkMode
      });
    }
  }, [isSettingsModalOpen, configPath, settings]);

  const handleToggleServer = useCallback((name: string) => {
    let changed = false;
    let nextEnabled = false;

    setServers(prev => {
      const server = prev[name];
      if (!server) return prev;

      changed = true;
      nextEnabled = !server.enabled;

      return {
        ...prev,
        [name]: {
          ...server,
          enabled: nextEnabled,
          updatedAt: Date.now()
        }
      };
    });

    if (changed) {
      notyfRef.current?.success(`Server "${name}" ${nextEnabled ? 'enabled' : 'disabled'}`);
    }
  }, []);

  const handleDeleteServer = useCallback((name: string) => {
    if (settings.confirmDelete) {
      const confirmed = window.confirm(`Are you sure you want to delete server "${name}"?`);
      if (!confirmed) {
        return;
      }
    }

    let removed = false;
    setServers(prev => {
      if (!prev[name]) return prev;
      removed = true;
      const next = { ...prev };
      delete next[name];
      return next;
    });

    if (removed) {
      notyfRef.current?.success(`Server "${name}" deleted`);
    }
  }, [settings.confirmDelete]);

  const handleUpdateServerConfig = useCallback((name: string, config: ServerConfig) => {
    let updated = false;
    setServers(prev => {
      const server = prev[name];
      if (!server) return prev;

      updated = true;
      return {
        ...prev,
        [name]: {
          ...server,
          config,
          updatedAt: Date.now()
        }
      };
    });

    if (updated) {
      notyfRef.current?.success(`Server "${name}" updated`);
    }
  }, []);

  const handleServerModalSubmit = useCallback(() => {
    try {
      const entries = extractServerEntries(serverModalJson);
      const invalid = Object.entries(entries).filter(([_, config]) => !isValidServerConfig(config));
      if (invalid.length > 0) {
        throw new Error(`Invalid server configuration for "${invalid[0][0]}"`);
      }

      const duplicates = Object.keys(entries).filter(name => Boolean(servers[name]));
      if (duplicates.length > 0) {
        throw new Error(`Server "${duplicates[0]}" already exists`);
      }

      const now = Date.now();
      setServers(prev => {
        const next = { ...prev };
        Object.entries(entries).forEach(([name, config]) => {
          next[name] = {
            name,
            config,
            enabled: true,
            updatedAt: now
          };
        });
        return next;
      });

      const addedCount = Object.keys(entries).length;
      setServerModalJson('');
      setServerModalOpen(false);
      notyfRef.current?.success(`Added ${addedCount} server${addedCount > 1 ? 's' : ''} successfully`);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      notyfRef.current?.error(`Failed to add server: ${message}`);
    }
  }, [serverModalJson, servers]);

  const handleFormatJson = useCallback(() => {
    try {
      setServerModalJson(formatJsonString(serverModalJson));
      notyfRef.current?.success('JSON formatted successfully');
    } catch (error) {
      notyfRef.current?.error('Invalid JSON format');
    }
  }, [serverModalJson]);

  const handleValidateJson = useCallback(() => {
    try {
      JSON.parse(serverModalJson);
      notyfRef.current?.success('Valid JSON');
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      notyfRef.current?.error(`Invalid JSON: ${message}`);
    }
  }, [serverModalJson]);

  const handleImportFile = useCallback(async (event: ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    try {
      const text = await file.text();
      const parsed = JSON.parse(text);
      const imported = (parsed && typeof parsed === 'object' && 'mcpServers' in parsed)
        ? (parsed as { mcpServers: Record<string, ServerConfig> }).mcpServers
        : parsed;

      if (!imported || typeof imported !== 'object') {
        throw new Error('Invalid configuration file');
      }

      const entries = imported as Record<string, ServerConfig>;
      const now = Date.now();
      let importedCount = 0;

      setServers(prev => {
        const next = { ...prev };
        Object.entries(entries).forEach(([name, config]) => {
          if (!isValidServerConfig(config)) {
            return;
          }
          importedCount += 1;
          const existing = next[name];
          next[name] = {
            name,
            config,
            enabled: true,
            updatedAt: now
          };
        });
        return next;
      });

      if (importedCount > 0) {
        notyfRef.current?.success(`Imported ${importedCount} server${importedCount > 1 ? 's' : ''}`);
      } else {
        notyfRef.current?.error('No valid servers found in file');
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      notyfRef.current?.error(`Import failed: ${message}`);
    } finally {
      event.target.value = '';
    }
  }, []);

  const handleExport = useCallback(() => {
    const data = JSON.stringify({ mcpServers: toEnabledServerConfigs(servers) }, null, 2);
    const blob = new Blob([data], { type: 'application/json' });
    const url = URL.createObjectURL(blob);

    const anchor = document.createElement('a');
    anchor.href = url;
    anchor.download = 'mcp-servers-config.json';
    anchor.click();

    URL.revokeObjectURL(url);
    notyfRef.current?.success('Configuration exported');
  }, [servers]);

  const handleContextMenu = useCallback((event: ReactMouseEvent, server: ServerModel) => {
    event.preventDefault();
    setContextMenu({
      visible: true,
      x: event.clientX,
      y: event.clientY,
      server
    });
  }, []);

  const handleManualSave = useCallback(() => {
    persistLocal(servers);
    void syncServers(servers);
    notyfRef.current?.success('Configuration saved');
  }, [persistLocal, servers, syncServers]);

  const handleRawEditorChange = useCallback((value: string) => {
    setRawEditorValue(value);
    setRawEditorDirty(true);
    setRawEditorError(null);
  }, []);

  const handleRawEditorReset = useCallback(() => {
    setRawEditorValue(JSON.stringify(serializeServers(servers), null, 2));
    setRawEditorDirty(false);
    setRawEditorError(null);
  }, [servers]);

  const handleRawEditorFormat = useCallback(() => {
    try {
      const parsed = JSON.parse(rawEditorValue);
      setRawEditorValue(JSON.stringify(parsed, null, 2));
      setRawEditorDirty(true);
      setRawEditorError(null);
      notyfRef.current?.success('JSON formatted');
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      setRawEditorError(message);
      notyfRef.current?.error(`Invalid JSON: ${message}`);
    }
  }, [rawEditorValue]);

  const handleRawEditorApply = useCallback(() => {
    try {
      const parsed = JSON.parse(rawEditorValue);
      if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed)) {
        throw new Error('Expected an object of server definitions');
      }

      const entries = Object.entries(parsed as Record<string, unknown>);
      const now = Date.now();
      const next: ServerMap = {};

      entries.forEach(([name, value]) => {
        if (!name || typeof name !== 'string') {
          throw new Error('Server names must be strings');
        }

        if (!value || typeof value !== 'object' || Array.isArray(value)) {
          throw new Error(`Server "${name}" must be an object`);
        }

        const candidate = value as Partial<ServerModel> & { config?: ServerConfig };
        const config = candidate.config;

        if (!isValidServerConfig(config)) {
          throw new Error(`Server "${name}" has an invalid config`);
        }

        const enabled = typeof candidate.enabled === 'boolean' ? candidate.enabled : true;
        const updatedAt = typeof candidate.updatedAt === 'number' ? candidate.updatedAt : now;

        next[name] = {
          name,
          config,
          enabled,
          updatedAt
        };
      });

      setServers(next);
      setRawEditorDirty(false);
      setRawEditorError(null);
      notyfRef.current?.success('Servers updated from JSON');
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      setRawEditorError(message);
      notyfRef.current?.error(`Failed to apply JSON: ${message}`);
    }
  }, [rawEditorValue]);

  useEffect(() => {
    if (!ready) return;

    const handler = (event: KeyboardEvent) => {
      if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === 'k') {
        event.preventDefault();
        searchInputRef.current?.focus();
      }

      if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === 'n') {
        event.preventDefault();
        setServerModalJson('');
        setServerModalOpen(true);
      }

      if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === 's') {
        event.preventDefault();
        handleManualSave();
      }

      if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === 'r') {
        event.preventDefault();
        void loadServers();
      }

      if (event.key === 'Escape') {
        setServerModalOpen(false);
        setSettingsModalOpen(false);
        setContextMenu({ visible: false, x: 0, y: 0 });
      }
    };

    window.addEventListener('keydown', handler);
    return () => window.removeEventListener('keydown', handler);
  }, [ready, handleManualSave, loadServers]);

  const handleTestConnection = useCallback(async () => {
    const normalizedPath = settingsDraft.configPath.trim() || DEFAULT_CLAUDE_CONFIG_PATH;
    setTestingConnection(true);
    try {
      const response = await testConfigPath(normalizedPath);
      const count = Object.keys(response.servers ?? {}).length;
      notyfRef.current?.success(`Connected! Found ${count} server${count === 1 ? '' : 's'}.`);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      notyfRef.current?.error(`Connection failed: ${message}`);
    } finally {
      setTestingConnection(false);
    }
  }, [settingsDraft.configPath]);

  const handleSaveSettings = useCallback(() => {
    const normalizedPath = settingsDraft.configPath.trim() || DEFAULT_CLAUDE_CONFIG_PATH;

    setSettings({
      confirmDelete: settingsDraft.confirmDelete,
      cyberpunkMode: settingsDraft.cyberpunkMode
    });
    setConfigPath(normalizedPath);
    setSettingsModalOpen(false);
    notyfRef.current?.success('Settings updated');
    void loadServers({ path: normalizedPath });
  }, [loadServers, settingsDraft]);

  const handleOnboardingComplete = useCallback(async (filePath: string) => {
    localStorage.setItem('mcp-config-selected', 'true');
    localStorage.setItem('mcp-configPath', filePath);
    setConfigPath(filePath);
    setShowOnboarding(false);
    await loadServers({ path: filePath, silent: true });
    setReady(true);
    notyfRef.current?.success('Configuration loaded successfully');
  }, [loadServers]);

  return (
    <div className="relative min-h-screen bg-gradient-to-br from-[#070b1f] via-[#0f172a] to-[#05060f] text-slate-100">
      {loading && <LoadingOverlay />}

      {sidebarOpen && (
        <button
          type="button"
          className="fixed inset-0 z-30 bg-slate-950/60 backdrop-blur-sm transition-opacity lg:hidden"
          onClick={() => setSidebarOpen(false)}
          aria-label="Close sidebar"
        />
      )}

      <div className="relative z-40 mx-auto flex min-h-screen w-full max-w-7xl flex-col px-6 py-10 lg:px-10">
        <Header
          onToggleSidebar={() => setSidebarOpen(prev => !prev)}
          status={status}
          searchQuery={searchQuery}
          onSearchChange={setSearchQuery}
          onOpenSettings={() => setSettingsModalOpen(true)}
          searchRef={searchInputRef}
        />

        <div className="mt-8 flex flex-1 flex-col gap-6 lg:flex-row">
          <Sidebar
            open={sidebarOpen}
            onNewServer={() => {
              setServerModalJson('');
              setServerModalOpen(true);
              setSidebarOpen(false);
            }}
            onImport={() => fileInputRef.current?.click()}
            onExport={handleExport}
          />

          <main className="flex flex-1 flex-col gap-6">
            <Toolbar
              viewMode={viewMode}
              onViewChange={setViewMode}
              filter={filter}
              onFilterChange={setFilter}
              onRefresh={() => void loadServers()}
              onSave={handleManualSave}
            />

            <div className="glass-panel flex-1 overflow-hidden p-6">
              {filteredServers.length === 0 ? (
                <EmptyState
                  onCreate={() => {
                    setServerModalJson('');
                    setServerModalOpen(true);
                  }}
                />
              ) : viewMode === 'grid' ? (
                <ServerGrid
                  servers={filteredServers}
                  onToggle={handleToggleServer}
                  onDelete={handleDeleteServer}
                  onContextMenu={handleContextMenu}
                  onUpdateConfig={handleUpdateServerConfig}
                />
              ) : (
                <RawJsonEditor
                  value={rawEditorValue}
                  onChange={handleRawEditorChange}
                  onApply={handleRawEditorApply}
                  onReset={handleRawEditorReset}
                  onFormat={handleRawEditorFormat}
                  dirty={rawEditorDirty}
                  error={rawEditorError}
                  editorRef={rawEditorRef}
                />
              )}
            </div>
          </main>
        </div>
      </div>

      <ServerModal
        open={isServerModalOpen}
        jsonValue={serverModalJson}
        onChangeJson={setServerModalJson}
        onClose={() => setServerModalOpen(false)}
        onSubmit={handleServerModalSubmit}
        onFormat={handleFormatJson}
        onValidate={handleValidateJson}
      />

      <SettingsModal
        open={isSettingsModalOpen}
        onClose={() => setSettingsModalOpen(false)}
        draft={settingsDraft}
        onChangeDraft={setSettingsDraft}
        onSave={handleSaveSettings}
        onTestConnection={handleTestConnection}
        testing={isTestingConnection}
      />

      <ContextMenu
        state={contextMenu}
        onToggle={() => {
          if (contextMenu.server) {
            handleToggleServer(contextMenu.server.name);
          }
          setContextMenu({ visible: false, x: 0, y: 0 });
        }}
        onDelete={() => {
          if (contextMenu.server) {
            handleDeleteServer(contextMenu.server.name);
          }
          setContextMenu({ visible: false, x: 0, y: 0 });
        }}
      />

      <OnboardingModal
        open={showOnboarding}
        onComplete={handleOnboardingComplete}
      />

      <input
        type="file"
        accept=".json,application/json"
        className="hidden"
        ref={fileInputRef}
        onChange={handleImportFile}
      />
    </div>
  );
};

interface OnboardingModalProps {
  open: boolean;
  onComplete: (filePath: string) => void;
}

const OnboardingModal = ({ open, onComplete }: OnboardingModalProps) => {
  const [selectedPath, setSelectedPath] = useState<string>('');
  const [selecting, setSelecting] = useState(false);

  if (!open) return null;

  const handleSelectFile = async () => {
    if (!window.api?.selectConfigFile) {
      console.error('File picker not available');
      return;
    }

    setSelecting(true);
    try {
      const result = await window.api.selectConfigFile();
      if (!result.canceled && result.filePath) {
        setSelectedPath(result.filePath);
      }
    } catch (error) {
      console.error('Failed to select file:', error);
    } finally {
      setSelecting(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-950/95 backdrop-blur-sm p-4">
      <div className="glass-panel w-full max-w-lg overflow-hidden rounded-3xl border border-white/10 bg-slate-950/95">
        <div className="border-b border-white/5 px-8 py-6">
          <h2 className="text-2xl font-semibold text-white">Welcome to MCP Server Manager</h2>
          <p className="mt-2 text-sm text-slate-300">
            Let's get started by locating your Claude configuration file.
          </p>
        </div>

        <div className="space-y-6 px-8 py-6">
          <div className="rounded-2xl border border-sky-500/20 bg-sky-500/5 p-4">
            <p className="text-sm text-slate-200">
              <strong>Your config file is usually located at:</strong>
            </p>
            <p className="mt-2 font-mono text-xs text-sky-400">
              ~/.claude.json
            </p>
            <p className="mt-3 text-xs text-slate-400">
              Click "Select Config File" below to browse to this location. Hidden files will be shown automatically.
            </p>
            <p className="mt-2 text-xs text-slate-500">
              💡 Tip: If you don't see hidden files, press <kbd className="rounded bg-slate-700 px-2 py-1 text-sm font-semibold text-white">⌘</kbd>+<kbd className="rounded bg-slate-700 px-2 py-1 text-sm font-semibold text-white">⇧</kbd>+<kbd className="rounded bg-slate-700 px-2 py-1 text-sm font-semibold text-white">.</kbd>
            </p>
          </div>

          {selectedPath && (
            <div className="rounded-2xl border border-green-500/20 bg-green-500/5 p-4">
              <p className="text-sm font-medium text-green-400">✓ File selected:</p>
              <p className="mt-1 truncate font-mono text-xs text-slate-300">{selectedPath}</p>
            </div>
          )}

          <button
            type="button"
            onClick={handleSelectFile}
            disabled={selecting}
            className="w-full rounded-full bg-gradient-to-r from-sky-500 via-indigo-500 to-fuchsia-500 px-6 py-3 font-semibold text-white shadow-lg shadow-sky-500/30 transition hover:opacity-90 focus:outline-none focus:ring-2 focus:ring-sky-400/50 disabled:opacity-50"
          >
            {selecting ? 'Opening...' : 'Select Config File'}
          </button>

          {selectedPath && (
            <button
              type="button"
              onClick={() => onComplete(selectedPath)}
              className="w-full rounded-full border border-white/10 bg-white/5 px-6 py-3 font-semibold text-white transition hover:bg-white/10 focus:outline-none focus:ring-2 focus:ring-sky-400/50"
            >
              Continue
            </button>
          )}
        </div>

        <div className="border-t border-white/5 px-8 py-4">
          <p className="text-xs text-slate-400">
            This step is required for App Store security compliance. Your file selection is stored locally and never shared.
          </p>
        </div>
      </div>
    </div>
  );
};

export default App;

interface HeaderProps {
  onToggleSidebar: () => void;
  status: StatusState;
  searchQuery: string;
  onSearchChange: (value: string) => void;
  onOpenSettings: () => void;
  searchRef: RefObject<HTMLInputElement>;
}

const Header = ({
  onToggleSidebar,
  status,
  searchQuery,
  onSearchChange,
  onOpenSettings,
  searchRef
}: HeaderProps) => {
  return (
    <header className="glass-panel flex flex-col gap-6 p-6 shadow-2xl lg:flex-row lg:items-center lg:justify-between">
      <div className="flex w-full flex-col gap-4 lg:w-auto lg:flex-row lg:items-center lg:gap-6">
        <div className="flex items-center gap-3">
          <button
            type="button"
            onClick={onToggleSidebar}
            className="inline-flex h-11 w-11 items-center justify-center rounded-full border border-white/10 bg-white/10 text-slate-200 transition hover:text-white focus:outline-none focus:ring-2 focus:ring-sky-400/50 lg:hidden"
            aria-label="Toggle sidebar"
          >
            <svg className="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
              <path fillRule="evenodd" d="M3 5a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zM3 10a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zM3 15a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1z" />
            </svg>
          </button>
          <div className="flex items-center gap-4">
            <span className="flex h-12 w-12 items-center justify-center rounded-2xl bg-gradient-to-br from-sky-500 via-indigo-500 to-fuchsia-500 text-xl shadow-lg shadow-sky-500/40">⚡</span>
            <div>
              <h1 className="text-xl font-semibold text-white">
                <span className="bg-gradient-to-r from-sky-300 via-cyan-200 to-indigo-200 bg-clip-text text-transparent">
                  MCP Server Manager
                </span>
              </h1>
              <p className="text-sm text-slate-400">Curate Claude MCP server connections with style</p>
            </div>
          </div>
        </div>

        <div className="relative w-full lg:min-w-[320px]">
          <svg className="pointer-events-none absolute left-4 top-1/2 h-4 w-4 -translate-y-1/2 text-sky-300/60" viewBox="0 0 16 16" fill="currentColor">
            <path d="M11.742 10.344a6.5 6.5 0 1 0-1.397 1.398l3.85 3.85a1 1 0 1 0 1.414-1.415l-3.85-3.85a1 1 0 0 0-.017-.012zM12 6.5a5.5 5.5 0 1 1-11 0 5.5 5.5 0 0 1 11 0z" />
          </svg>
          <input
            ref={searchRef}
            value={searchQuery}
            onChange={event => onSearchChange(event.target.value)}
            placeholder="Search servers… (⌘K)"
            className="w-full rounded-full border border-white/10 bg-white/10 py-2.5 pl-11 pr-4 text-sm text-slate-100 shadow-inner shadow-slate-950/40 placeholder:text-slate-400 focus:border-sky-400 focus:outline-none focus:ring-2 focus:ring-sky-500/30"
          />
        </div>
      </div>

      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-end sm:gap-4">
        <div className="flex items-center gap-2 rounded-full border border-white/10 bg-white/10 px-4 py-1.5 text-xs text-slate-200">
          <span
            className={`status-dot h-2.5 w-2.5 rounded-full shadow-sm shadow-emerald-400/40 ${status.connected ? 'bg-emerald-400' : 'bg-rose-400'}`}
          />
          <span className="font-medium tracking-wide">{status.message}</span>
        </div>
        <button
          type="button"
          onClick={onOpenSettings}
          className="inline-flex items-center gap-2 rounded-full bg-gradient-to-r from-sky-500 via-indigo-500 to-fuchsia-500 px-4 py-2 text-sm font-medium text-white shadow-lg shadow-sky-500/30 transition hover:opacity-90 focus:outline-none focus:ring-2 focus:ring-sky-400/60"
        >
          <svg className="h-4 w-4" viewBox="0 0 20 20" fill="currentColor">
            <path
              fillRule="evenodd"
              d="M11.49 3.17c-.38-1.56-2.6-1.56-2.98 0a1.532 1.532 0 01-2.286.948c-1.372-.836-2.942.734-2.106 2.106.54.886.061 2.042-.947 2.287-1.561.379-1.561 2.6 0 2.978a1.532 1.532 0 01.947 2.287c-.836 1.372.734 2.942 2.106 2.106a1.532 1.532 0 012.287.947c.379 1.561 2.6 1.561 2.978 0a1.533 1.533 0 012.287-.947c1.372.836 2.942-.734 2.106-2.106a1.533 1.533 0 01.947-2.287c1.561-.379 1.561-2.6 0-2.978a1.532 1.532 0 01-.947-2.287c.836-1.372-.734-2.942-2.106-2.106a1.532 1.532 0 01-2.287-.947zM10 13a3 3 0 100-6 3 3 0 000 6z"
            />
          </svg>
          <span>Settings</span>
        </button>
      </div>
    </header>
  );
};

interface SidebarProps {
  open: boolean;
  onNewServer: () => void;
  onImport: () => void;
  onExport: () => void;
}

const Sidebar = ({ open, onNewServer, onImport, onExport }: SidebarProps) => {
  const handleExploreClick = () => {
    window.open('https://lobehub.com/mcp', '_blank', 'noopener');
  };

  return (
    <aside
      className={`glass-panel z-40 w-full max-h-[calc(100vh-12rem)] overflow-y-auto p-6 shadow-2xl transition-all duration-200 ${open ? 'block' : 'hidden lg:block'} lg:sticky lg:top-10 lg:w-72`}
    >
      <div className="space-y-8">
        <div className="rounded-2xl border border-white/5 bg-white/5 p-5 text-sm text-slate-300 shadow-inner shadow-slate-950/30">
          <h2 className="text-sm font-semibold text-white">Quick actions</h2>
          <p className="mt-1 text-xs text-slate-400">Discover, create, import, or export MCP server definitions in seconds.</p>
          <div className="mt-4 space-y-2">
            <button
              type="button"
              onClick={handleExploreClick}
              className="w-full rounded-xl border border-sky-400/30 bg-sky-500/10 px-4 py-2 text-sm font-semibold text-sky-100 shadow-lg shadow-sky-500/20 transition hover:bg-sky-500/20 hover:text-white focus:outline-none focus:ring-2 focus:ring-sky-400/50"
            >
              Explore New MCPs
            </button>
            <button
              type="button"
              onClick={onNewServer}
              className="w-full rounded-xl bg-gradient-to-r from-sky-500 via-indigo-500 to-fuchsia-500 px-4 py-2 text-sm font-semibold text-white shadow-lg shadow-sky-500/30 transition hover:opacity-90 focus:outline-none focus:ring-2 focus:ring-sky-400/60"
            >
              New Server
            </button>
            <button
              type="button"
              onClick={onImport}
              className="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2 text-sm text-slate-100 transition hover:border-sky-400/60 hover:text-white focus:outline-none focus:ring-2 focus:ring-sky-400/40"
            >
              Import JSON
            </button>
            <button
              type="button"
              onClick={onExport}
              className="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2 text-sm text-slate-100 transition hover:border-sky-400/60 hover:text-white focus:outline-none focus:ring-2 focus:ring-sky-400/40"
            >
              Export JSON
            </button>
          </div>
        </div>

      </div>
    </aside>
  );
};

interface ToolbarProps {
  viewMode: ViewMode;
  onViewChange: (mode: ViewMode) => void;
  filter: FilterMode;
  onFilterChange: (mode: FilterMode) => void;
  onRefresh: () => void;
  onSave: () => void;
}

const Toolbar = ({ viewMode, onViewChange, filter, onFilterChange, onRefresh, onSave }: ToolbarProps) => {
  return (
    <div className="glass-panel flex flex-wrap items-center justify-between gap-4 p-5">
      <div className="flex flex-wrap items-center gap-3">
        <div className="inline-flex items-center gap-1 rounded-full border border-white/10 bg-white/5 p-1">
          <button
            type="button"
            onClick={() => onViewChange('grid')}
            className={`rounded-full px-4 py-1.5 text-xs font-semibold transition ${viewMode === 'grid'
              ? 'bg-gradient-to-r from-sky-500 via-indigo-500 to-fuchsia-500 text-white shadow'
              : 'text-slate-300 hover:text-white'
            }`}
          >
            Grid
          </button>
          <button
            type="button"
            onClick={() => onViewChange('list')}
            className={`rounded-full px-4 py-1.5 text-xs font-semibold transition ${viewMode === 'list'
              ? 'bg-gradient-to-r from-sky-500 via-indigo-500 to-fuchsia-500 text-white shadow'
              : 'text-slate-300 hover:text-white'
            }`}
          >
            Raw JSON
          </button>
        </div>

        <select
          value={filter}
          onChange={event => onFilterChange(event.target.value as FilterMode)}
          className="rounded-full border border-white/10 bg-white/5 px-4 py-2 text-xs font-medium text-slate-200 focus:border-sky-400 focus:outline-none focus:ring-2 focus:ring-sky-500/30"
        >
          <option value="all">All Servers</option>
          <option value="active">Active Only</option>
          <option value="disabled">Disabled Only</option>
          <option value="recent">Recently Modified</option>
        </select>
      </div>

      <div className="flex items-center gap-2">
        <button
          type="button"
          onClick={onSave}
          className="inline-flex items-center gap-2 rounded-full border border-sky-400/40 bg-sky-500/20 px-4 py-2 text-xs font-semibold text-sky-100 shadow-lg shadow-sky-500/20 transition hover:bg-sky-500/30 focus:outline-none focus:ring-2 focus:ring-sky-400/40"
        >
          <svg className="h-4 w-4" viewBox="0 0 16 16" fill="currentColor">
            <path d="M5 1a2 2 0 00-2 2v10a2 2 0 002 2h6a2 2 0 002-2V4.414A2 2 0 0012.414 3L11 1.586A2 2 0 009.586 1H5zm6 4V3.5L9.5 2H5a1 1 0 00-1 1v2h7z" />
            <path d="M4.5 8a.5.5 0 01.5-.5h6a.5.5 0 010 1H5a.5.5 0 01-.5-.5z" />
          </svg>
          Save
        </button>
        <button
          type="button"
          onClick={onRefresh}
          className="inline-flex items-center gap-2 rounded-full border border-white/10 bg-white/5 px-4 py-2 text-xs font-semibold text-slate-200 transition hover:border-sky-300/50 hover:text-white focus:outline-none focus:ring-2 focus:ring-sky-400/40"
        >
          <svg className="h-4 w-4" viewBox="0 0 16 16" fill="currentColor">
            <path fillRule="evenodd" d="M8 3a5 5 0 104.546 2.914.5.5 0 01.908-.417A6 6 0 118 2v1z" />
            <path d="M8 4.466V.534a.25.25 0 01.41-.192l2.36 1.966c.12.1.12.284 0 .384L8.41 4.658A.25.25 0 018 4.466z" />
          </svg>
          Refresh
        </button>
      </div>
    </div>
  );
};

interface ServerCollectionProps {
  servers: ServerModel[];
  onToggle: (name: string) => void;
  onDelete: (name: string) => void;
  onContextMenu: (event: ReactMouseEvent, server: ServerModel) => void;
  onUpdateConfig?: (name: string, config: ServerConfig) => void;
}

const ServerGrid = ({ servers, onToggle, onDelete, onContextMenu, onUpdateConfig }: ServerCollectionProps) => {
  const [editingServer, setEditingServer] = useState<string | null>(null);
  const [editValue, setEditValue] = useState('');
  const [editError, setEditError] = useState<string | null>(null);

  const handleStartEdit = (server: ServerModel) => {
    setEditingServer(server.name);
    setEditValue(JSON.stringify(server.config, null, 2));
    setEditError(null);
  };

  const handleCancelEdit = () => {
    setEditingServer(null);
    setEditValue('');
    setEditError(null);
  };

  const handleSaveEdit = (serverName: string) => {
    try {
      const parsed = JSON.parse(editValue);
      if (!isValidServerConfig(parsed)) {
        throw new Error('Invalid server configuration');
      }

      if (onUpdateConfig) {
        onUpdateConfig(serverName, parsed as ServerConfig);
      }

      setEditingServer(null);
      setEditValue('');
      setEditError(null);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      setEditError(message);
    }
  };

  const handleFormatEdit = () => {
    try {
      const parsed = JSON.parse(editValue);
      setEditValue(JSON.stringify(parsed, null, 2));
      setEditError(null);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      setEditError(message);
    }
  };

  return (
    <div className="grid gap-5 md:grid-cols-2 xl:grid-cols-3">
      {servers.map(server => {
        const isEditing = editingServer === server.name;

        return (
          <div
            key={server.name}
            onContextMenu={event => onContextMenu(event, server)}
            className="group glass-panel flex h-full flex-col gap-4 p-5 transition-all duration-200 hover:-translate-y-1.5 hover:border-sky-400/40 hover:shadow-sky-500/20"
          >
            <div className="space-y-1">
              <h3 className="text-lg font-semibold text-white line-clamp-2">{server.name}</h3>
              <p className="text-xs text-slate-400">{summarizeServerConfig(server.config)}</p>
            </div>

            {isEditing ? (
              <div className="flex flex-col gap-2">
                {editError && (
                  <div className="rounded-lg border border-rose-400/40 bg-rose-500/10 px-3 py-2 text-[10px] text-rose-100">
                    {editError}
                  </div>
                )}
                <textarea
                  value={editValue}
                  onChange={e => setEditValue(e.target.value)}
                  className="max-h-52 min-h-[200px] flex-1 rounded-2xl border border-sky-400/40 bg-slate-950/90 p-3 font-mono text-[11px] leading-relaxed text-slate-100 shadow-inner shadow-slate-950/60 focus:border-sky-400 focus:outline-none focus:ring-2 focus:ring-sky-500/30"
                  spellCheck={false}
                />
                <div className="flex flex-wrap items-center gap-2">
                  <button
                    type="button"
                    onClick={handleFormatEdit}
                    className="inline-flex items-center gap-1 rounded-full border border-white/10 bg-white/5 px-3 py-1 text-[11px] font-semibold text-slate-200 transition hover:border-sky-300/40 hover:text-white focus:outline-none focus:ring-2 focus:ring-sky-400/40"
                  >
                    Format
                  </button>
                  <button
                    type="button"
                    onClick={() => handleSaveEdit(server.name)}
                    className="inline-flex items-center gap-1 rounded-full bg-gradient-to-r from-emerald-500 to-sky-500 px-3 py-1 text-[11px] font-semibold text-white shadow-lg shadow-emerald-500/20 transition hover:opacity-90 focus:outline-none focus:ring-2 focus:ring-emerald-400/50"
                  >
                    <svg className="h-3 w-3" viewBox="0 0 16 16" fill="currentColor">
                      <path d="M13.78 4.22a.75.75 0 010 1.06l-7.25 7.25a.75.75 0 01-1.06 0L2.22 9.28a.75.75 0 011.06-1.06L6 10.94l6.72-6.72a.75.75 0 011.06 0z" />
                    </svg>
                    Save
                  </button>
                  <button
                    type="button"
                    onClick={handleCancelEdit}
                    className="inline-flex items-center gap-1 rounded-full border border-white/10 bg-white/5 px-3 py-1 text-[11px] font-semibold text-slate-200 transition hover:text-white focus:outline-none focus:ring-2 focus:ring-sky-400/40"
                  >
                    Cancel
                  </button>
                </div>
              </div>
            ) : (
              <>
                <div className="relative flex-1">
                  <pre className="max-h-52 overflow-auto rounded-2xl border border-white/5 bg-slate-950/70 p-4 text-xs leading-relaxed text-slate-200 shadow-inner shadow-slate-950/60">
{JSON.stringify(server.config, null, 2)}
                  </pre>
                  <button
                    type="button"
                    onClick={() => handleStartEdit(server)}
                    className="absolute right-2 top-2 inline-flex items-center gap-1 rounded-lg border border-sky-400/30 bg-sky-500/10 px-2 py-1 text-[10px] font-semibold text-sky-100 opacity-0 shadow-lg shadow-sky-500/10 transition-all group-hover:opacity-100 hover:bg-sky-500/20 focus:outline-none focus:ring-2 focus:ring-sky-400/50"
                  >
                    <svg className="h-3 w-3" viewBox="0 0 16 16" fill="currentColor">
                      <path d="M11.013 1.427a1.75 1.75 0 012.474 0l1.086 1.086a1.75 1.75 0 010 2.474l-8.61 8.61c-.21.21-.47.364-.756.445l-3.251.93a.75.75 0 01-.927-.928l.929-3.25a1.75 1.75 0 01.445-.758l8.61-8.61zm1.414 1.06a.25.25 0 00-.354 0L10.811 3.75l1.439 1.44 1.263-1.263a.25.25 0 000-.354l-1.086-1.086zM11.189 6.25L9.75 4.81l-6.286 6.287a.25.25 0 00-.064.108l-.558 1.953 1.953-.558a.249.249 0 00.108-.064l6.286-6.286z" />
                    </svg>
                    Edit
                  </button>
                </div>

                <div className="flex items-center justify-between gap-3">
                  <ToggleSwitch active={server.enabled} onClick={() => onToggle(server.name)} />
                  <button
                    type="button"
                    onClick={() => onDelete(server.name)}
                    className="inline-flex items-center gap-2 rounded-full border border-rose-400/40 bg-rose-500/10 px-4 py-1.5 text-xs font-semibold text-rose-200 transition hover:bg-rose-500/20 focus:outline-none focus:ring-2 focus:ring-rose-400/40"
                  >
                    <svg className="h-4 w-4" viewBox="0 0 16 16" fill="currentColor">
                      <path d="M5.5 5.5A.5.5 0 016 6v6a.5.5 0 01-1 0V6a.5.5 0 01.5-.5zm2.5 0a.5.5 0 01.5.5v6a.5.5 0 01-1 0V6a.5.5 0 01.5-.5zm3 .5a.5.5 0 00-1 0v6a.5.5 0 001 0V6z" />
                      <path fillRule="evenodd" d="M14.5 3a1 1 0 01-1 1H13v9a2 2 0 01-2 2H5a2 2 0 01-2-2V4h-.5a1 1 0 01-1-1V2a1 1 0 011-1H6a1 1 0 011-1h2a1 1 0 011 1h3.5a1 1 0 011 1v1zM4.118 4L4 4.059V13a1 1 0 001 1h6a1 1 0 001-1V4.059L11.882 4H4.118zM2.5 3V2h11v1h-11z" />
                    </svg>
                    Delete
                  </button>
                </div>
              </>
            )}
          </div>
        );
      })}
    </div>
  );
};

const ToggleSwitch = ({ active, onClick }: { active: boolean; onClick: () => void }) => {
  return (
    <button
      type="button"
      onClick={onClick}
      aria-pressed={active}
      className={`relative inline-flex h-7 w-12 items-center rounded-full transition-all duration-200 focus:outline-none focus:ring-2 focus:ring-sky-400/40 ${active
        ? 'bg-gradient-to-r from-emerald-400 to-sky-400 shadow-inner shadow-emerald-400/60'
        : 'bg-white/10 hover:bg-white/20'
      }`}
    >
      <span
        className={`inline-block h-5 w-5 transform rounded-full bg-white shadow-lg transition-all duration-200 ${active ? 'translate-x-6' : 'translate-x-1'}`}
      />
    </button>
  );
};

const ContextMenu = ({ state, onToggle, onDelete }: { state: ContextMenuState; onToggle: () => void; onDelete: () => void }) => {
  if (!state.visible || !state.server) {
    return null;
  }

  return (
    <div
      className="glass-panel fixed z-50 min-w-[200px] border border-white/10 bg-slate-950/95 p-1 text-sm text-slate-100 shadow-2xl"
      style={{ top: state.y, left: state.x }}
    >
      <button
        type="button"
        onClick={onToggle}
        className="flex w-full items-center gap-2 rounded-xl px-3 py-2 text-left transition hover:bg-white/5"
      >
        <svg className="h-4 w-4" viewBox="0 0 16 16" fill="currentColor">
          <path d="M11.5 1a.5.5 0 01.5.5V4h-1V1.5a.5.5 0 01.5-.5zm-7 0a.5.5 0 01.5.5V4H4V1.5a.5.5 0 01.5-.5zm8 14a.5.5 0 01-.5-.5V12h1v2.5a.5.5 0 01-.5.5zm-8 0a.5.5 0 01-.5-.5V12h1v2.5a.5.5 0 01-.5.5z" />
          <path d="M2 5.5A1.5 1.5 0 013.5 4h9A1.5 1.5 0 0114 5.5v5a1.5 1.5 0 01-1.5 1.5h-9A1.5 1.5 0 012 10.5v-5z" />
        </svg>
        Toggle
      </button>
      <button
        type="button"
        onClick={onDelete}
        className="flex w-full items-center gap-2 rounded-xl px-3 py-2 text-left text-rose-200 transition hover:bg-rose-500/15"
      >
        <svg className="h-4 w-4" viewBox="0 0 16 16" fill="currentColor">
          <path d="M5.5 5.5A.5.5 0 016 6v6a.5.5 0 01-1 0V6a.5.5 0 01.5-.5zm2.5 0a.5.5 0 01.5.5v6a.5.5 0 01-1 0V6a.5.5 0 01.5-.5zm3 .5a.5.5 0 00-1 0v6a.5.5 0 001 0V6z" />
          <path fillRule="evenodd" d="M14.5 3a1 1 0 01-1 1H13v9a2 2 0 01-2 2H5a2 2 0 01-2-2V4h-.5a1 1 0 01-1-1V2a1 1 0 011-1H6a1 1 0 011-1h2a1 1 0 011 1h3.5a1 1 0 011 1v1zM4.118 4L4 4.059V13a1 1 0 001 1h6a1 1 0 001-1V4.059L11.882 4H4.118zM2.5 3V2h11v1h-11z" />
        </svg>
        Delete
      </button>
    </div>
  );
};

const EmptyState = ({ onCreate }: { onCreate: () => void }) => {
  return (
    <div className="flex h-full flex-col items-center justify-center gap-6 rounded-3xl border border-dashed border-white/15 bg-gradient-to-br from-white/5 via-white/10 to-transparent p-10 text-center">
      <div className="flex h-16 w-16 items-center justify-center rounded-2xl bg-white/10 text-2xl shadow-inner shadow-slate-950/40">🌌</div>
      <h3 className="text-xl font-semibold text-white">No servers configured yet</h3>
      <p className="max-w-md text-sm text-slate-300">
        Add your MCP servers to sync them with your Claude configuration. Paste JSON directly, import a config file, or craft a fresh setup from scratch.
      </p>
      <button
        type="button"
        onClick={onCreate}
        className="rounded-full bg-gradient-to-r from-sky-500 via-indigo-500 to-fuchsia-500 px-6 py-2 text-sm font-semibold text-white shadow-lg shadow-sky-500/30 transition hover:opacity-90 focus:outline-none focus:ring-2 focus:ring-sky-400/50"
      >
        Create Server
      </button>
    </div>
  );
};

const LoadingOverlay = () => {
  return (
    <div className="pointer-events-none fixed inset-0 z-50 flex items-center justify-center bg-slate-950/80 backdrop-blur">
      <div className="glass-panel flex items-center gap-4 px-6 py-4 text-sm font-medium text-slate-200">
        <span className="inline-flex h-10 w-10 animate-spin rounded-full border-2 border-transparent border-l-sky-500 border-t-sky-400" />
        Loading configuration…
      </div>
    </div>
  );
};

interface RawJsonEditorProps {
  value: string;
  onChange: (value: string) => void;
  onApply: () => void;
  onReset: () => void;
  onFormat: () => void;
  dirty: boolean;
  error: string | null;
  editorRef?: RefObject<HTMLTextAreaElement>;
}

const RawJsonEditor = ({ value, onChange, onApply, onReset, onFormat, dirty, error, editorRef }: RawJsonEditorProps) => {
  return (
    <div className="flex h-full flex-col gap-4">
      <div className="rounded-2xl border border-white/10 bg-white/5 p-5 text-sm text-slate-300 shadow-inner shadow-slate-950/30">
        <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <h3 className="text-sm font-semibold text-white">Raw server JSON</h3>
            <p className="text-xs text-slate-400">Edit the complete server map, including enabled state and transports.</p>
          </div>
          {dirty && (
            <span className="inline-flex items-center gap-2 rounded-full border border-amber-400/40 bg-amber-500/10 px-3 py-1 text-[11px] font-semibold uppercase tracking-wide text-amber-100">
              Unsaved edits
              <span className="h-2 w-2 rounded-full bg-amber-300" />
            </span>
          )}
        </div>
        <p className="mt-3 text-[11px] text-slate-500">
          Expecting an object keyed by server name: <code>{'{ "server-name": { config, enabled, updatedAt } }'}</code>.
        </p>
      </div>

      {error && (
        <div className="rounded-2xl border border-rose-400/40 bg-rose-500/10 px-4 py-3 text-xs text-rose-100">
          {error}
        </div>
      )}

      <textarea
        value={value}
        onChange={event => onChange(event.target.value)}
        ref={editorRef ?? undefined}
        className="h-full min-h-[320px] flex-1 rounded-3xl border border-white/10 bg-slate-950/80 p-5 font-mono text-xs leading-relaxed text-slate-100 shadow-inner shadow-slate-950/60 focus:border-sky-400 focus:outline-none focus:ring-2 focus:ring-sky-500/30"
        spellCheck={false}
      />

      <div className="flex flex-wrap items-center justify-between gap-3">
        <div className="flex items-center gap-2">
          <button
            type="button"
            onClick={onFormat}
            className="inline-flex items-center gap-2 rounded-full border border-white/10 bg-white/5 px-4 py-2 text-xs font-semibold text-slate-200 transition hover:border-sky-300/40 hover:text-white focus:outline-none focus:ring-2 focus:ring-sky-400/40"
          >
            Format JSON
          </button>
          <button
            type="button"
            onClick={onReset}
            className="inline-flex items-center gap-2 rounded-full border border-white/10 bg-white/5 px-4 py-2 text-xs font-semibold text-slate-200 transition hover:border-sky-300/40 hover:text-white focus:outline-none focus:ring-2 focus:ring-sky-400/40"
          >
            Reset to current
          </button>
        </div>

        <button
          type="button"
          onClick={onApply}
          disabled={!dirty}
          className={`inline-flex items-center gap-2 rounded-full px-5 py-2 text-xs font-semibold transition focus:outline-none focus:ring-2 focus:ring-sky-400/50 ${dirty
            ? 'bg-gradient-to-r from-sky-500 via-indigo-500 to-fuchsia-500 text-white shadow-lg shadow-sky-500/30 hover:opacity-90'
            : 'cursor-not-allowed border border-white/10 bg-white/5 text-slate-400'
          }`}
        >
          Apply changes
        </button>
      </div>
    </div>
  );
};

interface ServerModalProps {
  open: boolean;
  jsonValue: string;
  onChangeJson: (value: string) => void;
  onClose: () => void;
  onSubmit: () => void;
  onFormat: () => void;
  onValidate: () => void;
}

const ServerModal = ({
  open,
  jsonValue,
  onChangeJson,
  onClose,
  onSubmit,
  onFormat,
  onValidate
}: ServerModalProps) => {
  if (!open) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-950/85 backdrop-blur-sm p-4">
      <div className="glass-panel w-full max-w-3xl overflow-hidden rounded-3xl border border-white/10 bg-slate-950/95">
        <div className="flex items-center justify-between border-b border-white/5 px-8 py-6">
          <div>
            <p className="text-xs uppercase tracking-[0.35em] text-slate-400">Bulk add</p>
            <h2 className="mt-1 text-2xl font-semibold text-white">Add servers</h2>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="rounded-full border border-white/10 bg-white/10 p-2 text-slate-300 transition hover:text-white focus:outline-none focus:ring-2 focus:ring-sky-400/50"
          >
            ✕
          </button>
        </div>

        <div className="space-y-6 px-8 py-6">
          <label className="block text-xs font-semibold uppercase tracking-[0.3em] text-slate-400">
            Server JSON
            <textarea
              value={jsonValue}
              onChange={event => onChangeJson(event.target.value)}
              className="mt-3 h-60 w-full rounded-2xl border border-white/10 bg-slate-900/60 p-4 font-mono text-sm text-slate-100 shadow-inner shadow-slate-950/50 focus:border-sky-400 focus:outline-none focus:ring-2 focus:ring-sky-500/30"
              placeholder="Paste server configuration JSON here"
            />
          </label>
        </div>

        <div className="flex flex-col gap-3 border-t border-white/5 px-8 py-6 sm:flex-row sm:items-center sm:justify-between">
          <div className="flex items-center gap-3">
            <button
              type="button"
              onClick={onFormat}
              className="rounded-full border border-white/10 bg-white/5 px-4 py-2 text-xs font-semibold text-slate-200 transition hover:border-sky-300/40 hover:text-white focus:outline-none focus:ring-2 focus:ring-sky-400/40"
            >
              Format JSON
            </button>
            <button
              type="button"
              onClick={onValidate}
              className="rounded-full border border-white/10 bg-white/5 px-4 py-2 text-xs font-semibold text-slate-200 transition hover:border-sky-300/40 hover:text-white focus:outline-none focus:ring-2 focus:ring-sky-400/40"
            >
              Validate
            </button>
          </div>
          <div className="flex items-center gap-2">
            <button
              type="button"
              onClick={onClose}
              className="rounded-full border border-white/15 bg-white/5 px-4 py-2 text-sm font-medium text-slate-200 transition hover:border-sky-300/40 hover:text-white focus:outline-none focus:ring-2 focus:ring-sky-400/40"
            >
              Cancel
            </button>
            <button
              type="button"
              onClick={onSubmit}
              className="rounded-full bg-gradient-to-r from-sky-500 via-indigo-500 to-fuchsia-500 px-5 py-2 text-sm font-semibold text-white shadow-lg shadow-sky-500/30 transition hover:opacity-90 focus:outline-none focus:ring-2 focus:ring-sky-400/50"
            >
              Add servers
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

interface SettingsModalProps {
  open: boolean;
  onClose: () => void;
  draft: {
    configPath: string;
    confirmDelete: boolean;
    cyberpunkMode: boolean;
  };
  onChangeDraft: (next: SettingsModalProps['draft']) => void;
  onSave: () => void;
  onTestConnection: () => void;
  testing: boolean;
}

const SettingsModal = ({ open, onClose, draft, onChangeDraft, onSave, onTestConnection, testing }: SettingsModalProps) => {
  if (!open) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-950/85 backdrop-blur-sm p-4">
      <div className="glass-panel w-full max-w-2xl overflow-hidden rounded-3xl border border-white/10 bg-slate-950/95">
        <div className="flex items-center justify-between border-b border-white/5 px-8 py-6">
          <div>
            <p className="text-xs uppercase tracking-[0.35em] text-slate-400">Preferences</p>
            <h2 className="mt-1 text-2xl font-semibold text-white">Settings</h2>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="rounded-full border border-white/10 bg-white/10 p-2 text-slate-300 transition hover:text-white focus:outline-none focus:ring-2 focus:ring-sky-400/50"
          >
            ✕
          </button>
        </div>

        <div className="space-y-5 px-8 py-6 text-sm">
          <div className="space-y-4">
            <label className="block">
              <span className="text-xs font-semibold uppercase tracking-[0.3em] text-slate-400">Config Path</span>
              <div className="mt-2 flex gap-2">
                <input
                  value={draft.configPath}
                  onChange={event => onChangeDraft({ ...draft, configPath: event.target.value })}
                  className="flex-1 rounded-2xl border border-white/10 bg-slate-900/60 px-4 py-2 text-sm text-slate-100 shadow-inner shadow-slate-950/50 focus:border-sky-400 focus:outline-none focus:ring-2 focus:ring-sky-500/30"
                  placeholder="~/.claude.json"
                />
                <button
                  type="button"
                  onClick={async () => {
                    if (!window.api?.selectConfigFile) {
                      console.error('File picker not available in browser mode');
                      return;
                    }
                    try {
                      const result = await window.api.selectConfigFile();
                      if (!result.canceled && result.filePath) {
                        onChangeDraft({ ...draft, configPath: result.filePath });
                      }
                    } catch (error) {
                      console.error('Failed to select file:', error);
                    }
                  }}
                  className="rounded-2xl border border-white/10 bg-white/5 px-4 py-2 text-sm font-medium text-slate-100 transition hover:bg-white/10 focus:outline-none focus:ring-2 focus:ring-sky-500/30"
                >
                  Browse
                </button>
              </div>
            </label>
          </div>

          <div className="flex items-start justify-between gap-4 rounded-2xl border border-white/10 bg-white/5 px-4 py-3">
            <div>
              <p className="text-sm font-medium text-white">Ask before deleting servers</p>
              <p className="text-xs text-slate-400">Prevent accidental removals.</p>
            </div>
            <input
              type="checkbox"
              checked={draft.confirmDelete}
              onChange={event => onChangeDraft({ ...draft, confirmDelete: event.target.checked })}
              className="h-5 w-5 cursor-pointer rounded border-white/20 bg-white/10 text-sky-500 focus:ring-sky-400/40"
            />
          </div>

          <div className="flex items-start justify-between gap-4 rounded-2xl border border-white/10 bg-white/5 px-4 py-3">
            <div>
              <p className="text-sm font-medium text-white">Enable cyberpunk mode</p>
              <p className="text-xs text-slate-400">Adds extra neon flair to the UI.</p>
            </div>
            <input
              type="checkbox"
              checked={draft.cyberpunkMode}
              onChange={event => onChangeDraft({ ...draft, cyberpunkMode: event.target.checked })}
              className="h-5 w-5 cursor-pointer rounded border-white/20 bg-white/10 text-sky-500 focus:ring-sky-400/40"
            />
          </div>

          <button
            type="button"
            onClick={onTestConnection}
            className="inline-flex items-center justify-center gap-2 rounded-full border border-white/10 bg-white/5 px-5 py-2 text-sm font-semibold text-slate-200 transition hover:border-sky-300/40 hover:text-white focus:outline-none focus:ring-2 focus:ring-sky-400/40 disabled:cursor-not-allowed disabled:opacity-70"
            disabled={testing}
          >
            {testing ? 'Testing…' : 'Test connection'}
          </button>
        </div>

        <div className="flex items-center justify-end gap-2 border-t border-white/5 px-8 py-6">
          <button
            type="button"
            onClick={onClose}
            className="rounded-full border border-white/15 bg-white/5 px-4 py-2 text-sm font-medium text-slate-200 transition hover:border-sky-300/40 hover:text-white focus:outline-none focus:ring-2 focus:ring-sky-400/40"
          >
            Cancel
          </button>
          <button
            type="button"
            onClick={onSave}
            className="rounded-full bg-gradient-to-r from-sky-500 via-indigo-500 to-fuchsia-500 px-5 py-2 text-sm font-semibold text-white shadow-lg shadow-sky-500/30 transition hover:opacity-90 focus:outline-none focus:ring-2 focus:ring-sky-400/50"
          >
            Save settings
          </button>
        </div>
      </div>
    </div>
  );
};
