-- Add audio preferences to user_learning_preferences
ALTER TABLE user_learning_preferences
  ADD COLUMN IF NOT EXISTS audio_enabled BOOLEAN NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS audio_accent VARCHAR(5) NOT NULL DEFAULT 'us';
