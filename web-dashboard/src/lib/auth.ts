import { authBaseUrl } from "./config";
import { apiFetch } from "./api";
import { clearSession, setCachedUser, setToken } from "./session";
import type { DashboardUser, UserRole } from "./types";

function extractToken(data: Record<string, unknown>): string | null {
  const direct = data.token;
  if (typeof direct === "string" && direct) return direct;
  const session = data.session;
  if (session && typeof session === "object") {
    const s = session as Record<string, unknown>;
    const t = s.token ?? s.sessionToken;
    if (typeof t === "string" && t) return t;
  }
  return null;
}

function parseScopes(raw: unknown): string[] {
  if (Array.isArray(raw)) return raw.map(String);
  if (typeof raw === "string") {
    try {
      const parsed = JSON.parse(raw) as unknown;
      return Array.isArray(parsed) ? parsed.map(String) : [];
    } catch {
      return [];
    }
  }
  return [];
}

function parseAuthUser(data: Record<string, unknown>): DashboardUser | null {
  const raw = (data.user ?? data) as Record<string, unknown>;
  if (!raw.id || !raw.email) return null;
  const role = (raw.role?.toString() ?? "user") as UserRole;
  return {
    id: String(raw.id),
    name: String(raw.name ?? ""),
    email: String(raw.email),
    role,
    adminScopes: parseScopes(raw.adminScopes ?? raw.admin_scopes),
    imageUrl: raw.image?.toString() ?? raw.imageUrl?.toString(),
  };
}

async function mergeAppProfile(user: DashboardUser): Promise<DashboardUser> {
  try {
    const me = await apiFetch<{
      role?: string;
      adminScopes?: string[];
      admin_scopes?: string[];
    }>("/users/me");
    return {
      ...user,
      role: (me.role ?? user.role) as UserRole,
      adminScopes: parseScopes(me.adminScopes ?? me.admin_scopes ?? user.adminScopes),
    };
  } catch {
    return user;
  }
}

async function authPost(path: string, body: unknown): Promise<DashboardUser> {
  const base = authBaseUrl();
  if (!base) throw new Error("NEXT_PUBLIC_AUTH_BASE_URL is not set");
  const res = await fetch(`${base}${path}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
  const data = (await res.json().catch(() => ({}))) as Record<string, unknown>;
  if (!res.ok) {
    const err = data as { message?: string; error?: string };
    throw new Error(err.message ?? err.error ?? "Sign in failed");
  }
  const token = extractToken(data);
  const user = parseAuthUser(data);
  if (!token || !user) throw new Error("Invalid auth response");
  setToken(token);
  const merged = await mergeAppProfile(user);
  setCachedUser(JSON.stringify(merged));
  return merged;
}

export async function signIn(email: string, password: string): Promise<DashboardUser> {
  return authPost("/auth/sign-in/email", { email, password });
}

export async function signOut(): Promise<void> {
  const base = authBaseUrl();
  if (base) {
    const token = (await import("./session")).getToken();
    try {
      await fetch(`${base}/auth/sign-out`, {
        method: "POST",
        headers: token ? { Authorization: `Bearer ${token}` } : {},
      });
    } catch {
      // ignore
    }
  }
  clearSession();
}

export async function loadSession(): Promise<DashboardUser | null> {
  const base = authBaseUrl();
  const token = (await import("./session")).getToken();
  if (!base || !token) return null;
  const res = await fetch(`${base}/auth/get-session`, {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) {
    clearSession();
    return null;
  }
  const data = (await res.json()) as Record<string, unknown>;
  const user = parseAuthUser(data);
  if (!user) {
    clearSession();
    return null;
  }
  const merged = await mergeAppProfile(user);
  setCachedUser(JSON.stringify(merged));
  return merged;
}
