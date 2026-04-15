-- Lolipants app schema (D1)
-- NOTE: Mannequin options are admin-managed and should be edited from admin dashboard only.

CREATE TABLE IF NOT EXISTS users (
  id              TEXT PRIMARY KEY,
  name            TEXT NOT NULL,
  email           TEXT NOT NULL UNIQUE,
  role            TEXT NOT NULL DEFAULT 'user',
  avatar_url      TEXT,
  bio             TEXT,
  follower_count  INTEGER DEFAULT 0,
  created_at      TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at      TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS mannequin_options (
  id              TEXT PRIMARY KEY,
  label_en        TEXT NOT NULL,
  label_ar        TEXT NOT NULL,
  is_active       INTEGER NOT NULL DEFAULT 1,
  sort_order      INTEGER NOT NULL DEFAULT 0,
  created_at      TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS measurements (
  id              TEXT PRIMARY KEY,
  user_id         TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  chest           REAL,
  waist           REAL,
  hips            REAL,
  shoulder_width  REAL,
  height          REAL,
  arm_length      REAL,
  preferred_size  TEXT,
  saved_at        TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS designs (
  id              TEXT PRIMARY KEY,
  user_id         TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name            TEXT NOT NULL,
  garment_type    TEXT NOT NULL,
  mannequin_id    TEXT REFERENCES mannequin_options(id),
  fabric_id       TEXT,
  fabric_quality  TEXT NOT NULL DEFAULT 'standard',
  primary_colour  TEXT NOT NULL,
  accent_colour   TEXT,
  pattern_id      TEXT,
  print_image_url TEXT,
  preset_style_id TEXT,
  text_layers     TEXT,
  is_public       INTEGER DEFAULT 0,
  order_count     INTEGER DEFAULT 0,
  created_at      TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at      TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS fabric_options (
  id              TEXT PRIMARY KEY,
  name            TEXT NOT NULL,
  name_ar         TEXT NOT NULL,
  quality         TEXT NOT NULL,
  garment_type    TEXT NOT NULL,
  is_available    INTEGER DEFAULT 1,
  created_at      TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS presets (
  id              TEXT PRIMARY KEY,
  type            TEXT NOT NULL,
  name            TEXT NOT NULL,
  name_ar         TEXT NOT NULL,
  garment_type    TEXT,
  image_url       TEXT,
  is_active       INTEGER DEFAULT 1,
  created_at      TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS orders (
  id               TEXT PRIMARY KEY,
  user_id          TEXT NOT NULL REFERENCES users(id),
  design_id        TEXT NOT NULL REFERENCES designs(id),
  designer_id      TEXT REFERENCES users(id),
  tailor_id        TEXT REFERENCES users(id),
  status           TEXT NOT NULL DEFAULT 'placed',
  delivery_address TEXT NOT NULL,
  delivery_city    TEXT NOT NULL,
  delivery_phone   TEXT NOT NULL,
  delivery_notes   TEXT,
  base_price       REAL NOT NULL,
  fabric_fee       REAL NOT NULL DEFAULT 0,
  delivery_fee     REAL NOT NULL DEFAULT 0,
  total_price      REAL NOT NULL,
  payment_token    TEXT,
  estimated_delivery TEXT,
  placed_at        TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at       TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS order_status_history (
  id              TEXT PRIMARY KEY,
  order_id        TEXT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  status          TEXT NOT NULL,
  note            TEXT,
  updated_by      TEXT REFERENCES users(id),
  timestamp       TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS posts (
  id              TEXT PRIMARY KEY,
  author_id       TEXT NOT NULL REFERENCES users(id),
  body            TEXT NOT NULL,
  image_urls      TEXT,
  tags            TEXT,
  reaction_count  INTEGER DEFAULT 0,
  comment_count   INTEGER DEFAULT 0,
  posted_at       TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS post_reactions (
  id              TEXT PRIMARY KEY,
  post_id         TEXT NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  user_id         TEXT NOT NULL REFERENCES users(id),
  reaction_type   TEXT NOT NULL,
  created_at      TEXT NOT NULL DEFAULT (datetime('now')),
  UNIQUE(post_id, user_id)
);

CREATE TABLE IF NOT EXISTS post_comments (
  id              TEXT PRIMARY KEY,
  post_id         TEXT NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  author_id       TEXT NOT NULL REFERENCES users(id),
  body            TEXT NOT NULL,
  created_at      TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS follows (
  follower_id     TEXT NOT NULL REFERENCES users(id),
  following_id    TEXT NOT NULL REFERENCES users(id),
  created_at      TEXT NOT NULL DEFAULT (datetime('now')),
  PRIMARY KEY(follower_id, following_id)
);

CREATE TABLE IF NOT EXISTS consultations (
  id              TEXT PRIMARY KEY,
  user_id         TEXT NOT NULL REFERENCES users(id),
  designer_id     TEXT REFERENCES users(id),
  garment_type    TEXT NOT NULL,
  description     TEXT NOT NULL,
  budget_min      REAL,
  budget_max      REAL,
  status          TEXT NOT NULL DEFAULT 'open',
  created_at      TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS bookings (
  id              TEXT PRIMARY KEY,
  user_id         TEXT NOT NULL REFERENCES users(id),
  type            TEXT NOT NULL,
  address         TEXT,
  city            TEXT,
  date            TEXT NOT NULL,
  time_slot       TEXT NOT NULL,
  reference       TEXT NOT NULL UNIQUE,
  status          TEXT NOT NULL DEFAULT 'pending',
  created_at      TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS push_tokens (
  user_id         TEXT NOT NULL REFERENCES users(id),
  onesignal_id    TEXT NOT NULL,
  updated_at      TEXT NOT NULL DEFAULT (datetime('now')),
  PRIMARY KEY(user_id)
);
