import type { ConfigResponse, SaveResponse, ServerConfig } from './types';

type WindowApi = NonNullable<Window['api']>;

function ensureApi(): WindowApi {
  if (typeof window === 'undefined' || !window.api) {
    throw new Error('Renderer API bridge is unavailable');
  }
  return window.api;
}

export async function fetchConfig(configPath?: string): Promise<ConfigResponse> {
  const api = ensureApi();
  const response = await api.getConfig(configPath);
  if (!response.success && response.error) {
    throw new Error(response.error);
  }
  return response;
}

export async function saveConfig(servers: Record<string, ServerConfig>, configPath?: string): Promise<SaveResponse> {
  const api = ensureApi();
  const response = await api.saveConfig(servers, configPath);
  if (!response.success && response.error) {
    throw new Error(response.error);
  }
  return response;
}

export async function getConfigPath(configType?: string): Promise<string> {
  const api = ensureApi();
  return api.getConfigPath(configType);
}

export async function testConfigPath(path: string): Promise<ConfigResponse> {
  const api = ensureApi();
  return api.getConfig(path);
}
