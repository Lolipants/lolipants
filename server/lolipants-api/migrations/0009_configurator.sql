-- Modular garment configurator (Design yourself tab)

CREATE TABLE IF NOT EXISTS configurator_templates (
  id                TEXT PRIMARY KEY,
  name_en           TEXT NOT NULL,
  name_ar           TEXT NOT NULL,
  garment_type      TEXT NOT NULL DEFAULT 'abaya',
  region_tag        TEXT NOT NULL DEFAULT 'modest',
  sort_order        INTEGER NOT NULL DEFAULT 0,
  is_active         INTEGER NOT NULL DEFAULT 1,
  required_slot_keys TEXT,
  created_at        TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at        TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS configurator_slots (
  id                TEXT PRIMARY KEY,
  template_id       TEXT NOT NULL REFERENCES configurator_templates(id) ON DELETE CASCADE,
  slot_key          TEXT NOT NULL,
  title_en          TEXT NOT NULL,
  title_ar          TEXT NOT NULL,
  sort_order        INTEGER NOT NULL DEFAULT 0,
  is_active         INTEGER NOT NULL DEFAULT 1,
  created_at        TEXT NOT NULL DEFAULT (datetime('now')),
  UNIQUE (template_id, slot_key)
);

CREATE TABLE IF NOT EXISTS configurator_options (
  id                TEXT PRIMARY KEY,
  slot_id           TEXT NOT NULL REFERENCES configurator_slots(id) ON DELETE CASCADE,
  option_key        TEXT NOT NULL,
  label_en          TEXT NOT NULL,
  label_ar          TEXT NOT NULL,
  asset_url         TEXT,
  metadata_json     TEXT,
  sort_order        INTEGER NOT NULL DEFAULT 0,
  is_active         INTEGER NOT NULL DEFAULT 1,
  created_at        TEXT NOT NULL DEFAULT (datetime('now')),
  UNIQUE (slot_id, option_key)
);

CREATE INDEX IF NOT EXISTS idx_configurator_slots_template
  ON configurator_slots (template_id, sort_order);

CREATE INDEX IF NOT EXISTS idx_configurator_options_slot
  ON configurator_options (slot_id, sort_order);

-- MVP seed: modest abaya + western dress starters (2 slots each, 2 options per slot)

INSERT OR IGNORE INTO configurator_templates (
  id, name_en, name_ar, garment_type, region_tag, sort_order, is_active, required_slot_keys
) VALUES
  (
    'modest_abaya_v1',
    'Modest abaya',
    'عباءة محتشمة',
    'abaya',
    'modest',
    0,
    1,
    '["sleeve_length","collar_style"]'
  ),
  (
    'western_dress_v1',
    'Western dress',
    'فستان غربي',
    'dress',
    'western',
    1,
    1,
    '["bodice","sleeve"]'
  );

INSERT OR IGNORE INTO configurator_slots (
  id, template_id, slot_key, title_en, title_ar, sort_order, is_active
) VALUES
  ('slot_modest_sleeve', 'modest_abaya_v1', 'sleeve_length', 'Sleeve length', 'طول الكم', 0, 1),
  ('slot_modest_collar', 'modest_abaya_v1', 'collar_style', 'Collar', 'الياقة', 1, 1),
  ('slot_west_bodice', 'western_dress_v1', 'bodice', 'Bodice', 'الصدر', 0, 1),
  ('slot_west_sleeve', 'western_dress_v1', 'sleeve', 'Sleeve', 'الكم', 1, 1);

INSERT OR IGNORE INTO configurator_options (
  id, slot_id, option_key, label_en, label_ar, asset_url, metadata_json, sort_order, is_active
) VALUES
  (
    'opt_modest_sleeve_wide',
    'slot_modest_sleeve',
    'wide',
    'Wide sleeves',
    'أكمام واسعة',
    NULL,
    '{"assetPath":"assets/images/designs/design_gulf_abaya_black_closed.png","layerZ":1}',
    0,
    1
  ),
  (
    'opt_modest_sleeve_fitted',
    'slot_modest_sleeve',
    'fitted',
    'Fitted sleeves',
    'أكمام ضيقة',
    NULL,
    '{"assetPath":"assets/images/designs/design_mod_abaya_slate_tech.png","layerZ":1}',
    1,
    1
  ),
  (
    'opt_modest_collar_high',
    'slot_modest_collar',
    'high_neck',
    'High neck band',
    'ياقة عالية',
    NULL,
    '{"assetPath":"assets/images/designs/design_gulf_abaya_navy_champagne.png","layerZ":2}',
    0,
    1
  ),
  (
    'opt_modest_collar_open',
    'slot_modest_collar',
    'open_front',
    'Open front cardigan',
    'أمام مفتوح',
    NULL,
    '{"assetPath":"assets/images/designs/design_gulf_abaya_cardigan_charcoal.png","layerZ":2}',
    1,
    1
  ),
  (
    'opt_west_bodice_classic',
    'slot_west_bodice',
    'classic_tiffany',
    'Classic Tiffany',
    'تيفاني كلاسيك',
    NULL,
    '{"assetPath":"assets/images/designs/design_mod_abaya_butterfly_white.png","layerZ":1}',
    0,
    1
  ),
  (
    'opt_west_bodice_sweetheart',
    'slot_west_bodice',
    'sweetheart',
    'Sweetheart',
    'ياقة قلب',
    NULL,
    '{"assetPath":"assets/images/designs/design_mod_abaya_plum_satin.png","layerZ":1}',
    1,
    1
  ),
  (
    'opt_west_sleeve_none',
    'slot_west_sleeve',
    'sleeveless',
    'Sleeveless',
    'بدون أكمام',
    NULL,
    '{"assetPath":"assets/images/designs/design_casual_tee_crew_white.png","layerZ":2}',
    0,
    1
  ),
  (
    'opt_west_sleeve_cap',
    'slot_west_sleeve',
    'cap',
    'Cap sleeve',
    'كم قصير',
    NULL,
    '{"assetPath":"assets/images/designs/design_casual_longsleeve_crew_white.png","layerZ":2}',
    1,
    1
  );
