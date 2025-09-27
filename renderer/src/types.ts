export type ViewMode = 'grid' | 'list';
export type FilterMode = 'all' | 'active' | 'disabled' | 'recent';

export interface ServerConfig {
  command: string;
  args?: string[];
  cwd?: string;
  env?: Record<string, string>;
  transport?: Record<string, unknown>;
  [key: string]: unknown;
}

export interface ServerModel {
  name: string;
  config: ServerConfig;
  enabled: boolean;
  tags: string[];
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
