export function authBaseUrl(): string {
  return process.env.NEXT_PUBLIC_AUTH_BASE_URL?.trim() ?? "";
}

export function apiBaseUrl(): string {
  return process.env.NEXT_PUBLIC_API_BASE_URL?.trim() ?? "";
}

export function catalogCdnBaseUrl(): string {
  return process.env.NEXT_PUBLIC_CATALOG_CDN_BASE_URL?.trim().replace(/\/+$/, "") ?? "";
}
