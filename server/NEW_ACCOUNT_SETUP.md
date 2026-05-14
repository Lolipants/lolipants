# New Cloudflare company account

Both Workers are pinned to account `ed0f9a60460ec8572f9c24d4d91461ec` via `account_id` in each `wrangler.toml`.

The `database_id` values in `wrangler.toml` are still the **old** account’s IDs until you complete step 2 and paste the new IDs from `wrangler d1 create` output.

Do this on a machine where you can sign in as **Lolipants26@gmail.com** (browser OAuth) or set `CLOUDFLARE_API_TOKEN` with permissions for Workers, D1, and R2.

## 1) Log in to the new account

```bash
npx wrangler login
```

Confirm with `npx wrangler whoami` that you are on the right account.

## 2) Create D1 databases (same names as before)

From the repo root:

```bash
cd server/lolipants-api
npm install
npx wrangler d1 create lolipants-db
```

Copy the printed **`database_id`** into `wrangler.toml` in **both** `[[d1_databases]]` blocks (top-level and `[[env.production.d1_databases]]`).

```bash
cd ../better-auth-worker
npm install
npx wrangler d1 create lolipants_auth
```

Copy the **`database_id`** into `better-auth-worker/wrangler.toml` under `[[d1_databases]]`.

## 3) Create the R2 bucket

```bash
cd ../lolipants-api
npx wrangler r2 bucket create lolipants-media
```

If the bucket already exists, Wrangler will report that; no change needed in `wrangler.toml` (`bucket_name = "lolipants-media"`).

## 4) Apply SQL migrations

**API database** (`lolipants-db`) — same order as [lolipants-api/README.md](lolipants-api/README.md):

```bash
cd server/lolipants-api
npx wrangler d1 execute lolipants-db --remote --file=./migrations/0001_app_schema.sql
npx wrangler d1 execute lolipants-db --remote --file=./migrations/0002_mannequin_jobs.sql
npx wrangler d1 execute lolipants-db --remote --file=./migrations/0003_phase4_hardening.sql
npx wrangler d1 execute lolipants-db --remote --file=./migrations/0004_phase6_community.sql
npx wrangler d1 execute lolipants-db --remote --file=./migrations/0005_roles_and_scopes.sql
npx wrangler d1 execute lolipants-db --remote --file=./migrations/0006_role_requests.sql
npx wrangler d1 execute lolipants-db --remote --file=./migrations/0007_design_render_jobs.sql
```

**Auth database** (`lolipants_auth`):

```bash
cd ../better-auth-worker
npx wrangler d1 execute lolipants_auth --remote --file=./migrations/0001_better_auth.sql
npx wrangler d1 execute lolipants_auth --remote --file=./migrations/0002_user_roles.sql
```

## 5) Workers.dev URL (until `loli-pants.com` is live)

Worker names stay **`lolipants-api`** and **`lolipants-better-auth`**. The hostname is:

`https://<worker-name>.<your-account-workers-subdomain>.workers.dev`

This repo uses account subdomain **`loli-pants`**. Better Auth is at:

`https://lolipants-better-auth.loli-pants.workers.dev`

The API worker (for Flutter `API_BASE_URL`) is:

`https://lolipants-api.loli-pants.workers.dev`

If you ever change the workers.dev subdomain in Cloudflare, update these files to match:

  - `server/lolipants-api/wrangler.toml` → `BETTER_AUTH_BASE_URL` (default + `env.production`)
  - `server/better-auth-worker/wrangler.toml` → `BETTER_AUTH_URL` and `TRUSTED_ORIGINS` (must include the same HTTPS origin + `http://localhost:3000` + `lolipants://auth`)
  - Flutter `.env` → `BETTER_AUTH_BASE_URL` / optional `BETTER_AUTH_ORIGIN` (see root `.env.example`)

## 6) Deploy order

1. Deploy **better-auth** first: `cd server/better-auth-worker && npm run deploy`
2. Then **API**: `cd server/lolipants-api && npm run deploy`

Re-apply `wrangler secret put` on the new account for every secret you used before (both workers).

## 7) Service binding

`lolipants-api` binds to the worker named `lolipants-better-auth`. Both must exist on **this** account (they will, after deploy).
