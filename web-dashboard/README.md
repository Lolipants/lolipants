# Lolipants Web Dashboard

Next.js operations console for **admin** and **tailor** roles. Uses the same Better Auth + lolipants-api stack as the mobile app.

## Setup

```bash
cd web-dashboard
cp .env.example .env.local
npm install
npm run dev
```

Open [http://localhost:3000](http://localhost:3000).

## Environment

| Variable | Description |
|----------|-------------|
| `NEXT_PUBLIC_AUTH_BASE_URL` | Better Auth worker URL |
| `NEXT_PUBLIC_API_BASE_URL` | lolipants-api worker URL |

## CORS

Ensure both workers allow this origin:

- `lolipants-api`: `APP_ALLOWED_ORIGINS` includes `http://localhost:3000` and production dashboard URL
- `better-auth-worker`: `TRUSTED_ORIGINS` includes the same

For Google OAuth on web, add redirect URI to Google Cloud Console:

`{AUTH_BASE_URL}/auth/callback/google`

## Roles

- **Admin** (`role=admin`) → `/admin/*` with scope-filtered navigation
- **Tailor** (`role=tailor`) → `/tailor/*`
- Other roles → `/unauthorized`

## Scripts

- `npm run dev` — local development
- `npm run build` — production build
- `npm run test:e2e` — Playwright smoke tests (login page)
