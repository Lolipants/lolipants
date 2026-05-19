/**
 * Uploads Flutter catalogue PNGs to R2 under `catalog/{designs|mannequins|configurator}/`.
 *
 * Prerequisites:
 *   - `wrangler` logged in (`npx wrangler whoami`)
 *   - Bucket `lolipants-media` exists (see wrangler.toml)
 *
 * Usage (from server/lolipants-api):
 *   pnpm upload:catalog-assets          # uploads to **remote** R2 (production CDN)
 *   pnpm upload:catalog-assets -- --local   # local wrangler persistence only (dev)
 *   pnpm upload:catalog-assets -- --dry-run
 */
import { execSync } from "node:child_process";
import { readdir, stat } from "node:fs/promises";
import { join, relative } from "node:path";

const BUCKET = "lolipants-media";
const CATALOG_DIRS = ["designs", "mannequins", "configurator"] as const;
const REPO_ROOT = join(import.meta.dirname, "../../..");
const IMAGES_ROOT = join(REPO_ROOT, "assets/images");

const dryRun = process.argv.includes("--dry-run");
/** Default remote so objects are reachable at CLOUDFLARE_R2_BASE_URL in the app. */
const useRemote = !process.argv.includes("--local");

function contentType(file: string): string {
  const lower = file.toLowerCase();
  if (lower.endsWith(".png")) return "image/png";
  if (lower.endsWith(".jpg") || lower.endsWith(".jpeg")) return "image/jpeg";
  if (lower.endsWith(".webp")) return "image/webp";
  return "application/octet-stream";
}

async function walkFiles(dir: string): Promise<string[]> {
  const entries = await readdir(dir, { withFileTypes: true });
  const out: string[] = [];
  for (const entry of entries) {
    const full = join(dir, entry.name);
    if (entry.isDirectory()) {
      out.push(...(await walkFiles(full)));
    } else if (entry.isFile()) {
      out.push(full);
    }
  }
  return out;
}

async function main() {
  let uploaded = 0;
  for (const sub of CATALOG_DIRS) {
    const root = join(IMAGES_ROOT, sub);
    let st;
    try {
      st = await stat(root);
    } catch {
      console.warn(`skip missing folder: ${root}`);
      continue;
    }
    if (!st.isDirectory()) continue;

    const files = await walkFiles(root);
    for (const file of files) {
      const rel = relative(join(IMAGES_ROOT), file).replace(/\\/g, "/");
      const key = `catalog/${rel}`;
      const remoteFlag = useRemote ? "--remote" : "--local";
      const cmd = [
        "npx",
        "wrangler",
        "r2",
        "object",
        "put",
        `${BUCKET}/${key}`,
        `--file=${JSON.stringify(file)}`,
        `--content-type=${contentType(file)}`,
        remoteFlag,
      ].join(" ");

      if (dryRun) {
        console.log(`[dry-run] ${key}`);
      } else {
        execSync(cmd, { stdio: "inherit", cwd: import.meta.dirname });
        console.log(`uploaded ${key}`);
      }
      uploaded++;
    }
  }
  const target = useRemote ? "remote" : "local";
  console.log(
    dryRun
      ? `Would upload ${uploaded} object(s) to ${target} ${BUCKET}.`
      : `Done. Uploaded ${uploaded} object(s) to ${target} ${BUCKET}.`,
  );
  if (uploaded === 0) {
    console.warn(
      "No files found. Restore assets/images/{designs,mannequins,configurator} before uploading.",
    );
  }
  console.log(
    "Set CLOUDFLARE_R2_BASE_URL in the app .env to your public R2 domain.",
  );
  if (useRemote && !dryRun && uploaded > 0) {
    console.log(
      "Verify: curl -I \"${CLOUDFLARE_R2_BASE_URL}/catalog/designs/<one-file>.png\"",
    );
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
