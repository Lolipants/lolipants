-- Editor flat-lay design catalog (CMS-managed, merged with bundled assets in app).
CREATE TABLE IF NOT EXISTS design_catalog_items (
  id              TEXT PRIMARY KEY,
  section_title   TEXT NOT NULL,
  label_en        TEXT NOT NULL,
  label_ar        TEXT NOT NULL,
  image_url       TEXT NOT NULL,
  garment_type    TEXT,
  gender_lane     TEXT,
  sort_order      INTEGER NOT NULL DEFAULT 0,
  is_active       INTEGER NOT NULL DEFAULT 1,
  created_at      TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at      TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_design_catalog_items_section
  ON design_catalog_items(section_title, sort_order, label_en);
