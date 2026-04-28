# Lolipants launch runbook

This runbook consolidates every operator task required to take Lolipants from
"all green in staging" to "customers placing paid orders in production." Use
it as the single source of truth the day before launch.

> Checklist conventions
> - `⬜` = not yet done
> - `✅` = verified on production
> - Owners are short-handed: **PO** (Product Owner), **SRE** (Platform
>   Engineer), **DES** (Designer), **SUP** (Support Lead).

---

## 1. Tap Payments — production credentials

| Item | Owner | Status |
|------|-------|--------|
| Tap merchant account approved (KYC, settlement IBAN) | PO | ⬜ |
| Tap **live** `secret_*` key exchanged via 1Password | SRE | ⬜ |
| `TAP_SECRET_KEY` set on Cloudflare Worker (production) | SRE | ⬜ |
| `TAP_PUBLIC_KEY` exposed to the Flutter release build | SRE | ⬜ |
| Webhook URL `POST /payments/webhook/tap` configured in Tap dashboard | SRE | ⬜ |
| End-to-end charge using a real card (refunded immediately) | SUP | ⬜ |

### Commands

```bash
# Set secrets (never commit!)
cd server/lolipants-api
wrangler secret put TAP_SECRET_KEY         # prompt -> paste live secret key
wrangler secret put TAP_PUBLIC_KEY         # prompt -> paste live public key
wrangler deploy
```

### Verification

1. Switch the Flutter build to `--release` (which disables the sandbox token
   fallback in `payment_screen.dart`).
2. Walk the checkout from "design" to the Tap card widget; ensure
   `POST /payments/confirm` returns `{ "status": "paid" }`.
3. Confirm the Tap dashboard shows the capture with the Lolipants order id
   in the metadata column.

---

## 2. OneSignal — push notifications

| Item | Owner | Status |
|------|-------|--------|
| Production OneSignal app created | SRE | ⬜ |
| iOS APNs key uploaded (10-year key, not certificate) | SRE | ⬜ |
| Android Firebase server key uploaded | SRE | ⬜ |
| `ONESIGNAL_APP_ID` + `ONESIGNAL_API_KEY` Worker secrets set | SRE | ⬜ |
| OneSignal App ID baked into the Flutter release build | SRE | ⬜ |
| Test push fires from `sendToUser()` in staging | SRE | ⬜ |

### Commands

```bash
cd server/lolipants-api
wrangler secret put ONESIGNAL_API_KEY
wrangler secret put ONESIGNAL_APP_ID
wrangler deploy
```

```bash
# On the Flutter side, pass the app id via --dart-define at build time:
flutter build ipa --dart-define=ONESIGNAL_APP_ID=xxx
flutter build appbundle --dart-define=ONESIGNAL_APP_ID=xxx
```

### Smoke test

1. Install a fresh release build on a phone, log in, place a test order.
2. Trigger an order status change from the admin panel.
3. Confirm the push lands in ~10s with the bilingual heading.
4. Cancel the order and confirm no duplicate pushes fire.

---

## 3. AWS SES — transactional email

Lolipants uses SES for auth magic links, receipts, and support replies.

| Item | Owner | Status |
|------|-------|--------|
| SES production access granted (exited sandbox) | PO | ⬜ |
| `no-reply@lolipants.com` verified (DKIM + SPF + DMARC) | SRE | ⬜ |
| `SES_ACCESS_KEY_ID` and `SES_SECRET_ACCESS_KEY` Worker secrets | SRE | ⬜ |
| `SES_REGION` pinned (`me-south-1` preferred for Middle East latency) | SRE | ⬜ |
| `SES_FROM_EMAIL` set to the verified sender | SRE | ⬜ |
| Test magic-link email lands in inbox (not spam) | SUP | ⬜ |

DNS records to publish (Cloudflare DNS):

```
TXT  @            "v=spf1 include:amazonses.com -all"
TXT  _dmarc       "v=DMARC1; p=quarantine; rua=mailto:dmarc@lolipants.com"
CNAME <token>._domainkey.lolipants.com -> <token>.dkim.amazonses.com
```

### Smoke test

1. Trigger a magic-link signup from the production app.
2. Open the Gmail raw headers — `ARC-Authentication-Results` should show
   `spf=pass`, `dkim=pass`, `dmarc=pass`.

---

## 4. Landing page

See `landing/README.md` for full instructions. Operator checklist:

| Item | Owner | Status |
|------|-------|--------|
| Cloudflare Pages project connected to Git | SRE | ⬜ |
| Build output dir set to `landing/` | SRE | ⬜ |
| Custom domain `lolipants.com` + `www` CNAME wired | SRE | ⬜ |
| HTTPS certificate issued | SRE | ⬜ |
| Real showcase imagery replacing CSS placeholders | DES | ⬜ |
| `/privacy.html` + `/terms.html` published and linked in footer | PO | ⬜ |
| Cloudflare Web Analytics enabled | SRE | ⬜ |

---

## 5. Store submissions

### Apple App Store

| Item | Owner | Status |
|------|-------|--------|
| App Store Connect record created | PO | ⬜ |
| Encryption declaration filed (we use HTTPS only) | PO | ⬜ |
| App Privacy questionnaire completed (location optional, name, email) | PO | ⬜ |
| Screenshots (6.7", 6.5", 5.5") rendered in EN + AR | DES | ⬜ |
| Localized listing: `en-US`, `ar-SA` | PO | ⬜ |
| TestFlight review passed | PO | ⬜ |
| Release build uploaded via Xcode / Codemagic | SRE | ⬜ |

### Google Play Store

| Item | Owner | Status |
|------|-------|--------|
| Play Console app created | PO | ⬜ |
| Data safety form submitted | PO | ⬜ |
| Signed AAB uploaded to Production track | SRE | ⬜ |
| Feature graphic (1024×500) + 8 screenshots per locale | DES | ⬜ |
| Arabic (ar) translations of the store listing uploaded | PO | ⬜ |
| Closed track tested on 5 devices | SUP | ⬜ |

---

## 6. Launch day runbook

1. **T-24h:** freeze the `main` branch, deploy the exact SHA to staging, run
   the Phase 8 smoke suite (`pnpm vitest run`).
2. **T-4h:** flip the Cloudflare Worker route from `staging-api` to `api`.
3. **T-2h:** push the App Store + Play Store releases to "Ready to release";
   do **not** publish yet.
4. **T-60m:** send the landing email to the waitlist.
5. **T-0:** publish both store releases. Monitor:
   - Worker metrics (error rate < 1%)
   - Tap dashboard (successful captures > 95%)
   - OneSignal dashboard (delivery > 90%)
   - SES bounce rate (< 5%)
6. **T+4h:** post-launch retro, triage any Sentry issues.

## 7. Rollback

| Surface | Rollback lever |
|---------|----------------|
| Worker API | `wrangler rollback` to the previous version |
| Landing site | Cloudflare Pages → Deployments → promote previous |
| iOS app | "Remove from Sale" in App Store Connect |
| Android app | Halt rollout, staged rollout = 0% |
| Payments | Flip `TAP_SECRET_KEY` to sandbox key to force sandbox capture |
| Push | Remove `ONESIGNAL_API_KEY` secret to short-circuit server-side sends |
