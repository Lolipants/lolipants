# Lolipants API Secrets Setup (Can Be Done Later)

You can deploy the API worker before every third-party key exists. Endpoints that need a missing secret fail or no-op at runtime until you add them.

---

## Feature → secrets → APIs (reference)

| Feature | Where the key lives | Secret / config | External API or behaviour |
|--------|---------------------|-----------------|---------------------------|
| **AI design / measure** | `lolipants-api` | `OPENAI_API_KEY` | `https://api.openai.com` via `/ai/*` |
| **3D / mesh jobs** (optional) | `lolipants-api` | `MESHY_API_KEY`, `MESHY_API_BASE_URL` | Meshy API when mannequin mesh routes call it |
| **Payments — intent + confirm** | `lolipants-api` | `TAP_SECRET_KEY` | Tap `https://api.tap.company/v2/charges` for `POST /payments/confirm`; intents use same account |
| **Push — server sends** | `lolipants-api` | `ONESIGNAL_API_KEY`, `ONESIGNAL_APP_ID` | `https://onesignal.com/api/v1/notifications` (order/delivery/post/consultation triggers) |
| **Push — client init** | Flutter `.env` | `ONESIGNAL_APP_ID` | OneSignal SDK (same app id as Worker); no secret in the app |
| **Push — token storage** | — | — | `POST /users/push-token` (authenticated; no extra secret) |
| **Auth (email, OAuth, OTP)** | `better-auth` worker | `BETTER_AUTH_SECRET`, optional `AWS_*` for SES, `GOOGLE_CLIENT_SECRET`, etc. | See `AWS_SES_SETUP.md`, `server/better-auth-worker/README.md` |
| **Admin / RBAC sync** | `lolipants-api` | `INTERNAL_SYNC_SECRET`, `ADMIN_HMAC_SECRET` (optional) | Internal HMAC between services; not a public SaaS API |
| **R2 public URLs** | `lolipants-api` | `CLOUDFLARE_R2_BASE_URL` (often a var, not always secret) | Your R2 public bucket / custom domain |

**Flutter app** (not Worker secrets, but required for production):

| Config | Purpose |
|--------|---------|
| `.env` `API_BASE_URL` / similar | Your deployed `lolipants-api` origin |
| `.env` `ONESIGNAL_APP_ID` | OneSignal SDK init (`lib/core/push/onesignal_bootstrap.dart`) |
| Tap **public** key (when SDK wired) | Client-side card tokenisation; pair with Worker `TAP_SECRET_KEY` |

---

## What you can do now vs later

### Do now (recommended)

1. Deploy `lolipants-api` worker.
2. Configure D1 + R2 + `AUTH_SERVICE` bindings.
3. Set `CLOUDFLARE_R2_BASE_URL` (and `BETTER_AUTH_BASE_URL` in `[vars]` if not already).
4. Update app `.env` with deployed API URL (and `ONESIGNAL_APP_ID` when you have it).

### Can be done later

- `OPENAI_API_KEY` — AI routes (`/ai/design`, `/ai/mannequin`, etc.)
- `MESHY_API_KEY` — optional mesh pipeline
- `TAP_SECRET_KEY` — real card capture on `POST /payments/confirm` (sandbox/debug can use simulate path where enabled)
- `ONESIGNAL_API_KEY` + `ONESIGNAL_APP_ID` — server push; client still needs `ONESIGNAL_APP_ID` in `.env` for the SDK
- Optional admin: `INTERNAL_SYNC_SECRET`, `ADMIN_HMAC_SECRET`

---

## Where to run Worker secret commands

From:

`server/lolipants-api`

Example:

```powershell
cd "C:\Users\medin\work\lolipants\server\lolipants-api"
```

---

## Add secrets later (lolipants-api)

When keys are ready:

```powershell
wrangler secret put OPENAI_API_KEY
wrangler secret put TAP_SECRET_KEY
wrangler secret put ONESIGNAL_API_KEY
wrangler secret put ONESIGNAL_APP_ID
```

Optional:

```powershell
wrangler secret put MESHY_API_KEY
wrangler secret put INTERNAL_SYNC_SECRET
wrangler secret put ADMIN_HMAC_SECRET
```

Rules:

- Do not wrap values in quotes.
- Do not store keys in `wrangler.toml`.
- Do not commit keys to git.

**Better Auth worker** (separate project — email/OAuth/SES):

```powershell
cd "C:\Users\medin\work\lolipants\server\better-auth-worker"
npx wrangler secret put BETTER_AUTH_SECRET
# plus SES / Google / Apple as in that repo’s README
```

---

## Verify secrets

```powershell
wrangler secret list
```

Re-deploy after changes:

```powershell
wrangler deploy
```

---

## Runtime behaviour if secrets are missing

| Area | Expected behaviour |
|------|----------------------|
| Non-secret routes | `/health`, many CRUD paths may still work |
| `OPENAI_API_KEY` | `/ai/*` errors until set |
| `TAP_SECRET_KEY` | `POST /payments/confirm` cannot call Tap; payment capture fails |
| OneSignal pair | `sendToUser` no-ops; pushes not delivered; app can still register token |
| `ONESIGNAL_APP_ID` missing in Flutter | SDK init skipped; no client subscription |

**Music:** playback uses **audio files the user picks from device storage** (paths saved in app preferences); no API key or Worker route.

---

## Suggested rollout order

1. `OPENAI_API_KEY` — unlocks AI editor / measurement flows.
2. `TAP_SECRET_KEY` — unlocks live `POST /payments/confirm` with Tap.
3. `ONESIGNAL_APP_ID` (Worker + Flutter `.env`) — client can subscribe.
4. `ONESIGNAL_API_KEY` — server can send transactional pushes (orders, delivery, posts, consultations).
5. Optional: `MESHY_API_KEY`, admin sync secrets, SES on auth worker.

Then `wrangler deploy` (both workers as needed) and re-test flows.

---

## Quick test commands

Replace `<api-url>` and token as needed.

```powershell
curl "<api-url>/health"
```

Authenticated examples:

```powershell
curl -H "Authorization: Bearer <token>" "<api-url>/orders"
curl -H "Authorization: Bearer <token>" -X POST "<api-url>/users/push-token" -H "Content-Type: application/json" -d "{\"oneSignalId\":\"test\"}"
```

---

## Troubleshooting

- `wrangler not recognized` — install/update: `npm i -g wrangler`
- Not logged in — `wrangler login`
- Secret set but endpoint still fails — redeploy; confirm same Cloudflare account/environment
- Wrong API URL in app — `.env` should point at your deployed `lolipants-api` base URL (see your Dio client / env loader)
- Push works on device but not from server — verify **both** Worker `ONESIGNAL_*` secrets **and** Flutter `ONESIGNAL_APP_ID` match the same OneSignal app
