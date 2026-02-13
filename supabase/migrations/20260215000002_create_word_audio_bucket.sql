-- Create public storage bucket for word audio files
-- Storage path: {accent}/{lemma}.mp3 — e.g., us/abandon.mp3, gb/abandon.mp3
INSERT INTO storage.buckets (id, name, public)
VALUES ('word-audio', 'word-audio', true)
ON CONFLICT (id) DO NOTHING;
