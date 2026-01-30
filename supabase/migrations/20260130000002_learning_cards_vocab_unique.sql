-- Migration: Add unique constraint for learning cards per vocabulary item
-- This prevents duplicate learning cards for the same vocabulary item per user

CREATE UNIQUE INDEX IF NOT EXISTS idx_learning_cards_user_vocab
  ON learning_cards(user_id, vocabulary_id)
  WHERE deleted_at IS NULL;
