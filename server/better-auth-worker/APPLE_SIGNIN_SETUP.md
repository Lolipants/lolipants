# Sign in with Apple (Better Auth + Flutter)

Native iOS flow (same pattern as Google): Flutter obtains an **identity token**, then calls **`POST /auth/sign-in/social`** with `provider: "apple"`.

## Where is the Services ID?

It is **not** in this repo until you set worker secrets. You created it in Apple Developer:

**Certificates, Identifiers & Profiles → Identifiers → filter type “Services IDs”**

Example identifier: `com.lolipants.lolipants.auth` (yours may differ — copy the exact string from that list).

| Apple portal item | Worker secret | Example |
|-------------------|---------------|---------|
| **Services ID** (Identifiers → Services IDs) | `APPLE_CLIENT_ID` | `com.lolipants.lolipants.auth` |
| **Team ID** (Membership / account header) | `APPLE_TEAM_ID` | `8NDNQMAZZG` |
| **Key ID** (Keys → your “lolipants auth” key) | `APPLE_KEY_ID` | `4CB88LHK6N` |
| **`.p8` private key** (downloaded once) | `APPLE_PRIVATE_KEY` | full PEM contents |
| **App ID / bundle ID** | `APPLE_APP_BUNDLE_IDENTIFIER` | `com.lolipants.lolipants` |

The **Services ID** is the OAuth `clientId` for Better Auth. The **bundle ID** is used to verify the native iOS token audience (`aud`).

## Worker secrets

From `server/better-auth-worker`:

```bash
npx wrangler secret put APPLE_CLIENT_ID
npx wrangler secret put APPLE_TEAM_ID
npx wrangler secret put APPLE_KEY_ID
npx wrangler secret put APPLE_PRIVATE_KEY
npx wrangler secret put APPLE_APP_BUNDLE_IDENTIFIER
npm run deploy
```

For local `wrangler dev`, copy `server/better-auth-worker/.dev.vars.example` → `.dev.vars` and fill the same keys.

## Apple Developer checklist

1. **App ID** `com.lolipants.lolipants` → Sign In with Apple enabled.
2. **Services ID** → Sign In with Apple configured (Primary App ID + domain + return URL).
3. **Key** with Sign In with Apple enabled (`.p8` downloaded).

Return URL (Better Auth callback):

`https://lolipants-better-auth.loli-pants.workers.dev/auth/callback/apple`

## Flutter

No Apple env vars in `.env` — only Better Auth base URL. The iOS app uses the system Sign in with Apple sheet.

Rebuild after pulling these changes. Test on a **physical iPhone** (Simulator is limited).

## Reference

- [Apple | Better Auth](https://better-auth.com/docs/authentication/apple)
