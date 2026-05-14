# Lolipants API Worker

Cloudflare Worker API for app domain endpoints:

- `/designs`
- `/orders`
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

## Important note

Mannequin options are designed to be managed by the admin dashboard. Do not hardcode mannequin catalogs in API responses for production.
