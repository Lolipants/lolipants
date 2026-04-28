ALTER TABLE mannequin_options ADD COLUMN preview_url TEXT;

CREATE TABLE IF NOT EXISTS mannequin_jobs (
  id            TEXT PRIMARY KEY,
  user_id       TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  source_url    TEXT NOT NULL,
  preview_url   TEXT,
  status        TEXT NOT NULL DEFAULT 'processing',
  error_message TEXT,
  retry_count   INTEGER NOT NULL DEFAULT 0,
  created_at    TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at    TEXT NOT NULL DEFAULT (datetime('now'))
);
