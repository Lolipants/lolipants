# Lolipants

Flutter client for Lolipants (custom garments, orders, community, tailor/delivery flows).

## Repository layout

- **App**: Flutter/Dart in the repo root (`lib/`, `pubspec.yaml`).
- **API**: Cloudflare Worker in `server/lolipants-api/` — see [server/lolipants-api/README.md](server/lolipants-api/README.md).
- **Auth**: Better Auth worker in `server/better-auth-worker/` — see [server/better-auth-worker/README.md](server/better-auth-worker/README.md).
- **Static landing**: `landing/`.

## Local setup (app)

1. Copy `.env.example` to `.env` and set `BETTER_AUTH_BASE_URL` and `API_BASE_URL` (see comments in `.env.example`).
2. Run `flutter pub get`, then `flutter run`.

For worker env vars, use each package’s `.dev.vars.example` as a template.

## Tests

```bash
flutter test
```

In `server/lolipants-api`: `npm test` (see that README).
