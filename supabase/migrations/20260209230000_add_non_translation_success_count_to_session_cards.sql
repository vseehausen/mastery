-- Migration: Add non_translation_success_count to get_session_cards RPC
-- Enables instant local stage calculation without async DB calls during grading

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
  -- Aggregated data
  meanings JSONB,
  cues JSONB,
  -- Eligibility flags for cue selection
  has_encounter_context BOOLEAN,
  has_confusables BOOLEAN,
  -- NEW: Count of successful non-translation reviews for stage calculation
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
    v.word,
    v.stem,
    -- Aggregate meanings
    (
      SELECT COALESCE(jsonb_agg(jsonb_build_object(
        'id', m.id,
        'primary_translation', m.primary_translation,
        'english_definition', m.english_definition,
        'extended_definition', m.extended_definition,
        'part_of_speech', m.part_of_speech,
        'synonyms', m.synonyms,
        'is_primary', m.is_primary,
        'sort_order', m.sort_order
      ) ORDER BY m.sort_order), '[]'::jsonb)
      FROM meanings m
      WHERE m.vocabulary_id = v.id
        AND m.user_id = p_user_id
        AND m.deleted_at IS NULL
    ) AS meanings,
    -- Aggregate cues
    (
      SELECT COALESCE(jsonb_agg(jsonb_build_object(
        'id', c.id,
        'meaning_id', c.meaning_id,
        'cue_type', c.cue_type,
        'prompt_text', c.prompt_text,
        'answer_text', c.answer_text,
        'hint_text', c.hint_text
      )), '[]'::jsonb)
      FROM cues c
      JOIN meanings m ON m.id = c.meaning_id
      WHERE m.vocabulary_id = v.id
        AND m.user_id = p_user_id
        AND c.deleted_at IS NULL
        AND m.deleted_at IS NULL
    ) AS cues,
    -- Check for encounters with context
    EXISTS (
      SELECT 1 FROM encounters e
      WHERE e.vocabulary_id = v.id
        AND e.user_id = p_user_id
        AND e.deleted_at IS NULL
        AND e.context IS NOT NULL
        AND e.context != ''
    ) AS has_encounter_context,
    -- Check for confusable sets
    EXISTS (
      SELECT 1 FROM confusable_sets cs
      JOIN confusable_set_members csm ON cs.id = csm.confusable_set_id
      WHERE csm.vocabulary_id = v.id
        AND cs.user_id = p_user_id
        AND cs.deleted_at IS NULL
    ) AS has_confusables,
    -- NEW: Count successful non-translation reviews
    -- Count of reviews with rating >= 3 (Good or Easy)
    -- and cue_type in ('definition', 'synonym', 'context_cloze', 'disambiguation')
    (
      SELECT COUNT(*)
      FROM review_logs rl
      WHERE rl.learning_card_id = lc.id
        AND rl.rating >= 3
        AND rl.cue_type IN ('definition', 'synonym', 'context_cloze', 'disambiguation')
    ) AS non_translation_success_count
  FROM learning_cards lc
  JOIN vocabulary v ON v.id = lc.vocabulary_id
  WHERE lc.user_id = p_user_id
    AND lc.deleted_at IS NULL
    AND v.deleted_at IS NULL
    -- Only cards with meanings (enriched vocabulary)
    AND EXISTS (
      SELECT 1 FROM meanings m
      WHERE m.vocabulary_id = v.id
        AND m.user_id = p_user_id
        AND m.deleted_at IS NULL
    )
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

-- Update comment for documentation
COMMENT ON FUNCTION get_session_cards IS
'Fetches learning cards with all data needed for a session in a single query.
Returns cards with embedded vocabulary, meanings, cues, eligibility flags
for cue type selection, and non-translation success count for stage calculation.
Replaces multiple queries in session planning.';
