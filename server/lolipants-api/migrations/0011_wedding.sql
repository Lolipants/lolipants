-- Wedding dress catalogue, tailor category pricing, and order fulfillment extensions.

CREATE TABLE IF NOT EXISTS wedding_dresses (
  id                  TEXT PRIMARY KEY,
  label_en            TEXT NOT NULL,
  label_ar            TEXT NOT NULL,
  category            TEXT NOT NULL CHECK (category IN ('wedding_dress', 'bridesmaid')),
  image_url           TEXT NOT NULL,
  rent_price_per_day  REAL NOT NULL DEFAULT 0,
  sale_price          REAL NOT NULL DEFAULT 0,
  insurance_deposit   REAL NOT NULL DEFAULT 0,
  is_active           INTEGER NOT NULL DEFAULT 1,
  sort_order          INTEGER NOT NULL DEFAULT 0,
  created_at          TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at          TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_wedding_dresses_active
  ON wedding_dresses(is_active, sort_order);

CREATE TABLE IF NOT EXISTS tailor_wedding_prices (
  id                  TEXT PRIMARY KEY,
  tailor_id           TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  category            TEXT NOT NULL CHECK (category IN ('wedding_dress', 'bridesmaid')),
  rent_price_per_day  REAL NOT NULL,
  sale_price          REAL NOT NULL,
  insurance_deposit   REAL NOT NULL,
  created_at          TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at          TEXT NOT NULL DEFAULT (datetime('now')),
  UNIQUE(tailor_id, category)
);

CREATE INDEX IF NOT EXISTS idx_tailor_wedding_prices_tailor
  ON tailor_wedding_prices(tailor_id);

ALTER TABLE orders ADD COLUMN fulfillment_type TEXT NOT NULL DEFAULT 'custom';
ALTER TABLE orders ADD COLUMN wedding_dress_id TEXT REFERENCES wedding_dresses(id);
ALTER TABLE orders ADD COLUMN rental_days INTEGER;
ALTER TABLE orders ADD COLUMN insurance_deposit REAL;
ALTER TABLE orders ADD COLUMN rent_subtotal REAL;

-- Seed platform default dresses (replace image_url via admin CMS upload).
INSERT OR IGNORE INTO wedding_dresses (
  id, label_en, label_ar, category, image_url,
  rent_price_per_day, sale_price, insurance_deposit, is_active, sort_order
) VALUES
  (
    'wedding_seed_bridal_01',
    'Classic Bridal Gown',
    'فستان عروس كلاسيكي',
    'wedding_dress',
    'https://placehold.co/600x900/1a1a1a/d4af37?text=Bridal',
    120, 4500, 800, 1, 1
  ),
  (
    'wedding_seed_bridesmaid_01',
    'Satin Bridesmaid Dress',
    'فستان وصيفة ساتان',
    'bridesmaid',
    'https://placehold.co/600x900/1a1a1a/d4af37?text=Bridesmaid',
    45, 650, 200, 1, 2
  );
