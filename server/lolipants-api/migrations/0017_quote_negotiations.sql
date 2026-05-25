-- Structured price negotiation between customer and tailor at compare-checkout.

CREATE TABLE IF NOT EXISTS quote_negotiations (
  id                    TEXT PRIMARY KEY,
  user_id               TEXT NOT NULL,
  tailor_id             TEXT NOT NULL,
  design_id             TEXT NOT NULL,
  delivery_city         TEXT NOT NULL,
  delivery_lat          REAL NOT NULL,
  delivery_lng          REAL NOT NULL,
  delivery_address      TEXT NOT NULL,
  delivery_phone        TEXT NOT NULL,
  list_base_price       INTEGER NOT NULL,
  list_fabric_fee       INTEGER NOT NULL,
  list_delivery_fee     INTEGER NOT NULL,
  list_total            INTEGER NOT NULL,
  price_plan_id         TEXT NOT NULL,
  currency              TEXT NOT NULL DEFAULT 'QAR',
  offered_total         INTEGER NOT NULL,
  offered_by            TEXT NOT NULL CHECK (offered_by IN ('customer', 'tailor')),
  customer_note         TEXT,
  locked_base_price     INTEGER,
  locked_fabric_fee     INTEGER,
  locked_delivery_fee   INTEGER,
  locked_total          INTEGER,
  status                TEXT NOT NULL DEFAULT 'open'
    CHECK (status IN ('open', 'tailor_review', 'countered', 'accepted', 'declined', 'expired', 'cancelled')),
  tailor_counter_used   INTEGER NOT NULL DEFAULT 0,
  quote_lock_token      TEXT,
  quote_lock_expires_at TEXT,
  expires_at            TEXT NOT NULL,
  accepted_at           TEXT,
  created_at            TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at            TEXT NOT NULL DEFAULT (datetime('now')),
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (tailor_id) REFERENCES users(id),
  FOREIGN KEY (design_id) REFERENCES designs(id)
);

CREATE INDEX IF NOT EXISTS idx_quote_negotiations_user_status
  ON quote_negotiations(user_id, status, updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_quote_negotiations_tailor_status
  ON quote_negotiations(tailor_id, status, updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_quote_negotiations_lock_token
  ON quote_negotiations(quote_lock_token);

CREATE TABLE IF NOT EXISTS quote_negotiation_messages (
  id              TEXT PRIMARY KEY,
  negotiation_id  TEXT NOT NULL,
  sender_id       TEXT NOT NULL,
  sender_role     TEXT NOT NULL CHECK (sender_role IN ('customer', 'tailor', 'system')),
  body            TEXT NOT NULL,
  created_at      TEXT NOT NULL DEFAULT (datetime('now')),
  FOREIGN KEY (negotiation_id) REFERENCES quote_negotiations(id) ON DELETE CASCADE,
  FOREIGN KEY (sender_id) REFERENCES users(id)
);

CREATE INDEX IF NOT EXISTS idx_quote_neg_messages_negotiation
  ON quote_negotiation_messages(negotiation_id, created_at ASC);
