-- Adds the `platform` column to vLearnLicense.verify_log so the
-- License service can record what kind of device verified the
-- license (android, windows, ios, ...).
--
-- This is the *external* license DB (the one LICENSE_DB_URL points
-- at), separate from the main app DB. Run once against that DB:
--
--   psql "$LICENSE_DB_URL" -f datamanage/add_verify_log_platform.sql
--
-- Backend tolerates the column being missing -- it falls back to
-- the four-column insert at runtime -- so this migration is safe
-- to delay if you can't reach the license DB right now.

ALTER TABLE verify_log
  ADD COLUMN IF NOT EXISTS platform TEXT;
