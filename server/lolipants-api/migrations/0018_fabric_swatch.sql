-- Admin-uploaded square swatch photo per fabric (nullable until CMS upload).
ALTER TABLE fabric_options ADD COLUMN swatch_url TEXT;
