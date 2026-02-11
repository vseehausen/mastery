ALTER TABLE global_dictionary ADD COLUMN enrichment_version INT;
-- Stamp existing rows as v1 (they were just re-enriched)
UPDATE global_dictionary SET enrichment_version = 1;
