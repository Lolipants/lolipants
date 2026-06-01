/**
 * Creates (or signs in) default admin / tailor / delivery dev accounts and
 * promotes roles in lolipants-api D1 + better-auth session mirror.
 *
 * Usage (from server/lolipants-api):
 *
 *   DEV_SEED_PASSWORD='your-password' \
 *   INTERNAL_SYNC_SECRET='...' \
 *   pnpm exec tsx scripts/seed-dev-accounts.ts
 *
 * Optional:
 *   --auth-base https://lolipants-better-auth.loli-pants.workers.dev
 *   --origin    Origin header (default: AUTH_ORIGIN env or --auth-base)
 *   --remote          wrangler d1 --remote (default)
 *   --local           wrangler d1 local only
 *
 * Accounts created:
 *   admin    lolipants26@gmail.com
 *   tailor   lolipants26+tailor@gmail.com
 *   delivery lolipants26+driver@gmail.com  (driver role in app = delivery)
 */
import { createHmac } from "node:crypto";
import { execSync } from "node:child_process";
import {
  existsSync,
  mkdtempSync,
  readFileSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));

/** Loads `KEY=value` lines from `.dev.vars` (wrangler-style, not committed). */
function loadDevVarsFile(): void {
  const path = join(__dirname, "..", ".dev.vars");
  if (!existsSync(path)) return;
  const text = readFileSync(path, "utf8");
  for (const line of text.split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("#")) continue;
    const eq = trimmed.indexOf("=");
    if (eq <= 0) continue;
    const key = trimmed.slice(0, eq).trim();
    let value = trimmed.slice(eq + 1).trim();
    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    }
    if (process.env[key] === undefined || process.env[key] === "") {
      process.env[key] = value;
    }
  }
}

loadDevVarsFile();

type DevAccount = {
  email: string;
  name: string;
  role: "admin" | "tailor" | "delivery";
  adminScopes: string[];
};

const ACCOUNTS: DevAccount[] = [
  {
    email: "lolipants26@gmail.com",
    name: "Lolipants Admin",
    role: "admin",
    adminScopes: ["*"],
  },
  {
    email: "lolipants26+tailor@gmail.com",
    name: "Lolipants Tailor",
    role: "tailor",
    adminScopes: [],
  },
  {
    email: "lolipants26+driver@gmail.com",
    name: "Lolipants Driver",
    role: "delivery",
    adminScopes: [],
  },
];

type Cli = {
  authBase: string;
  authOrigin: string;
  password: string;
  syncSecret: string;
  d1Remote: boolean;
};

function parseCli(argv: string[]): Cli {
  let authBase =
    process.env.BETTER_AUTH_BASE_URL?.trim() ||
    "https://lolipants-better-auth.loli-pants.workers.dev";
  let authOrigin = process.env.AUTH_ORIGIN?.trim() ?? "";
  let d1Remote = true;
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === "--auth-base" && argv[i + 1]) {
      authBase = argv[++i]!.trim().replace(/\/+$/, "");
    } else if (a === "--origin" && argv[i + 1]) {
      authOrigin = argv[++i]!.trim().replace(/\/+$/, "");
    } else if (a === "--local") {
      d1Remote = false;
    } else if (a === "--remote") {
      d1Remote = true;
    }
  }
  if (!authOrigin) {
    authOrigin = authBase;
  }
  const password = process.env.DEV_SEED_PASSWORD?.trim();
  if (!password) {
    throw new Error(
      "Set DEV_SEED_PASSWORD (e.g. export DEV_SEED_PASSWORD='...')",
    );
  }
  const syncSecret = process.env.INTERNAL_SYNC_SECRET?.trim() ?? "";
  const placeholder =
    !syncSecret ||
    syncSecret.includes("same-value-as-wrangler") ||
    syncSecret.includes("your-");
  if (placeholder) {
    // eslint-disable-next-line no-console
    console.warn(
      "\nWarning: INTERNAL_SYNC_SECRET missing or still a placeholder in .dev.vars.\n" +
        "D1 roles will be set (app uses lolipants-api users table). Better Auth session\n" +
        "mirror will be skipped until you run: pnpm exec tsx scripts/push-internal-sync-secret.ts\n",
    );
  }
  return { authBase, authOrigin, password, syncSecret: placeholder ? "" : syncSecret, d1Remote };
}

async function authEmail(
  base: string,
  origin: string,
  path: "sign-up/email" | "sign-in/email",
  body: Record<string, string>,
): Promise<{ id: string; email: string }> {
  const res = await fetch(`${base}/auth/${path}`, {
    method: "POST",
    headers: {
      "content-type": "application/json",
      Origin: origin,
    },
    body: JSON.stringify(body),
  });
  const text = await res.text();
  let json: Record<string, unknown> = {};
  try {
    json = JSON.parse(text) as Record<string, unknown>;
  } catch {
    // ignore
  }
  if (!res.ok) {
    throw new Error(`${path} ${res.status}: ${text.slice(0, 300)}`);
  }
  const user = json.user as Record<string, unknown> | undefined;
  const id = user?.id?.toString();
  const email = user?.email?.toString();
  if (!id || !email) {
    throw new Error(`No user in ${path} response: ${text.slice(0, 300)}`);
  }
  return { id, email };
}

async function ensureUser(
  base: string,
  origin: string,
  password: string,
  account: DevAccount,
): Promise<{ id: string; email: string }> {
  const signUpBody = {
    name: account.name,
    email: account.email,
    password,
  };
  try {
    return await authEmail(base, origin, "sign-up/email", signUpBody);
  } catch (signUpErr) {
    try {
      return await authEmail(base, origin, "sign-in/email", {
        email: account.email,
        password,
      });
    } catch {
      throw signUpErr;
    }
  }
}

/** Escape a value for a SQLite single-quoted string literal. */
function sqlLiteral(value: string): string {
  return `'${value.replace(/'/g, "''")}'`;
}

/** Run SQL via a temp file so JSON in admin_scopes is not mangled by the shell. */
function d1Execute(remote: boolean, sql: string): void {
  const apiDir = join(__dirname, "..");
  const dir = mkdtempSync(join(tmpdir(), "lolipants-seed-"));
  const file = join(dir, "stmt.sql");
  writeFileSync(file, sql, "utf8");
  try {
    if (remote) {
      const helper = join(apiDir, "scripts", "d1-remote-exec.sh");
      execSync(`bash ${JSON.stringify(helper)} lolipants-db ${JSON.stringify(file)}`, {
        cwd: apiDir,
        stdio: "inherit",
      });
    } else {
      execSync(`wrangler d1 execute lolipants-db --local --file=${JSON.stringify(file)}`, {
        cwd: apiDir,
        stdio: "inherit",
      });
    }
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
}

/** Doha workshop + default price plan so proximity checkout works locally. */
function seedTailorInD1(remote: boolean, userId: string, shopName: string): void {
  const lat = 25.2854;
  const lng = 51.531;
  const safeName = shopName.replace(/'/g, "''");
  d1Execute(
    remote,
    `INSERT INTO tailor_profiles (user_id, shop_name, address, city, lat, lng, service_radius_km, is_accepting_orders)
     VALUES ('${userId}', '${safeName}', 'West Bay', 'Doha', ${lat}, ${lng}, 50, 1)
     ON CONFLICT(user_id) DO UPDATE SET
       shop_name = excluded.shop_name,
       lat = excluded.lat,
       lng = excluded.lng,
       service_radius_km = 50,
       is_accepting_orders = 1,
       updated_at = datetime('now');`,
  );
  d1Execute(
    remote,
    `INSERT INTO tailor_price_plans (id, tailor_id, name, currency, is_active)
     SELECT lower(hex(randomblob(16))), '${userId}', 'Default', 'QAR', 1
     WHERE NOT EXISTS (
       SELECT 1 FROM tailor_price_plans WHERE tailor_id = '${userId}' AND is_active = 1
     );`,
  );
  d1Execute(
    remote,
    `INSERT INTO tailor_garment_prices (id, plan_id, garment_type, fabric_quality, base_price, fabric_fee)
     SELECT lower(hex(randomblob(16))), p.id, g.garment_type, g.fabric_quality, 350,
       CASE g.fabric_quality WHEN 'premium' THEN 120 WHEN 'suit_grade' THEN 180 ELSE 60 END
     FROM tailor_price_plans p
     CROSS JOIN (
       SELECT 'thobe' AS garment_type, 'standard' AS fabric_quality UNION ALL
       SELECT 'thobe', 'premium' UNION ALL
       SELECT 'thobe', 'suit_grade' UNION ALL
       SELECT '*', '*'
     ) g
     WHERE p.tailor_id = '${userId}' AND p.is_active = 1
       AND NOT EXISTS (
         SELECT 1 FROM tailor_garment_prices tgp
         WHERE tgp.plan_id = p.id AND tgp.garment_type = g.garment_type
           AND tgp.fabric_quality = g.fabric_quality
       );`,
  );
  d1Execute(
    remote,
    `INSERT INTO tailor_delivery_fees (id, plan_id, city_key, fee)
     SELECT lower(hex(randomblob(16))), p.id, c.city_key, c.fee
     FROM tailor_price_plans p
     CROSS JOIN (
       SELECT 'doha' AS city_key, 20 AS fee UNION ALL
       SELECT 'default', 25
     ) c
     WHERE p.tailor_id = '${userId}' AND p.is_active = 1
       AND NOT EXISTS (
         SELECT 1 FROM tailor_delivery_fees tdf
         WHERE tdf.plan_id = p.id AND tdf.city_key = c.city_key
       );`,
  );
}

function promoteInD1(
  remote: boolean,
  userId: string,
  account: DevAccount,
): void {
  const scopesJson = JSON.stringify(account.adminScopes);
  const scopes = sqlLiteral(scopesJson);
  const sql = `INSERT INTO users (id, name, email, role, admin_scopes)
VALUES (${sqlLiteral(userId)}, ${sqlLiteral(account.name)}, ${sqlLiteral(account.email)}, ${sqlLiteral(account.role)}, ${scopes})
ON CONFLICT(id) DO UPDATE SET
  role = ${sqlLiteral(account.role)},
  admin_scopes = ${scopes},
  name = excluded.name,
  email = excluded.email,
  updated_at = datetime('now');`;
  d1Execute(remote, sql);
}

async function syncAuthRole(
  base: string,
  secret: string,
  userId: string,
  account: DevAccount,
): Promise<void> {
  const body = JSON.stringify({
    role: account.role,
    adminScopes: account.adminScopes,
  });
  const signature = createHmac("sha256", secret).update(body).digest("hex");
  const url = `${base}/internal/user/${encodeURIComponent(userId)}/role`;
  const res = await fetch(url, {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "x-internal-signature": signature,
    },
    body,
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`role sync ${res.status}: ${text}`);
  }
}

async function main() {
  const cli = parseCli(process.argv.slice(2));
  // eslint-disable-next-line no-console
  console.log(`Auth base: ${cli.authBase}`);
  // eslint-disable-next-line no-console
  console.log(`Origin: ${cli.authOrigin}`);
  // eslint-disable-next-line no-console
  console.log(`D1 target: ${cli.d1Remote ? "remote" : "local"}`);

  for (const account of ACCOUNTS) {
    // eslint-disable-next-line no-console
    console.log(`\n--- ${account.role}: ${account.email} ---`);
    const { id } = await ensureUser(
      cli.authBase,
      cli.authOrigin,
      cli.password,
      account,
    );
    // eslint-disable-next-line no-console
    console.log(`user id: ${id}`);
    promoteInD1(cli.d1Remote, id, account);
    if (cli.syncSecret) {
      await syncAuthRole(cli.authBase, cli.syncSecret, id, account);
    }
    if (account.role === "tailor") {
      try {
        seedTailorInD1(cli.d1Remote, id, account.name);
      } catch (err) {
        const msg = err instanceof Error ? err.message : String(err);
        if (/no such table:\s*tailor_/i.test(msg)) {
          // eslint-disable-next-line no-console
          console.error(
            "\nTailor workshop seed failed: tailor pricing tables are missing.\n" +
              "Apply migrations, then re-run seed:\n" +
              "  wrangler d1 migrations apply lolipants-db --remote\n",
          );
        }
        throw err;
      }
    }
    // eslint-disable-next-line no-console
    console.log("promoted + synced");
  }

  // eslint-disable-next-line no-console
  console.log("\nDone. Sign out and sign in again in the app to refresh role.");
  // eslint-disable-next-line no-console
  console.log("\nLogin summary:");
  for (const a of ACCOUNTS) {
    // eslint-disable-next-line no-console
    console.log(`  ${a.role.padEnd(8)} ${a.email}`);
  }
}

main().catch((err) => {
  // eslint-disable-next-line no-console
  console.error(err);
  process.exit(1);
});
