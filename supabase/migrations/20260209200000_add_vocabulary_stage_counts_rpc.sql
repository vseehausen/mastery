CREATE OR REPLACE FUNCTION get_vocabulary_stage_counts(p_user_id uuid)
RETURNS TABLE(stage text, count bigint)
LANGUAGE sql STABLE
AS $$
  -- Count learning cards by stage (computed or persisted)
  SELECT
    COALESCE(
      lc.progress_stage,
      CASE
        WHEN lc.stability >= 90 AND lc.reps >= 12 AND lc.lapses <= 1 AND lc.state = 2 THEN 'mastered'
        WHEN lc.stability >= 1.0 AND lc.reps >= 3 AND lc.lapses <= 2 AND lc.state = 2 THEN 'stabilizing'
        WHEN lc.reps >= 1 THEN 'practicing'
        ELSE 'captured'
      END
    ) AS stage,
    COUNT(*) AS count
  FROM learning_cards lc
  WHERE lc.user_id = p_user_id AND lc.deleted_at IS NULL
  GROUP BY stage

  UNION ALL

  -- Captured = vocab without any learning card
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
