# Google Sign-In (Better Auth + Flutter)

This follows [Better Auth — Google](https://better-auth.com/docs/authentication/google): the **Flutter app uses the native Google Sign-In SDK**, obtains an **ID token**, and calls **`POST /auth/sign-in/social`** with `idToken: { token }`. **No browser**, **no `lolipants://` redirect**, and **no Custom Tab / WebView** for this flow.

The worker still uses the same **Web** OAuth client (`GOOGLE_CLIENT_ID` + `GOOGLE_CLIENT_SECRET`) to verify that ID token (`aud` must match a configured client id).

## Values for Google Cloud Console

Use these when creating **Web**, **Android**, and **iOS** OAuth clients. The **Web client ID** is public (it ships in the app via `GOOGLE_SERVER_CLIENT_ID`); never put the **client secret** in Flutter or commit it to git.

| Where / what | Value |
|--------------|--------|
| **Web application — Client ID** (same as Wrangler `GOOGLE_CLIENT_ID` and Flutter `GOOGLE_SERVER_CLIENT_ID`) | `407254430257-3l0bn97r2l34nt918guir3tjgqhek2i2.apps.googleusercontent.com` |
| **Web — Authorized JavaScript origins** | `https://lolipants-better-auth.loli-pants.workers.dev` (and `http://localhost:8787` for local worker dev) |
| **Web — Authorized redirect URIs** | `https://lolipants-better-auth.loli-pants.workers.dev/auth/callback/google`, `http://localhost:8787/auth/callback/google` |
| **Android — Package name** | `com.lolipants.lolipants` |
| **Android — SHA-1 certificate fingerprints** | Register **each** keystore you use: **debug** from `%USERPROFILE%\.android\debug.keystore` (`keytool -list -v -keystore … -alias androiddebugkey`), and **release** / **Play App Signing** SHA-1 from Play Console or your upload keystore. |
| **iOS — Bundle ID** | `com.lolipants.lolipants` (matches `PRODUCT_BUNDLE_IDENTIFIER` in Xcode) |
| **iOS — Client ID** (in `Info.plist` as `GIDClientID`, not in `.env`) | `407254430257-ic7np5kv4t6nae7o54rsvtl084u930jp.apps.googleusercontent.com` |
| **iOS — URL scheme (reversed client id)** | `com.googleusercontent.apps.407254430257-ic7np5kv4t6nae7o54rsvtl084u930jp` (second entry under **URL types** in `Info.plist`) |
| **Android — OAuth client ID** (Cloud Console only; `installed` JSON) | `407254430257-luhlgbnsvfe25teeisrb40mqucbumt92.apps.googleusercontent.com` — not used in Flutter `.env`; ties package + SHA-1 to Google Sign-In. |

## 1) Google Cloud project

1. Open [Google Cloud Console](https://console.cloud.google.com/).
2. **APIs & Services → OAuth consent screen** — configure app name, scopes (`email`, `profile`, `openid`), test users while in Testing, etc.

## 2) Web OAuth client (Better Auth + ID token audience)

1. **Credentials → Create credentials → OAuth client ID → Web application**.
2. **Authorized JavaScript origins** — your Better Auth origin, e.g.  
   `https://lolipants-better-auth.loli-pants.workers.dev`
3. **Authorized redirect URIs** — Better Auth callback (with `basePath: /auth`):  
   `https://lolipants-better-auth.loli-pants.workers.dev/auth/callback/google`  
   (and `http://localhost:8787/auth/callback/google` for local `wrangler dev` if needed.)
4. Copy **Client ID** and **Client secret** (never commit them to git).

## 3) Android (native Sign-In)

1. **Credentials → OAuth client ID → Android**.
2. Use the **package name** and **SHA-1** rows from the table above.
3. Add a separate fingerprint for **release** / **Play signing** when you ship to Play.
4. Optional: `android/app/src/main/res/values/strings.xml` defines `default_web_client_id` as the **Web** client ID (same as `GOOGLE_SERVER_CLIENT_ID`) so Play Services matches the ID token audience used by Better Auth.

## 4) iOS (native Sign-In)

1. **Credentials → OAuth client ID → iOS** — use the **Bundle ID** from the table above (`com.lolipants.lolipants`).
2. In **`ios/Runner/Info.plist`**, set **`GIDClientID`** to the iOS OAuth **Client ID** and add a **URL type** whose scheme is the **reversed client id** (see [Google iOS setup](https://developers.google.com/identity/sign-in/ios/start)). This repo already includes both for the current iOS client in the table above.

## 5) Worker secrets

From `server/better-auth-worker`:

```bash
npx wrangler secret put GOOGLE_CLIENT_ID
npx wrangler secret put GOOGLE_CLIENT_SECRET
```

Use the **Web** client ID and secret from step 2. Redeploy after changing secrets:

```bash
npm run deploy
```

## 6) Flutter `.env`

In the project root `.env` (not committed):

```env
BETTER_AUTH_BASE_URL=https://lolipants-better-auth.loli-pants.workers.dev
GOOGLE_SERVER_CLIENT_ID=407254430257-3l0bn97r2l34nt918guir3tjgqhek2i2.apps.googleusercontent.com
```

`GOOGLE_SERVER_CLIENT_ID` is passed to `GoogleSignIn.initialize(serverClientId: …)` so the returned **ID token `aud`** matches what Better Auth verifies.

Rebuild the app after changing `.env`.

## 7) `TRUSTED_ORIGINS`

`wrangler.toml` `TRUSTED_ORIGINS` must still include your Better Auth **HTTPS** origin (and `http://localhost:3000` if you use a local admin). The old `lolipants://auth` entry is optional for this native flow but harmless if left in place.

## 8) Smoke test

1. Fill `.env` as above, cold-restart the app.
2. Tap **Continue with Google** — system Google account picker, then signed in in-app.
3. If Better Auth returns **401** / invalid token: confirm `GOOGLE_SERVER_CLIENT_ID` **exactly** equals the worker’s `GOOGLE_CLIENT_ID` (Web client), and that Android SHA-1 / iOS URL scheme are set in Google Cloud.

## Reference

- [Google | Better Auth](https://better-auth.com/docs/authentication/google) — ID token sign-in (`idToken` in `signIn.social`).
