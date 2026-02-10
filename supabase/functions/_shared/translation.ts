/**
 * Shared translation functions for DeepL and Google Translate APIs
 */

export async function getDeepLTranslation(
  word: string,
  targetLang: string,
  apiKey: string,
): Promise<string | null> {
  const response = await fetch('https://api-free.deepl.com/v2/translate', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Authorization': `DeepL-Auth-Key ${apiKey}` },
    body: JSON.stringify({
      text: [word],
      source_lang: 'EN',
      target_lang: targetLang.toUpperCase(),
    }),
  });

  if (!response.ok) throw new Error(`DeepL API error: ${response.status}`);

  const data = await response.json();
  const translation = data.translations?.[0]?.text || null;

  // Validate translation quality - reject if:
  // 1. Too short (< 2 chars, e.g. just punctuation)
  // 2. Same as input word (no translation happened)
  // 3. Only punctuation/whitespace
  if (translation) {
    const cleaned = translation.trim();
    if (cleaned.length < 2 ||
        cleaned.toLowerCase() === word.toLowerCase() ||
        /^[\s\p{P}]+$/u.test(cleaned)) {
      console.warn(`[translation] Rejecting low-quality DeepL translation for "${word}": "${translation}"`);
      return null;
    }
  }

  return translation;
}

export async function getGoogleTranslation(
  word: string,
  targetLang: string,
  apiKey: string,
): Promise<string | null> {
  const response = await fetch(
    `https://translation.googleapis.com/language/translate/v2?key=${apiKey}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        q: word,
        source: 'en',
        target: targetLang,
        format: 'text',
      }),
    },
  );

  if (!response.ok) throw new Error(`Google Translate API error: ${response.status}`);

  const data = await response.json();
  const translation = data.data?.translations?.[0]?.translatedText || null;

  // Validate translation quality (same as DeepL)
  if (translation) {
    const cleaned = translation.trim();
    if (cleaned.length < 2 ||
        cleaned.toLowerCase() === word.toLowerCase() ||
        /^[\s\p{P}]+$/u.test(cleaned)) {
      console.warn(`[translation] Rejecting low-quality Google translation for "${word}": "${translation}"`);
      return null;
    }
  }

  return translation;
}

/** Full translation fallback chain: DeepL → Google → word itself. */
export async function translateWord(
  word: string,
  targetLang: string,
): Promise<{ translation: string; source: string }> {
  const deeplKey = Deno.env.get('DEEPL_API_KEY');
  if (deeplKey) {
    try {
      const t = await getDeepLTranslation(word, targetLang, deeplKey);
      if (t) return { translation: t, source: 'deepl' };
    } catch (err) {
      console.warn('[translation] DeepL failed:', err);
    }
  }

  const googleKey = Deno.env.get('GOOGLE_TRANSLATE_API_KEY');
  if (googleKey) {
    try {
      const t = await getGoogleTranslation(word, targetLang, googleKey);
      if (t) return { translation: t, source: 'google' };
    } catch (err) {
      console.warn('[translation] Google Translate failed:', err);
    }
  }

  return { translation: word, source: 'none' };
}
