-- Migration: Fix duplicate meanings and enforce one meaning per vocabulary
-- This migration:
-- 1. Deletes duplicate meanings, keeping the one with highest confidence
-- 2. Adds unique constraint to prevent future duplicates

-- =============================================================================
-- Step 1: Delete duplicate meanings, keeping the one with highest confidence
-- =============================================================================

-- For each (user_id, vocabulary_id) pair with multiple meanings,
-- keep only the meaning with highest confidence (or lowest id as tiebreaker)
DELETE FROM meanings
WHERE id NOT IN (
    SELECT DISTINCT ON (user_id, vocabulary_id) id
    FROM meanings
    WHERE deleted_at IS NULL
    ORDER BY user_id, vocabulary_id, confidence DESC, created_at ASC
);

-- =============================================================================
-- Step 2: Add unique constraint to enforce one meaning per vocabulary per user
-- =============================================================================

-- Drop existing index if it exists (to avoid conflicts)
DROP INDEX IF EXISTS idx_meanings_user_vocab;

-- Create unique index that enforces one active meaning per (user, vocabulary)
-- Uses partial index to only apply to non-deleted records
CREATE UNIQUE INDEX IF NOT EXISTS uk_meanings_user_vocab_active
    ON meanings(user_id, vocabulary_id)
    WHERE deleted_at IS NULL;

-- =============================================================================
-- Step 3: Add stale processing timeout column to enrichment_queue (optional)
-- =============================================================================

-- No schema change needed - we'll handle stale processing in application code
-- by checking last_attempted_at timestamp
