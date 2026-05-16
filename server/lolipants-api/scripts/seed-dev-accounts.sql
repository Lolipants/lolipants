-- Promote dev accounts by email (run AFTER they exist in `users` from sign-up).
-- Usage:
--   wrangler d1 execute lolipants-db --remote --file=./scripts/seed-dev-accounts.sql
--
-- Prefer the TypeScript seeder (creates accounts + syncs better-auth):
--   DEV_SEED_PASSWORD='...' INTERNAL_SYNC_SECRET='...' pnpm exec tsx scripts/seed-dev-accounts.ts

UPDATE users
SET role = 'admin',
    admin_scopes = '["*"]',
    updated_at = datetime('now')
WHERE email = 'lolipants26@gmail.com';

UPDATE users
SET role = 'tailor',
    admin_scopes = '[]',
    updated_at = datetime('now')
WHERE email = 'lolipants26+tailor@gmail.com';

UPDATE users
SET role = 'delivery',
    admin_scopes = '[]',
    updated_at = datetime('now')
WHERE email = 'lolipants26+driver@gmail.com';

SELECT id, email, role, admin_scopes FROM users
WHERE email IN (
  'lolipants26@gmail.com',
  'lolipants26+tailor@gmail.com',
  'lolipants26+driver@gmail.com'
);
