// Edge function: enrich-vocabulary
// Enriches vocabulary words and writes to global_dictionary table
// Phase 1: Check if word exists in global_dictionary by content_hash
// Phase 2: If not, call OpenAI to generate full enrichment data
// Phase 3: Write to global_dictionary with ON CONFLICT DO NOTHING
// Phase 4: Link vocabulary to global_dictionary_id

import { handleCors } from '../_shared/cors.ts';
import { createServiceClient, getUserId, type SupabaseClient } from '../_shared/supabase.ts';
import { jsonResponse, errorResponse, unauthorizedResponse } from '../_shared/response.ts';
import { getDeepLTranslation, getGoogleTranslation } from '../_shared/translation.ts';
import { generateContentHash } from '../_shared/crypto.ts';

const MAX_BATCH_SIZE = 10;
const DEFAULT_BATCH_SIZE = 5;
const MAX_RETRY_ATTEMPTS = 3;
const BUFFER_TARGET = 10;
const STALE_PROCESSING_TIMEOUT_MINUTES = 5;

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
  will_retry?: boolean;
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
  }>;
  example_sentences: ClozeText[];
  pronunciation_ipa: string;
  cefr_level: string | null;
  confidence: number;
  native_alternatives: string[];
}

interface TranslationEntry {
  primary: string;
  alternatives: string[];
  source: string;
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

  const wordContexts = await getEncounterContexts(client, userId, wordsToEnrich);
  const result = await processWords(client, userId, wordsToEnrich, nativeLanguageCode, wordContexts, false);

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

  await resetStaleProcessingEntries(client, userId);

  let wordsToEnrich: VocabWord[];

  if (vocabularyIds && vocabularyIds.length > 0) {
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
    wordsToEnrich = await getUnEnrichedWords(client, userId, batchSize);
  }

  console.log(`[enrich-vocabulary] Enriching ${wordsToEnrich.length} words for user=${userId}, language=${nativeLanguageCode}`);

  const wordContexts = await getEncounterContexts(client, userId, wordsToEnrich);
  const result = await processWords(client, userId, wordsToEnrich, nativeLanguageCode, wordContexts, forceReEnrich);

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
// Shared word processing loop
// =============================================================================

async function processWords(
  client: SupabaseClient,
  userId: string,
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
      if (!forceReEnrich) {
        const alreadyEnriched = await checkExistingMeaning(client, word.id);
        if (alreadyEnriched) {
          console.log(`[enrich-vocabulary] Skipping "${word.word}" - already has meaning`);
          skipped.push(word.id);
          await updateQueueStatus(client, userId, word.id, 'completed');
          continue;
        }
      }

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

      const context = wordContexts[word.id] || null;
      const result = await enrichWord(word, nativeLanguageCode, context, client);

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
      console.error(`[enrich-vocabulary] ✗ Exception for "${word.word}":`, err);
      failed.push({ vocabulary_id: word.id, error: errorMsg, will_retry: true });
      await incrementQueueAttempt(client, userId, word.id, errorMsg);
    }
  }

  return { enriched, failed, skipped };
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
  client: SupabaseClient,
): Promise<EnrichedWord | null> {
  const stemForLookup = word.stem || word.word.toLowerCase().trim();
  const contentHash = await generateContentHash(stemForLookup);

  // Check global_dictionary for existing entry
  const { data: existingEntry, error: lookupError } = await client
    .from('global_dictionary')
    .select('id, stem')
    .eq('content_hash', contentHash)
    .single();

  if (lookupError && lookupError.code !== 'PGRST116') {
    console.error('[enrich-vocabulary] global_dictionary lookup failed:', lookupError);
    return null;
  }

  if (existingEntry) {
    console.log(`[enrich-vocabulary] Found existing global_dictionary entry for "${word.word}"`);
    await linkVocabularyToGlobalDict(client, word.id, existingEntry.id, existingEntry.stem);
    return { vocabulary_id: word.id, word: word.word, global_dictionary_id: existingEntry.id };
  }

  // Translation: DeepL → Google → fallback
  const { translation, source: translationSource } = await getTranslation(word.word, nativeLanguageCode);

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

  // Write to global_dictionary
  const finalStem = aiEnhancement.stem;
  const finalContentHash = await generateContentHash(finalStem);
  const globalDictId = crypto.randomUUID();
  const now = new Date().toISOString();

  const translations: Record<string, TranslationEntry> = {
    [nativeLanguageCode]: {
      primary: translation,
      alternatives: aiEnhancement.native_alternatives || [],
      source: translationSource,
    }
  };

  const { error: insertError } = await client
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
      confusables: aiEnhancement.confusables.map(c => ({
        word: c.word,
        explanation: c.explanation,
        disambiguation_sentence: c.disambiguation_sentence,
      })),
      example_sentences: aiEnhancement.example_sentences,
      pronunciation_ipa: aiEnhancement.pronunciation_ipa,
      translations,
      cefr_level: aiEnhancement.cefr_level,
      confidence: aiEnhancement.confidence,
      created_at: now,
      updated_at: now,
    })
    .select('id')
    .single();

  if (insertError) {
    if (insertError.code === '23505') {
      // Race condition: another request inserted this word concurrently
      console.log(`[enrich-vocabulary] Race condition detected, fetching existing entry for "${finalStem}"`);
      const { data: raceEntry, error: raceError } = await client
        .from('global_dictionary')
        .select('id')
        .eq('content_hash', finalContentHash)
        .single();

      if (raceError || !raceEntry) {
        console.error('[enrich-vocabulary] Failed to fetch race-condition entry:', raceError);
        return null;
      }

      await linkVocabularyToGlobalDict(client, word.id, raceEntry.id, finalStem);
      return { vocabulary_id: word.id, word: word.word, global_dictionary_id: raceEntry.id };
    }
    console.error('[enrich-vocabulary] Failed to insert global_dictionary entry:', insertError);
    return null;
  }

  await linkVocabularyToGlobalDict(client, word.id, globalDictId, finalStem);
  console.log(`[enrich-vocabulary] Successfully enriched "${word.word}" → global_dictionary ${globalDictId}`);

  return { vocabulary_id: word.id, word: word.word, global_dictionary_id: globalDictId };
}

// =============================================================================
// Translation: DeepL → Google → fallback
// =============================================================================

async function getTranslation(
  word: string,
  nativeLanguageCode: string,
): Promise<{ translation: string; source: string }> {
  const deeplKey = Deno.env.get('DEEPL_API_KEY');
  if (deeplKey) {
    try {
      const t = await getDeepLTranslation(word, nativeLanguageCode, deeplKey);
      if (t) {
        console.log(`[enrich-vocabulary] Translation (DeepL) for "${word}": ${t}`);
        return { translation: t, source: 'deepl' };
      }
    } catch (err) {
      console.warn(`[enrich-vocabulary] DeepL failed for "${word}":`, err);
    }
  }

  const googleKey = Deno.env.get('GOOGLE_TRANSLATE_API_KEY');
  if (googleKey) {
    try {
      const t = await getGoogleTranslation(word, nativeLanguageCode, googleKey);
      if (t) {
        console.log(`[enrich-vocabulary] Translation (Google) for "${word}": ${t}`);
        return { translation: t, source: 'google' };
      }
    } catch (err) {
      console.warn(`[enrich-vocabulary] Google Translate failed for "${word}":`, err);
    }
  }

  console.log(`[enrich-vocabulary] No translation service available for "${word}"`);
  return { translation: word, source: 'none' };
}

// =============================================================================
// OpenAI Enhancement
// =============================================================================

async function getOpenAIEnhancement(
  word: VocabWord,
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
      max_tokens: 1000,
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
// Shared DB helpers
// =============================================================================

async function linkVocabularyToGlobalDict(
  client: SupabaseClient,
  vocabularyId: string,
  globalDictId: string,
  stem: string,
): Promise<void> {
  const { error } = await client
    .from('vocabulary')
    .update({
      global_dictionary_id: globalDictId,
      stem,
      updated_at: new Date().toISOString(),
    })
    .eq('id', vocabularyId);

  if (error) {
    console.error(`[enrich-vocabulary] Failed to link vocabulary ${vocabularyId}:`, error);
  }
}

async function checkExistingMeaning(
  client: SupabaseClient,
  vocabularyId: string,
): Promise<boolean> {
  const { data, error } = await client
    .from('vocabulary')
    .select('global_dictionary_id')
    .eq('id', vocabularyId)
    .single();

  if (error) {
    console.error(`[enrich-vocabulary] checkExistingMeaning query failed:`, error);
    return false;
  }

  return data?.global_dictionary_id !== null;
}

async function tryClaimWord(
  client: SupabaseClient,
  userId: string,
  vocabularyId: string,
): Promise<boolean> {
  const { data: existing, error: selectError } = await client
    .from('enrichment_queue')
    .select('status')
    .eq('user_id', userId)
    .eq('vocabulary_id', vocabularyId)
    .single();

  if (selectError && selectError.code !== 'PGRST116') {
    console.error('[enrich-vocabulary] tryClaimWord select failed:', selectError);
    return false;
  }

  if (existing?.status === 'completed' || existing?.status === 'processing') {
    return false;
  }

  const { error } = await client.from('enrichment_queue').upsert({
    user_id: userId,
    vocabulary_id: vocabularyId,
    status: 'processing',
    last_attempted_at: new Date().toISOString(),
  }, { onConflict: 'user_id,vocabulary_id' });

  if (error) {
    console.error('[enrich-vocabulary] tryClaimWord upsert failed:', error);
    return false;
  }

  return true;
}

async function resetStaleProcessingEntries(
  client: SupabaseClient,
  userId: string,
): Promise<void> {
  const staleThreshold = new Date(Date.now() - STALE_PROCESSING_TIMEOUT_MINUTES * 60 * 1000).toISOString();

  const { error } = await client
    .from('enrichment_queue')
    .update({
      status: 'pending',
      last_error: 'Processing timeout - will retry',
    })
    .eq('user_id', userId)
    .eq('status', 'processing')
    .lt('last_attempted_at', staleThreshold);

  if (error) {
    console.error('[enrich-vocabulary] Failed to reset stale entries:', error);
  }
}

async function updateQueueStatus(
  client: SupabaseClient,
  userId: string,
  vocabularyId: string,
  status: string,
): Promise<void> {
  const now = new Date().toISOString();
  const { error } = await client.from('enrichment_queue').upsert({
    user_id: userId,
    vocabulary_id: vocabularyId,
    status,
    ...(status === 'completed' ? { completed_at: now } : {}),
  }, { onConflict: 'user_id,vocabulary_id' });

  if (error) {
    console.error('[enrich-vocabulary] updateQueueStatus failed:', error);
  }
}

async function incrementQueueAttempt(
  client: SupabaseClient,
  userId: string,
  vocabularyId: string,
  errorMsg: string,
): Promise<void> {
  const { data: existing, error: selectError } = await client
    .from('enrichment_queue')
    .select('id, attempts')
    .eq('user_id', userId)
    .eq('vocabulary_id', vocabularyId)
    .single();

  if (selectError && selectError.code !== 'PGRST116') {
    console.error('[enrich-vocabulary] incrementQueueAttempt select failed:', selectError);
  }

  const attempts = (existing?.attempts || 0) + 1;
  const status = attempts >= MAX_RETRY_ATTEMPTS ? 'failed' : 'pending';

  const { error } = await client.from('enrichment_queue').upsert({
    user_id: userId,
    vocabulary_id: vocabularyId,
    status,
    attempts,
    last_error: errorMsg,
    last_attempted_at: new Date().toISOString(),
  }, { onConflict: 'user_id,vocabulary_id' });

  if (error) {
    console.error('[enrich-vocabulary] incrementQueueAttempt upsert failed:', error);
  }
}

async function getUnEnrichedWords(
  client: SupabaseClient,
  userId: string,
  limit: number,
): Promise<VocabWord[]> {
  const { data, error } = await client
    .from('vocabulary')
    .select('id, word, stem')
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
  const [enrichedRes, totalRes, pendingRes] = await Promise.all([
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
    client
      .from('enrichment_queue')
      .select('id', { count: 'exact', head: true })
      .eq('user_id', userId)
      .in('status', ['pending', 'processing']),
  ]);

  return {
    enriched_count: enrichedRes.count || 0,
    un_enriched_count: (totalRes.count || 0) - (enrichedRes.count || 0),
    buffer_target: BUFFER_TARGET,
    pending_in_queue: pendingRes.count || 0,
  };
}
