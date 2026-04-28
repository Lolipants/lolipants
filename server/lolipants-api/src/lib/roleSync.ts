import type { Env } from "../types";

/**
 * HMAC for legacy commission endpoint and for Better Auth role sync signatures.
 */
export async function hmacSha256Hex(secret: string, payload: string): Promise<string> {
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

type SyncContext = { env: Env };

/**
 * Pushes D1 role / adminScopes to the better-auth worker when configured.
 */
export async function syncRoleWithAuthWorker(
  c: SyncContext,
  userId: string,
  patch: { role: string; adminScopes: string[] },
): Promise<void> {
  const secret = c.env.INTERNAL_SYNC_SECRET?.trim();
  if (!secret) return;
  const base = c.env.BETTER_AUTH_BASE_URL?.replace(/\/+$/, "");
  if (!base) return;
  const payload = JSON.stringify({
    role: patch.role,
    adminScopes: patch.adminScopes,
  });
  const signature = await hmacSha256Hex(secret, payload);
  try {
    const request = new Request(
      `https://auth.local/internal/user/${encodeURIComponent(userId)}/role`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-internal-signature": signature,
        },
        body: payload,
      },
    );
    await c.env.AUTH_SERVICE.fetch(request);
  } catch (error) {
    console.warn("role sync failed", { userId, error });
  }
}
