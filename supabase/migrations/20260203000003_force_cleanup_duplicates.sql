-- Migration: Force cleanup ALL duplicate meanings
-- This is a more aggressive cleanup that soft-deletes all but one meaning per vocabulary

-- Step 1: Find all duplicate pairs and soft-delete the older ones
-- Keep the meaning with highest confidence, then most recent updated_at
UPDATE meanings m1
SET deleted_at = NOW(), updated_at = NOW()
WHERE deleted_at IS NULL
  AND id != (
    SELECT id
    FROM meanings m2
    WHERE m2.user_id = m1.user_id
      AND m2.vocabulary_id = m1.vocabulary_id
      AND m2.deleted_at IS NULL
    ORDER BY confidence DESC, updated_at DESC
    LIMIT 1
  );

-- Step 2: Log how many meanings remain per vocabulary (for verification)
-- SELECT user_id, vocabulary_id, COUNT(*) as cnt
-- FROM meanings
-- WHERE deleted_at IS NULL
-- GROUP BY user_id, vocabulary_id
-- HAVING COUNT(*) > 1;

-- The trigger from previous migration will prevent new duplicates
