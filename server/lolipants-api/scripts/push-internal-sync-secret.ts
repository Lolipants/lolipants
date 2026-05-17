/**
 * Pushes INTERNAL_SYNC_SECRET from `.dev.vars` to both Cloudflare Workers.
 *
 *   pnpm exec tsx scripts/push-internal-sync-secret.ts
 *
 * Generate a value first (e.g. `openssl rand -hex 32`) and add to `.dev.vars`:
 *   INTERNAL_SYNC_SECRET=...
 */
import { execSync } from "node:child_process";
import { existsSync, readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const apiDir = join(__dirname, "..");
const authDir = join(apiDir, "..", "better-auth-worker");

function loadSecret(): string {
  const path = join(apiDir, ".dev.vars");
  if (!existsSync(path)) {
    throw new Error(`Create ${path} with INTERNAL_SYNC_SECRET=...`);
  }
  const text = readFileSync(path, "utf8");
  for (const line of text.split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("#")) continue;
    if (!trimmed.startsWith("INTERNAL_SYNC_SECRET=")) continue;
    let value = trimmed.slice("INTERNAL_SYNC_SECRET=".length).trim();
    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    }
    if (
      !value ||
      value.includes("same-value-as-wrangler") ||
      value.includes("your-")
    ) {
      throw new Error(
        "Set a real INTERNAL_SYNC_SECRET in .dev.vars (e.g. openssl rand -hex 32)",
      );
    }
    return value;
  }
  throw new Error("INTERNAL_SYNC_SECRET not found in .dev.vars");
}

function putSecret(cwd: string, secret: string): void {
  execSync("wrangler secret put INTERNAL_SYNC_SECRET", {
    cwd,
    input: secret,
    stdio: ["pipe", "inherit", "inherit"],
  });
}

function main() {
  const secret = loadSecret();
  // eslint-disable-next-line no-console
  console.log("Pushing INTERNAL_SYNC_SECRET to lolipants-api...");
  putSecret(apiDir, secret);
  // eslint-disable-next-line no-console
  console.log("Pushing INTERNAL_SYNC_SECRET to lolipants-better-auth...");
  putSecret(authDir, secret);
  // eslint-disable-next-line no-console
  console.log(
    "\nDone. Re-run pnpm seed:dev-accounts to mirror roles into Better Auth.",
  );
}

main();
