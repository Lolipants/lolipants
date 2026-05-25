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

For **slim MVP** exports you can also pass `--dart-define=FEATURE_CASUAL=false` to hide the Casual browse lane and related presets (women-first / traditional-only pilots).

For worker env vars, use each package’s `.dev.vars.example` as a template.

## Payments (Tap)

The checkout flow creates orders and payment intents against the Worker, then confirms using a **manual Tap token** entry sheet on release builds (or sandbox / mock shortcuts in debug and `FEATURE_MOCK_PAYMENT` builds). The **Tap Flutter SDK is not bundled** until product explicitly requests in-app card collection; see `lib/features/orders/screens/payment_screen.dart`.

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

## App Store / TestFlight (GitHub Actions)

CI builds and TestFlight uploads are configured in [`.github/workflows/ios-testflight.yml`](.github/workflows/ios-testflight.yml).

**Setup:** add Apple signing + App Store Connect API secrets and runtime URL secrets — full checklist in [`docs/ios-github-actions.md`](docs/ios-github-actions.md).

**Release a build:**

```bash
git tag v1.0.0
git push origin v1.0.0
```

Or run **Actions → iOS TestFlight → Run workflow** on `main`.

PRs run [`flutter-ci.yml`](.github/workflows/flutter-ci.yml) (analyze + test on Ubuntu).

## Tests

```bash
flutter test
```

In `server/lolipants-api`: `npm test` (see that README).
