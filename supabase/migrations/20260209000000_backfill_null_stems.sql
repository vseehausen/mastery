-- Backfill null stems with the raw word.
-- displayWord returns stem ?? word, so stem = word is identical to before.
-- AI-generated lemmas will overwrite on next enrichment.
UPDATE vocabulary SET stem = word, updated_at = now()
WHERE stem IS NULL AND deleted_at IS NULL;
