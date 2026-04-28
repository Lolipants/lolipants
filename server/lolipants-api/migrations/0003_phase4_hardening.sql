CREATE TABLE IF NOT EXISTS payment_transactions (
  id             TEXT PRIMARY KEY,
  order_id        TEXT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  provider        TEXT NOT NULL,
  amount          REAL NOT NULL,
  currency        TEXT NOT NULL DEFAULT 'QAR',
  status          TEXT NOT NULL,
  provider_ref    TEXT,
  created_at      TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at      TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS order_idempotency_keys (
  id               TEXT PRIMARY KEY,
  user_id          TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  idempotency_key  TEXT NOT NULL,
  order_id         TEXT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  created_at       TEXT NOT NULL DEFAULT (datetime('now')),
  UNIQUE(user_id, idempotency_key)
);

CREATE INDEX IF NOT EXISTS idx_orders_user_status
  ON orders(user_id, status, placed_at DESC);

CREATE INDEX IF NOT EXISTS idx_orders_design
  ON orders(design_id);

CREATE INDEX IF NOT EXISTS idx_order_history_order
  ON order_status_history(order_id, timestamp DESC);

CREATE INDEX IF NOT EXISTS idx_measurements_user_saved
  ON measurements(user_id, saved_at DESC);
