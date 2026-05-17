# Lolipants API Worker

Cloudflare Worker API for app domain endpoints:

- `/designs`
- `/orders` (proximity tailor assignment + per-tailor pricing at quote/checkout)
- `/tailor/pricing` (tailor workshop location and price plan CRUD)
- `/fabrics`
- `/presets`
- `/measurements`
- `/posts`
- `/community`
- `/bookings`
- `/upload`
- `/ai`
- `/mannequins`
- `/users`

## Setup

1. Install dependencies:
   - `npm install`
2. Set D1 database ID in `wrangler.toml` (and `account_id` if you use a different Cloudflare account). For a fresh company account, follow [../NEW_ACCOUNT_SETUP.md](../NEW_ACCOUNT_SETUP.md).
3. Apply migrations in order (local + remote):
   - `wrangler d1 execute lolipants-db --local --file=./migrations/0001_app_schema.sql`
   - `wrangler d1 execute lolipants-db --local --file=./migrations/0002_mannequin_jobs.sql`
   - `wrangler d1 execute lolipants-db --local --file=./migrations/0003_phase4_hardening.sql`
   - `wrangler d1 execute lolipants-db --local --file=./migrations/0004_phase6_community.sql`
   - `wrangler d1 execute lolipants-db --local --file=./migrations/0005_roles_and_scopes.sql`
   - `wrangler d1 execute lolipants-db --local --file=./migrations/0006_role_requests.sql`
   - `wrangler d1 execute lolipants-db --local --file=./migrations/0007_design_render_jobs.sql`
   - `wrangler d1 execute lolipants-db --local --file=./migrations/0008_sketch_image_url.sql`
   - `wrangler d1 execute lolipants-db --remote --file=./migrations/0001_app_schema.sql`
   - `wrangler d1 execute lolipants-db --remote --file=./migrations/0002_mannequin_jobs.sql`
   - `wrangler d1 execute lolipants-db --remote --file=./migrations/0003_phase4_hardening.sql`
   - `wrangler d1 execute lolipants-db --remote --file=./migrations/0004_phase6_community.sql`
   - `wrangler d1 execute lolipants-db --remote --file=./migrations/0005_roles_and_scopes.sql`
   - `wrangler d1 execute lolipants-db --remote --file=./migrations/0006_role_requests.sql`
   - `wrangler d1 execute lolipants-db --remote --file=./migrations/0007_design_render_jobs.sql`
   - `wrangler d1 execute lolipants-db --remote --file=./migrations/0008_sketch_image_url.sql`
   - `wrangler d1 migrations apply lolipants-db --remote` (includes `0010_tailor_pricing.sql` for tailor price plans)
4. Add secrets:
   - `OPENAI_API_KEY`
   - `GEMINI_API_KEY` (optional; enables Gemini image refinement for `POST /ai/design-render`; key from Google AI Studio)
   - `TAP_SECRET_KEY`
   - `ONESIGNAL_API_KEY`
   - `ONESIGNAL_APP_ID`
   - `CLOUDFLARE_R2_BASE_URL`
5. Optional Worker vars (non-secret): `GEMINI_IMAGE_MODEL` — defaults to `gemini-2.5-flash-image` when `GEMINI_API_KEY` is set.
6. Run locally:
   - `npm run dev`

## Dev accounts (admin / tailor / delivery)

Creates or updates three default accounts and promotes roles in **remote** D1 + Better Auth:

| Role     | Email                         | Password              |
|----------|-------------------------------|------------------------|
| Admin    | `lolipants26@gmail.com`       | `DEV_SEED_PASSWORD`    |
| Tailor   | `lolipants26+tailor@gmail.com`| same                   |
| Delivery | `lolipants26+driver@gmail.com`| same                   |

1. Copy `.dev.vars.example` → `.dev.vars` and set `DEV_SEED_PASSWORD`.
2. Optional but recommended — generate and deploy a shared sync secret (admin role changes in the dashboard use this):

   ```bash
   openssl rand -hex 32   # paste into .dev.vars as INTERNAL_SYNC_SECRET=
   pnpm secrets:push-internal-sync
   ```

   If `INTERNAL_SYNC_SECRET` is not on the workers yet, `pnpm seed:dev-accounts` still sets roles in **lolipants-api D1** (what the app reads); run `secrets:push-internal-sync` later, then seed again to mirror Better Auth.

3. Seed accounts:

   ```bash
   pnpm seed:dev-accounts
   ```

   Use `--local` for local D1 only. The tailor account also gets a Doha workshop + default price plan.

4. Sign out and sign in again in the app so the session picks up the new role.

This does **not** wipe the database; it upserts these users and roles only.

## Important note

Mannequin options are designed to be managed by the admin dashboard. Do not hardcode mannequin catalogs in API responses for production.
