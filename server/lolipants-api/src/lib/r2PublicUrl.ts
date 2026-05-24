import type { Env } from "../types";

/** Public base URL for R2 objects (no trailing slash). */
export function r2PublicBaseUrl(env: Env): string | null {
  const raw = env.CLOUDFLARE_R2_BASE_URL?.trim();
  if (!raw) return null;
  return raw.replace(/\/+$/, "");
}

export function buildR2PublicUrl(env: Env, objectKey: string): string | null {
  const base = r2PublicBaseUrl(env);
  if (!base) return null;
  const key = objectKey.replace(/^\/+/, "");
  return `${base}/${key}`;
}
