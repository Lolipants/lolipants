/**
 * Tiny helper to push a user's role + admin scopes into the better-auth
 * worker's `user` table so sessions reflect the new permissions.
 *
 * Run AFTER `seed-super-admin.sql` (or any manual UPDATE to lolipants-api
 * users.role / users.admin_scopes):
 *
 *   pnpm tsx server/lolipants-api/scripts/sync-super-admin.ts \
 *     --user-id <user-id> \
 *     --role admin \
 *     --scopes '["*"]' \
 *     --base https://better-auth.<worker>.workers.dev \
 *     --secret $INTERNAL_SYNC_SECRET
 */
import { createHmac } from "node:crypto";

type Args = {
  userId: string;
  role: string;
  scopes: string;
  base: string;
  secret: string;
};

function parseArgs(argv: string[]): Args {
  const out: Partial<Args> = {};
  for (let i = 0; i < argv.length; i += 2) {
    const key = argv[i]?.replace(/^--/, "");
    const value = argv[i + 1];
    if (!key || value === undefined) continue;
    switch (key) {
      case "user-id":
        out.userId = value;
        break;
      case "role":
        out.role = value;
        break;
      case "scopes":
        out.scopes = value;
        break;
      case "base":
        out.base = value;
        break;
      case "secret":
        out.secret = value;
        break;
    }
  }
  if (!out.userId || !out.role || !out.scopes || !out.base || !out.secret) {
    throw new Error(
      "Usage: --user-id <id> --role <role> --scopes <json> --base <url> --secret <hex>",
    );
  }
  return out as Args;
}

async function main() {
  const { userId, role, scopes, base, secret } = parseArgs(process.argv.slice(2));
  const body = JSON.stringify({ role, adminScopes: JSON.parse(scopes) });
  const signature = createHmac("sha256", secret).update(body).digest("hex");
  const url = `${base.replace(/\/$/, "")}/internal/user/${encodeURIComponent(
    userId,
  )}/role`;
  const response = await fetch(url, {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "x-internal-signature": signature,
    },
    body,
  });
  if (!response.ok) {
    const text = await response.text();
    throw new Error(`sync failed: ${response.status} ${text}`);
  }
  const json = await response.json();
  // eslint-disable-next-line no-console
  console.log("synced", json);
}

main().catch((err) => {
  // eslint-disable-next-line no-console
  console.error(err);
  process.exit(1);
});
