import { drizzle } from "drizzle-orm/d1";
import { eq } from "drizzle-orm";
import { Hono } from "hono";
import { cors } from "hono/cors";
import { createAuth } from "./auth";
import * as schema from "./db/schema";

/** Copy Set-Cookie headers from Better Auth redirect onto our HTML response. */
function appendSetCookieHeaders(from: Headers, to: Headers): void {
  const getSetCookie = (
    from as unknown as { getSetCookie?: () => string[] }
  ).getSetCookie;
  if (typeof getSetCookie === "function") {
    for (const c of getSetCookie.call(from)) {
      to.append("Set-Cookie", c);
    }
    return;
  }
  const single = from.get("Set-Cookie");
  if (single) to.append("Set-Cookie", single);
}

function escapeHtmlAttr(s: string): string {
  return s
    .replace(/&/g, "&amp;")
    .replace(/"/g, "&quot;")
    .replace(/</g, "&lt;");
}

const ANDROID_APP_PACKAGE = "com.lolipants.lolipants";

/** Primary tap target for Custom Tabs: intent URI avoids broken history / reload. */
function androidIntentHrefFromDeepLink(deep: URL): string {
  const hostPathQuery = `${deep.host}${deep.pathname}${deep.search}`;
  return `intent://${hostPathQuery}#Intent;scheme=lolipants;package=${ANDROID_APP_PACKAGE};end`;
}

/**
 * HTML bridge for **redirect-based** OAuth only (e.g. web clients). The Flutter
 * app uses **native Google Sign-In + ID token** and does not load this page.
 *
 * Putting a long session token in the HTTP `Location` header breaks some browsers
 * (Custom Tabs / desktop WebView can spin forever). Instead return 200 HTML that
 * sets the same cookies, then sends the user back with `lolipants://…?token=…`.
 *
 * **Do not** use automatic redirects to custom schemes inside Chrome Custom Tabs:
 * navigation can fail and the tab can restore the **previous** history entry
 * (the Google OAuth page). A **user tap** on the link is reliable; on Android
 * the `intent://…#Intent;scheme=lolipants;package=…;end` form is used for the
 * primary button.
 */
function withMobileOAuthDeepLinkToken(
  response: Response,
  userAgent: string | undefined,
): Response {
  if (response.status < 300 || response.status >= 400) return response;
  const locationHeader = response.headers.get("Location")?.trim();
  const authToken = response.headers.get("set-auth-token");
  if (!locationHeader || !authToken) return response;
  let target: URL;
  try {
    target = new URL(locationHeader);
  } catch {
    return response;
  }
  if (target.protocol !== "lolipants:") return response;
  if (!target.searchParams.has("token")) {
    target.searchParams.set("token", authToken);
  }
  const deepLink = target.toString();

  const headers = new Headers();
  appendSetCookieHeaders(response.headers, headers);
  headers.set("content-type", "text/html; charset=utf-8");
  headers.set("cache-control", "no-store");

  const isAndroid = /\bAndroid\b/i.test(userAgent ?? "");
  const primaryHref = isAndroid
    ? androidIntentHrefFromDeepLink(target)
    : deepLink;
  const primaryAttr = escapeHtmlAttr(primaryHref);
  const deepAttr = escapeHtmlAttr(deepLink);

  const html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width,initial-scale=1"/>
  <title>Return to app</title>
  <style>
    body{font-family:system-ui,sans-serif;margin:0;padding:24px;max-width:28rem;margin-inline:auto;text-align:center}
    a{display:inline-block;margin-top:20px;padding:14px 22px;background:#111;color:#fff;text-decoration:none;border-radius:10px;font-weight:600}
    p{color:#333;line-height:1.45}
    .sub{margin-top:16px;font-size:14px;color:#555}
  </style>
</head>
<body>
  <p><strong>Almost done.</strong> Tap the button once to return to Lolipants and finish signing in.</p>
  <p><a href="${primaryAttr}" rel="noopener">Open Lolipants</a></p>
  ${
    isAndroid
      ? `<p class="sub">If the button does nothing, try <a href="${deepAttr}">this link</a> instead.</p>`
      : ""
  }
</body>
</html>`;

  return new Response(html, { status: 200, headers });
}

function escapeHtml(s: string): string {
  return s.replace(/[&<>"']/g, (ch) => {
    if (ch === "&") return "&amp;";
    if (ch === "<") return "&lt;";
    if (ch === ">") return "&gt;";
    if (ch === '"') return "&quot;";
    return "&#39;";
  });
}

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
    });
  }

  try {
    const res = await cachedAuth.handler(c.req.raw);
    return withMobileOAuthDeepLinkToken(res, c.req.header("User-Agent"));
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

app.get("/", (c) => {
  const error = c.req.query("error");
  if (error) {
    const safe = /^[A-Za-z0-9_.-]+$/.test(error) ? error : "unknown";
    const html = `<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"/><meta name="viewport" content="width=device-width, initial-scale=1"/><title>Sign-in</title></head><body style="font-family:system-ui,sans-serif;padding:1.5rem;max-width:32rem"><p><strong>Sign-in did not complete.</strong></p><p>Error code: <code>${escapeHtml(safe)}</code></p><p>You can close this window and try again in the app.</p></body></html>`;
    return c.body(html, 200, { "content-type": "text/html; charset=utf-8" });
  }
  return c.json({
    ok: true,
    service: "lolipants-better-auth",
    authPath: "/auth",
  });
});

export default app;
