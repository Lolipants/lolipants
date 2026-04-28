import { drizzle } from "drizzle-orm/d1";
import { eq } from "drizzle-orm";
import { Hono } from "hono";
import { cors } from "hono/cors";
import { createAuth } from "./auth";
import * as schema from "./db/schema";

/** One Better Auth instance per isolate — rebuilding `betterAuth()` every request can exceed CPU limits (CF 1102). */
let cachedAuth: ReturnType<typeof createAuth> | null = null;

type Bindings = {
  DB: D1Database;
  BETTER_AUTH_SECRET: string;
  BETTER_AUTH_URL?: string;
  TRUSTED_ORIGINS?: string;
  AWS_ACCESS_KEY_ID?: string;
  AWS_SECRET_ACCESS_KEY?: string;
  AWS_SESSION_TOKEN?: string;
  AWS_SES_REGION?: string;
  RESET_FROM_EMAIL?: string;
  APP_NAME?: string;
  GOOGLE_CLIENT_ID?: string;
  GOOGLE_CLIENT_SECRET?: string;
  APPLE_CLIENT_ID?: string;
  APPLE_TEAM_ID?: string;
  APPLE_KEY_ID?: string;
  APPLE_PRIVATE_KEY?: string;
  INTERNAL_SYNC_SECRET?: string;
};

const app = new Hono<{ Bindings: Bindings }>();

app.use(
  "/auth/*",
  cors({
    origin: (origin, c) => {
      const configured = c.env.TRUSTED_ORIGINS?.split(",")
        .map((x: string) => x.trim())
        .filter((x: string) => x.length > 0);
      if (!configured || configured.length === 0) {
        return origin || "*";
      }
      if (!origin) {
        return configured[0]!;
      }
      return configured.includes(origin) ? origin : configured[0]!;
    },
    allowMethods: ["GET", "POST", "OPTIONS"],
    allowHeaders: ["Content-Type", "Authorization"],
    exposeHeaders: ["set-auth-token"],
  }),
);

app.on(["GET", "POST", "OPTIONS"], "/auth/*", async (c) => {
  const secret = c.env.BETTER_AUTH_SECRET?.trim();
  if (!secret) {
    return c.json(
      {
        error: "misconfigured",
        message: "BETTER_AUTH_SECRET is not set on this worker",
      },
      500,
    );
  }

  const baseURL = c.env.BETTER_AUTH_URL ?? new URL(c.req.url).origin;
  const trustedOrigins = (c.env.TRUSTED_ORIGINS ?? "")
    .split(",")
    .map((x) => x.trim())
    .filter((x) => x.length > 0);

  if (!cachedAuth) {
    const db = drizzle(c.env.DB, { schema });
    cachedAuth = createAuth({
      db,
      secret,
      baseURL,
      trustedOrigins,
      awsAccessKeyId: c.env.AWS_ACCESS_KEY_ID,
      awsSecretAccessKey: c.env.AWS_SECRET_ACCESS_KEY,
      awsSessionToken: c.env.AWS_SESSION_TOKEN,
      awsSesRegion: c.env.AWS_SES_REGION ?? "us-east-1",
      resetFromEmail: c.env.RESET_FROM_EMAIL ?? "LOLIPANTS <no-reply@lolipants.com>",
      appName: c.env.APP_NAME ?? "LOLIPANTS",
      google: {
        clientId: c.env.GOOGLE_CLIENT_ID,
        clientSecret: c.env.GOOGLE_CLIENT_SECRET,
      },
      apple: {
        clientId: c.env.APPLE_CLIENT_ID,
        teamId: c.env.APPLE_TEAM_ID,
        keyId: c.env.APPLE_KEY_ID,
        privateKey: c.env.APPLE_PRIVATE_KEY,
      },
    });
  }

  try {
    return await cachedAuth.handler(c.req.raw);
  } catch (err) {
    console.error("better-auth handler error:", err);
    return c.json({ error: "auth_handler_failed" }, 500);
  }
});

async function hmacSha256Hex(secret: string, payload: string): Promise<string> {
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "HMAC",
    key,
    encoder.encode(payload),
  );
  return Array.from(new Uint8Array(signature))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

// HMAC-guarded internal endpoint invoked by lolipants-api whenever an admin
// changes a user's role or admin_scopes. Keeps session payloads authoritative.
app.post("/internal/user/:id/role", async (c) => {
  const secret = c.env.INTERNAL_SYNC_SECRET?.trim();
  if (!secret) {
    return c.json({ error: "internal sync disabled" }, 404);
  }
  const raw = await c.req.text();
  const provided = c.req.header("x-internal-signature") ?? "";
  const expected = await hmacSha256Hex(secret, raw);
  if (!provided || provided !== expected) {
    return c.json({ error: "invalid signature" }, 401);
  }
  let body: Record<string, unknown>;
  try {
    body = raw.length > 0 ? (JSON.parse(raw) as Record<string, unknown>) : {};
  } catch {
    return c.json({ error: "invalid json" }, 400);
  }
  const id = c.req.param("id");
  const role = body.role ? String(body.role).trim() : undefined;
  const scopesRaw = body.adminScopes ?? body.admin_scopes;
  let scopesJson: string | undefined;
  if (Array.isArray(scopesRaw)) {
    scopesJson = JSON.stringify(
      scopesRaw.map((s) => String(s ?? "").trim()).filter((s) => s.length > 0),
    );
  } else if (typeof scopesRaw === "string" && scopesRaw.trim().length > 0) {
    scopesJson = scopesRaw.trim();
  }

  const db = drizzle(c.env.DB, { schema });
  const patch: Partial<typeof schema.user.$inferInsert> = {
    updatedAt: new Date(),
  };
  if (role) patch.role = role;
  if (scopesJson !== undefined) patch.adminScopes = scopesJson;
  if (Object.keys(patch).length === 1) {
    return c.json({ updated: false });
  }
  await db.update(schema.user).set(patch).where(eq(schema.user.id, id));
  return c.json({ updated: true, id, role: patch.role, adminScopes: patch.adminScopes });
});

app.get("/", (c) =>
  c.json({
    ok: true,
    service: "lolipants-better-auth",
    authPath: "/auth",
  }),
);

export default app;
