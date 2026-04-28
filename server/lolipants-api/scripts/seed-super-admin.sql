-- One-off: promote the first super admin.
-- Usage:
--   wrangler d1 execute lolipants-api-db --remote \
--     --file=./scripts/seed-super-admin.sql \
--     -v EMAIL=owner@example.com
--
-- Notes:
--   * Assumes the target account has already signed up via better-auth so a
--     row exists in the `users` table (auto-created by the requireAuth
--     middleware on first authenticated request).
--   * `admin_scopes = '["*"]'` is the super-admin sentinel; it short-circuits
--     every requireAdmin(scope) check.
--   * After running this you MUST mirror the change into better-auth so the
--     user's session carries role=admin. The Flutter app reads role from the
--     session, not from /users/me. See scripts/sync-super-admin.ts for a
--     helper that hits POST /internal/user/:id/role.

UPDATE users
SET role = 'admin',
    admin_scopes = '["*"]'
WHERE email = :EMAIL;

-- Sanity check: returns the promoted row (if any).
SELECT id, email, role, admin_scopes
FROM users
WHERE email = :EMAIL;
