-- Drop unused meaning_display_mode column from user_learning_preferences
-- This preference was fully plumbed but never read at runtime (zero effect)

ALTER TABLE user_learning_preferences DROP COLUMN IF EXISTS meaning_display_mode;
