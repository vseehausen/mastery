// Audio generation utilities for TTS (Text-to-Speech)

import type { SupabaseClient } from './supabase.ts';

/**
 * Sanitizes a lemma for use in storage path.
 * Converts to lowercase and replaces all non-alphanumeric characters except hyphens with underscores.
 */
export function sanitizeLemmaForStorage(lemma: string): string {
  return lemma.toLowerCase().replace(/[^a-z0-9-]/g, '_');
}

/**
 * Generates audio for a single lemma using Google TTS API and uploads to Supabase storage.
 *
 * @param lemma - The word to generate audio for
 * @param accent - Either 'us' or 'gb' for American or British English
 * @param googleApiKey - Google Cloud API key for TTS
 * @param client - Supabase client for storage operations
 * @returns Public URL of the uploaded audio file, or null if generation/upload fails
 */
export async function generateAudio(
  lemma: string,
  accent: 'us' | 'gb',
  googleApiKey: string,
  client: SupabaseClient,
): Promise<string | null> {
  try {
    const voice = accent === 'us' ? 'en-US-Chirp3-HD-Gacrux' : 'en-GB-Chirp3-HD-Gacrux';
    const languageCode = accent === 'us' ? 'en-US' : 'en-GB';

    const response = await fetch(
      `https://texttospeech.googleapis.com/v1/text:synthesize?key=${googleApiKey}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          input: { text: lemma },
          voice: { languageCode, name: voice },
          audioConfig: { audioEncoding: 'MP3' },
        }),
      },
    );

    if (!response.ok) {
      console.error(`[tts] Failed for "${lemma}" (${accent}): ${response.status}`);
      return null;
    }

    const { audioContent } = await response.json();
    const raw = atob(audioContent);
    const audioBytes = new Uint8Array(raw.length);
    for (let i = 0; i < raw.length; i++) {
      audioBytes[i] = raw.charCodeAt(i);
    }

    const storagePath = `${accent}/${sanitizeLemmaForStorage(lemma)}.mp3`;

    const { error: uploadError } = await client.storage
      .from('word-audio')
      .upload(storagePath, audioBytes, {
        contentType: 'audio/mpeg',
        upsert: true,
      });

    if (uploadError) {
      console.error(`[tts] Upload failed for "${storagePath}":`, uploadError.message);
      return null;
    }

    const { data: { publicUrl } } = client.storage
      .from('word-audio')
      .getPublicUrl(storagePath);

    return publicUrl;
  } catch (err) {
    console.error(`[tts] Error for "${lemma}" (${accent}):`, err);
    return null;
  }
}

/**
 * Generates audio for both US and GB accents concurrently.
 *
 * @param lemma - The word to generate audio for
 * @param googleApiKey - Google Cloud API key for TTS
 * @param client - Supabase client for storage operations
 * @returns Record mapping accent codes to public URLs (only includes successful generations)
 */
export async function generateAllAudio(
  lemma: string,
  googleApiKey: string,
  client: SupabaseClient,
): Promise<Record<string, string>> {
  const [usUrl, gbUrl] = await Promise.all([
    generateAudio(lemma, 'us', googleApiKey, client),
    generateAudio(lemma, 'gb', googleApiKey, client),
  ]);

  const urls: Record<string, string> = {};
  if (usUrl) urls.us = usUrl;
  if (gbUrl) urls.gb = gbUrl;
  return urls;
}
