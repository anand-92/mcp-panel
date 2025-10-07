import type { ConfigResponse, SaveResponse, ServerConfig } from './types';
import type { FetchRegistryOptions, RegistryListResponse } from './registry';

declare global {
  interface WindowApi {
    getConfigPath: (configType?: string) => Promise<string>;
    selectConfigFile: () => Promise<{ canceled: boolean; filePath?: string }>;
    getConfig: (path?: string) => Promise<ConfigResponse>;
    saveConfig: (servers: Record<string, ServerConfig>, configPath?: string) => Promise<SaveResponse>;
    addServer: (name: string, config: ServerConfig, configPath?: string) => Promise<SaveResponse>;
    deleteServer: (name: string, configPath?: string) => Promise<SaveResponse>;
    getProfiles: () => Promise<{ success: boolean; profiles: string[] }>;
    getProfile: (name: string) => Promise<{ success: boolean; servers: Record<string, ServerConfig> } | { success: false; error: string } >;
    saveProfile: (name: string, servers: string[]) => Promise<SaveResponse>;
    deleteProfile: (name: string) => Promise<SaveResponse>;
    getGlobalConfigs: () => Promise<{ success: boolean; configs: Record<string, unknown>; error?: string }>;
    saveGlobalConfigs: (configs: Record<string, unknown>) => Promise<SaveResponse>;
    fetchRegistry: (options?: FetchRegistryOptions) => Promise<RegistryListResponse>;
    getPlatform: () => string;
  }

  interface Window {
    api?: WindowApi;
  }
}

export {};
