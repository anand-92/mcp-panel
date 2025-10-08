export type ViewMode = 'grid' | 'list';
export type FilterMode = 'all' | 'active' | 'disabled' | 'recent';

export interface ServerTransportConfig {
  type: string;
  url?: string;
  headers?: Record<string, string>;
  [key: string]: unknown;
}

export interface ServerRemoteConfig {
  type: string;
  url: string;
  headers?: Record<string, string>;
  [key: string]: unknown;
}

export interface ServerConfig {
  command?: string;
  args?: string[];
  cwd?: string;
  env?: Record<string, string>;
  transport?: ServerTransportConfig;
  remotes?: ServerRemoteConfig[];
  [key: string]: unknown;
}

export interface ServerModel {
  name: string;
  config: ServerConfig;
  enabled: boolean;
  updatedAt: number;
}

export interface SettingsState {
  confirmDelete: boolean;
  cyberpunkMode: boolean;
}

export interface ConfigResponse {
  success: boolean;
  servers: Record<string, ServerConfig>;
  fullConfig?: {
    mcpServers?: Record<string, ServerConfig>;
    [key: string]: unknown;
  };
  isNew?: boolean;
  error?: string;
}

export interface SaveResponse {
  success: boolean;
  error?: string;
}
