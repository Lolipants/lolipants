# RBAC operator guide

Phase 8 introduces four roles (`user`, `tailor`, `delivery`, `admin`) and a
scope list on each admin. This doc captures the one-off steps to promote the
first super admin and the day-to-day workflow once the dashboard is running.

## Roles

| Role       | What it unlocks                                                |
| ---------- | -------------------------------------------------------------- |
| `user`     | Default role. Browse/designs/orders/community.                 |
| `tailor`   | Tailor shell (`/tailor/*`) — incoming / active / completed.    |
| `delivery` | Delivery shell (`/delivery/*`) — queue / active / history.     |
| `admin`    | Admin shell (`/admin/*`) — scope-filtered sub-pages.           |

Only admins use `admin_scopes`. A value of `["*"]` is the **super admin**
sentinel and bypasses every scope check. Otherwise each scope unlocks one
dashboard tab:

| Scope               | Dashboard area             |
| ------------------- | -------------------------- |
| `users_mgmt`        | Users + roles + bans       |
| `orders_oversight`  | All-orders oversight       |
| `payouts`           | Commission payout review   |
| `moderation`        | Content moderation         |
| `cms`               | Mannequins/fabrics/presets |
| `complaints`        | User complaints            |
| `tailor_mgmt`       | (reserved for sub-admins)  |
| `delivery_mgmt`     | (reserved for sub-admins)  |

## Data sources

* `lolipants-api` D1 (`users` table) is authoritative for `role` +
  `admin_scopes`.
* `better-auth-worker` mirrors both fields on its own `user` row so the
  session payload surfaced to the client carries them. Mirroring happens via
  the HMAC-gated `POST /internal/user/:id/role` endpoint.
* `requireAuth` rewrites `c.set("userRole", ...)` / `c.set("adminScopes", ...)`
  on every request from the `lolipants-api` `users` row, so stale sessions
  never out-rank a demotion.

## Promoting the first super admin

1. Have the owner sign up via the normal better-auth flow (email/password,
   Google, Apple, or magic link). This creates a row in both
   `better-auth-worker.user` and `lolipants-api.users`.
2. Grab their `id` (same across both workers — better-auth mirrors the id).
   A quick way is:
   ```sh
   pnpm wrangler d1 execute lolipants-api-db --remote \
     --command "SELECT id, email FROM users WHERE email = 'owner@example.com'"
   ```
3. Run the SQL seed to flip the role + scopes in `lolipants-api`:
   ```sh
   pnpm wrangler d1 execute lolipants-api-db --remote \
     --file=server/lolipants-api/scripts/seed-super-admin.sql \
     -v EMAIL=owner@example.com
   ```
4. Sync the new role into better-auth so the session reflects it:
   ```sh
   pnpm tsx server/lolipants-api/scripts/sync-super-admin.ts \
     --user-id <id-from-step-2> \
     --role admin \
     --scopes '["*"]' \
     --base https://<better-auth-worker>.workers.dev \
     --secret $INTERNAL_SYNC_SECRET
   ```
5. Have the owner sign out + back in (or wait for session refresh). The app
   now routes them to `/admin` on next boot.

## Day-to-day

Once a super admin exists, every further promotion/demotion/ban should flow
through **Admin → Users** in the app. That screen calls
`PATCH /admin/users/:id`, which runs `syncRoleWithAuthWorker` on the backend
so the better-auth mirror stays in step automatically.

## Secrets

Set these once per environment:

```sh
# lolipants-api
pnpm wrangler secret put INTERNAL_SYNC_SECRET

# better-auth-worker
pnpm wrangler secret put INTERNAL_SYNC_SECRET
```

Both secrets must match exactly — the HMAC uses them as shared key.
