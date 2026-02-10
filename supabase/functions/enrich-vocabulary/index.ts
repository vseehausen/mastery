// Edge function: enrich-vocabulary
// Enriches vocabulary words and writes to global_dictionary table
// Phase 1: Check if word exists in global_dictionary by content_hash
// Phase 2: If not, call OpenAI to generate full enrichment data
// Phase 3: Write to global_dictionary with ON CONFLICT DO NOTHING
// Phase 4: Link vocabulary to global_dictionary_id
//
// Key features:
// - Shared global dictionary for all users (deduplication by content_hash)
// - Stale processing timeout to prevent stuck items
// - Duplicate check before API calls to save costs

import { handleCors } from '../_shared/cors.ts';
import { createServiceClient, getUserId } from '../_shared/supabase.ts';
import { jsonResponse, errorResponse, unauthorizedResponse } from '../_shared/response.ts';
import { getDeepLTranslation, getGoogleTranslation } from '../_shared/translation.ts';
import { generateContentHash } from '../_shared/crypto.ts';

const MAX_BATCH_SIZE = 10;
const DEFAULT_BATCH_SIZE = 5;
const MAX_RETRY_ATTEMPTS = 3;
const BUFFER_TARGET = 10;
const STALE_PROCESSING_TIMEOUT_MINUTES = 5;

Deno.serve(async (req) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  // Check if using service role key (for server-side calls)
  const authHeader = req.headers.get("Authorization");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const isServiceRoleKey = authHeader === `Bearer ${serviceRoleKey}`;

  let userId: string | null = null;

  if (isServiceRoleKey) {
    // Service role key - userId will be extracted from request body
    const body = await req.json();
    const url = new URL(req.url);
    const path = url.pathname.split('/').pop();

    try {
      if (req.method === 'POST' && path === 'request') {
        // For batch enrichment, get userId from the request (will be validated in handleEnrichRequest)
        return await handleEnrichRequestServerSide(body);
      }
      return errorResponse('Method not allowed', 405);
    } catch (error) {
      console.error('[enrich-vocabulary] Error:', error);
      return errorResponse('Internal server error', 500);
    }
  } else {
    // User JWT authentication
    userId = await getUserId(req);
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
  }
});

// =============================================================================
// POST /enrich-vocabulary/request (server-side with service role key)
// =============================================================================

async function handleEnrichRequestServerSide(body: any): Promise<Response> {
  const vocabularyIds: string[] = body.vocabulary_ids;

  if (!vocabularyIds || vocabularyIds.length === 0) {
    return errorResponse('vocabulary_ids is required', 400);
  }

  const client = createServiceClient();

  // Get the userId from the first vocabulary entry
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

  // Fetch vocabulary words
  const { data: wordsData, error: wordsError } = await client
    .from('vocabulary')
    .select('id, word, stem')
    .eq('user_id', userId)
    .in('id', vocabularyIds.slice(0, batchSize))
    .is('deleted_at', null);

  if (wordsError) {
    console.error('[enrich-vocabulary] Failed to fetch vocabulary:', wordsError);
    return errorResponse('Failed to fetch vocabulary', 500);
  }

  const wordsToEnrich: VocabWord[] = wordsData || [];
  console.log(`[enrich-vocabulary] Server-side enriching ${wordsToEnrich.length} words for user=${userId}, language=${nativeLanguageCode}`);

  // Get encounter contexts
  const wordContexts = await getEncounterContexts(client, userId, wordsToEnrich);

  // Process each word
  const enriched: EnrichedWord[] = [];
  const failed: FailedWord[] = [];
  const skipped: string[] = [];

  for (const word of wordsToEnrich) {
    try {
      // Check if already enriched
      const existingMeaning = await checkExistingMeaning(client, userId, word.id);
      if (existingMeaning) {
        console.log(`[enrich-vocabulary] Skipping "${word.word}" - already has meaning`);
        skipped.push(word.id);
        await updateQueueStatus(client, userId, word.id, 'completed');
        continue;
      }

      // Try to claim the word
      const claimed = await tryClaimWord(client, userId, word.id);
      if (!claimed) {
        console.log(`[enrich-vocabulary] Skipping "${word.word}" - already being processed`);
        skipped.push(word.id);
        continue;
      }

      // Enrich the word
      const context = wordContexts[word.id] || null;
      const result = await enrichWord(word, nativeLanguageCode, context, client, userId);

      if (result) {
        enriched.push(result);
        await updateQueueStatus(client, userId, word.id, 'completed');
        console.log(`[enrich-vocabulary] ✓ Enriched "${word.word}"`);
      } else {
        failed.push({ vocabulary_id: word.id, error: 'All enrichment services failed', will_retry: true });
        await incrementQueueAttempt(client, userId, word.id, 'All enrichment services failed');
        console.error(`[enrich-vocabulary] ✗ Failed "${word.word}": All enrichment services failed`);
      }
    } catch (err) {
      const errorMsg = err instanceof Error ? err.message : String(err);
      failed.push({ vocabulary_id: word.id, error: errorMsg });
      await incrementQueueAttempt(client, userId, word.id, errorMsg);
      console.error(`[enrich-vocabulary] ✗ Exception for "${word.word}":`, err);
    }
  }

  return jsonResponse({
    enriched,
    failed,
    skipped,
  });
}

// =============================================================================
// POST /enrich-vocabulary/request
// =============================================================================

async function handleEnrichRequest(req: Request, userId: string): Promise<Response> {
  const body = await req.json();
  const nativeLanguageCode: string = body.native_language_code;
  const batchSize = Math.min(body.batch_size || DEFAULT_BATCH_SIZE, MAX_BATCH_SIZE);
  const vocabularyIds: string[] | undefined = body.vocabulary_ids;
  const forceReEnrich: boolean = body.force_re_enrich ?? false;

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
      // Skip this check if force_re_enrich is true
      if (!forceReEnrich) {
        const existingMeaning = await checkExistingMeaning(client, userId, word.id);
        if (existingMeaning) {
          console.log(`[enrich-vocabulary] Skipping "${word.word}" - already has meaning`);
          skipped.push(word.id);
          continue;
        }
      }

      // SAFEGUARD 2: Try to atomically claim the word in queue
      // If force_re_enrich is true, reset the queue status first
      if (forceReEnrich) {
        await client.from('enrichment_queue')
          .delete()
          .eq('user_id', userId)
          .eq('vocabulary_id', word.id);
      }

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
  // Get stem (use existing or the word itself for now, will be refined by AI)
  const stemForLookup = word.stem || word.word.toLowerCase().trim();
  const contentHash = await generateContentHash(stemForLookup);

  // Phase 1: Check if this word already exists in global_dictionary
  const { data: existingEntry } = await client
    .from('global_dictionary')
    .select('*')
    .eq('content_hash', contentHash)
    .single();

  if (existingEntry) {
    console.log(`[enrich-vocabulary] Found existing global_dictionary entry for "${word.word}"`);

    // Link vocabulary to this global_dictionary entry
    await client
      .from('vocabulary')
      .update({
        global_dictionary_id: existingEntry.id,
        stem: existingEntry.stem,
        updated_at: new Date().toISOString()
      })
      .eq('id', word.id);

    return {
      vocabulary_id: word.id,
      word: word.word,
      global_dictionary_id: existingEntry.id,
    };
  }

  // Phase 2: Get translation from DeepL or Google
  let translation: string | null = null;
  let translationSource: string = 'none';

  const deeplKey = Deno.env.get('DEEPL_API_KEY');
  if (deeplKey) {
    try {
      translation = await getDeepLTranslation(word.word, nativeLanguageCode, deeplKey);
      translationSource = 'deepl';
      console.log(`[enrich-vocabulary] Translation (DeepL) for "${word.word}": ${translation}`);
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
        console.log(`[enrich-vocabulary] Translation (Google) for "${word.word}": ${translation}`);
      } catch (err) {
        console.warn(`[enrich-vocabulary] Google Translate failed for "${word.word}":`, err);
      }
    }
  }

  if (!translation) {
    translation = word.word;
    translationSource = 'none';
    console.log(`[enrich-vocabulary] No translation service available for "${word.word}"`);
  }

  // Phase 3: Get AI enhancement from OpenAI
  let aiEnhancement: AIEnhancement | null = null;
  const openaiKey = Deno.env.get('OPENAI_API_KEY');
  if (!openaiKey) {
    console.error('[enrich-vocabulary] OpenAI API key not configured');
    return null;
  }

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

  // Phase 4: Write to global_dictionary with the AI-provided stem
  const finalStem = aiEnhancement.stem;
  const finalContentHash = await generateContentHash(finalStem);

  const globalDictId = crypto.randomUUID();
  const now = new Date().toISOString();

  // Build translations JSONB (keyed by language code)
  const translations: Record<string, any> = {
    [nativeLanguageCode]: {
      primary: translation,
      alternatives: aiEnhancement.native_alternatives || [],
      source: translationSource,
    }
  };

  // Build confusables JSONB
  const confusables = aiEnhancement.confusables.map(c => ({
    word: c.word,
    explanation: c.explanation,
    disambiguation_sentence: c.disambiguation_sentence,
  }));

  // Insert into global_dictionary with ON CONFLICT DO NOTHING
  const { data: insertedEntry, error: insertError } = await client
    .from('global_dictionary')
    .insert({
      id: globalDictId,
      word: finalStem,
      content_hash: finalContentHash,
      stem: finalStem,
      part_of_speech: aiEnhancement.part_of_speech,
      english_definition: aiEnhancement.english_definition,
      synonyms: aiEnhancement.synonyms,
      antonyms: aiEnhancement.antonyms,
      confusables,
      example_sentences: aiEnhancement.example_sentences,
      pronunciation_ipa: aiEnhancement.pronunciation_ipa,
      translations,
      cefr_level: aiEnhancement.cefr_level,
      confidence: aiEnhancement.confidence,
      created_at: now,
      updated_at: now,
    })
    .select()
    .single();

  // Handle conflict: another request may have inserted this word
  if (insertError) {
    if (insertError.code === '23505') { // Unique constraint violation
      console.log(`[enrich-vocabulary] Race condition detected, fetching existing entry for "${finalStem}"`);
      const { data: existingEntry } = await client
        .from('global_dictionary')
        .select('id')
        .eq('content_hash', finalContentHash)
        .single();

      if (existingEntry) {
        // Link vocabulary to this entry
        await client
          .from('vocabulary')
          .update({
            global_dictionary_id: existingEntry.id,
            stem: finalStem,
            updated_at: new Date().toISOString()
          })
          .eq('id', word.id);

        return {
          vocabulary_id: word.id,
          word: word.word,
          global_dictionary_id: existingEntry.id,
        };
      }
    }
    console.error(`[enrich-vocabulary] Failed to insert global_dictionary entry:`, insertError);
    return null;
  }

  // Phase 5: Link vocabulary to global_dictionary
  await client
    .from('vocabulary')
    .update({
      global_dictionary_id: globalDictId,
      stem: finalStem,
      updated_at: now
    })
    .eq('id', word.id);

  console.log(`[enrich-vocabulary] Successfully enriched "${word.word}" → global_dictionary ${globalDictId}`);

  return {
    vocabulary_id: word.id,
    word: word.word,
    global_dictionary_id: globalDictId,
  };
}

// =============================================================================
// Phase 1: Translation Services
// =============================================================================


// =============================================================================
// Phase 2: OpenAI Enhancement (definition, synonyms, confusables ONLY)
// =============================================================================

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
  }>;
  example_sentences: ClozeText[];
  pronunciation_ipa: string;
  cefr_level: string | null;
  confidence: number;
  native_alternatives: string[];
}

async function getOpenAIEnhancement(
  word: VocabWord,
  context: string | null,
  apiKey: string,
  primaryTranslation: string,
  nativeLanguageCode: string,
): Promise<AIEnhancement | null> {
  // Map language codes to full names
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
  - disambiguation_sentence: object with { "sentence": "full sentence", "before": "text before blank", "blank": "the target word", "after": "text after blank" }
- example_sentences: array of 2-3 objects, each with { "sentence": "full sentence", "before": "text before blank", "blank": "word form used", "after": "text after blank" }
- pronunciation_ipa: IPA pronunciation (e.g., /ˈwɜːrd/)
- cefr_level: A1/A2/B1/B2/C1/C2 or null if uncertain
- confidence: 0.0-1.0 indicating overall confidence
- native_alternatives: 2-4 alternative ${langName} translations (synonyms/near-synonyms in ${langName}, NOT "${primaryTranslation}", no trivial inflections like plural forms, no duplicates). If no good alternatives exist, return empty array [].

IMPORTANT for example_sentences and disambiguation_sentence:
- Each sentence should demonstrate the target word in context
- Split the sentence into "before", "blank" (the word), and "after" parts
- The "sentence" field should contain the complete sentence for reference
- Example: For "ubiquitous" → { "sentence": "Wi-Fi has become so ubiquitous.", "before": "Wi-Fi has become so ", "blank": "ubiquitous", "after": "." }

Word: ${word.word}
Stem: ${word.stem || word.word}
Context: ${context || 'none'}
Primary ${langName} translation: ${primaryTranslation}`;

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
    stem: parsed.stem || word.word,
    english_definition: parsed.english_definition || '',
    synonyms: parsed.synonyms || [],
    antonyms: parsed.antonyms || [],
    part_of_speech: parsed.part_of_speech || null,
    confusables: parsed.confusables || [],
    example_sentences: parsed.example_sentences || [],
    pronunciation_ipa: parsed.pronunciation_ipa || '',
    cefr_level: parsed.cefr_level || null,
    confidence: parsed.confidence || 0.9,
    native_alternatives: Array.isArray(parsed.native_alternatives)
      ? parsed.native_alternatives.filter((a: string) => a && typeof a === 'string')
      : [],
  };
}

// =============================================================================
// Utilities
// =============================================================================


// =============================================================================
// Safeguards: Prevent duplicate API calls
// =============================================================================

async function checkExistingMeaning(
  client: ReturnType<typeof createServiceClient>,
  userId: string,
  vocabularyId: string,
): Promise<boolean> {
  const { data } = await client
    .from('vocabulary')
    .select('global_dictionary_id')
    .eq('id', vocabularyId)
    .single();

  return data?.global_dictionary_id !== null;
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
  // Get vocabulary that doesn't have global_dictionary_id set
  const { data: allVocab, error } = await client
    .from('vocabulary')
    .select('id, word, stem')
    .eq('user_id', userId)
    .is('global_dictionary_id', null)
    .is('deleted_at', null)
    .order('created_at', { ascending: true })
    .limit(limit);

  if (error || !allVocab) return [];

  return allVocab;
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
  // Count vocabulary with global_dictionary_id
  const { count: enrichedCount } = await client
    .from('vocabulary')
    .select('id', { count: 'exact', head: true })
    .eq('user_id', userId)
    .not('global_dictionary_id', 'is', null)
    .is('deleted_at', null);

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
    enriched_count: enrichedCount || 0,
    un_enriched_count: (totalCount || 0) - (enrichedCount || 0),
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

interface EnrichedWord {
  vocabulary_id: string;
  word: string;
  global_dictionary_id: string;
}

interface FailedWord {
  vocabulary_id: string;
  error: string;
  will_retry: boolean;
}
