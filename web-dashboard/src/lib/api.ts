import { apiBaseUrl } from "./config";
import { getToken } from "./session";
import type { ApiError } from "./types";

export async function apiFetch<T>(
  path: string,
  init: RequestInit = {},
): Promise<T> {
  const base = apiBaseUrl();
  if (!base) {
    throw { message: "NEXT_PUBLIC_API_BASE_URL is not set", status: 0 } satisfies ApiError;
  }
  const token = getToken();
  const headers = new Headers(init.headers);
  headers.set("Content-Type", "application/json");
  if (token) headers.set("Authorization", `Bearer ${token}`);

  const res = await fetch(`${base}${path}`, { ...init, headers });
  if (!res.ok) {
    let message = res.statusText;
    let code: string | undefined;
    try {
      const body = (await res.json()) as { error?: { message?: string; code?: string } };
      message = body.error?.message ?? message;
      code = body.error?.code;
    } catch {
      // ignore parse errors
    }
    throw { message, status: res.status, code } satisfies ApiError;
  }
  if (res.status === 204) return undefined as T;
  return (await res.json()) as T;
}

export async function apiUpload<T>(
  path: string,
  form: FormData,
): Promise<T> {
  const base = apiBaseUrl();
  const token = getToken();
  const headers = new Headers();
  if (token) headers.set("Authorization", `Bearer ${token}`);
  const res = await fetch(`${base}${path}`, { method: "POST", headers, body: form });
  if (!res.ok) {
    const body = (await res.json().catch(() => ({}))) as {
      error?: { message?: string; code?: string };
    };
    throw {
      message: body.error?.message ?? res.statusText,
      status: res.status,
      code: body.error?.code,
    } satisfies ApiError;
  }
  return (await res.json()) as T;
}
