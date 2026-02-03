// Edge function: enrich-vocabulary
// Enriches vocabulary words with meanings using a 2-phase approach:
// Phase 1: DeepL/Google for reliable translation
// Phase 2: OpenAI for english_definition, synonyms, confusables only
//
// Key features:
// - ONE meaning per vocabulary word (enforced by unique constraint)
// - Stale processing timeout to prevent stuck items
// - Duplicate check before API calls to save costs

import { handleCors } from '../_shared/cors.ts';
import { createServiceClient, getUserId } from '../_shared/supabase.ts';
import { jsonResponse, errorResponse, unauthorizedResponse } from '../_shared/response.ts';

const MAX_BATCH_SIZE = 10;
const DEFAULT_BATCH_SIZE = 5;
const MAX_RETRY_ATTEMPTS = 3;
const BUFFER_TARGET = 10;
const STALE_PROCESSING_TIMEOUT_MINUTES = 5;

Deno.serve(async (req) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  const userId = await getUserId(req);
  if (!userId) return unauthorizedResponse();

  const url = new URL(req.url);
  const path = url.pathname.split('/').pop();

  try {
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
// POST /enrich-vocabulary/request
// =============================================================================

async function handleEnrichRequest(req: Request, userId: string): Promise<Response> {
  const body = await req.json();
  const nativeLanguageCode: string = body.native_language_code;
  const batchSize = Math.min(body.batch_size || DEFAULT_BATCH_SIZE, MAX_BATCH_SIZE);
  const vocabularyIds: string[] | undefined = body.vocabulary_ids;

  if (!nativeLanguageCode) {
    return errorResponse('native_language_code is required', 400);
  }

  const client = createServiceClient();

  // Reset stale "processing" entries before fetching words
  await resetStaleProcessingEntries(client, userId);

  // Get vocabulary words to enrich
  let wordsToEnrich: VocabWord[];

  if (vocabularyIds && vocabularyIds.length > 0) {
    // Specific words requested - bypass buffer logic
    const { data, error } = await client
      .from('vocabulary')
      .select('id, word, stem')
      .eq('user_id', userId)
      .in('id', vocabularyIds.slice(0, batchSize))
      .is('deleted_at', null);

    if (error) {
      console.error('[enrich-vocabulary] Failed to fetch vocabulary:', error);
      return errorResponse('Failed to fetch vocabulary', 500);
    }
    wordsToEnrich = data || [];
  } else {
    // Buffer logic: pick next un-enriched words
    wordsToEnrich = await getUnEnrichedWords(client, userId, batchSize);
  }

  console.log(`[enrich-vocabulary] Enriching ${wordsToEnrich.length} words for user=${userId}, language=${nativeLanguageCode}`);

  // Get encounter context for each word
  const wordContexts = await getEncounterContexts(client, userId, wordsToEnrich);

  // Process each word
  const enriched: EnrichedWord[] = [];
  const failed: FailedWord[] = [];
  const skipped: string[] = [];

  for (const word of wordsToEnrich) {
    try {
      // SAFEGUARD 1: Check if meaning already exists (race condition guard)
      const existingMeaning = await checkExistingMeaning(client, userId, word.id);
      if (existingMeaning) {
        console.log(`[enrich-vocabulary] Skipping "${word.word}" - already has meaning`);
        skipped.push(word.id);
        continue;
      }

      // SAFEGUARD 2: Try to atomically claim the word in queue
      const claimed = await tryClaimWord(client, userId, word.id);
      if (!claimed) {
        console.log(`[enrich-vocabulary] Skipping "${word.word}" - already being processed`);
        skipped.push(word.id);
        continue;
      }

      const context = wordContexts[word.id];
      const result = await enrichWord(word, nativeLanguageCode, context, client, userId);

      if (result) {
        enriched.push(result);
        await updateQueueStatus(client, userId, word.id, 'completed');
      } else {
        failed.push({ vocabulary_id: word.id, error: 'All enrichment services failed', will_retry: true });
        await incrementQueueAttempt(client, userId, word.id, 'All enrichment services failed');
      }
    } catch (err) {
      const errorMsg = err instanceof Error ? err.message : String(err);
      console.error(`[enrich-vocabulary] Failed to enrich "${word.word}":`, errorMsg);
      failed.push({ vocabulary_id: word.id, error: errorMsg, will_retry: true });
      await incrementQueueAttempt(client, userId, word.id, errorMsg);
    }
  }

  // Get buffer status
  const bufferStatus = await getBufferStatus(client, userId);

  return jsonResponse({
    enriched,
    failed,
    skipped,
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
// Enrichment: 2-phase approach
// Phase 1: Translation (DeepL → Google → skip)
// Phase 2: AI enhancement (OpenAI for definition/synonyms/confusables)
// =============================================================================

async function enrichWord(
  word: VocabWord,
  nativeLanguageCode: string,
  context: string | null,
  client: ReturnType<typeof createServiceClient>,
  userId: string,
): Promise<EnrichedWord | null> {
  // Phase 1: Get translation from DeepL or Google (reliable, cheap)
  let translation: string | null = null;
  let translationSource: string = 'none';

  const deeplKey = Deno.env.get('DEEPL_API_KEY');
  if (deeplKey) {
    try {
      translation = await getDeepLTranslation(word.word, nativeLanguageCode, deeplKey);
      translationSource = 'deepl';
      console.log(`[enrich-vocabulary] Phase 1 (DeepL) translation for "${word.word}": ${translation}`);
    } catch (err) {
      console.warn(`[enrich-vocabulary] DeepL failed for "${word.word}":`, err);
    }
  }

  if (!translation) {
    const googleKey = Deno.env.get('GOOGLE_TRANSLATE_API_KEY');
    if (googleKey) {
      try {
        translation = await getGoogleTranslation(word.word, nativeLanguageCode, googleKey);
        translationSource = 'google';
        console.log(`[enrich-vocabulary] Phase 1 (Google) translation for "${word.word}": ${translation}`);
      } catch (err) {
        console.warn(`[enrich-vocabulary] Google Translate failed for "${word.word}":`, err);
      }
    }
  }

  // If no translation service available, use the word itself
  if (!translation) {
    translation = word.word;
    translationSource = 'none';
    console.log(`[enrich-vocabulary] No translation service available for "${word.word}"`);
  }

  // Phase 2: Get AI enhancement (definition, synonyms, confusables) from OpenAI
  let aiEnhancement: AIEnhancement | null = null;
  const openaiKey = Deno.env.get('OPENAI_API_KEY');
  if (openaiKey) {
    try {
      aiEnhancement = await getOpenAIEnhancement(word, context, openaiKey);
      console.log(`[enrich-vocabulary] Phase 2 (OpenAI) enhancement for "${word.word}"`);
    } catch (err) {
      console.warn(`[enrich-vocabulary] OpenAI enhancement failed for "${word.word}":`, err);
    }
  }

  // Build the single meaning record
  const result = buildEnrichedWord(word, translation, translationSource, aiEnhancement, nativeLanguageCode);

  // Store the result (single meaning, upsert to handle unique constraint)
  await storeEnrichmentResult(client, userId, word.id, result, nativeLanguageCode);

  return result;
}

// =============================================================================
// Phase 1: Translation Services
// =============================================================================

async function getDeepLTranslation(
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
  return data.translations?.[0]?.text || null;
}

async function getGoogleTranslation(
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
  return data.data?.translations?.[0]?.translatedText || null;
}

// =============================================================================
// Phase 2: OpenAI Enhancement (definition, synonyms, confusables ONLY)
// =============================================================================

interface AIEnhancement {
  english_definition: string;
  synonyms: string[];
  part_of_speech: string | null;
  confusables: Array<{
    word: string;
    explanation: string;
    example_sentence?: string;
  }>;
  confidence: number;
}

async function getOpenAIEnhancement(
  word: VocabWord,
  context: string | null,
  apiKey: string,
): Promise<AIEnhancement | null> {
  // Note: We do NOT ask for translation - that comes from DeepL/Google
  const prompt = `You are a vocabulary enhancement assistant for language learners.

Given an English word and optional context sentence, return a JSON object with:
- english_definition: one-sentence plain English definition
- synonyms: up to 3 English synonyms (array of strings)
- part_of_speech: noun/verb/adjective/adverb/other (string)
- confusables: array of commonly confused words (max 3), each with:
  - word: the confusable English word
  - explanation: one-sentence distinction in English
  - example_sentence: English sentence demonstrating correct usage
- confidence: 0.0-1.0 indicating overall confidence

IMPORTANT: Do NOT provide translations. Only provide English definitions and synonyms.

Word: ${word.word}
Stem: ${word.stem || word.word}
Context: ${context || 'none'}`;

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
      max_tokens: 1000, // Reduced since we don't need translations
    }),
  });

  if (!response.ok) {
    throw new Error(`OpenAI API error: ${response.status} ${response.statusText}`);
  }

  const data = await response.json();
  const content = data.choices?.[0]?.message?.content;
  if (!content) throw new Error('No content in OpenAI response');

  const parsed = JSON.parse(content);
  return {
    english_definition: parsed.english_definition || '',
    synonyms: parsed.synonyms || [],
    part_of_speech: parsed.part_of_speech || null,
    confusables: parsed.confusables || [],
    confidence: parsed.confidence || 0.9,
  };
}

// =============================================================================
// Build enriched word result
// =============================================================================

function buildEnrichedWord(
  word: VocabWord,
  translation: string,
  translationSource: string,
  aiEnhancement: AIEnhancement | null,
  _nativeLanguageCode: string,
): EnrichedWord {
  // Generate deterministic ID based on user context (will be set during storage)
  const meaningId = crypto.randomUUID();

  // Build cues
  const cues: EnrichedCue[] = [];

  // Translation cue (from DeepL/Google)
  cues.push({
    id: crypto.randomUUID(),
    cue_type: 'translation',
    prompt_text: translation,
    answer_text: word.word,
    hint_text: null,
    metadata: { source: translationSource },
  });

  // Definition cue (from OpenAI)
  if (aiEnhancement?.english_definition) {
    cues.push({
      id: crypto.randomUUID(),
      cue_type: 'definition',
      prompt_text: aiEnhancement.english_definition,
      answer_text: word.word,
      hint_text: null,
      metadata: {},
    });
  }

  // Synonym cue (from OpenAI)
  if (aiEnhancement?.synonyms && aiEnhancement.synonyms.length > 0) {
    cues.push({
      id: crypto.randomUUID(),
      cue_type: 'synonym',
      prompt_text: aiEnhancement.synonyms.join(', '),
      answer_text: word.word,
      hint_text: null,
      metadata: {},
    });
  }

  // Build confusable set (from OpenAI)
  let confusableSet: EnrichedConfusableSet | null = null;
  if (aiEnhancement?.confusables && aiEnhancement.confusables.length > 0) {
    const explanations: Record<string, string> = {};
    const exampleSentences: Record<string, string> = {};
    const confusableWords = aiEnhancement.confusables.map((c) => {
      explanations[c.word] = c.explanation;
      if (c.example_sentence) exampleSentences[c.word] = c.example_sentence;
      return c.word;
    });
    // Include the word itself
    if (!confusableWords.includes(word.word)) {
      confusableWords.unshift(word.word);
    }

    confusableSet = {
      id: crypto.randomUUID(),
      words: confusableWords,
      explanations,
      example_sentences: exampleSentences,
    };

    // Add disambiguation cue if we have confusables
    if (aiEnhancement.confusables.length >= 2 && aiEnhancement.english_definition) {
      const disambigOptions = confusableWords.slice(0, 4);
      cues.push({
        id: crypto.randomUUID(),
        cue_type: 'disambiguation',
        prompt_text: `Choose the word that means: ${aiEnhancement.english_definition}`,
        answer_text: word.word,
        hint_text: null,
        metadata: {
          options: disambigOptions,
          explanations,
        },
      });
    }
  }

  // Determine confidence and source
  const confidence = aiEnhancement?.confidence || (translationSource !== 'none' ? 0.7 : 0.3);
  const source = aiEnhancement ? `${translationSource}+ai` : translationSource;

  return {
    vocabulary_id: word.id,
    word: word.word,
    meaning: {
      id: meaningId,
      primary_translation: translation,
      alternative_translations: [],
      english_definition: aiEnhancement?.english_definition || `${word.word} (${translationSource} translation)`,
      extended_definition: null,
      part_of_speech: aiEnhancement?.part_of_speech || null,
      synonyms: aiEnhancement?.synonyms || [],
      confidence,
      is_primary: true,
      sort_order: 0,
      source,
      cues,
    },
    confusable_set: confusableSet,
  };
}

// =============================================================================
// Storage: Single meaning with upsert
// =============================================================================

async function storeEnrichmentResult(
  client: ReturnType<typeof createServiceClient>,
  userId: string,
  vocabularyId: string,
  result: EnrichedWord,
  nativeLanguageCode: string,
): Promise<void> {
  const now = new Date().toISOString();
  const meaning = result.meaning;

  // Check if meaning already exists for this vocabulary
  const { data: existingMeaning } = await client
    .from('meanings')
    .select('id')
    .eq('user_id', userId)
    .eq('vocabulary_id', vocabularyId)
    .is('deleted_at', null)
    .single();

  let actualMeaningId: string;

  if (existingMeaning) {
    // Update existing meaning
    actualMeaningId = existingMeaning.id;
    const { error: updateError } = await client
      .from('meanings')
      .update({
        language_code: nativeLanguageCode,
        primary_translation: meaning.primary_translation,
        alternative_translations: meaning.alternative_translations,
        english_definition: meaning.english_definition,
        extended_definition: meaning.extended_definition,
        part_of_speech: meaning.part_of_speech,
        synonyms: meaning.synonyms,
        confidence: meaning.confidence,
        is_primary: meaning.is_primary,
        is_active: true,
        sort_order: meaning.sort_order,
        source: meaning.source,
        updated_at: now,
      })
      .eq('id', actualMeaningId);

    if (updateError) {
      console.error(`[enrich-vocabulary] Failed to update meaning:`, updateError);
      throw new Error(`Failed to update meaning: ${updateError.message}`);
    }
    console.log(`[enrich-vocabulary] Updated existing meaning ${actualMeaningId}`);
  } else {
    // Insert new meaning
    actualMeaningId = meaning.id;
    const { error: insertError } = await client.from('meanings').insert({
      id: actualMeaningId,
      user_id: userId,
      vocabulary_id: vocabularyId,
      language_code: nativeLanguageCode,
      primary_translation: meaning.primary_translation,
      alternative_translations: meaning.alternative_translations,
      english_definition: meaning.english_definition,
      extended_definition: meaning.extended_definition,
      part_of_speech: meaning.part_of_speech,
      synonyms: meaning.synonyms,
      confidence: meaning.confidence,
      is_primary: meaning.is_primary,
      is_active: true,
      sort_order: meaning.sort_order,
      source: meaning.source,
      created_at: now,
      updated_at: now,
      version: 1,
    });

    if (insertError) {
      console.error(`[enrich-vocabulary] Failed to insert meaning:`, insertError);
      throw new Error(`Failed to insert meaning: ${insertError.message}`);
    }
    console.log(`[enrich-vocabulary] Inserted new meaning ${actualMeaningId}`);
  }

  // Delete old cues for this meaning and insert new ones
  await client.from('cues')
    .delete()
    .eq('meaning_id', actualMeaningId);

  // Insert cues
  for (const cue of meaning.cues) {
    await client.from('cues').insert({
      id: cue.id,
      user_id: userId,
      meaning_id: actualMeaningId,
      cue_type: cue.cue_type,
      prompt_text: cue.prompt_text,
      answer_text: cue.answer_text,
      hint_text: cue.hint_text,
      metadata: cue.metadata,
      created_at: now,
      updated_at: now,
      version: 1,
    });
  }

  // Insert confusable set if present
  if (result.confusable_set) {
    const cs = result.confusable_set;

    // Delete old confusable set members for this vocabulary
    await client.from('confusable_set_members')
      .delete()
      .eq('vocabulary_id', vocabularyId);

    await client.from('confusable_sets').upsert({
      id: cs.id,
      user_id: userId,
      language_code: nativeLanguageCode,
      words: cs.words,
      explanations: cs.explanations,
      example_sentences: cs.example_sentences,
      created_at: now,
      updated_at: now,
      version: 1,
    });

    // Link vocabulary to confusable set
    await client.from('confusable_set_members').upsert({
      id: `${cs.id}_${vocabularyId}`,
      confusable_set_id: cs.id,
      vocabulary_id: vocabularyId,
      created_at: now,
    });
  }
}

// =============================================================================
// Safeguards: Prevent duplicate API calls
// =============================================================================

async function checkExistingMeaning(
  client: ReturnType<typeof createServiceClient>,
  userId: string,
  vocabularyId: string,
): Promise<boolean> {
  const { data } = await client
    .from('meanings')
    .select('id')
    .eq('user_id', userId)
    .eq('vocabulary_id', vocabularyId)
    .is('deleted_at', null)
    .limit(1)
    .single();

  return data !== null;
}

async function tryClaimWord(
  client: ReturnType<typeof createServiceClient>,
  userId: string,
  vocabularyId: string,
): Promise<boolean> {
  const now = new Date().toISOString();

  // Check if already processing or completed
  const { data: existing } = await client
    .from('enrichment_queue')
    .select('status')
    .eq('user_id', userId)
    .eq('vocabulary_id', vocabularyId)
    .single();

  if (existing?.status === 'completed' || existing?.status === 'processing') {
    return false;
  }

  // Try to upsert with processing status
  const { error } = await client.from('enrichment_queue').upsert({
    user_id: userId,
    vocabulary_id: vocabularyId,
    status: 'processing',
    last_attempted_at: now,
  }, { onConflict: 'user_id,vocabulary_id' });

  return !error;
}

async function resetStaleProcessingEntries(
  client: ReturnType<typeof createServiceClient>,
  userId: string,
): Promise<void> {
  const staleThreshold = new Date(Date.now() - STALE_PROCESSING_TIMEOUT_MINUTES * 60 * 1000).toISOString();

  await client
    .from('enrichment_queue')
    .update({
      status: 'pending',
      last_error: 'Processing timeout - will retry',
    })
    .eq('user_id', userId)
    .eq('status', 'processing')
    .lt('last_attempted_at', staleThreshold);
}

async function updateQueueStatus(
  client: ReturnType<typeof createServiceClient>,
  userId: string,
  vocabularyId: string,
  status: string,
): Promise<void> {
  const now = new Date().toISOString();
  await client.from('enrichment_queue').upsert({
    user_id: userId,
    vocabulary_id: vocabularyId,
    status,
    ...(status === 'completed' ? { completed_at: now } : {}),
  }, { onConflict: 'user_id,vocabulary_id' });
}

async function incrementQueueAttempt(
  client: ReturnType<typeof createServiceClient>,
  userId: string,
  vocabularyId: string,
  error: string,
): Promise<void> {
  const { data: existing } = await client
    .from('enrichment_queue')
    .select('id, attempts')
    .eq('user_id', userId)
    .eq('vocabulary_id', vocabularyId)
    .single();

  const attempts = (existing?.attempts || 0) + 1;
  const status = attempts >= MAX_RETRY_ATTEMPTS ? 'failed' : 'pending';

  await client.from('enrichment_queue').upsert({
    user_id: userId,
    vocabulary_id: vocabularyId,
    status,
    attempts,
    last_error: error,
    last_attempted_at: new Date().toISOString(),
  }, { onConflict: 'user_id,vocabulary_id' });
}

// =============================================================================
// Helpers
// =============================================================================

async function getUnEnrichedWords(
  client: ReturnType<typeof createServiceClient>,
  userId: string,
  limit: number,
): Promise<VocabWord[]> {
  // Get vocabulary IDs that already have meanings
  const { data: enrichedIds } = await client
    .from('meanings')
    .select('vocabulary_id')
    .eq('user_id', userId)
    .is('deleted_at', null);

  const enrichedSet = new Set((enrichedIds || []).map((r: { vocabulary_id: string }) => r.vocabulary_id));

  // Get all vocabulary, filter out enriched ones
  const { data: allVocab, error } = await client
    .from('vocabulary')
    .select('id, word, stem')
    .eq('user_id', userId)
    .is('deleted_at', null)
    .order('created_at', { ascending: true })
    .limit(limit + enrichedSet.size);

  if (error || !allVocab) return [];

  return allVocab
    .filter((v: VocabWord) => !enrichedSet.has(v.id))
    .slice(0, limit);
}

async function getEncounterContexts(
  client: ReturnType<typeof createServiceClient>,
  userId: string,
  words: VocabWord[],
): Promise<Record<string, string>> {
  if (words.length === 0) return {};

  const vocabIds = words.map(w => w.id);
  const { data: encounters } = await client
    .from('encounters')
    .select('vocabulary_id, context')
    .eq('user_id', userId)
    .in('vocabulary_id', vocabIds)
    .not('context', 'is', null)
    .order('occurred_at', { ascending: false });

  const contexts: Record<string, string> = {};
  for (const enc of (encounters || [])) {
    // Keep only the first (most recent) context per word
    if (!contexts[enc.vocabulary_id] && enc.context) {
      contexts[enc.vocabulary_id] = enc.context;
    }
  }
  return contexts;
}

async function getBufferStatus(
  client: ReturnType<typeof createServiceClient>,
  userId: string,
): Promise<{ enriched_count: number; un_enriched_count: number; buffer_target: number; pending_in_queue: number }> {
  // Count vocabulary with meanings (distinct vocabulary_id)
  const { data: enrichedData } = await client
    .from('meanings')
    .select('vocabulary_id')
    .eq('user_id', userId)
    .is('deleted_at', null);

  const enrichedCount = new Set((enrichedData || []).map((r: { vocabulary_id: string }) => r.vocabulary_id)).size;

  // Count total vocab
  const { count: totalCount } = await client
    .from('vocabulary')
    .select('id', { count: 'exact', head: true })
    .eq('user_id', userId)
    .is('deleted_at', null);

  // Count pending in queue
  const { count: pendingCount } = await client
    .from('enrichment_queue')
    .select('id', { count: 'exact', head: true })
    .eq('user_id', userId)
    .in('status', ['pending', 'processing']);

  return {
    enriched_count: enrichedCount,
    un_enriched_count: (totalCount || 0) - enrichedCount,
    buffer_target: BUFFER_TARGET,
    pending_in_queue: pendingCount || 0,
  };
}

// =============================================================================
// Types
// =============================================================================

interface VocabWord {
  id: string;
  word: string;
  stem: string | null;
}

interface EnrichedCue {
  id: string;
  cue_type: string;
  prompt_text: string;
  answer_text: string;
  hint_text: string | null;
  metadata: Record<string, unknown>;
}

interface EnrichedMeaning {
  id: string;
  primary_translation: string;
  alternative_translations: string[];
  english_definition: string;
  extended_definition: string | null;
  part_of_speech: string | null;
  synonyms: string[];
  confidence: number;
  is_primary: boolean;
  sort_order: number;
  source: string;
  cues: EnrichedCue[];
}

interface EnrichedConfusableSet {
  id: string;
  words: string[];
  explanations: Record<string, string>;
  example_sentences: Record<string, string>;
}

interface EnrichedWord {
  vocabulary_id: string;
  word: string;
  meaning: EnrichedMeaning; // Changed from meanings[] to single meaning
  confusable_set: EnrichedConfusableSet | null;
}

interface FailedWord {
  vocabulary_id: string;
  error: string;
  will_retry: boolean;
}
