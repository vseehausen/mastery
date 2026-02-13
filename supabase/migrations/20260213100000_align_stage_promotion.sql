-- Migration: Align stage promotion with Doc 14
-- Date: 2026-02-13
--
-- Changes:
-- 1. Add index on review_logs for windowed lapse queries
-- 2. Add lapses_last_8, lapses_last_12, hard_method_success_count to get_session_cards
-- 3. Update get_vocabulary_stage_counts to drop reps checks from fallback CASE

-- Index for efficient windowed lapse lookups
CREATE INDEX IF NOT EXISTS idx_review_logs_card_reviewed
  ON review_logs(learning_card_id, reviewed_at DESC);

-- ============================================================
-- get_session_cards: add windowed lapse and hard method columns
-- ============================================================

DROP FUNCTION IF EXISTS get_session_cards(UUID, INT, INT, UUID[]);

CREATE OR REPLACE FUNCTION get_session_cards(
  p_user_id UUID,
  p_review_limit INT,
  p_new_limit INT,
  p_exclude_ids UUID[] DEFAULT '{}'
)
RETURNS TABLE (
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
  word TEXT,
  stem TEXT,
  part_of_speech TEXT,
  english_definition TEXT,
  synonyms JSONB,
  antonyms JSONB,
  confusables JSONB,
  example_sentences JSONB,
  pronunciation_ipa TEXT,
  translations JSONB,
  cefr_level TEXT,
  overrides JSONB,
  encounter_context TEXT,
  has_confusables BOOLEAN,
  non_translation_success_count BIGINT,
  lapses_last_8 INT,
  lapses_last_12 INT,
  hard_method_success_count BIGINT
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  (
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
    v.word::text,
    COALESCE(gd.word, v.stem, v.word)::text AS stem,
    gd.part_of_speech::text,
    gd.english_definition::text,
    gd.synonyms,
    gd.antonyms,
    gd.confusables,
    gd.example_sentences,
    gd.pronunciation_ipa::text,
    gd.translations,
    gd.cefr_level::text,
    v.overrides,
    (
      SELECT e.context::text
      FROM encounters e
      WHERE e.vocabulary_id = v.id
        AND e.user_id = p_user_id
        AND e.deleted_at IS NULL
        AND e.context IS NOT NULL
        AND e.context != ''
      ORDER BY e.occurred_at DESC NULLS LAST, e.created_at DESC
      LIMIT 1
    ) AS encounter_context,
    (
      (gd.confusables IS NOT NULL AND jsonb_array_length(gd.confusables) > 0)
      OR
      EXISTS (
        SELECT 1 FROM confusable_sets cs
        JOIN confusable_set_members csm ON cs.id = csm.confusable_set_id
        WHERE csm.vocabulary_id = v.id
          AND cs.user_id = p_user_id
          AND cs.deleted_at IS NULL
      )
    ) AS has_confusables,
    (
      SELECT COUNT(*)
      FROM review_logs rl
      WHERE rl.learning_card_id = lc.id
        AND rl.rating >= 3
        AND rl.cue_type IN ('definition', 'synonym', 'context_cloze', 'disambiguation')
    ) AS non_translation_success_count,
    (
      SELECT COUNT(*) FILTER (WHERE sub.rating = 1)
      FROM (
        SELECT rl2.rating
        FROM review_logs rl2
        WHERE rl2.learning_card_id = lc.id
        ORDER BY rl2.reviewed_at DESC
        LIMIT 8
      ) sub
    )::int AS lapses_last_8,
    (
      SELECT COUNT(*) FILTER (WHERE sub.rating = 1)
      FROM (
        SELECT rl2.rating
        FROM review_logs rl2
        WHERE rl2.learning_card_id = lc.id
        ORDER BY rl2.reviewed_at DESC
        LIMIT 12
      ) sub
    )::int AS lapses_last_12,
    (
      SELECT COUNT(*)
      FROM review_logs rl
      WHERE rl.learning_card_id = lc.id
        AND rl.rating >= 3
        AND rl.cue_type IN ('disambiguation')
    ) AS hard_method_success_count
  FROM learning_cards lc
  JOIN vocabulary v ON v.id = lc.vocabulary_id
  LEFT JOIN global_dictionary gd ON gd.id = v.global_dictionary_id
  WHERE lc.user_id = p_user_id
    AND lc.deleted_at IS NULL
    AND v.deleted_at IS NULL
    AND v.global_dictionary_id IS NOT NULL
    AND lc.state > 0
    AND lc.due <= now()
    AND lc.id != ALL(p_exclude_ids)
  ORDER BY
    CASE WHEN lc.last_review >= (current_date AT TIME ZONE 'UTC') THEN 1 ELSE 0 END,
    CASE WHEN lc.is_leech THEN 0 ELSE 1 END,
    lc.due ASC
  LIMIT p_review_limit
  )

  UNION ALL

  (
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
    v.word::text,
    COALESCE(gd.word, v.stem, v.word)::text AS stem,
    gd.part_of_speech::text,
    gd.english_definition::text,
    gd.synonyms,
    gd.antonyms,
    gd.confusables,
    gd.example_sentences,
    gd.pronunciation_ipa::text,
    gd.translations,
    gd.cefr_level::text,
    v.overrides,
    (
      SELECT e.context::text
      FROM encounters e
      WHERE e.vocabulary_id = v.id
        AND e.user_id = p_user_id
        AND e.deleted_at IS NULL
        AND e.context IS NOT NULL
        AND e.context != ''
      ORDER BY e.occurred_at DESC NULLS LAST, e.created_at DESC
      LIMIT 1
    ) AS encounter_context,
    (
      (gd.confusables IS NOT NULL AND jsonb_array_length(gd.confusables) > 0)
      OR
      EXISTS (
        SELECT 1 FROM confusable_sets cs
        JOIN confusable_set_members csm ON cs.id = csm.confusable_set_id
        WHERE csm.vocabulary_id = v.id
          AND cs.user_id = p_user_id
          AND cs.deleted_at IS NULL
      )
    ) AS has_confusables,
    (
      SELECT COUNT(*)
      FROM review_logs rl
      WHERE rl.learning_card_id = lc.id
        AND rl.rating >= 3
        AND rl.cue_type IN ('definition', 'synonym', 'context_cloze', 'disambiguation')
    ) AS non_translation_success_count,
    (
      SELECT COUNT(*) FILTER (WHERE sub.rating = 1)
      FROM (
        SELECT rl2.rating
        FROM review_logs rl2
        WHERE rl2.learning_card_id = lc.id
        ORDER BY rl2.reviewed_at DESC
        LIMIT 8
      ) sub
    )::int AS lapses_last_8,
    (
      SELECT COUNT(*) FILTER (WHERE sub.rating = 1)
      FROM (
        SELECT rl2.rating
        FROM review_logs rl2
        WHERE rl2.learning_card_id = lc.id
        ORDER BY rl2.reviewed_at DESC
        LIMIT 12
      ) sub
    )::int AS lapses_last_12,
    (
      SELECT COUNT(*)
      FROM review_logs rl
      WHERE rl.learning_card_id = lc.id
        AND rl.rating >= 3
        AND rl.cue_type IN ('disambiguation')
    ) AS hard_method_success_count
  FROM learning_cards lc
  JOIN vocabulary v ON v.id = lc.vocabulary_id
  LEFT JOIN global_dictionary gd ON gd.id = v.global_dictionary_id
  WHERE lc.user_id = p_user_id
    AND lc.deleted_at IS NULL
    AND v.deleted_at IS NULL
    AND v.global_dictionary_id IS NOT NULL
    AND lc.state = 0
    AND lc.id != ALL(p_exclude_ids)
  ORDER BY
    lc.created_at DESC
  LIMIT p_new_limit
  );
END;
$$;

GRANT EXECUTE ON FUNCTION get_session_cards(UUID, INT, INT, UUID[]) TO authenticated;

COMMENT ON FUNCTION get_session_cards IS
'Fetches learning cards for a session using UNION ALL with separate review/new word limits.
Reviews (state > 0): due cards ordered by deprioritize-today, then due ASC.
New words (state = 0): ordered by created_at DESC (most recent first).
p_exclude_ids prevents duplicates across batches.
Includes windowed lapse counts (last 8/12 reviews) and hard method success count.';

-- ============================================================
-- get_vocabulary_stage_counts: drop reps checks from fallback
-- ============================================================

CREATE OR REPLACE FUNCTION get_vocabulary_stage_counts(p_user_id uuid)
RETURNS TABLE(stage text, count bigint)
LANGUAGE sql STABLE
AS $$
  SELECT
    COALESCE(
      lc.progress_stage,
      CASE
        WHEN lc.stability >= 90 AND lc.lapses <= 1 AND lc.state = 2 THEN 'mastered'
        WHEN lc.stability >= 1.0 AND lc.lapses <= 2 AND lc.state = 2 THEN 'stabilizing'
        WHEN lc.reps >= 1 THEN 'practicing'
        ELSE 'captured'
      END
    ) AS stage,
    COUNT(*) AS count
  FROM learning_cards lc
  WHERE lc.user_id = p_user_id AND lc.deleted_at IS NULL
  GROUP BY stage

  UNION ALL

  SELECT
    'captured' AS stage,
    COUNT(*) AS count
  FROM vocabulary v
  WHERE v.user_id = p_user_id
    AND v.deleted_at IS NULL
    AND NOT EXISTS (
      SELECT 1 FROM learning_cards lc
      WHERE lc.vocabulary_id = v.id AND lc.deleted_at IS NULL
    )
$$;
