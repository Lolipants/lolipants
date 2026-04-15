# AWS SES Setup Guide (After You Buy a Domain)

You can safely continue development without SES for now.
When your domain is ready, follow this checklist to enable password-reset emails in production.

## Prerequisites

- Your Cloudflare Worker is deployed (`lolipants-better-auth`).
- You have access to AWS Console.
- You own a domain (example: `lolipants.com`).

## 1) Choose one SES region

Pick one region and keep it consistent everywhere.
Recommended starter region: `us-east-1`.

In `server/better-auth-worker/wrangler.toml`:

```toml
AWS_SES_REGION = "us-east-1"
```

## 2) Verify your SES sender identity

1. Open AWS SES Console in your chosen region.
2. Go to **Verified identities** > **Create identity**.
3. Choose **Domain** (recommended) and enter your domain.
4. SES will give DNS records (DKIM + verification).
5. Add those DNS records at your domain provider (or Cloudflare DNS).
6. Wait until SES shows identity as **Verified**.

Then set sender in `wrangler.toml`:

```toml
RESET_FROM_EMAIL = "LOLIPANTS <no-reply@mail.yourdomain.com>"
```

Use an address under your verified domain.

## 3) Create IAM credentials for SES sending

1. Open AWS IAM > Users > Create user (example: `lolipants-ses-worker`).
2. Create access key (programmatic).
3. Attach permissions for SES send actions.

Minimum policy example:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "SesSendEmail",
      "Effect": "Allow",
      "Action": [
        "ses:SendEmail",
        "ses:SendRawEmail"
      ],
      "Resource": "*"
    }
  ]
}
```

Copy and save:
- Access Key ID
- Secret Access Key

## 4) Add Cloudflare Worker secrets

From `server/better-auth-worker`:

```bash
npx wrangler secret put AWS_ACCESS_KEY_ID
npx wrangler secret put AWS_SECRET_ACCESS_KEY
# Optional only if using temporary credentials:
npx wrangler secret put AWS_SESSION_TOKEN
```

## 5) Deploy worker

```bash
npm run deploy
```

## 6) Test reset-password API

```bash
curl -X POST "https://lolipants-better-auth.lolipants.workers.dev/auth/request-password-reset" \
  -H "content-type: application/json" \
  -H "origin: https://lolipants-better-auth.lolipants.workers.dev" \
  -d "{\"email\":\"your-test-email@yourdomain.com\"}"
```

Expected: HTTP 200 + generic success message.

## 7) If no email arrives, inspect logs

```bash
npx wrangler tail lolipants-better-auth
```

Common errors:
- `MessageRejected`: sender not verified or SES sandbox rules
- `AccessDenied`: IAM policy/credentials issue
- `SignatureDoesNotMatch`: wrong region or bad credentials

## 8) SES sandbox reminder

New SES accounts are often in sandbox:
- Can only send **from verified identities**
- Can only send **to verified recipient addresses**

For production sending, request SES production access in AWS SES.

## Temporary development note

If SES is not configured yet, forgot-password endpoint can still return success,
but no email will be sent until credentials and verified identity are in place.
