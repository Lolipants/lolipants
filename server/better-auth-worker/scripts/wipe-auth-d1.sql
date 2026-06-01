-- Wipe all auth users/sessions for a production reset.
PRAGMA foreign_keys = OFF;

DROP TABLE IF EXISTS "session";
DROP TABLE IF EXISTS "account";
DROP TABLE IF EXISTS "verification";
DROP TABLE IF EXISTS "rateLimit";
DROP TABLE IF EXISTS "user";

PRAGMA foreign_keys = ON;
