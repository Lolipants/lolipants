-- Accessories catalogue, order line items, and order accessory fee.

CREATE TABLE IF NOT EXISTS accessories (
  id              TEXT PRIMARY KEY,
  label_en        TEXT NOT NULL,
  label_ar        TEXT NOT NULL,
  category        TEXT NOT NULL CHECK (category IN ('scarf', 'bag', 'jewellery', 'other')),
  image_url       TEXT NOT NULL,
  sale_price      REAL NOT NULL DEFAULT 0,
  description_en  TEXT,
  description_ar  TEXT,
  allow_addon     INTEGER NOT NULL DEFAULT 1,
  is_active       INTEGER NOT NULL DEFAULT 1,
  sort_order      INTEGER NOT NULL DEFAULT 0,
  created_at      TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at      TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_accessories_active
  ON accessories(is_active, sort_order, label_en);

CREATE TABLE IF NOT EXISTS order_accessories (
  id            TEXT PRIMARY KEY,
  order_id      TEXT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  accessory_id  TEXT NOT NULL REFERENCES accessories(id),
  quantity      INTEGER NOT NULL DEFAULT 1,
  unit_price    REAL NOT NULL,
  label_en      TEXT NOT NULL,
  label_ar      TEXT NOT NULL,
  created_at    TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_order_accessories_order
  ON order_accessories(order_id);

ALTER TABLE orders ADD COLUMN accessory_fee REAL NOT NULL DEFAULT 0;

INSERT OR IGNORE INTO accessories (
  id, label_en, label_ar, category, image_url, sale_price,
  description_en, description_ar, allow_addon, is_active, sort_order
) VALUES
  (
    'accessory_seed_scarf_01',
    'Silk Evening Scarf',
    'وشاح حرير مسائي',
    'scarf',
    'https://placehold.co/400x400/E8E4EA/6B6560?text=Scarf',
    85,
    'Lightweight silk scarf for evening wear.',
    'وشاح حرير خفيف للمناسبات المسائية.',
    1, 1, 1
  ),
  (
    'accessory_seed_bag_01',
    'Embroidered Clutch',
    'حقيبة يد مطرزة',
    'bag',
    'https://placehold.co/400x400/E8E4EA/6B6560?text=Bag',
    120,
    'Hand-finished clutch with gold thread detail.',
    'حقيبة يد بتطريز يدوي بتفاصيل ذهبية.',
    1, 1, 2
  ),
  (
    'accessory_seed_jewellery_01',
    'Pearl Drop Earrings',
    'أقراط لؤلؤ متدلية',
    'jewellery',
    'https://placehold.co/400x400/E8E4EA/6B6560?text=Jewellery',
    65,
    'Classic pearl drops for formal occasions.',
    'أقراط لؤلؤ كلاسيكية للمناسبات الرسمية.',
    1, 1, 3
  );
