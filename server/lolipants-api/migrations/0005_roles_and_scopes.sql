-- Phase 8: role-based accounts.
-- Adds admin_scopes + banned_at to users, courier/delivery columns to orders,
-- and a complaints table used by the in-app admin moderation screen.

ALTER TABLE users ADD COLUMN admin_scopes TEXT NOT NULL DEFAULT '[]';
ALTER TABLE users ADD COLUMN banned_at TEXT;

ALTER TABLE orders ADD COLUMN courier_id TEXT REFERENCES users(id);
ALTER TABLE orders ADD COLUMN delivery_proof_url TEXT;
ALTER TABLE orders ADD COLUMN delivered_at TEXT;

CREATE TABLE IF NOT EXISTS complaints (
  id            TEXT PRIMARY KEY,
  user_id       TEXT NOT NULL REFERENCES users(id),
  target_type   TEXT NOT NULL,
  target_id     TEXT NOT NULL,
  subject       TEXT NOT NULL,
  body          TEXT NOT NULL,
  status        TEXT NOT NULL DEFAULT 'open',
  resolution    TEXT,
  resolved_by   TEXT REFERENCES users(id),
  created_at    TEXT NOT NULL DEFAULT (datetime('now')),
  resolved_at   TEXT
);

CREATE INDEX IF NOT EXISTS idx_complaints_status ON complaints(status);
CREATE INDEX IF NOT EXISTS idx_orders_courier ON orders(courier_id);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
