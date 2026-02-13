-- Add audio_urls JSONB column to global_dictionary
-- Structure: {"us": "https://...mp3", "gb": "https://...mp3"}
ALTER TABLE global_dictionary ADD COLUMN IF NOT EXISTS audio_urls JSONB DEFAULT '{}'::jsonb;
