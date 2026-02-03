-- Migration: Fix meanings unique constraint for upsert compatibility
-- The previous partial index doesn't work with Supabase upsert onConflict

-- Step 1: Delete ALL duplicate meanings again (more aggressive)
-- Keep only the one with highest confidence, then earliest created_at as tiebreaker
WITH ranked_meanings AS (
    SELECT id,
           ROW_NUMBER() OVER (
               PARTITION BY user_id, vocabulary_id
               ORDER BY confidence DESC, created_at ASC
           ) as rn
    FROM meanings
    WHERE deleted_at IS NULL
)
DELETE FROM meanings
WHERE id IN (
    SELECT id FROM ranked_meanings WHERE rn > 1
);

-- Step 2: Soft-delete any remaining duplicates (shouldn't be any, but safety)
UPDATE meanings m1
SET deleted_at = NOW()
WHERE deleted_at IS NULL
  AND EXISTS (
    SELECT 1 FROM meanings m2
    WHERE m2.user_id = m1.user_id
      AND m2.vocabulary_id = m1.vocabulary_id
      AND m2.deleted_at IS NULL
      AND m2.id < m1.id
  );

-- Step 3: Drop the partial index (doesn't work with upsert)
DROP INDEX IF EXISTS uk_meanings_user_vocab_active;

-- Step 4: Create a proper unique constraint that works with upsert
-- We'll use a unique index on (user_id, vocabulary_id) for non-deleted records
-- But since partial indexes don't work with onConflict, we need a different approach

-- Option: Create a unique constraint using COALESCE to treat NULL deleted_at specially
-- This won't work either for onConflict

-- Best solution: Add a column to track "is_current" and use that for uniqueness
-- But that's a bigger change

-- Simpler solution: Just ensure we check-then-insert in the edge function
-- For now, let's at least clean up the data and add a regular unique index
-- that will prevent duplicates at the application level

-- Create a function to enforce one active meaning per vocabulary
CREATE OR REPLACE FUNCTION enforce_single_active_meaning()
RETURNS TRIGGER AS $$
BEGIN
    -- If inserting/updating a non-deleted meaning, soft-delete others for same vocab
    IF NEW.deleted_at IS NULL THEN
        UPDATE meanings
        SET deleted_at = NOW(), updated_at = NOW()
        WHERE user_id = NEW.user_id
          AND vocabulary_id = NEW.vocabulary_id
          AND id != NEW.id
          AND deleted_at IS NULL;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS trg_enforce_single_meaning ON meanings;
CREATE TRIGGER trg_enforce_single_meaning
    AFTER INSERT OR UPDATE ON meanings
    FOR EACH ROW
    EXECUTE FUNCTION enforce_single_active_meaning();
