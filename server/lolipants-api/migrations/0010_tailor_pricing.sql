-- Tailor-owned price plans and proximity-based checkout snapshots.

CREATE TABLE IF NOT EXISTS tailor_profiles (
  user_id             TEXT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  shop_name           TEXT,
  address             TEXT,
  city                TEXT,
  lat                 REAL,
  lng                 REAL,
  service_radius_km   REAL NOT NULL DEFAULT 50,
  is_accepting_orders INTEGER NOT NULL DEFAULT 0,
  created_at          TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at          TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS tailor_price_plans (
  id          TEXT PRIMARY KEY,
  tailor_id   TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name        TEXT NOT NULL DEFAULT 'Default',
  currency    TEXT NOT NULL DEFAULT 'QAR',
  is_active   INTEGER NOT NULL DEFAULT 1,
  created_at  TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at  TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_tailor_price_plans_tailor_active
  ON tailor_price_plans(tailor_id, is_active);

CREATE TABLE IF NOT EXISTS tailor_garment_prices (
  id              TEXT PRIMARY KEY,
  plan_id         TEXT NOT NULL REFERENCES tailor_price_plans(id) ON DELETE CASCADE,
  garment_type    TEXT NOT NULL,
  fabric_quality  TEXT NOT NULL,
  base_price      REAL NOT NULL,
  fabric_fee      REAL NOT NULL,
  UNIQUE(plan_id, garment_type, fabric_quality)
);

CREATE INDEX IF NOT EXISTS idx_tailor_garment_prices_plan
  ON tailor_garment_prices(plan_id);

CREATE TABLE IF NOT EXISTS tailor_delivery_fees (
  id          TEXT PRIMARY KEY,
  plan_id     TEXT NOT NULL REFERENCES tailor_price_plans(id) ON DELETE CASCADE,
  city_key    TEXT NOT NULL,
  fee         REAL NOT NULL,
  UNIQUE(plan_id, city_key)
);

CREATE INDEX IF NOT EXISTS idx_tailor_delivery_fees_plan
  ON tailor_delivery_fees(plan_id);

ALTER TABLE orders ADD COLUMN price_plan_id TEXT REFERENCES tailor_price_plans(id);
ALTER TABLE orders ADD COLUMN assignment_method TEXT;
ALTER TABLE orders ADD COLUMN delivery_lat REAL;
ALTER TABLE orders ADD COLUMN delivery_lng REAL;
