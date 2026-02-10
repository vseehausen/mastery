-- Migration: Replace stemming with variant-mapping architecture
-- No users yet — fresh schema rewrite.

-- Fix language_code default (words are English, not German)
ALTER TABLE global_dictionary ALTER COLUMN language_code SET DEFAULT 'en';
UPDATE global_dictionary SET language_code = 'en' WHERE language_code = 'de';

-- Add lemma column
ALTER TABLE global_dictionary ADD COLUMN lemma VARCHAR(100);
UPDATE global_dictionary SET lemma = lower(trim(COALESCE(stem, word)));
ALTER TABLE global_dictionary ALTER COLUMN lemma SET NOT NULL;
ALTER TABLE global_dictionary ADD CONSTRAINT uq_global_dictionary_lang_lemma
  UNIQUE (language_code, lemma);

-- Create word_variants table
CREATE TABLE word_variants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  language_code VARCHAR(5) NOT NULL DEFAULT 'en',
  variant VARCHAR(100) NOT NULL,
  global_dictionary_id UUID NOT NULL REFERENCES global_dictionary(id) ON DELETE CASCADE,
  method VARCHAR(20) NOT NULL DEFAULT 'enrichment',
  confidence DOUBLE PRECISION NOT NULL DEFAULT 1.0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE UNIQUE INDEX idx_word_variants_lookup ON word_variants(language_code, variant);
CREATE INDEX idx_word_variants_dict ON word_variants(global_dictionary_id);

ALTER TABLE word_variants ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated read word_variants" ON word_variants
  FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Service role manages word_variants" ON word_variants
  FOR ALL USING (auth.role() = 'service_role');

-- Seed word_variants from existing global_dictionary
INSERT INTO word_variants (language_code, variant, global_dictionary_id, method)
SELECT language_code, lower(trim(lemma)), id, 'backfill'
FROM global_dictionary
ON CONFLICT DO NOTHING;

INSERT INTO word_variants (language_code, variant, global_dictionary_id, method)
SELECT language_code, lower(trim(word)), id, 'backfill'
FROM global_dictionary WHERE lower(trim(word)) != lower(trim(lemma))
ON CONFLICT DO NOTHING;

-- Drop old indexes that conflict with variant-mapping flow
DROP INDEX IF EXISTS idx_vocabulary_user_global_dict;
DROP INDEX IF EXISTS idx_global_dictionary_content_hash;
ALTER TABLE global_dictionary DROP COLUMN IF EXISTS canonical_key;
ALTER TABLE global_dictionary DROP COLUMN IF EXISTS content_hash;
ALTER TABLE vocabulary DROP CONSTRAINT IF EXISTS uq_vocabulary_user_canonical_key;
ALTER TABLE vocabulary DROP CONSTRAINT IF EXISTS vocabulary_user_id_content_hash_key;
ALTER TABLE vocabulary DROP COLUMN IF EXISTS canonical_key;
ALTER TABLE vocabulary DROP COLUMN IF EXISTS content_hash;

-- New vocabulary dedup: unique on (user_id, word) for active (non-deleted) entries
CREATE UNIQUE INDEX idx_vocabulary_user_word
  ON vocabulary(user_id, word) WHERE deleted_at IS NULL;

-- Drop enrichment_queue
DROP TABLE IF EXISTS enrichment_queue;

-- Drop legacy meaning-graph tables
ALTER TABLE enrichment_feedback DROP CONSTRAINT IF EXISTS enrichment_feedback_reference_check;
ALTER TABLE enrichment_feedback DROP CONSTRAINT IF EXISTS enrichment_feedback_meaning_id_fkey;
ALTER TABLE enrichment_feedback DROP COLUMN IF EXISTS meaning_id;
ALTER TABLE enrichment_feedback ALTER COLUMN global_dictionary_id SET NOT NULL;
DROP TABLE IF EXISTS meaning_edits;
DROP TABLE IF EXISTS cues;
DROP TABLE IF EXISTS meanings;
