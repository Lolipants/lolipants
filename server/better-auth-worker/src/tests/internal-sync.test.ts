/**
 * Regression for the HMAC-gated /internal/user/:id/role endpoint.
 *
 * Walks the three guard branches (missing secret, bad signature, happy
 * path) using a minimal D1 stub - drizzle is only asked to run an update,
 * so we can swap the underlying DB with a thin mock that records the
 * statement.
 */
import { describe, expect, it } from "vitest";
import app from "../index";

async function hmacHex(secret: string, payload: string): Promise<string> {
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

function buildEnv(opts: { secret?: string } = {}) {
  const statements: Array<{ sql: string; params: unknown[] }> = [];
  const prepared = (sql: string) => ({
    bind: (...params: unknown[]) => ({
      run: async () => {
        statements.push({ sql, params });
        return { success: true, meta: { changes: 1 } };
      },
      all: async () => ({ results: [] }),
      first: async () => null,
    }),
  });
  const db = {
    prepare: prepared,
    batch: async () => [],
    dump: async () => new ArrayBuffer(0),
    exec: async () => ({ count: 0, duration: 0 }),
  } as unknown as D1Database;
  return {
    env: {
      DB: db,
      BETTER_AUTH_SECRET: "test",
      INTERNAL_SYNC_SECRET: opts.secret,
    },
    statements,
  };
}

describe("better-auth internal sync", () => {
  it("returns 404 when the sync secret is not configured", async () => {
    const { env } = buildEnv({});
    const response = await app.request(
      "http://localhost/internal/user/user-1/role",
      { method: "POST", body: JSON.stringify({ role: "admin" }) },
      env,
    );
    expect(response.status).toBe(404);
  });

  it("rejects requests without a valid signature", async () => {
    const { env } = buildEnv({ secret: "topsecret" });
    const response = await app.request(
      "http://localhost/internal/user/user-1/role",
      {
        method: "POST",
        headers: {
          "content-type": "application/json",
          "x-internal-signature": "deadbeef",
        },
        body: JSON.stringify({ role: "admin", adminScopes: ["*"] }),
      },
      env,
    );
    expect(response.status).toBe(401);
  });

  it("accepts a correctly-signed payload", async () => {
    const secret = "topsecret";
    const body = JSON.stringify({ role: "admin", adminScopes: ["*"] });
    const signature = await hmacHex(secret, body);
    const { env, statements } = buildEnv({ secret });
    const response = await app.request(
      "http://localhost/internal/user/user-1/role",
      {
        method: "POST",
        headers: {
          "content-type": "application/json",
          "x-internal-signature": signature,
        },
        body,
      },
      env,
    );
    expect(response.status).toBe(200);
    // drizzle turned the update into a prepared statement.
    expect(statements.some((s) => s.sql.toLowerCase().includes("update"))).toBe(
      true,
    );
  });
});
