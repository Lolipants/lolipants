-- Admin-curated fashion news articles for the News tab hero.
CREATE TABLE IF NOT EXISTS fashion_news (
  id              TEXT PRIMARY KEY,
  title_en        TEXT NOT NULL,
  title_ar        TEXT NOT NULL,
  summary_en      TEXT NOT NULL DEFAULT '',
  summary_ar      TEXT NOT NULL DEFAULT '',
  body_en         TEXT NOT NULL DEFAULT '',
  body_ar         TEXT NOT NULL DEFAULT '',
  cover_image_url TEXT,
  is_published    INTEGER NOT NULL DEFAULT 0,
  is_featured     INTEGER NOT NULL DEFAULT 0,
  published_at    TEXT,
  author_id       TEXT NOT NULL REFERENCES users(id),
  created_at      TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at      TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_fashion_news_published
  ON fashion_news(is_published, published_at DESC);

CREATE INDEX IF NOT EXISTS idx_fashion_news_featured
  ON fashion_news(is_featured);
