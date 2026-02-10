-- Migration: Add global_dictionary table for shared enrichment data
-- Feature: 008-global-dictionary
-- Date: 2026-02-10
--
-- This migration creates a global dictionary table to store enrichment data
-- that can be shared across users and referenced by vocabulary entries.
-- User-specific overrides are stored in vocabulary.overrides JSONB field.

-- =============================================================================
-- Global Dictionary Table
-- Stores enrichment data (definitions, translations, linguistic features)
-- =============================================================================

CREATE TABLE IF NOT EXISTS global_dictionary (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Word identification
    word VARCHAR(100) NOT NULL,
    content_hash VARCHAR(64) NOT NULL UNIQUE,
    stem VARCHAR(100),
    language_code VARCHAR(5) NOT NULL DEFAULT 'de',

    -- Linguistic metadata
    part_of_speech VARCHAR(20),
    pronunciation_ipa TEXT,

    -- Definitions and translations
    english_definition TEXT,
    translations JSONB DEFAULT '[]'::jsonb,

    -- Related words
    synonyms JSONB DEFAULT '[]'::jsonb,
    antonyms JSONB DEFAULT '[]'::jsonb,
    confusables JSONB DEFAULT '[]'::jsonb,

    -- Usage examples
    example_sentences JSONB DEFAULT '[]'::jsonb,

    -- Difficulty indicators
    cefr_level VARCHAR(2),
    frequency_band INTEGER,
    frequency_rank INTEGER,

    -- Data quality
    confidence DOUBLE PRECISION NOT NULL DEFAULT 1.0,

    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for global_dictionary
CREATE INDEX IF NOT EXISTS idx_global_dictionary_word
    ON global_dictionary(word);
CREATE INDEX IF NOT EXISTS idx_global_dictionary_content_hash
    ON global_dictionary(content_hash);
CREATE INDEX IF NOT EXISTS idx_global_dictionary_stem
    ON global_dictionary(stem) WHERE stem IS NOT NULL;

-- Trigger for updated_at
CREATE TRIGGER update_global_dictionary_updated_at
    BEFORE UPDATE ON global_dictionary
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- =============================================================================
-- Update Vocabulary Table
-- Add reference to global_dictionary and overrides field
-- =============================================================================

-- Add global_dictionary_id FK to vocabulary
ALTER TABLE vocabulary
    ADD COLUMN IF NOT EXISTS global_dictionary_id UUID
    REFERENCES global_dictionary(id) ON DELETE SET NULL;

-- Add overrides JSONB field for user-specific data
ALTER TABLE vocabulary
    ADD COLUMN IF NOT EXISTS overrides JSONB DEFAULT '{}'::jsonb;

-- Add index on global_dictionary_id
CREATE INDEX IF NOT EXISTS idx_vocabulary_global_dictionary
    ON vocabulary(global_dictionary_id)
    WHERE global_dictionary_id IS NOT NULL;

-- Add unique constraint to prevent duplicate vocabulary entries per user
-- (user can only have one vocabulary entry per global dictionary entry)
CREATE UNIQUE INDEX IF NOT EXISTS idx_vocabulary_user_global_dict
    ON vocabulary(user_id, global_dictionary_id)
    WHERE global_dictionary_id IS NOT NULL AND deleted_at IS NULL;

-- =============================================================================
-- Update Enrichment Feedback Table
-- Re-point from meaning_id to global_dictionary_id
-- =============================================================================

-- Add global_dictionary_id column
ALTER TABLE enrichment_feedback
    ADD COLUMN IF NOT EXISTS global_dictionary_id UUID
    REFERENCES global_dictionary(id) ON DELETE CASCADE;

-- Create index for new column
CREATE INDEX IF NOT EXISTS idx_enrichment_feedback_global_dict
    ON enrichment_feedback(global_dictionary_id)
    WHERE global_dictionary_id IS NOT NULL;

-- Note: We keep the meaning_id column for backward compatibility during migration.
-- The meaning_id constraint will be made nullable in a future migration after
-- data migration is complete. For now, both columns can coexist.

-- Make meaning_id nullable (may fail if NOT NULL constraint exists, that's OK)
ALTER TABLE enrichment_feedback
    ALTER COLUMN meaning_id DROP NOT NULL;

-- Update the FK constraint to allow NULL
ALTER TABLE enrichment_feedback
    DROP CONSTRAINT IF EXISTS enrichment_feedback_meaning_id_fkey;

ALTER TABLE enrichment_feedback
    ADD CONSTRAINT enrichment_feedback_meaning_id_fkey
    FOREIGN KEY (meaning_id) REFERENCES meanings(id) ON DELETE CASCADE;

-- Add check constraint: either meaning_id or global_dictionary_id must be set
ALTER TABLE enrichment_feedback
    ADD CONSTRAINT enrichment_feedback_reference_check
    CHECK (
        (meaning_id IS NOT NULL AND global_dictionary_id IS NULL) OR
        (meaning_id IS NULL AND global_dictionary_id IS NOT NULL)
    );

-- =============================================================================
-- Comments for Documentation
-- =============================================================================

COMMENT ON TABLE global_dictionary IS
'Global enrichment data dictionary. Stores linguistic data (definitions, translations,
examples) that can be shared across users. User-specific overrides are stored in
vocabulary.overrides JSONB field.';

COMMENT ON COLUMN global_dictionary.content_hash IS
'SHA-256 hash of normalized word form. Used to deduplicate entries and match vocabulary.';

COMMENT ON COLUMN vocabulary.global_dictionary_id IS
'Reference to global enrichment data. NULL means word is not yet enriched.';

COMMENT ON COLUMN vocabulary.overrides IS
'User-specific overrides for global dictionary fields. Structure mirrors global_dictionary
columns. Example: {"english_definition": "user custom definition", "translations": ["custom", "translations"]}';

COMMENT ON COLUMN enrichment_feedback.global_dictionary_id IS
'Reference to global dictionary entry for feedback on shared enrichment data.';
