import type { Context, Next } from "hono";
import type { AppVariables, Env } from "../types";
import { getBearerToken } from "../lib/http";

type SessionPayload = {
  session?: { token?: string; userId?: string };
  user?: { id: string; role?: string; name?: string; email?: string };
};

export async function requireAuth(
  c: Context<{ Bindings: Env; Variables: AppVariables }>,
  next: Next,
) {
  const token = getBearerToken(c);
  if (!token) return c.json({ error: "Unauthorised" }, 401);

  const authBase = c.env.BETTER_AUTH_BASE_URL?.replace(/\/+$/, "");
  if (!authBase) return c.json({ error: "Auth base URL not configured" }, 500);

  const request = new Request("https://auth.local/auth/get-session", {
    method: "GET",
    headers: {
      Authorization: `Bearer ${token}`,
      Cookie: `better-auth.session_token=${token}`,
    },
  });
  const response = await c.env.AUTH_SERVICE.fetch(request);

  if (!response.ok) {
    return c.json({ error: "Invalid or expired session" }, 401);
  }

  const payload = (await response.json()) as SessionPayload;
  const userId = payload.user?.id;
  const userRole = payload.user?.role ?? "user";
  if (!userId) return c.json({ error: "Invalid session payload" }, 401);

  // Keep local app user table in sync with authenticated users.
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

  c.set("userId", userId);
  c.set("userRole", userRole);
  await next();
}

export function requireRole(...roles: string[]) {
  return async (
    c: Context<{ Bindings: Env; Variables: AppVariables }>,
    next: Next,
  ) => {
    const userRole = c.get("userRole") as string | undefined;
    if (!userRole) return c.json({ error: "Unauthorised" }, 401);
    if (userRole === "admin" || roles.includes(userRole)) return next();
    return c.json({ error: "Forbidden" }, 403);
  };
}
