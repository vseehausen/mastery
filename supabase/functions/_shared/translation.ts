/**
 * Shared translation functions for DeepL and Google Translate APIs
 */

export interface TranslationEntry {
  primary: string;
  alternatives: string[];
  source: string;
  confusable_alternatives?: string[];
}

export async function getDeepLTranslation(
  word: string,
  targetLang: string,
  apiKey: string,
  context?: string,
): Promise<string | null> {
  const body: Record<string, unknown> = {
    text: [word],
    source_lang: 'EN',
    target_lang: targetLang.toUpperCase(),
  };
  if (context) body.context = context;

  const response = await fetch('https://api-free.deepl.com/v2/translate', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Authorization': `DeepL-Auth-Key ${apiKey}` },
    body: JSON.stringify(body),
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
  _context?: string,
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
  context?: string,
): Promise<{ translation: string; source: string }> {
  const deeplKey = Deno.env.get('DEEPL_API_KEY');
  if (deeplKey) {
    try {
      const t = await getDeepLTranslation(word, targetLang, deeplKey, context);
      if (t) return { translation: t, source: 'deepl' };
    } catch (err) {
      console.warn('[translation] DeepL failed:', err);
    }
  }

  const googleKey = Deno.env.get('GOOGLE_TRANSLATE_API_KEY');
  if (googleKey) {
    try {
      const t = await getGoogleTranslation(word, targetLang, googleKey, context);
      if (t) return { translation: t, source: 'google' };
    } catch (err) {
      console.warn('[translation] Google Translate failed:', err);
    }
  }

  return { translation: word, source: 'none' };
}

/**
 * Resolve the best primary translation given machine translation and AI enhancement.
 * Extracted for testability.
 */
export function resolveTranslation(
  machineTranslation: string,
  machineSource: string,
  aiEnhancement: { best_native_translation?: string | null; confidence?: number } | null,
): { primary: string; alternatives: string[]; source: string } {
  if (!aiEnhancement) {
    return { primary: machineTranslation, alternatives: [], source: machineSource };
  }

  const aiTranslation = aiEnhancement.best_native_translation;
  const aiConfidence = aiEnhancement.confidence ?? 0;
  const useAiTranslation = !!aiTranslation && aiConfidence >= 0.6;

  if (useAiTranslation) {
    // AI translation becomes primary; demote machine translation to alternatives (if different)
    const alternatives = aiTranslation!.toLowerCase() !== machineTranslation.toLowerCase()
      ? [machineTranslation]
      : [];
    return { primary: aiTranslation!, alternatives, source: 'openai' };
  }

  return { primary: machineTranslation, alternatives: [], source: machineSource };
}

/**
 * Build translations object by merging resolved translation with AI alternatives.
 * Consolidates the duplicated logic from enrichWord() and maintainEntry().
 */
export function buildTranslations(
  nativeLanguageCode: string,
  machineTranslation: string,
  machineSource: string,
  aiEnhancement: { best_native_translation?: string | null; confidence?: number; native_alternatives?: string[]; confusable_translations?: string[] } | null,
): Record<string, TranslationEntry> {
  const resolved = resolveTranslation(machineTranslation, machineSource, aiEnhancement);
  const aiAlternatives = aiEnhancement?.native_alternatives || [];
  const allAlternatives = [...new Set([...resolved.alternatives, ...aiAlternatives])]
    .filter(a => a.toLowerCase() !== resolved.primary.toLowerCase());

  const entry: TranslationEntry = {
    primary: resolved.primary,
    alternatives: allAlternatives,
    source: resolved.source,
  };

  const confusableAlts = aiEnhancement?.confusable_translations;
  if (confusableAlts && confusableAlts.length > 0) {
    entry.confusable_alternatives = confusableAlts;
  }

  return { [nativeLanguageCode]: entry };
}
