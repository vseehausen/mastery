-- Drop unused frequency columns from global_dictionary
-- These were never read by any part of the app.

ALTER TABLE global_dictionary DROP COLUMN IF EXISTS frequency_band;
ALTER TABLE global_dictionary DROP COLUMN IF EXISTS frequency_rank;
