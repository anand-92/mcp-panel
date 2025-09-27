const OFFICIAL_REGISTRY_BASE_URL = 'https://registry.modelcontextprotocol.io';
const PROXY_REGISTRY_BASE_PATH = '/registry';

const isBrowser = typeof window !== 'undefined';
const hasRegistryBridge = isBrowser && typeof window.api?.fetchRegistry === 'function';

const getHttpBaseUrl = (): string => {
  if (!isBrowser) {
    return OFFICIAL_REGISTRY_BASE_URL;
  }

  const protocol = window.location.protocol;
  if (protocol === 'http:' || protocol === 'https:') {
    return PROXY_REGISTRY_BASE_PATH;
  }

  return OFFICIAL_REGISTRY_BASE_URL;
};

const buildQueryString = (options: FetchRegistryOptions): string => {
  const params = new URLSearchParams();

  if (options.limit) {
    params.set('limit', String(options.limit));
  }

  if (options.cursor) {
    params.set('cursor', options.cursor);
  }

  if (options.query) {
    params.set('query', options.query);
  }

  return params.toString();
};

const buildHttpEndpoint = (options: FetchRegistryOptions): string => {
  const base = getHttpBaseUrl();
  const trimmedBase = base.endsWith('/') ? base.slice(0, -1) : base;
  const query = buildQueryString(options);

  if (trimmedBase.startsWith('http')) {
    const url = new URL('/v0/servers', trimmedBase);
    if (query) {
      url.search = query;
    }
    return url.toString();
  }

  const endpoint = `${trimmedBase}/v0/servers`;
  return query ? `${endpoint}?${query}` : endpoint;
};

export interface RegistryRemoteHeader {
  name: string;
  description?: string;
  isSecret?: boolean;
  isRequired?: boolean;
}

export interface RegistryRemote {
  type: string;
  url: string;
  headers?: RegistryRemoteHeader[];
}

export interface RegistryPackageEnvVariable {
  name: string;
  description?: string;
  isRequired?: boolean;
  isSecret?: boolean;
  format?: string;
  value?: string;
  valueHint?: string;
  variables?: Record<string, unknown>;
}

export interface RegistryPackageTransport {
  type: string;
  [key: string]: unknown;
}

export interface RegistryPackage {
  registryType: string;
  identifier: string;
  version?: string;
  registryBaseUrl?: string;
  transport?: RegistryPackageTransport;
  environmentVariables?: RegistryPackageEnvVariable[];
  instructions?: string;
  [key: string]: unknown;
}

export interface RegistryRepository {
  url: string;
  source?: string;
}

export interface RegistryMetaOfficial {
  serverId: string;
  versionId: string;
  publishedAt: string;
  updatedAt: string;
  isLatest?: boolean;
}

export interface RegistryMeta {
  'io.modelcontextprotocol.registry/official'?: RegistryMetaOfficial;
  [key: string]: unknown;
}

export interface RegistryServer {
  name: string;
  description?: string;
  status?: string;
  version?: string;
  repository?: RegistryRepository;
  packages?: RegistryPackage[] | null;
  remotes?: RegistryRemote[] | null;
  _meta?: RegistryMeta;
  [key: string]: unknown;
}

export interface RegistryListMetadata {
  next_cursor?: string;
  count?: number;
  [key: string]: unknown;
}

export interface RegistryListResponse {
  servers: RegistryServer[];
  metadata?: RegistryListMetadata;
}

export interface FetchRegistryOptions {
  cursor?: string;
  limit?: number;
  query?: string;
}

export async function fetchRegistryServers(
  options: FetchRegistryOptions = {}
): Promise<RegistryListResponse> {
  if (hasRegistryBridge) {
    try {
      return await window.api!.fetchRegistry(options);
    } catch (error) {
      console.warn('Registry bridge failed, falling back to HTTP fetch', error);
    }
  }

  const endpoint = buildHttpEndpoint(options);
  const response = await fetch(endpoint, {
    headers: { Accept: 'application/json' }
  });

  if (!response.ok) {
    const message = `Registry request failed with status ${response.status}`;
    throw new Error(message);
  }

  return response.json() as Promise<RegistryListResponse>;
}

export function normalizeRegistryServers(servers: RegistryServer[]): RegistryServer[] {
  const byName = new Map<string, RegistryServer>();

  servers.forEach(server => {
    const existing = byName.get(server.name);
    if (!existing) {
      byName.set(server.name, server);
      return;
    }

    const currentMeta = existing._meta?.['io.modelcontextprotocol.registry/official'];
    const incomingMeta = server._meta?.['io.modelcontextprotocol.registry/official'];
    const incomingIsLatest = incomingMeta?.isLatest ?? true;
    const currentIsLatest = currentMeta?.isLatest ?? false;

    if (incomingIsLatest && !currentIsLatest) {
      byName.set(server.name, server);
      return;
    }

    if (incomingIsLatest === currentIsLatest) {
      const incomingUpdatedAt = incomingMeta?.updatedAt ?? '';
      const currentUpdatedAt = currentMeta?.updatedAt ?? '';
      if (incomingUpdatedAt > currentUpdatedAt) {
        byName.set(server.name, server);
      }
    }
  });

  return Array.from(byName.values()).sort((a, b) => a.name.localeCompare(b.name));
}

export function formatRegistryError(error: unknown): string {
  if (error instanceof Error) {
    return error.message;
  }
  return String(error ?? 'Unknown error');
}
