import type { Context, Next } from "hono";
import type { AppVariables, Env } from "../types";
import { apiError, getBearerToken } from "../lib/http";

type AppUserRow = {
  role: string | null;
  admin_scopes: string | null;
  banned_at: string | null;
};

function userDbErrorUserMessage(sqliteMsg: string): string {
  const hint =
    "Apply API migrations: cd server/lolipants-api && wrangler d1 migrations apply --remote";
  const short =
    sqliteMsg.length > 160 ? `${sqliteMsg.slice(0, 160)}…` : sqliteMsg;
  return `Could not read users table in D1 (${short}). ${hint}`;
}

/** Loads role/scopes/ban; falls back if pre-0005 columns are missing. */
async function loadAppUserRow(
  db: D1Database,
  userId: string,
): Promise<{ ok: true; row: AppUserRow | null } | { ok: false; message: string }> {
  const full =
    "SELECT role, admin_scopes, banned_at FROM users WHERE id = ?";
  const legacy =
    "SELECT role, NULL AS admin_scopes, NULL AS banned_at FROM users WHERE id = ?";
  try {
    const row = await db
      .prepare(full)
      .bind(userId)
      .first<AppUserRow>();
    return { ok: true, row };
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    if (!/no such column/i.test(message)) {
      return { ok: false, message };
    }
    try {
      const row = await db
        .prepare(legacy)
        .bind(userId)
        .first<AppUserRow>();
      return { ok: true, row };
    } catch (e2) {
      return {
        ok: false,
        message: e2 instanceof Error ? e2.message : String(e2),
      };
    }
  }
}

type SessionPayload = {
  session?: { token?: string; userId?: string };
  user?: {
    id: string;
    role?: string;
    name?: string;
    email?: string;
    adminScopes?: string | string[];
    admin_scopes?: string | string[];
  };
};

function parseScopes(raw: unknown): string[] {
  if (!raw) return [];
  if (Array.isArray(raw)) {
    return raw
      .map((v) => String(v ?? "").trim())
      .filter((v) => v.length > 0);
  }
  let text = String(raw).trim();
  if (text.length === 0) return [];
  // D1 / CSV paste sometimes stores a JSON *string* (outer quotes) or
  // double-JSON: unwrap once to get `["*"]` as text.
  if (text.startsWith('"') && text.endsWith('"')) {
    try {
      const unwrapped = JSON.parse(text) as unknown;
      if (typeof unwrapped === "string") {
        text = unwrapped.trim();
      }
    } catch {
      // keep text
    }
  }
  if (text.startsWith("[")) {
    try {
      const parsed = JSON.parse(text) as unknown;
      if (Array.isArray(parsed)) {
        return parsed
          .map((v) => String(v ?? "").trim())
          .filter((v) => v.length > 0);
      }
      if (typeof parsed === "string" && parsed.trim().startsWith("[")) {
        const inner = JSON.parse(parsed) as unknown;
        if (Array.isArray(inner)) {
          return inner
            .map((v) => String(v ?? "").trim())
            .filter((v) => v.length > 0);
        }
      }
    } catch {
      // fall through
    }
  }
  return text
    .split(",")
    .map((v) => v.trim())
    .filter((v) => v.length > 0);
}

export async function requireAuth(
  c: Context<{ Bindings: Env; Variables: AppVariables }>,
  next: Next,
) {
  const token = getBearerToken(c);
  if (!token) return apiError(c, 401, "UNAUTHORIZED", "Unauthorised");

  const authBase = c.env.BETTER_AUTH_BASE_URL?.replace(/\/+$/, "");
  if (!authBase) {
    return apiError(
      c,
      500,
      "AUTH_CONFIG_MISSING",
      "Auth base URL not configured",
    );
  }

  if (!c.env.AUTH_SERVICE) {
    return apiError(
      c,
      500,
      "AUTH_SERVICE_MISSING",
      "Auth service is not bound (local wrangler: check [[services]] AUTH_SERVICE).",
    );
  }

  const request = new Request("https://auth.local/auth/get-session", {
    method: "GET",
    headers: {
      Authorization: `Bearer ${token}`,
      Cookie: `better-auth.session_token=${token}`,
    },
  });

  let response: Response;
  try {
    response = await c.env.AUTH_SERVICE.fetch(request);
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    console.error("[auth] AUTH_SERVICE.fetch failed:", message);
    return apiError(
      c,
      503,
      "AUTH_UNAVAILABLE",
      "Could not reach the authentication service. Try again in a moment.",
    );
  }

  if (!response.ok) {
    return apiError(c, 401, "INVALID_SESSION", "Invalid or expired session");
  }

  let payload: SessionPayload;
  try {
    payload = (await response.json()) as SessionPayload;
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    console.error("[auth] get-session JSON parse failed:", message);
    return apiError(c, 502, "AUTH_INVALID_RESPONSE", "Invalid session response");
  }
  const userId = payload.user?.id;
  if (!userId) {
    return apiError(c, 401, "INVALID_SESSION_PAYLOAD", "Invalid session payload");
  }

  // The better-auth session only carries basic identity today. Role and
  // admin_scopes are sourced from the application users table (updated in
  // /admin/users), so load them here to keep requireAdmin and requireRole
  // fully authoritative.
  const loaded = await loadAppUserRow(c.env.DB, userId);
  if (!loaded.ok) {
    console.error("[auth] users lookup failed:", loaded.message);
    return apiError(
      c,
      500,
      "USER_DB_ERROR",
      userDbErrorUserMessage(loaded.message),
    );
  }
  const appUser = loaded.row;

  if (appUser?.banned_at) {
    return apiError(c, 403, "ACCOUNT_BANNED", "This account has been suspended");
  }

  const sessionRole = payload.user?.role;
  const appRole = appUser?.role ?? undefined;
  const userRole = (appRole ?? sessionRole ?? "user").toString();
  const sessionScopes = parseScopes(
    payload.user?.adminScopes ?? payload.user?.admin_scopes,
  );
  const appScopes = parseScopes(appUser?.admin_scopes);
  const adminScopes = appScopes.length > 0 ? appScopes : sessionScopes;

  // Keep local app user table in sync with authenticated users.
  try {
    await c.env.DB.prepare(
      `INSERT INTO users (id, name, email, role)
       VALUES (?, ?, ?, ?)
       ON CONFLICT(id) DO UPDATE SET
         name = excluded.name,
         email = excluded.email,
         updated_at = datetime('now')`,
    )
      .bind(
        userId,
        payload.user?.name ?? "Lolipants User",
        payload.user?.email ?? `${userId}@placeholder.local`,
        userRole,
      )
      .run();
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    console.error("[auth] user upsert failed:", message);
    return apiError(
      c,
      500,
      "USER_UPSERT_FAILED",
      "Could not sync user profile. Check D1 schema/migrations.",
    );
  }

  c.set("userId", userId);
  c.set("userRole", userRole);
  c.set("adminScopes", adminScopes);
  await next();
}

export function requireRole(...roles: string[]) {
  return async (
    c: Context<{ Bindings: Env; Variables: AppVariables }>,
    next: Next,
  ) => {
    const userRole = c.get("userRole") as string | undefined;
    if (!userRole) return apiError(c, 401, "UNAUTHORIZED", "Unauthorised");
    if (userRole === "admin" || roles.includes(userRole)) return next();
    return apiError(c, 403, "FORBIDDEN", "Forbidden");
  };
}

/** Role gate for delivery-person accounts. */
export function requireCourier() {
  return requireRole("delivery");
}

/**
 * Role gate for admins. When [scope] is provided, the admin must either have
 * the `*` super-admin sentinel in admin_scopes or include that specific scope.
 */
export function requireAdmin(scope?: string) {
  return async (
    c: Context<{ Bindings: Env; Variables: AppVariables }>,
    next: Next,
  ) => {
    const userRole = c.get("userRole") as string | undefined;
    if (userRole !== "admin") {
      return apiError(c, 403, "FORBIDDEN", "Admin only");
    }
    if (!scope) return next();
    const scopes = (c.get("adminScopes") as string[] | undefined) ?? [];
    if (scopes.includes("*") || scopes.includes(scope)) return next();
    // Legacy: role=admin with no admin_scopes in D1 yet — treat as full access
    // until scopes are set explicitly (see rbac.md; prefer `["*"]` or per-scope).
    if (userRole === "admin" && scopes.length === 0) return next();
    return apiError(c, 403, "FORBIDDEN", `Missing admin scope: ${scope}`);
  };
}
