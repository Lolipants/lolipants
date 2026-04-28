ALTER TABLE mannequin_jobs ADD COLUMN provider TEXT NOT NULL DEFAULT 'meshy';
ALTER TABLE mannequin_jobs ADD COLUMN provider_job_id TEXT;
ALTER TABLE mannequin_jobs ADD COLUMN provider_status TEXT NOT NULL DEFAULT 'queued';
ALTER TABLE mannequin_jobs ADD COLUMN artifact_urls TEXT NOT NULL DEFAULT '{}';
ALTER TABLE mannequin_jobs ADD COLUMN started_at TEXT;
ALTER TABLE mannequin_jobs ADD COLUMN completed_at TEXT;
ALTER TABLE mannequin_jobs ADD COLUMN failed_at TEXT;

CREATE INDEX IF NOT EXISTS idx_mannequin_jobs_user_status
  ON mannequin_jobs(user_id, status, created_at DESC);

ALTER TABLE designs ADD COLUMN render_metadata TEXT;

CREATE TABLE IF NOT EXISTS design_render_jobs (
  id              TEXT PRIMARY KEY,
  user_id         TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  design_id       TEXT NOT NULL REFERENCES designs(id) ON DELETE CASCADE,
  mannequin_id    TEXT REFERENCES mannequin_options(id),
  status          TEXT NOT NULL DEFAULT 'queued',
  provider        TEXT NOT NULL DEFAULT 'meshy',
  provider_job_id TEXT,
  provider_status TEXT NOT NULL DEFAULT 'queued',
  artifact_urls   TEXT NOT NULL DEFAULT '{}',
  error_message   TEXT,
  attempt_count   INTEGER NOT NULL DEFAULT 0,
  started_at      TEXT,
  completed_at    TEXT,
  failed_at       TEXT,
  created_at      TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at      TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_design_render_jobs_user_status
  ON design_render_jobs(user_id, status, created_at DESC);
