-- Rename `intensity` preference to `new_words_per_session`
-- and migrate stored values from legacy scale (0/1/2) to explicit values (3/5/8).

ALTER TABLE user_learning_preferences
RENAME COLUMN intensity TO new_words_per_session;

UPDATE user_learning_preferences
SET new_words_per_session = CASE new_words_per_session
  WHEN 0 THEN 3
  WHEN 1 THEN 5
  WHEN 2 THEN 8
  ELSE COALESCE(new_words_per_session, 5)
END;

ALTER TABLE user_learning_preferences
ALTER COLUMN new_words_per_session SET DEFAULT 5;

ALTER TABLE user_learning_preferences
DROP CONSTRAINT IF EXISTS user_learning_preferences_new_words_per_session_check;

ALTER TABLE user_learning_preferences
ADD CONSTRAINT user_learning_preferences_new_words_per_session_check
CHECK (new_words_per_session IN (3, 5, 8));
