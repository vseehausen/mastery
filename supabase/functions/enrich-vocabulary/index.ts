// Edge function: enrich-vocabulary
// Enriches vocabulary words and writes to global_dictionary table
// Phase 1: Check if word has a word_variants mapping → global_dictionary
// Phase 2: If not, call OpenAI to generate full enrichment data with lemma
// Phase 3: Write to global_dictionary, create word_variants mappings
// Phase 4: Link vocabulary to global_dictionary_id, merge duplicates

import { handleCors } from '../_shared/cors.ts';
import { createServiceClient, getUserId, type SupabaseClient } from '../_shared/supabase.ts';
import { jsonResponse, errorResponse, unauthorizedResponse } from '../_shared/response.ts';
import { normalize } from '../_shared/normalize.ts';
import { resolveGlobalEntry, resolveByLemma, linkVocabulary, upsertVariant } from '../_shared/global-dictionary.ts';
import { mergeIfDuplicate } from '../_shared/vocabulary-lifecycle.ts';
import { translateWord, buildTranslations, type TranslationEntry } from '../_shared/translation.ts';
import { generateAllAudio } from '../_shared/audio.ts';

const MAX_BATCH_SIZE = 10;
const DEFAULT_BATCH_SIZE = 5;
const BUFFER_TARGET = 10;

// ENRICHMENT_VERSION: Increment this on EVERY change to enrichment logic, prompt, or output format.
// This enables the /maintain endpoint to detect and re-enrich stale entries.
// Version history:
// - v1: Initial enrichment implementation
// - v2: Added translation resolution logic
// - v3: Added quality rules (acronyms, circular definitions, disambiguation)
// - v4: Expanded card types - novel cloze, usage recognition, L1 confusables, tiered distractors
// - v5: Added TTS audio generation (US + GB accents)
const ENRICHMENT_VERSION = 5;

const MAINTAIN_DEFAULT_BATCH_SIZE = 20;
const MAINTAIN_CONCURRENCY = 10;
const SOURCE_LANGUAGE = 'en';

// =============================================================================
// Types
// =============================================================================

interface VocabWord {
  id: string;
  word: string;
  stem: string | null;
  user_id: string;
  global_dictionary_id: string | null;
}

interface EnrichedWord {
  vocabulary_id: string;
  word: string;
  global_dictionary_id: string;
}

interface FailedWord {
  vocabulary_id: string;
  error: string;
}

interface EnrichRequestBody {
  vocabulary_ids?: string[];
  native_language_code?: string;
  batch_size?: number;
  force_re_enrich?: boolean;
}

interface ProcessResult {
  enriched: EnrichedWord[];
  failed: FailedWord[];
  skipped: string[];
}

interface ClozeText {
  sentence: string;
  before: string;
  blank: string;
  after: string;
}

interface AIEnhancement {
  stem: string;
  english_definition: string;
  synonyms: string[];
  antonyms: string[];
  part_of_speech: string | null;
  confusables: Array<{
    word: string;
    explanation: string;
    disambiguation_sentence: ClozeText;
    disambiguation_sentences: ClozeText[];
    l1_translation: string;
  }>;
  example_sentences: ClozeText[];
  usage_examples: Array<{
    correct_sentence: ClozeText;
    incorrect_sentences: ClozeText[];
  }>;
  pronunciation_ipa: string;
  cefr_level: string | null;
  confidence: number;
  native_alternatives: string[];
  best_native_translation: string | null;
  confusable_translations: string[];
}

interface MaintainRequestBody {
  batch_size?: number;
  native_language_code?: string;
}

// =============================================================================
// Router
// =============================================================================

Deno.serve(async (req) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  const authHeader = req.headers.get("Authorization");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const isServiceRoleKey = authHeader === `Bearer ${serviceRoleKey}`;

  const url = new URL(req.url);
  const path = url.pathname.split('/').pop();

  try {
    // Admin-key protected maintenance endpoint
    if (req.method === 'POST' && path === 'maintain') {
      const adminKey = Deno.env.get('ADMIN_API_KEY');
      if (!adminKey || authHeader !== `Bearer ${adminKey}`) {
        return unauthorizedResponse();
      }
      return await handleMaintain(await req.json());
    }

    if (isServiceRoleKey) {
      if (req.method === 'POST' && path === 'request') {
        return await handleEnrichRequestServerSide(await req.json());
      }
      return errorResponse('Method not allowed', 405);
    }

    const userId = await getUserId(req);
    if (!userId) return unauthorizedResponse();

    if (req.method === 'POST' && path === 'request') {
      return await handleEnrichRequest(req, userId);
    } else if (req.method === 'GET' && path === 'status') {
      return await handleStatus(userId);
    }
    return errorResponse('Method not allowed', 405);
  } catch (error) {
    console.error('[enrich-vocabulary] Error:', error);
    return errorResponse('Internal server error', 500);
  }
});

// =============================================================================
// POST /enrich-vocabulary/request (server-side with service role key)
// =============================================================================

async function handleEnrichRequestServerSide(body: EnrichRequestBody): Promise<Response> {
  const vocabularyIds = body.vocabulary_ids;
  if (!vocabularyIds || vocabularyIds.length === 0) {
    return errorResponse('vocabulary_ids is required', 400);
  }

  const client = createServiceClient();

  const { data: vocab, error: vocabError } = await client
    .from('vocabulary')
    .select('user_id')
    .eq('id', vocabularyIds[0])
    .single();

  if (vocabError || !vocab) {
    return errorResponse('Vocabulary entry not found', 404);
  }

  const userId = vocab.user_id;
  const nativeLanguageCode = body.native_language_code || 'de';
  const batchSize = Math.min(body.batch_size || 1, vocabularyIds.length);

  const { data: wordsData, error: wordsError } = await client
    .from('vocabulary')
    .select('id, word, stem, user_id, global_dictionary_id')
    .eq('user_id', userId)
    .in('id', vocabularyIds.slice(0, batchSize))
    .is('deleted_at', null);

  if (wordsError) {
    console.error('[enrich-vocabulary] Failed to fetch vocabulary:', wordsError);
    return errorResponse('Failed to fetch vocabulary', 500);
  }

  const wordsToEnrich: VocabWord[] = wordsData || [];
  console.log(`[enrich-vocabulary] Server-side enriching ${wordsToEnrich.length} words for user=${userId}, language=${nativeLanguageCode}`);

  const wordContexts = await getEncounterContexts(client, userId, wordsToEnrich);
  const result = await processWords(client, wordsToEnrich, nativeLanguageCode, wordContexts, false);

  return jsonResponse(result);
}

// =============================================================================
// POST /enrich-vocabulary/request (user JWT)
// =============================================================================

async function handleEnrichRequest(req: Request, userId: string): Promise<Response> {
  const body: EnrichRequestBody = await req.json();
  const nativeLanguageCode = body.native_language_code;
  const batchSize = Math.min(body.batch_size || DEFAULT_BATCH_SIZE, MAX_BATCH_SIZE);
  const vocabularyIds = body.vocabulary_ids;
  const forceReEnrich = body.force_re_enrich ?? false;

  if (!nativeLanguageCode) {
    return errorResponse('native_language_code is required', 400);
  }

  const client = createServiceClient();

  let wordsToEnrich: VocabWord[];

  if (vocabularyIds && vocabularyIds.length > 0) {
    const { data, error } = await client
      .from('vocabulary')
      .select('id, word, stem, user_id, global_dictionary_id')
      .eq('user_id', userId)
      .in('id', vocabularyIds.slice(0, batchSize))
      .is('deleted_at', null);

    if (error) {
      console.error('[enrich-vocabulary] Failed to fetch vocabulary:', error);
      return errorResponse('Failed to fetch vocabulary', 500);
    }
    wordsToEnrich = data || [];
  } else {
    wordsToEnrich = await getUnEnrichedWords(client, userId, batchSize);
  }

  console.log(`[enrich-vocabulary] Enriching ${wordsToEnrich.length} words for user=${userId}, language=${nativeLanguageCode}`);

  const wordContexts = await getEncounterContexts(client, userId, wordsToEnrich);
  const result = await processWords(client, wordsToEnrich, nativeLanguageCode, wordContexts, forceReEnrich);

  const bufferStatus = await getBufferStatus(client, userId);

  return jsonResponse({
    ...result,
    buffer_status: bufferStatus,
  });
}

// =============================================================================
// GET /enrich-vocabulary/status
// =============================================================================

async function handleStatus(userId: string): Promise<Response> {
  const client = createServiceClient();
  const status = await getBufferStatus(client, userId);

  return jsonResponse({
    ...status,
    needs_replenishment: status.enriched_count < BUFFER_TARGET,
  });
}

// =============================================================================
// POST /enrich-vocabulary/maintain (admin-key protected)
// =============================================================================

async function handleMaintain(body: MaintainRequestBody): Promise<Response> {
  const batchSize = Math.min(body.batch_size || MAINTAIN_DEFAULT_BATCH_SIZE, 100);
  const nativeLanguageCode = body.native_language_code || 'de';
  const client = createServiceClient();

  // Fetch stale global_dictionary entries
  const { data: staleEntries, error: fetchError } = await client
    .from('global_dictionary')
    .select('id, word, stem, lemma, language_code')
    .or(`enrichment_version.is.null,enrichment_version.lt.${ENRICHMENT_VERSION}`)
    .order('updated_at', { ascending: true })
    .limit(batchSize);

  if (fetchError) {
    console.error('[maintain] Failed to fetch stale entries:', fetchError);
    return errorResponse('Failed to fetch stale entries', 500);
  }

  if (!staleEntries || staleEntries.length === 0) {
    return jsonResponse({ updated: 0, failed: 0, remaining: 0 });
  }

  // Count total remaining (including current batch)
  const { count: remainingCount } = await client
    .from('global_dictionary')
    .select('id', { count: 'exact', head: true })
    .or(`enrichment_version.is.null,enrichment_version.lt.${ENRICHMENT_VERSION}`);

  const totalRemaining = remainingCount || 0;

  console.log(`[maintain] Processing ${staleEntries.length} stale entries (${totalRemaining} total remaining)`);

  let updated = 0;
  let failed = 0;

  // Process in chunks of MAINTAIN_CONCURRENCY using Promise.allSettled
  for (let i = 0; i < staleEntries.length; i += MAINTAIN_CONCURRENCY) {
    const chunk = staleEntries.slice(i, i + MAINTAIN_CONCURRENCY);
    const results = await Promise.allSettled(
      chunk.map(entry => maintainEntry(client, entry, nativeLanguageCode))
    );

    for (const result of results) {
      if (result.status === 'fulfilled' && result.value) {
        updated++;
      } else {
        failed++;
        if (result.status === 'rejected') {
          console.error('[maintain] Entry failed:', result.reason);
        }
      }
    }
  }

  const remaining = totalRemaining - updated;
  console.log(`[maintain] Done: updated=${updated}, failed=${failed}, remaining=${remaining}`);

  return jsonResponse({ updated, failed, remaining });
}

async function maintainEntry(
  client: SupabaseClient,
  entry: { id: string; word: string; stem: string | null; lemma: string | null; language_code: string },
  nativeLanguageCode: string,
): Promise<boolean> {
  // Find best encounter context from any vocabulary linked to this global_dict_id
  const { data: vocabRows } = await client
    .from('vocabulary')
    .select('id, user_id')
    .eq('global_dictionary_id', entry.id)
    .is('deleted_at', null)
    .limit(1);

  let context: string | null = null;
  if (vocabRows && vocabRows.length > 0) {
    const { data: encounters } = await client
      .from('encounters')
      .select('context')
      .eq('vocabulary_id', vocabRows[0].id)
      .not('context', 'is', null)
      .order('occurred_at', { ascending: false })
      .limit(1);

    if (encounters && encounters.length > 0) {
      context = encounters[0].context;
    }
  }

  // Translate
  const { translation, source: translationSource } = await translateWord(
    entry.word, nativeLanguageCode, context ?? undefined,
  );

  // AI enhance
  const openaiKey = Deno.env.get('OPENAI_API_KEY');
  if (!openaiKey) throw new Error('OPENAI_API_KEY not configured');

  const aiEnhancement = await getOpenAIEnhancement(
    { word: entry.word, stem: entry.stem }, context, openaiKey, translation, nativeLanguageCode,
  );
  if (!aiEnhancement) throw new Error(`AI enhancement returned null for "${entry.word}"`);

  // Build translations and enrichment payload
  const lemma = normalize(aiEnhancement.stem);
  const translations = buildTranslations(nativeLanguageCode, translation, translationSource, aiEnhancement);

  // Generate TTS audio for maintenance re-enrichment
  const googleApiKey = Deno.env.get('GOOGLE_TRANSLATE_API_KEY');
  let audioUrls: Record<string, string> = {};
  if (googleApiKey) {
    audioUrls = await generateAllAudio(aiEnhancement.stem, googleApiKey, client);
  }

  const updatePayload = {
    ...buildEnrichmentPayload(aiEnhancement, lemma, translations, audioUrls),
    updated_at: new Date().toISOString(),
  };

  const { error: updateError } = await client
    .from('global_dictionary')
    .update(updatePayload)
    .eq('id', entry.id);

  if (updateError) {
    throw new Error(`Failed to update entry ${entry.id}: ${updateError.message}`);
  }

  console.log(`[maintain] ✓ Updated "${entry.word}" → v${ENRICHMENT_VERSION}`);
  return true;
}

// =============================================================================
// Shared word processing loop
// =============================================================================

async function processWords(
  client: SupabaseClient,
  words: VocabWord[],
  nativeLanguageCode: string,
  wordContexts: Record<string, string>,
  forceReEnrich: boolean,
): Promise<ProcessResult> {
  const enriched: EnrichedWord[] = [];
  const failed: FailedWord[] = [];
  const skipped: string[] = [];

  for (const word of words) {
    try {
      if (!forceReEnrich && word.global_dictionary_id) {
        console.log(`[enrich-vocabulary] Skipping "${word.word}" - already enriched`);
        skipped.push(word.id);
        continue;
      }

      const context = wordContexts[word.id] || null;
      const result = await enrichWord(word, nativeLanguageCode, context, client, forceReEnrich);

      if (result) {
        enriched.push(result);
        console.log(`[enrich-vocabulary] ✓ Enriched "${word.word}"`);
      } else {
        failed.push({ vocabulary_id: word.id, error: 'All enrichment services failed' });
        console.error(`[enrich-vocabulary] ✗ Failed "${word.word}"`);
      }
    } catch (err) {
      const errorMsg = err instanceof Error ? err.message : String(err);
      console.error(`[enrich-vocabulary] ✗ Exception for "${word.word}":`, err);
      failed.push({ vocabulary_id: word.id, error: errorMsg });
    }
  }

  return { enriched, failed, skipped };
}

// =============================================================================
// Enrichment: variant-mapping approach
// Phase 1: Check word_variants for existing mapping
// Phase 2: Translation (DeepL → Google → skip)
// Phase 3: AI enhancement (OpenAI for definition/synonyms/confusables + lemma)
// Phase 4: Upsert global_dictionary + word_variants, link + merge
// =============================================================================

// =============================================================================
// TTS Audio Generation (Google Cloud TTS)
// =============================================================================


/**
 * Build enrichment payload from AI enhancement and translations.
 * Consolidates the duplicated payload construction from enrichWord() and maintainEntry().
 */
function buildEnrichmentPayload(
  aiEnhancement: AIEnhancement,
  lemma: string,
  translations: Record<string, TranslationEntry>,
  audioUrls?: Record<string, string>,
): Record<string, unknown> {
  return {
    word: aiEnhancement.stem,
    stem: aiEnhancement.stem,
    lemma,
    part_of_speech: aiEnhancement.part_of_speech,
    english_definition: aiEnhancement.english_definition,
    synonyms: aiEnhancement.synonyms,
    antonyms: aiEnhancement.antonyms,
    confusables: aiEnhancement.confusables.map(c => ({
      word: c.word,
      explanation: c.explanation,
      disambiguation_sentence: c.disambiguation_sentences?.[0] ?? c.disambiguation_sentence,
      disambiguation_sentences: c.disambiguation_sentences ?? (c.disambiguation_sentence ? [c.disambiguation_sentence] : []),
      l1_translation: c.l1_translation ?? '',
    })),
    example_sentences: aiEnhancement.example_sentences,
    usage_examples: aiEnhancement.usage_examples ?? [],
    pronunciation_ipa: aiEnhancement.pronunciation_ipa,
    translations,
    cefr_level: aiEnhancement.cefr_level,
    confidence: aiEnhancement.confidence,
    enrichment_version: ENRICHMENT_VERSION,
    audio_urls: audioUrls || {},
  };
}

/**
 * Upsert global_dictionary entry with three-branch logic:
 * 1. Reuse existing entry (if found and not forcing)
 * 2. Force-update existing entry (if found and forcing)
 * 3. Insert new entry (with race-condition handling)
 * Returns globalDictId on success, null on failure.
 */
async function upsertGlobalDictEntry(
  client: SupabaseClient,
  lemma: string,
  payload: Record<string, unknown>,
  forceReEnrich: boolean,
): Promise<string | null> {
  const existingLemma = await resolveByLemma(client, lemma, SOURCE_LANGUAGE);

  if (existingLemma && !forceReEnrich) {
    console.log(`[enrich-vocabulary] Reusing existing global_dictionary for lemma "${lemma}"`);
    return existingLemma.id;
  }

  if (existingLemma) {
    // Force re-enrich: update existing entry with fresh data
    const { error: updateError } = await client
      .from('global_dictionary')
      .update({ ...payload, updated_at: new Date().toISOString() })
      .eq('id', existingLemma.id);

    if (updateError) {
      console.error('[enrich-vocabulary] Failed to update global_dictionary entry:', updateError);
      return null;
    }
    console.log(`[enrich-vocabulary] Updated global_dictionary for lemma "${lemma}"`);
    return existingLemma.id;
  }

  // Insert new global_dictionary entry
  const globalDictId = crypto.randomUUID();
  const now = new Date().toISOString();

  const { error: insertError } = await client
    .from('global_dictionary')
    .insert({ id: globalDictId, ...payload, created_at: now, updated_at: now })
    .select('id')
    .single();

  if (insertError) {
    if (insertError.code === '23505') {
      console.log(`[enrich-vocabulary] Race condition, fetching existing entry for lemma "${lemma}"`);
      const raceEntry = await resolveByLemma(client, lemma, SOURCE_LANGUAGE);
      if (!raceEntry) {
        console.error('[enrich-vocabulary] Failed to fetch race-condition entry');
        return null;
      }
      return raceEntry.id;
    }
    console.error('[enrich-vocabulary] Failed to insert global_dictionary entry:', insertError);
    return null;
  }

  return globalDictId;
}

async function enrichWord(
  word: VocabWord,
  nativeLanguageCode: string,
  context: string | null,
  client: SupabaseClient,
  forceReEnrich = false,
): Promise<EnrichedWord | null> {
  // Check word_variants → global_dictionary for existing entry
  const existingEntry = await resolveGlobalEntry(client, word.word, SOURCE_LANGUAGE);
  if (existingEntry && !forceReEnrich) {
    console.log(`[enrich-vocabulary] Found existing global_dictionary entry for "${word.word}"`);
    await linkVocabulary(client, word.id, existingEntry.id);
    await mergeIfDuplicate(client, word.user_id, existingEntry.id);
    return { vocabulary_id: word.id, word: word.word, global_dictionary_id: existingEntry.id };
  }

  // Translation (with sentence context for polysemous word disambiguation)
  const { translation, source: translationSource } = await translateWord(word.word, nativeLanguageCode, context ?? undefined);

  // AI enhancement from OpenAI
  const openaiKey = Deno.env.get('OPENAI_API_KEY');
  if (!openaiKey) {
    console.error('[enrich-vocabulary] OpenAI API key not configured');
    return null;
  }

  let aiEnhancement: AIEnhancement | null;
  try {
    aiEnhancement = await getOpenAIEnhancement(word, context, openaiKey, translation, nativeLanguageCode);
    console.log(`[enrich-vocabulary] AI enhancement complete for "${word.word}"`);
  } catch (err) {
    console.error(`[enrich-vocabulary] OpenAI enhancement failed for "${word.word}":`, err);
    return null;
  }

  if (!aiEnhancement) {
    console.error(`[enrich-vocabulary] AI enhancement returned null for "${word.word}"`);
    return null;
  }

  // Resolve lemma from AI response
  const lemma = normalize(aiEnhancement.stem);
  const normalizedWord = normalize(word.word);

  // Build translations and enrichment payload
  const translations = buildTranslations(nativeLanguageCode, translation, translationSource, aiEnhancement);

  // Generate TTS audio (non-blocking — null on failure)
  const googleApiKey = Deno.env.get('GOOGLE_TRANSLATE_API_KEY');
  let audioUrls: Record<string, string> = {};
  if (googleApiKey) {
    audioUrls = await generateAllAudio(aiEnhancement.stem, googleApiKey, client);
  }

  const enrichmentPayload = {
    ...buildEnrichmentPayload(aiEnhancement, lemma, translations, audioUrls),
    language_code: SOURCE_LANGUAGE,
  };

  // Upsert global_dictionary entry
  const globalDictId = await upsertGlobalDictEntry(client, lemma, enrichmentPayload, forceReEnrich);
  if (!globalDictId) return null;

  // Create word_variants mappings
  await upsertVariant(client, SOURCE_LANGUAGE, normalizedWord, globalDictId);
  if (lemma !== normalizedWord) {
    await upsertVariant(client, SOURCE_LANGUAGE, lemma, globalDictId);
  }

  // Link vocabulary and merge duplicates
  await linkVocabulary(client, word.id, globalDictId);
  await mergeIfDuplicate(client, word.user_id, globalDictId);

  console.log(`[enrich-vocabulary] Successfully enriched "${word.word}" → lemma "${lemma}" → global_dictionary ${globalDictId}`);
  return { vocabulary_id: word.id, word: word.word, global_dictionary_id: globalDictId };
}

// =============================================================================
// OpenAI Enhancement
// =============================================================================

async function getOpenAIEnhancement(
  word: { word: string; stem: string | null },
  context: string | null,
  apiKey: string,
  primaryTranslation: string,
  nativeLanguageCode: string,
): Promise<AIEnhancement | null> {
  const langNames: Record<string, string> = {
    de: 'German', es: 'Spanish', fr: 'French', it: 'Italian',
    pt: 'Portuguese', nl: 'Dutch', pl: 'Polish', ru: 'Russian',
    ja: 'Japanese', zh: 'Chinese', ko: 'Korean',
  };
  const langName = langNames[nativeLanguageCode] || nativeLanguageCode.toUpperCase();

  const prompt = `You are a vocabulary enhancement assistant for language learners.

Given an English word and optional context sentence, return a JSON object with:
- stem: the base/dictionary form (lemma) of the word. For verbs, the infinitive. For nouns, nominative singular. If the word is already in base form, return it unchanged.
- english_definition: one-sentence plain English definition
- synonyms: up to 3 English synonyms (array of strings)
- antonyms: up to 2 English antonyms (array of strings, empty array if none)
- part_of_speech: noun/verb/adjective/adverb/preposition/conjunction/determiner/pronoun/interjection/other (string)
- confusables: array of commonly confused words (max 3), each with:
  - word: the confusable English word
  - explanation: one-sentence distinction in English
  - disambiguation_sentences: array of 4 objects with { "sentence", "before", "blank", "after" }
    Each sentence demonstrates the CONFUSABLE word (NOT the target) in context
  - l1_translation: the ${langName} translation of this confusable word
- example_sentences: array of 3 NOVEL objects (NOT the provided context), each with { "sentence": "full sentence", "before": "text before blank", "blank": "word form used", "after": "text after blank" }
  Show the target word in DIFFERENT contexts than the encounter
- usage_examples: array of 1 object with:
  - correct_sentence: object with { "sentence", "before", "blank", "after" } showing CORRECT usage of the target word
  - incorrect_sentences: array of 2 objects with { "sentence", "before", "blank", "after" } showing INCORRECT or AWKWARD usage of the target word
- pronunciation_ipa: IPA pronunciation (e.g., /ˈwɜːrd/)
- cefr_level: A1/A2/B1/B2/C1/C2 or null if uncertain
- confidence: 0.0-1.0 indicating overall confidence
- best_native_translation: the single best ${langName} translation for this word as used in the given context. Consider the context carefully — for polysemous words, pick the sense that matches. Return null if uncertain.
- native_alternatives: 2-4 other valid ${langName} translations (not the best_native_translation, no trivial inflections like plural forms, no duplicates). If no good alternatives exist, return empty array [].
- confusable_translations: 2-3 ${langName} words that LOOK SIMILAR to the correct translation but mean something different. Example: For "desert" → ${langName} "Wüste", confusables might be "Würste" (sausages), "wüsste" (would know). Return empty array if none.

IMPORTANT for all sentence objects (example_sentences, disambiguation_sentences, usage_examples):
- Each sentence should demonstrate the word in context
- Split the sentence into "before", "blank" (the word), and "after" parts
- The "sentence" field should contain the complete sentence for reference
- Example: For "ubiquitous" → { "sentence": "Wi-Fi has become so ubiquitous.", "before": "Wi-Fi has become so ", "blank": "ubiquitous", "after": "." }

QUALITY RULES (CRITICAL):
1. ACRONYMS: If the word is an acronym (e.g., "TLC", "FAQ", "ASAP"), identify it as such and provide both the expanded form and its meaning. Example: "TLC" → "Tender Loving Care: careful and kind attention given to someone or something"
2. CIRCULAR DEFINITIONS: The english_definition MUST NOT contain the target word or any of its variants (stem, inflections). Use different vocabulary to explain the meaning.
3. DISAMBIGUATION SENTENCES: The disambiguation_sentences should NOT contain the target word. Use only the confusable word in the blank to demonstrate the distinction clearly.

Word: ${word.word}
Stem: ${word.stem || word.word}
Context: ${context || 'none'}
Machine ${langName} translation (may be incorrect): ${primaryTranslation}`;

  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: 'gpt-4o-mini',
      messages: [{ role: 'user', content: prompt }],
      response_format: { type: 'json_object' },
      temperature: 0.3,
      max_tokens: 1500,
    }),
  });

  if (!response.ok) {
    throw new Error(`OpenAI API error: ${response.status} ${response.statusText}`);
  }

  const data = await response.json();
  const content = data.choices?.[0]?.message?.content;
  if (!content) throw new Error('No content in OpenAI response');

  const parsed = JSON.parse(content);

  // Validate quality rules
  const targetWord = word.word.toLowerCase();
  const stem = (parsed.stem || word.word).toLowerCase();
  const definition = (parsed.english_definition || '').toLowerCase();

  // Rule 2: Check for circular definitions
  if (definition.includes(targetWord) || definition.includes(stem)) {
    console.warn(`[enrichment-quality] Circular definition detected for "${word.word}": "${parsed.english_definition}"`);
  }

  // Rule 3: Check disambiguation sentences for target word
  if (Array.isArray(parsed.confusables)) {
    for (const confusable of parsed.confusables) {
      const sentences = Array.isArray(confusable.disambiguation_sentences)
        ? confusable.disambiguation_sentences
        : (confusable.disambiguation_sentence ? [confusable.disambiguation_sentence] : []);
      for (const sent of sentences) {
        const disambigSentence = (sent.sentence || '').toLowerCase();
        if (disambigSentence.includes(targetWord) || disambigSentence.includes(stem)) {
          console.warn(`[enrichment-quality] Disambiguation sentence contains target word "${word.word}": "${sent.sentence}"`);
        }
      }
    }
  }

  return {
    stem: parsed.stem || word.word,
    english_definition: parsed.english_definition || '',
    synonyms: parsed.synonyms || [],
    antonyms: parsed.antonyms || [],
    part_of_speech: parsed.part_of_speech || null,
    confusables: (parsed.confusables || []).map((c: Record<string, unknown>) => ({
      word: c.word || '',
      explanation: c.explanation || '',
      disambiguation_sentence: Array.isArray(c.disambiguation_sentences) && c.disambiguation_sentences.length > 0
        ? c.disambiguation_sentences[0]
        : c.disambiguation_sentence || { sentence: '', before: '', blank: '', after: '' },
      disambiguation_sentences: Array.isArray(c.disambiguation_sentences)
        ? c.disambiguation_sentences
        : (c.disambiguation_sentence ? [c.disambiguation_sentence] : []),
      l1_translation: c.l1_translation || '',
    })),
    example_sentences: parsed.example_sentences || [],
    usage_examples: parsed.usage_examples || [],
    pronunciation_ipa: parsed.pronunciation_ipa || '',
    cefr_level: parsed.cefr_level || null,
    confidence: parsed.confidence || 0.9,
    native_alternatives: Array.isArray(parsed.native_alternatives)
      ? parsed.native_alternatives.filter((a: string) => a && typeof a === 'string')
      : [],
    best_native_translation: (parsed.best_native_translation && typeof parsed.best_native_translation === 'string')
      ? parsed.best_native_translation
      : null,
    confusable_translations: Array.isArray(parsed.confusable_translations)
      ? parsed.confusable_translations.filter((a: string) => a && typeof a === 'string')
      : [],
  };
}

// =============================================================================
// Shared DB helpers
// =============================================================================

async function getUnEnrichedWords(
  client: SupabaseClient,
  userId: string,
  limit: number,
): Promise<VocabWord[]> {
  const { data, error } = await client
    .from('vocabulary')
    .select('id, word, stem, user_id, global_dictionary_id')
    .eq('user_id', userId)
    .is('global_dictionary_id', null)
    .is('deleted_at', null)
    .order('created_at', { ascending: true })
    .limit(limit);

  if (error) {
    console.error('[enrich-vocabulary] getUnEnrichedWords failed:', error);
    return [];
  }

  return data || [];
}

async function getEncounterContexts(
  client: SupabaseClient,
  userId: string,
  words: VocabWord[],
): Promise<Record<string, string>> {
  if (words.length === 0) return {};

  const vocabIds = words.map(w => w.id);
  const { data: encounters, error } = await client
    .from('encounters')
    .select('vocabulary_id, context')
    .eq('user_id', userId)
    .in('vocabulary_id', vocabIds)
    .not('context', 'is', null)
    .order('occurred_at', { ascending: false });

  if (error) {
    console.error('[enrich-vocabulary] getEncounterContexts failed:', error);
    return {};
  }

  const contexts: Record<string, string> = {};
  for (const enc of (encounters || [])) {
    if (!contexts[enc.vocabulary_id] && enc.context) {
      contexts[enc.vocabulary_id] = enc.context;
    }
  }
  return contexts;
}

async function getBufferStatus(
  client: SupabaseClient,
  userId: string,
): Promise<{ enriched_count: number; un_enriched_count: number; buffer_target: number; pending_in_queue: number }> {
  const [enrichedRes, totalRes] = await Promise.all([
    client
      .from('vocabulary')
      .select('id', { count: 'exact', head: true })
      .eq('user_id', userId)
      .not('global_dictionary_id', 'is', null)
      .is('deleted_at', null),
    client
      .from('vocabulary')
      .select('id', { count: 'exact', head: true })
      .eq('user_id', userId)
      .is('deleted_at', null),
  ]);

  return {
    enriched_count: enrichedRes.count || 0,
    un_enriched_count: (totalRes.count || 0) - (enrichedRes.count || 0),
    buffer_target: BUFFER_TARGET,
    pending_in_queue: 0,
  };
}
