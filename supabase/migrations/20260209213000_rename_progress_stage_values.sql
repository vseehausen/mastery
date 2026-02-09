-- Migration: Rename progress stage values to user-facing terminology
-- Date: 2026-02-09
-- Changes:
-- - active   -> known
-- - captured -> new

-- Drop old validation first so transitional values don't violate checks.
ALTER TABLE learning_cards
  DROP CONSTRAINT IF EXISTS check_progress_stage_valid;

-- Backfill existing values.
UPDATE learning_cards
SET progress_stage = 'known'
WHERE progress_stage = 'active';

UPDATE learning_cards
SET progress_stage = 'new'
WHERE progress_stage = 'captured';

-- Update default and validation constraint to canonical values.
ALTER TABLE learning_cards
  ALTER COLUMN progress_stage SET DEFAULT 'new';

ALTER TABLE learning_cards
  ADD CONSTRAINT check_progress_stage_valid
  CHECK (progress_stage IN ('new', 'practicing', 'stabilizing', 'known', 'mastered'));

COMMENT ON COLUMN learning_cards.progress_stage IS
  'Current progress stage: new, practicing, stabilizing, known, mastered.
   Computed from user-driven learning events (reviews, recalls, non-translation retrievals).
   Updated client-side after each review that changes FSRS metrics.
   Valid values: new | practicing | stabilizing | known | mastered';

-- Keep RPC stage counts aligned to canonical values and tolerant of legacy rows.
CREATE OR REPLACE FUNCTION get_vocabulary_stage_counts(p_user_id uuid)
RETURNS TABLE(stage text, count bigint)
LANGUAGE sql STABLE
AS $$
  -- Count learning cards by stage (computed or persisted)
  SELECT
    COALESCE(
      CASE lc.progress_stage
        WHEN 'active' THEN 'known'
        WHEN 'captured' THEN 'new'
        ELSE lc.progress_stage
      END,
      CASE
        WHEN lc.stability >= 90 AND lc.reps >= 12 AND lc.lapses <= 1 AND lc.state = 2 THEN 'mastered'
        WHEN lc.stability >= 1.0 AND lc.reps >= 3 AND lc.lapses <= 2 AND lc.state = 2 THEN 'stabilizing'
        WHEN lc.reps >= 1 THEN 'practicing'
        ELSE 'new'
      END
    ) AS stage,
    COUNT(*) AS count
  FROM learning_cards lc
  WHERE lc.user_id = p_user_id AND lc.deleted_at IS NULL
  GROUP BY stage

  UNION ALL

  -- New = vocab without any learning card
  SELECT
    'new' AS stage,
    COUNT(*) AS count
  FROM vocabulary v
  WHERE v.user_id = p_user_id
    AND v.deleted_at IS NULL
    AND NOT EXISTS (
      SELECT 1 FROM learning_cards lc
      WHERE lc.vocabulary_id = v.id AND lc.deleted_at IS NULL
    )
$$;
