-- Test that audio-related columns and objects exist
-- Run with: psql -f supabase/tests/audio_migrations_test.sql

-- Test 1: audio_urls column exists on global_dictionary
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'global_dictionary' AND column_name = 'audio_urls'
  ) THEN
    RAISE EXCEPTION 'audio_urls column not found on global_dictionary';
  END IF;
  RAISE NOTICE 'PASS: audio_urls column exists on global_dictionary';
END $$;

-- Test 2: audio_enabled column exists on user_learning_preferences
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'user_learning_preferences' AND column_name = 'audio_enabled'
  ) THEN
    RAISE EXCEPTION 'audio_enabled column not found on user_learning_preferences';
  END IF;
  RAISE NOTICE 'PASS: audio_enabled column exists on user_learning_preferences';
END $$;

-- Test 3: audio_accent column exists on user_learning_preferences
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'user_learning_preferences' AND column_name = 'audio_accent'
  ) THEN
    RAISE EXCEPTION 'audio_accent column not found on user_learning_preferences';
  END IF;
  RAISE NOTICE 'PASS: audio_accent column exists on user_learning_preferences';
END $$;

-- Test 4: word-audio bucket exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM storage.buckets WHERE id = 'word-audio'
  ) THEN
    RAISE EXCEPTION 'word-audio storage bucket not found';
  END IF;
  RAISE NOTICE 'PASS: word-audio storage bucket exists';
END $$;

-- Test 5: get_session_cards returns audio_urls column
DO $$
DECLARE
  col_exists BOOLEAN;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'get_session_cards' AND column_name = 'audio_urls'
  ) INTO col_exists;
  -- For functions, we check the function definition
  IF NOT EXISTS (
    SELECT 1 FROM pg_proc
    WHERE proname = 'get_session_cards'
    AND pg_get_function_result(oid) LIKE '%audio_urls%'
  ) THEN
    RAISE EXCEPTION 'get_session_cards does not return audio_urls';
  END IF;
  RAISE NOTICE 'PASS: get_session_cards returns audio_urls';
END $$;

SELECT 'All audio migration tests passed!' AS result;
