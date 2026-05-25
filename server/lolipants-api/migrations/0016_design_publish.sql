-- Explicit showcase publish metadata (commissions earned on order, not publish).
ALTER TABLE designs ADD COLUMN published_at TEXT;
ALTER TABLE designs ADD COLUMN commission_terms_version TEXT;
