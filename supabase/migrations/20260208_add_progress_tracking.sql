-- Migration: Add word-level progress tracking
-- Feature: 006-word-progress
-- Date: 2026-02-08
-- Description: Add progress_stage column to learning_cards for user-driven competence tracking

-- Add progress_stage column with default value 'captured'
ALTER TABLE learning_cards
  ADD COLUMN IF NOT EXISTS progress_stage VARCHAR(20) NOT NULL DEFAULT 'captured';

-- Add comment explaining the column
COMMENT ON COLUMN learning_cards.progress_stage IS
  'Current progress stage: captured, practicing, stabilizing, active, mastered.
   Computed from user-driven learning events (reviews, recalls, non-translation retrievals).
   Updated client-side after each review that changes FSRS metrics.
   Valid values: captured | practicing | stabilizing | active | mastered';

-- Create index for fast vocabulary list filtering by stage
CREATE INDEX IF NOT EXISTS idx_learning_cards_user_stage
  ON learning_cards(user_id, progress_stage)
  WHERE deleted_at IS NULL;

-- Add check constraint to ensure valid stage values
ALTER TABLE learning_cards
  ADD CONSTRAINT check_progress_stage_valid
  CHECK (progress_stage IN ('captured', 'practicing', 'stabilizing', 'active', 'mastered'));
