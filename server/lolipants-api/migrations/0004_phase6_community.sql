-- Phase 6 - Community, Marketplace & Designer Payouts

-- Designer profile metadata. `bio` and `follower_count` were added in 0001;
-- we add pro-designer flag and speciality tag here. D1 does not support
-- `ADD COLUMN IF NOT EXISTS`, so the migration is destructive-safe only on
-- clean remote apply; existing rows keep their defaults.
ALTER TABLE users ADD COLUMN is_pro_designer INTEGER NOT NULL DEFAULT 0;
ALTER TABLE users ADD COLUMN speciality TEXT;

-- Commission ledger. One row per order where the buyer ordered a design
-- authored by another user (designerId != buyer). Status moves
-- pending -> approved (on delivery) -> paid (admin marks with payout_reference).
CREATE TABLE IF NOT EXISTS commissions (
  id                TEXT PRIMARY KEY,
  order_id          TEXT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  designer_id       TEXT NOT NULL REFERENCES users(id),
  buyer_id          TEXT NOT NULL REFERENCES users(id),
  amount            REAL NOT NULL,
  percentage        REAL NOT NULL DEFAULT 10,
  currency          TEXT NOT NULL DEFAULT 'QAR',
  status            TEXT NOT NULL DEFAULT 'pending',
  payout_reference  TEXT,
  notes             TEXT,
  created_at        TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at        TEXT NOT NULL DEFAULT (datetime('now')),
  UNIQUE(order_id)
);

CREATE INDEX IF NOT EXISTS idx_commissions_designer_status
  ON commissions(designer_id, status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_commissions_order
  ON commissions(order_id);

-- Community query perf.
CREATE INDEX IF NOT EXISTS idx_posts_posted_at
  ON posts(posted_at DESC);
CREATE INDEX IF NOT EXISTS idx_post_reactions_post
  ON post_reactions(post_id);
CREATE INDEX IF NOT EXISTS idx_post_reactions_user
  ON post_reactions(user_id, post_id);
CREATE INDEX IF NOT EXISTS idx_post_comments_post_created
  ON post_comments(post_id, created_at ASC);
CREATE INDEX IF NOT EXISTS idx_follows_following
  ON follows(following_id);
CREATE INDEX IF NOT EXISTS idx_consultations_user
  ON consultations(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_consultations_designer
  ON consultations(designer_id, status);

-- Showcase/trending helpers.
CREATE INDEX IF NOT EXISTS idx_designs_public_created
  ON designs(is_public, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_designs_public_order_count
  ON designs(is_public, order_count DESC);
