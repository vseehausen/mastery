-- Migration: Update get_session_cards to return lemma from global_dictionary as stem
-- Feature: 008-global-dictionary
-- Date: 2026-02-11
--
-- The RPC currently returns v.stem for the stem column, but vocabulary.stem
-- is just a copy of the normalized word. The real display word should be
-- the lemma (gd.word) from global_dictionary.
--
-- Change: v.stem → COALESCE(gd.word, v.stem, v.word) AS stem

-- Drop and recreate to ensure clean state
DROP FUNCTION IF EXISTS get_session_cards(UUID, INT);

CREATE OR REPLACE FUNCTION get_session_cards(
  p_user_id UUID,
  p_limit INT DEFAULT 50
)
RETURNS TABLE (
  -- Learning card fields
  card_id UUID,
  vocabulary_id UUID,
  state INT,
  due TIMESTAMPTZ,
  stability DOUBLE PRECISION,
  difficulty DOUBLE PRECISION,
  reps INT,
  lapses INT,
  last_review TIMESTAMPTZ,
  is_leech BOOLEAN,
  created_at TIMESTAMPTZ,

  -- Vocabulary fields
  word TEXT,
  stem TEXT,

  -- Global dictionary enrichment fields
  part_of_speech TEXT,
  english_definition TEXT,
  synonyms JSONB,
  antonyms JSONB,
  confusables JSONB,
  example_sentences JSONB,
  pronunciation_ipa TEXT,
  translations JSONB,
  cefr_level TEXT,

  -- User overrides
  overrides JSONB,

  -- Context from encounters
  encounter_context TEXT,

  -- Eligibility flags for cue selection
  has_confusables BOOLEAN,
  non_translation_success_count BIGINT
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT
    lc.id AS card_id,
    lc.vocabulary_id,
    lc.state,
    lc.due,
    lc.stability,
    lc.difficulty,
    lc.reps,
    lc.lapses,
    lc.last_review,
    lc.is_leech,
    lc.created_at,

    -- Vocabulary data
    v.word,
    COALESCE(gd.word, v.stem, v.word) AS stem,

    -- Global dictionary enrichment fields
    gd.part_of_speech,
    gd.english_definition,
    gd.synonyms,
    gd.antonyms,
    gd.confusables,
    gd.example_sentences,
    gd.pronunciation_ipa,
    gd.translations,
    gd.cefr_level,

    -- User-specific overrides
    v.overrides,

    -- Most recent encounter with non-empty context
    (
      SELECT e.context
      FROM encounters e
      WHERE e.vocabulary_id = v.id
        AND e.user_id = p_user_id
        AND e.deleted_at IS NULL
        AND e.context IS NOT NULL
        AND e.context != ''
      ORDER BY e.occurred_at DESC NULLS LAST, e.created_at DESC
      LIMIT 1
    ) AS encounter_context,

    -- Check if word has confusables (from global dict or legacy confusable_sets)
    (
      -- Check global dictionary confusables
      (gd.confusables IS NOT NULL AND jsonb_array_length(gd.confusables) > 0)
      OR
      -- Check legacy confusable_sets table for backward compatibility
      EXISTS (
        SELECT 1 FROM confusable_sets cs
        JOIN confusable_set_members csm ON cs.id = csm.confusable_set_id
        WHERE csm.vocabulary_id = v.id
          AND cs.user_id = p_user_id
          AND cs.deleted_at IS NULL
      )
    ) AS has_confusables,

    -- Count successful non-translation reviews
    (
      SELECT COUNT(*)
      FROM review_logs rl
      WHERE rl.learning_card_id = lc.id
        AND rl.rating >= 3
        AND rl.cue_type IN ('definition', 'synonym', 'context_cloze', 'disambiguation')
    ) AS non_translation_success_count

  FROM learning_cards lc
  JOIN vocabulary v ON v.id = lc.vocabulary_id
  LEFT JOIN global_dictionary gd ON gd.id = v.global_dictionary_id

  WHERE lc.user_id = p_user_id
    AND lc.deleted_at IS NULL
    AND v.deleted_at IS NULL
    -- Only cards with enriched vocabulary (have global_dictionary reference)
    AND v.global_dictionary_id IS NOT NULL

  ORDER BY
    -- New cards (state=0) get lower priority, due reviews first
    CASE WHEN lc.state = 0 THEN 1 ELSE 0 END,
    -- Leeches get priority boost within their group
    CASE WHEN lc.is_leech THEN 0 ELSE 1 END,
    -- Then by due date
    lc.due ASC

  LIMIT p_limit;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_session_cards(UUID, INT) TO authenticated;

COMMENT ON FUNCTION get_session_cards IS
'Fetches learning cards with all data needed for a session in a single query.
Returns cards with embedded vocabulary, global dictionary enrichment data,
user overrides, encounter context, eligibility flags for cue type selection,
and non-translation success count for stage calculation.
Uses global_dictionary.word (lemma) as the stem/display word.
Only returns enriched vocabulary (with global_dictionary_id).';
