# Phase 8 / RBAC deploy runbook

Applies to both Cloudflare Workers: `lolipants-api` and `better-auth-worker`.
Run the commands from the repo root unless noted. Every step can be replayed
against `local` first by swapping `--remote` for `--local` on the D1 calls.

## 1. Apply migrations

```sh
# App DB: role/ban columns, courier columns, complaints table.
npx wrangler d1 migrations apply lolipants-db --remote \
  --config server/lolipants-api/wrangler.toml

# Auth DB: carry role + adminScopes on the better-auth user row.
npx wrangler d1 migrations apply lolipants_auth --remote \
  --config server/better-auth-worker/wrangler.toml
```

Verify with:

```sh
npx wrangler d1 execute lolipants-db --remote \
  --config server/lolipants-api/wrangler.toml \
  --command "PRAGMA table_info(users);"

npx wrangler d1 execute lolipants_auth --remote \
  --config server/better-auth-worker/wrangler.toml \
  --command "PRAGMA table_info(user);"
```

Expected new columns: `admin_scopes`, `banned_at` on `users`; `role`,
`adminScopes` on better-auth `user`.

## 2. Set the shared HMAC secret

```sh
# Same value in BOTH workers; 32+ bytes of hex is fine.
openssl rand -hex 32 | tee /tmp/internal-sync-secret

npx wrangler secret put INTERNAL_SYNC_SECRET \
  --config server/lolipants-api/wrangler.toml < /tmp/internal-sync-secret

npx wrangler secret put INTERNAL_SYNC_SECRET \
  --config server/better-auth-worker/wrangler.toml < /tmp/internal-sync-secret

rm /tmp/internal-sync-secret
```

`INTERNAL_SYNC_SECRET` is the shared key between the admin users endpoint
and the `/internal/user/:id/role` mirror. If they get out of sync, admin
role changes in the app will succeed locally but the better-auth session
will keep the stale role until the user signs out + back in.

`ADMIN_HMAC_SECRET` is a separate, older secret used by the external
`/admin/commissions/:id` webhook and is unrelated here.

## 3. Deploy both workers

```sh
npx wrangler deploy --config server/better-auth-worker/wrangler.toml
npx wrangler deploy --config server/lolipants-api/wrangler.toml
```

Order matters: deploy the auth worker first so the new `/internal/user/:id/role`
route exists when the admin worker starts issuing sync calls.

## 4. Promote the first super admin

Follow `server/lolipants-api/docs/rbac.md`. In short:

```sh
# 1. Grab the user id.
npx wrangler d1 execute lolipants-db --remote \
  --config server/lolipants-api/wrangler.toml \
  --command "SELECT id, email FROM users WHERE email = 'owner@example.com'"

# 2. Promote.
npx wrangler d1 execute lolipants-db --remote \
  --config server/lolipants-api/wrangler.toml \
  --file=server/lolipants-api/scripts/seed-super-admin.sql \
  -v EMAIL=owner@example.com

# 3. Sync to better-auth.
node --loader tsx server/lolipants-api/scripts/sync-super-admin.ts \
  --user-id <id> --role admin --scopes '["*"]' \
  --base https://lolipants-better-auth.loli-pants.workers.dev \
  --secret "$(cat /path/to/secret)"
```

## 5. Sanity check

Hit `GET /admin/stats` with the freshly promoted account's bearer token.
It should return `{ usersByRole, ordersByStatus, commissionsByStatus,
openComplaints }`. Any 403 response means the better-auth mirror didn't
update — re-run step 4, then sign out + back in on the app.
