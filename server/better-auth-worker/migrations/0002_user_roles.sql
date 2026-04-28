-- Phase 8: carry role + admin_scopes in the better-auth user record so
-- sessions include them. Actual permissions are still authoritative in
-- lolipants-api users.admin_scopes and are mirrored here via the
-- HMAC-gated /internal/user/:id/role endpoint.

ALTER TABLE "user" ADD COLUMN "role" TEXT NOT NULL DEFAULT 'user';
ALTER TABLE "user" ADD COLUMN "adminScopes" TEXT NOT NULL DEFAULT '[]';
