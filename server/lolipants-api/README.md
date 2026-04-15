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
- `/users`

## Setup

1. Install dependencies:
   - `npm install`
2. Set D1 database ID in `wrangler.toml`.
3. Apply migration:
   - `wrangler d1 execute lolipants-db --local --file=./migrations/0001_app_schema.sql`
   - `wrangler d1 execute lolipants-db --remote --file=./migrations/0001_app_schema.sql`
4. Add secrets:
   - `OPENAI_API_KEY`
   - `TAP_SECRET_KEY`
   - `ONESIGNAL_API_KEY`
   - `ONESIGNAL_APP_ID`
   - `CLOUDFLARE_R2_BASE_URL`
5. Run locally:
   - `npm run dev`

## Important note

Mannequin options are designed to be managed by the admin dashboard. Do not hardcode mannequin catalogs in API responses for production.
