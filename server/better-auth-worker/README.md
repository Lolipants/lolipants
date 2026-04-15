# Lolipants Better Auth Worker

Cloudflare Worker + D1 auth server for the Lolipants Flutter app.

## What this exposes

- Better Auth endpoints on `/auth/*` (matches your Flutter `ApiEndpoints`)
- Email/password auth enabled
- Password-reset emails sent through AWS SES with LOLIPANTS-branded HTML
- Bearer-token support enabled via Better Auth `bearer()` plugin
- D1-backed tables (`user`, `session`, `account`, `verification`, `rateLimit`)

## 1) Install

```bash
cd server/better-auth-worker
npm install
```

## 2) Create D1 database

```bash
npx wrangler d1 create lolipants_auth
```

Copy the returned `database_id` into `wrangler.toml` under `[[d1_databases]]`.

## 3) Apply schema migration

```bash
npx wrangler d1 execute lolipants_auth --remote --file=./migrations/0001_better_auth.sql
```

## 4) Set secrets

```bash
npx wrangler secret put BETTER_AUTH_SECRET
npx wrangler secret put AWS_ACCESS_KEY_ID
npx wrangler secret put AWS_SECRET_ACCESS_KEY
# Optional (temporary credentials only):
npx wrangler secret put AWS_SESSION_TOKEN
```

Use a long, random value (>= 32 chars) for `BETTER_AUTH_SECRET`.
Use IAM credentials that can send email with SES.

## 5) Configure sender identity

Set `RESET_FROM_EMAIL` in `wrangler.toml` to a verified SES sender/domain
address, for example:

```toml
RESET_FROM_EMAIL = "LOLIPANTS <no-reply@mail.lolipants.com>"
```

SES will reject delivery if the from address is not verified.

Set your SES region in `wrangler.toml`:

```toml
AWS_SES_REGION = "us-east-1"
```

## 6) Local dev

```bash
cp .dev.vars.example .dev.vars
npm run dev
```

Worker runs on `http://localhost:8787`.

## 7) Deploy

```bash
npm run deploy
```

After deploy, note your worker URL, for example:

`https://lolipants-better-auth.<your-subdomain>.workers.dev`

Then update Flutter `.env` in project root:

```env
BETTER_AUTH_BASE_URL=https://lolipants-better-auth.<your-subdomain>.workers.dev
```

Do not include `/auth` in `BETTER_AUTH_BASE_URL` because the app already calls `/auth/...`.

## 8) Smoke tests

```bash
curl -X POST "https://<your-worker-domain>/auth/sign-up/email" \
  -H "content-type: application/json" \
  -d "{\"name\":\"Test User\",\"email\":\"test@example.com\",\"password\":\"Passw0rd!\"}"
```

You should get JSON containing user/session details.

Password-reset request:

```bash
curl -X POST "https://<your-worker-domain>/auth/request-password-reset" \
  -H "content-type: application/json" \
  -H "origin: https://<your-worker-domain>" \
  -d "{\"email\":\"test@example.com\"}"
```
