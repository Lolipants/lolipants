# Lolipants API Secrets Setup (Can Be Done Later)

Yes, you can set these secrets later:

- `OPENAI_API_KEY`
- `TAP_SECRET_KEY`
- `ONESIGNAL_API_KEY`
- `ONESIGNAL_APP_ID`

The API worker can still be deployed before these keys are available. Endpoints that require missing secrets will fail at runtime until you add them.

---

## What You Can Do Now vs Later

### Do now (recommended)

1. Deploy `lolipants-api` worker.
2. Configure D1 + R2 bindings.
3. Set `CLOUDFLARE_R2_BASE_URL` secret.
4. Update app `.env` with deployed API URL.

### Can be done later

- OpenAI key for AI routes (`/ai/design`, `/ai/measure`)
- Tap key for payment routes
- OneSignal keys for push token/notification workflows

---

## Where To Run Commands

Run all commands from:

`server/lolipants-api`

Example:

```powershell
cd "C:\Users\medin\work\lolipants\server\lolipants-api"
```

---

## Add Secrets Later (One by One)

When your keys are ready, run:

```powershell
wrangler secret put OPENAI_API_KEY
wrangler secret put TAP_SECRET_KEY
wrangler secret put ONESIGNAL_API_KEY
wrangler secret put ONESIGNAL_APP_ID
```

Each command prompts for the value. Paste the key and press Enter.

Important:

- Do not wrap the key in quotes.
- Do not store these in `wrangler.toml`.
- Do not commit keys to git.

---

## Verify Secrets Were Saved

```powershell
wrangler secret list
```

You should see the secret names listed.

---

## Re-Deploy After Adding Secrets

After setting new secrets, deploy again so latest worker version runs with expected config:

```powershell
wrangler deploy
```

---

## Runtime Behavior If Secrets Are Missing

Expected behavior before keys are set:

- Non-secret endpoints may still work (`/health`, orders/designs CRUD depending on route logic).
- Secret-dependent endpoints can fail:
  - AI routes: likely `503`/error response without `OPENAI_API_KEY`
  - Payment flow: fails without `TAP_SECRET_KEY`
  - Push workflows: fail/skip without OneSignal keys

This is normal and safe during phased setup.

---

## Suggested Rollout Order

1. `OPENAI_API_KEY` (unblocks AI design/measurement)
2. `TAP_SECRET_KEY` (unblocks payment backend logic)
3. `ONESIGNAL_APP_ID`
4. `ONESIGNAL_API_KEY`

Then:

1. `wrangler deploy`
2. Re-test related app flows

---

## Quick Test Commands After Setup

Replace `<api-url>` and token as needed.

```powershell
curl "<api-url>/health"
```

For authenticated routes (example only):

```powershell
curl -H "Authorization: Bearer <token>" "<api-url>/orders"
```

---

## Troubleshooting

- `wrangler not recognized`
  - Install/update Wrangler: `npm i -g wrangler`
- `Not logged in`
  - `wrangler login`
- `Secret appears set but endpoint still fails`
  - Re-run `wrangler deploy`
  - Confirm you updated secrets in the same Cloudflare account/environment
- `Wrong worker URL in app`
  - Ensure `.env` uses your deployed `lolipants-api` URL (no `/api` suffix in current implementation)

