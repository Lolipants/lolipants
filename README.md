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

## Store builds (App Store / Play)

Before generating a release binary for Store review, make sure the app uses real integrations:

1. Put the following values into `.env` (these are loaded at app startup via `flutter_dotenv`):
   - `BETTER_AUTH_BASE_URL`
   - `API_BASE_URL`
   - `TAP_PUBLIC_KEY`
   - `ONESIGNAL_APP_ID`
2. Ensure mock payment is disabled:
   - Do **not** set `--dart-define=FEATURE_MOCK_PAYMENT=true`
   - For CI safety, you can pass `--dart-define=FEATURE_MOCK_PAYMENT=false`

For **Google Play**, add `android/key.properties` and your upload keystore so the release AAB is signed with your production key (without it, Gradle falls back to debug signing and Play will reject the upload).

Typical build commands:

```bash
# Android
flutter build appbundle --release --dart-define=FEATURE_MOCK_PAYMENT=false

# iOS
flutter build ipa --release --dart-define=FEATURE_MOCK_PAYMENT=false
```

On a Mac CI runner, the first `flutter build ipa` will create the iOS `Podfile.lock` (CocoaPods). Commit the generated `ios/Podfile.lock` to keep lockfiles stable across submissions.

## Tests

```bash
flutter test
```

In `server/lolipants-api`: `npm test` (see that README).
