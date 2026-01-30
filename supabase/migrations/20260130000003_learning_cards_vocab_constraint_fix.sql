-- Migration: Fix unique constraint for learning cards upsert
-- The partial index doesn't work with ON CONFLICT, need a proper constraint

-- Drop the partial index
DROP INDEX IF EXISTS idx_learning_cards_user_vocab;

-- Add a proper unique constraint (can be used with ON CONFLICT)
ALTER TABLE learning_cards
  ADD CONSTRAINT uq_learning_cards_user_vocab UNIQUE (user_id, vocabulary_id);
