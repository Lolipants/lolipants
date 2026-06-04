/**
 * Seeds App Store review demo accounts with feed posts + public showcase designs.
 *
 *   APP_REVIEW_EMAIL='review@example.com' \
 *   APP_REVIEW_PASSWORD='...' \
 *   pnpm exec tsx scripts/seed-app-review-demo.ts --remote
 *
 * Optional: APP_REVIEW_DESIGNER_EMAIL (default review.designer@lolipants.com)
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
import { v4 as uuidv4 } from "uuid";

const __dirname = dirname(fileURLToPath(import.meta.url));

function loadDevVarsFile(): void {
  const path = join(__dirname, "..", ".dev.vars");
  if (!existsSync(path)) return;
  for (const line of readFileSync(path, "utf8").split(/\r?\n/)) {
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

type AccountSpec = {
  email: string;
  name: string;
  role: "user" | "admin" | "tailor" | "delivery";
  isProDesigner: boolean;
};

function sqlLiteral(value: string): string {
  return `'${value.replace(/'/g, "''")}'`;
}

function d1Execute(remote: boolean, sql: string): void {
  const apiDir = join(__dirname, "..");
  const dir = mkdtempSync(join(tmpdir(), "lolipants-review-seed-"));
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

async function authEmail(
  base: string,
  origin: string,
  path: "sign-up/email" | "sign-in/email",
  body: Record<string, string>,
): Promise<{ id: string; email: string }> {
  const res = await fetch(`${base}/auth/${path}`, {
    method: "POST",
    headers: { "content-type": "application/json", Origin: origin },
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
  account: AccountSpec,
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

function upsertUser(remote: boolean, userId: string, account: AccountSpec): void {
  const pro = account.isProDesigner ? 1 : 0;
  d1Execute(
    remote,
    `INSERT INTO users (id, name, email, role, is_pro_designer, admin_scopes)
VALUES (
  ${sqlLiteral(userId)},
  ${sqlLiteral(account.name)},
  ${sqlLiteral(account.email)},
  ${sqlLiteral(account.role)},
  ${pro},
  '[]'
)
ON CONFLICT(id) DO UPDATE SET
  name = excluded.name,
  email = excluded.email,
  role = excluded.role,
  is_pro_designer = excluded.is_pro_designer,
  updated_at = datetime('now');`,
  );
}

function seedCommunityContent(remote: boolean, designerId: string): void {
  const posts: { body: string; tags: string[] }[] = [
    {
      body: "Midnight thobe with gold trim — available to order from Showcase.",
      tags: ["thobe", "showcase"],
    },
    {
      body: "Pearl abaya layering idea for Eid. Tap Showcase to order this look.",
      tags: ["abaya"],
    },
    {
      body: "Casual Gulf streetwear set — feedback welcome from the community.",
      tags: ["casual"],
    },
  ];

  const postSql = posts
    .map((p) => {
      const id = uuidv4();
      const tags = sqlLiteral(JSON.stringify(p.tags));
      return `INSERT INTO posts (id, author_id, body, image_urls, tags, reaction_count, comment_count)
VALUES (${sqlLiteral(id)}, ${sqlLiteral(designerId)}, ${sqlLiteral(p.body)}, '[]', ${tags}, 2, 1);`;
    })
    .join("\n");

  const designs: { name: string; garment: string; colour: string }[] = [
    { name: "Midnight Thobe", garment: "thobe", colour: "#0A1A2F" },
    { name: "Pearl Abaya", garment: "abaya", colour: "#F5F0E8" },
  ];

  const designSql = designs
    .map((d) => {
      const id = uuidv4();
      return `INSERT INTO designs (
  id, user_id, name, garment_type, fabric_quality, primary_colour,
  is_public, order_count, published_at, created_at, updated_at
) VALUES (
  ${sqlLiteral(id)},
  ${sqlLiteral(designerId)},
  ${sqlLiteral(d.name)},
  ${sqlLiteral(d.garment)},
  'standard',
  ${sqlLiteral(d.colour)},
  1,
  3,
  datetime('now'),
  datetime('now'),
  datetime('now')
);`;
    })
    .join("\n");

  d1Execute(remote, `${postSql}\n${designSql}`);
}

async function syncAuthRole(
  base: string,
  secret: string,
  userId: string,
  role: string,
): Promise<void> {
  const body = JSON.stringify({ role, adminScopes: [] });
  const signature = createHmac("sha256", secret).update(body).digest("hex");
  const res = await fetch(`${base}/internal/user/${encodeURIComponent(userId)}/role`, {
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

function parseCli(argv: string[]) {
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
    } else if (a === "--local") d1Remote = false;
    else if (a === "--remote") d1Remote = true;
  }
  if (!authOrigin) authOrigin = authBase;

  const password =
    process.env.APP_REVIEW_PASSWORD?.trim() ||
    process.env.DEV_SEED_PASSWORD?.trim();
  if (!password) {
    throw new Error("Set APP_REVIEW_PASSWORD or DEV_SEED_PASSWORD");
  }

  const customerEmail =
    process.env.APP_REVIEW_EMAIL?.trim() ||
    "modin.alexandria-applesid@gmail.com";
  const designerEmail =
    process.env.APP_REVIEW_DESIGNER_EMAIL?.trim() ||
    "review.designer@lolipants.com";

  const syncSecret = process.env.INTERNAL_SYNC_SECRET?.trim() ?? "";

  return {
    authBase,
    authOrigin,
    password,
    d1Remote,
    customerEmail,
    designerEmail,
    syncSecret,
  };
}

async function main() {
  const cli = parseCli(process.argv.slice(2));

  const customer: AccountSpec = {
    email: cli.customerEmail,
    name: "App Store Reviewer",
    role: "user",
    isProDesigner: false,
  };
  const designer: AccountSpec = {
    email: cli.designerEmail,
    name: "Lolipants Demo Designer",
    role: "user",
    isProDesigner: true,
  };

  // eslint-disable-next-line no-console
  console.log(`Auth: ${cli.authBase}`);
  // eslint-disable-next-line no-console
  console.log(`D1: ${cli.d1Remote ? "remote" : "local"}`);

  // eslint-disable-next-line no-console
  console.log(`\n--- customer (App Store sign-in): ${customer.email} ---`);
  const customerUser = await ensureUser(
    cli.authBase,
    cli.authOrigin,
    cli.password,
    customer,
  );
  upsertUser(cli.d1Remote, customerUser.id, customer);
  if (cli.syncSecret) {
    await syncAuthRole(cli.authBase, cli.syncSecret, customerUser.id, "user");
  }

  // eslint-disable-next-line no-console
  console.log(`\n--- designer (seeded content): ${designer.email} ---`);
  const designerUser = await ensureUser(
    cli.authBase,
    cli.authOrigin,
    cli.password,
    designer,
  );
  upsertUser(cli.d1Remote, designerUser.id, designer);
  if (cli.syncSecret) {
    await syncAuthRole(cli.authBase, cli.syncSecret, designerUser.id, "user");
  }
  seedCommunityContent(cli.d1Remote, designerUser.id);

  // eslint-disable-next-line no-console
  console.log("\nDone. App Store Connect sign-in:");
  // eslint-disable-next-line no-console
  console.log(`  Username: ${customer.email}`);
  // eslint-disable-next-line no-console
  console.log(`  Password: (APP_REVIEW_PASSWORD)`);
  // eslint-disable-next-line no-console
  console.log("\nVerify in app: Community → Feed (3 posts), Showcase (2 designs).");
  // eslint-disable-next-line no-console
  console.log(`Designer login (optional): ${designer.email}`);
}

main().catch((err) => {
  // eslint-disable-next-line no-console
  console.error(err);
  process.exit(1);
});
