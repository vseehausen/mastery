// Edge function: lookup-word
// Two routes: POST /lookup-word for word lookups, GET /lookup-word/batch-status for statistics

import { handleCors } from '../_shared/cors.ts';
import { createSupabaseClient, getUserId } from '../_shared/supabase.ts';
import type { SupabaseClient } from '../_shared/supabase.ts';
import { jsonResponse, errorResponse, unauthorizedResponse } from '../_shared/response.ts';
import { getDeepLTranslation, getGoogleTranslation } from '../_shared/translation.ts';
import { generateContentHash, extractDomain } from '../_shared/crypto.ts';
import { mapCardToStage } from '../_shared/stage.ts';

const DEFAULT_NATIVE_LANG = 'de';
const SUPPORTED_LANGS = new Set(['de', 'es', 'fr', 'it', 'pt', 'nl', 'pl', 'ru', 'ja', 'zh', 'ko']);

// =============================================================================
// Types
// =============================================================================

interface LookupRequest {
  raw_word: string;
  sentence: string;
  url: string;
  title: string;
  native_lang?: string;
}

interface LookupResponse {
  lemma: string;
  raw_word: string;
  translation: string;
  pronunciation: string;
  part_of_speech: string;
  english_definition: string;
  context_original: string;
  context_translated: string;
  stage: string;
  is_new: boolean;
  vocabulary_id: string;
}

interface GlobalDictRow {
  id: string;
  stem: string;
  translations: Record<string, { primary?: string }> | null;
  pronunciation_ipa: string | null;
  part_of_speech: string | null;
  english_definition: string | null;
}

type ResolveResult =
  | { type: 'existing_user_vocab'; vocabularyId: string; globalDict: GlobalDictRow }
  | { type: 'existing_different_form'; vocabularyId: string; globalDict: GlobalDictRow }
  | { type: 'new_from_global_dict'; globalDict: GlobalDictRow }
  | { type: 'new_unknown' };

/** PGRST116 = "The result contains 0 rows" — expected for .single() with no match. */
function isNotFoundError(error: { code?: string } | null): boolean {
  return error?.code === 'PGRST116';
}

// =============================================================================
// Main Handler
// =============================================================================

Deno.serve(async (req) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  const userId = await getUserId(req);
  if (!userId) return unauthorizedResponse();

  const url = new URL(req.url);
  const pathSegments = url.pathname.split('/').filter(Boolean);

  try {
    if (req.method === 'POST') {
      return await handleLookup(req, userId);
    } else if (req.method === 'GET' && pathSegments[pathSegments.length - 1] === 'batch-status') {
      return await handleBatchStatus(req, userId);
    }
    return errorResponse('Not found', 404);
  } catch (err) {
    console.error('lookup-word error:', err);
    return errorResponse(
      err instanceof Error ? `${err.message} (${err.name})` : 'Internal server error',
      500
    );
  }
});

// =============================================================================
// POST /lookup-word — Word Lookup
// =============================================================================

async function handleLookup(req: Request, userId: string): Promise<Response> {
  let body: LookupRequest;
  try {
    body = await req.json();
  } catch {
    return errorResponse('Invalid JSON body', 400);
  }

  const validationError = validateLookupRequest(body);
  if (validationError) return validationError;

  const { raw_word, sentence, url, title } = body;
  const nativeLang = body.native_lang || DEFAULT_NATIVE_LANG;
  if (!SUPPORTED_LANGS.has(nativeLang)) {
    return errorResponse(`Unsupported language: ${nativeLang}`, 400);
  }
  const client = createSupabaseClient(req);
  const estimatedLemma = raw_word.toLowerCase().trim();
  const estimatedHash = await generateContentHash(estimatedLemma);

  const resolved = await resolveWord(client, userId, estimatedHash);

  // Existing word — record encounter and return
  if (resolved.type === 'existing_user_vocab' || resolved.type === 'existing_different_form') {
    await createEncounter(client, resolved.vocabularyId, userId, url, title, sentence);
    const stage = await getVocabularyStage(client, resolved.vocabularyId, userId);
    return jsonResponse(buildLookupResponse({
      globalDict: resolved.globalDict, raw_word, sentence, stage, nativeLang,
      is_new: false, vocabulary_id: resolved.vocabularyId,
    }));
  }

  // New word — create vocab + card + encounter (non-atomic; each step is idempotent for retries)
  const globalDict = resolved.type === 'new_from_global_dict' ? resolved.globalDict : null;
  let translation: string | null = null;
  let lemma = estimatedLemma;
  let contentHash = estimatedHash;

  if (globalDict) {
    lemma = globalDict.stem;
    contentHash = await generateContentHash(lemma);
  } else {
    translation = await getTranslation(raw_word, nativeLang);
    if (!translation) return errorResponse('Translation service unavailable', 503);
  }

  const { outcome, vocabularyId } = await findOrCreateVocabulary(
    client, userId, raw_word, lemma, contentHash, globalDict?.id ?? null
  );

  if (outcome === 'created') {
    await createLearningCard(client, userId, vocabularyId);
  }

  await createEncounter(client, vocabularyId, userId, url, title, sentence);

  if (!globalDict) {
    await queueEnrichment(client, userId, vocabularyId, nativeLang);
  }

  const stage = outcome === 'created' ? 'new' : await getVocabularyStage(client, vocabularyId, userId);

  return jsonResponse(buildLookupResponse({
    globalDict, raw_word, sentence, stage, nativeLang,
    is_new: outcome === 'created',
    vocabulary_id: vocabularyId,
    fallbackLemma: lemma,
    fallbackTranslation: translation,
  }));
}

// =============================================================================
// Validation
// =============================================================================

function validateLookupRequest(body: LookupRequest): Response | null {
  const { raw_word, sentence, url, title } = body;

  if (!raw_word || typeof raw_word !== 'string' || raw_word.length === 0)
    return errorResponse('raw_word is required', 400);
  if (raw_word.length > 100)
    return errorResponse('raw_word must be max 100 characters', 400);
  if (!sentence || typeof sentence !== 'string' || sentence.length === 0)
    return errorResponse('sentence is required', 400);
  if (sentence.length > 500)
    return errorResponse('sentence must be max 500 characters', 400);
  if (!url || typeof url !== 'string')
    return errorResponse('url is required', 400);
  if (!title || typeof title !== 'string')
    return errorResponse('title is required', 400);

  return null;
}

// =============================================================================
// Word Resolution
// =============================================================================

async function resolveWord(client: SupabaseClient, userId: string, contentHash: string): Promise<ResolveResult> {
  // Check user's vocabulary by content_hash
  const { data: existingVocab, error: vocabErr } = await client
    .from('vocabulary')
    .select('id, stem, global_dictionary_id')
    .eq('user_id', userId)
    .eq('content_hash', contentHash)
    .is('deleted_at', null)
    .single();

  if (vocabErr && !isNotFoundError(vocabErr)) {
    throw new Error(`Failed to check vocabulary: ${vocabErr.message}`);
  }

  if (existingVocab?.global_dictionary_id) {
    const { data: globalDict, error: gdErr } = await client
      .from('global_dictionary')
      .select('id, stem, translations, pronunciation_ipa, part_of_speech, english_definition')
      .eq('id', existingVocab.global_dictionary_id)
      .single();

    if (gdErr && !isNotFoundError(gdErr)) {
      throw new Error(`Failed to fetch global dictionary: ${gdErr.message}`);
    }

    if (globalDict) {
      return { type: 'existing_user_vocab', vocabularyId: existingVocab.id, globalDict };
    }
  }

  // Check global_dictionary by content_hash
  const { data: globalDictEntry, error: gdCheckErr } = await client
    .from('global_dictionary')
    .select('id, stem, translations, pronunciation_ipa, part_of_speech, english_definition')
    .eq('content_hash', contentHash)
    .single();

  if (gdCheckErr && !isNotFoundError(gdCheckErr)) {
    throw new Error(`Failed to check global dictionary: ${gdCheckErr.message}`);
  }

  if (globalDictEntry) {
    const { data: userVocabForDict, error: uvErr } = await client
      .from('vocabulary')
      .select('id')
      .eq('user_id', userId)
      .eq('global_dictionary_id', globalDictEntry.id)
      .is('deleted_at', null)
      .single();

    if (uvErr && !isNotFoundError(uvErr)) {
      throw new Error(`Failed to check user vocabulary: ${uvErr.message}`);
    }

    if (userVocabForDict) {
      return { type: 'existing_different_form', vocabularyId: userVocabForDict.id, globalDict: globalDictEntry };
    }
    return { type: 'new_from_global_dict', globalDict: globalDictEntry };
  }

  return { type: 'new_unknown' };
}

// =============================================================================
// Vocabulary Creation
// =============================================================================

async function findOrCreateVocabulary(
  client: SupabaseClient,
  userId: string,
  raw_word: string,
  stem: string,
  contentHash: string,
  globalDictionaryId: string | null,
): Promise<{ outcome: 'created' | 'existing'; vocabularyId: string }> {
  const vocabularyId = crypto.randomUUID();
  const now = new Date().toISOString();

  const { error } = await client.from('vocabulary').insert({
    id: vocabularyId,
    user_id: userId,
    word: raw_word,
    stem,
    content_hash: contentHash,
    global_dictionary_id: globalDictionaryId,
    created_at: now,
    updated_at: now,
  });

  if (!error) return { outcome: 'created', vocabularyId };

  if (error.code !== '23505') {
    throw new Error(`Failed to create vocabulary entry: ${error.message}`);
  }

  // Duplicate — resolve existing entry
  console.log(`[lookup-word] Duplicate vocabulary for "${raw_word}", resolving existing entry`);

  if (globalDictionaryId) {
    const { data: existing, error: updateError } = await client
      .from('vocabulary')
      .update({
        global_dictionary_id: globalDictionaryId,
        stem,
        updated_at: new Date().toISOString(),
      })
      .eq('user_id', userId)
      .eq('content_hash', contentHash)
      .is('deleted_at', null)
      .select('id')
      .single();

    if (updateError || !existing) {
      throw new Error(`Failed to link vocabulary to global_dictionary: ${updateError?.message || 'not found'}`);
    }
    return { outcome: 'existing', vocabularyId: existing.id };
  }

  const { data: existing, error: fetchError } = await client
    .from('vocabulary')
    .select('id')
    .eq('user_id', userId)
    .eq('content_hash', contentHash)
    .is('deleted_at', null)
    .single();

  if (fetchError || !existing) {
    throw new Error(`Failed to retrieve vocabulary entry: ${fetchError?.message || 'not found'}`);
  }
  return { outcome: 'existing', vocabularyId: existing.id };
}

// =============================================================================
// Learning Card Creation
// =============================================================================

async function createLearningCard(client: SupabaseClient, userId: string, vocabularyId: string): Promise<void> {
  const now = new Date().toISOString();
  const { error } = await client.from('learning_cards').insert({
    id: crypto.randomUUID(),
    user_id: userId,
    vocabulary_id: vocabularyId,
    state: 0,
    due: now,
    stability: 0,
    difficulty: 0,
    created_at: now,
    updated_at: now,
  });

  if (!error || error.code === '23505') return; // idempotent: ignore duplicate
  throw new Error(`Failed to create learning card: ${error.message}`);
}

// =============================================================================
// Encounter Creation
// =============================================================================

async function createEncounter(
  client: SupabaseClient,
  vocabularyId: string,
  userId: string,
  url: string,
  title: string,
  sentence: string,
): Promise<void> {
  const domain = extractDomain(url);
  const { data: existingSource, error: sourceErr } = await client
    .from('sources')
    .select('id')
    .eq('user_id', userId)
    .eq('type', 'website')
    .eq('url', url)
    .is('deleted_at', null)
    .single();

  if (sourceErr && !isNotFoundError(sourceErr)) {
    console.error('[lookup-word] source lookup failed:', sourceErr);
  }

  let sourceId: string;
  if (existingSource) {
    sourceId = existingSource.id;
  } else {
    sourceId = crypto.randomUUID();
    const now = new Date().toISOString();
    const { error: sourceError } = await client.from('sources').insert({
      id: sourceId,
      user_id: userId,
      type: 'website',
      title,
      url,
      domain,
      created_at: now,
      updated_at: now,
    });

    if (sourceError) {
      throw new Error('Failed to create source');
    }
  }

  const { error: encounterError } = await client.from('encounters').insert({
    id: crypto.randomUUID(),
    user_id: userId,
    vocabulary_id: vocabularyId,
    source_id: sourceId,
    context: sentence,
    occurred_at: new Date().toISOString(),
    created_at: new Date().toISOString(),
  });

  if (encounterError) {
    throw new Error('Failed to create encounter');
  }
}

// =============================================================================
// Stage Mapping
// =============================================================================

async function getVocabularyStage(client: SupabaseClient, vocabularyId: string, userId: string): Promise<string> {
  const { data: card, error } = await client
    .from('learning_cards')
    .select('state, stability')
    .eq('user_id', userId)
    .eq('vocabulary_id', vocabularyId)
    .is('deleted_at', null)
    .single();

  if (error && !isNotFoundError(error)) {
    console.error('[lookup-word] getVocabularyStage failed:', error);
  }

  return mapCardToStage(card);
}

// =============================================================================
// Translation
// =============================================================================

async function getTranslation(word: string, nativeLang: string): Promise<string | null> {
  const DEEPL_API_KEY = Deno.env.get('DEEPL_API_KEY');
  const GOOGLE_TRANSLATE_API_KEY = Deno.env.get('GOOGLE_TRANSLATE_API_KEY');

  if (DEEPL_API_KEY) {
    try {
      return await getDeepLTranslation(word, nativeLang, DEEPL_API_KEY);
    } catch (err) {
      console.warn('[lookup-word] DeepL failed:', err);
    }
  }

  if (GOOGLE_TRANSLATE_API_KEY) {
    try {
      return await getGoogleTranslation(word, nativeLang, GOOGLE_TRANSLATE_API_KEY);
    } catch (err) {
      console.warn('[lookup-word] Google Translate failed:', err);
    }
  }

  return null;
}

// =============================================================================
// Enrichment Queue
// =============================================================================

async function queueEnrichment(
  client: SupabaseClient, userId: string, vocabularyId: string, nativeLang: string,
): Promise<void> {
  const { error } = await client.from('enrichment_queue').upsert({
    user_id: userId,
    vocabulary_id: vocabularyId,
    status: 'pending',
  }, { onConflict: 'user_id,vocabulary_id' });

  if (error) {
    console.warn('Failed to queue enrichment (non-fatal):', error);
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (supabaseUrl && serviceRoleKey) {
    fetch(`${supabaseUrl}/functions/v1/enrich-vocabulary/request`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${serviceRoleKey}`,
      },
      body: JSON.stringify({
        native_language_code: nativeLang,
        vocabulary_ids: [vocabularyId],
        batch_size: 1,
      }),
    }).catch(err => console.warn('[lookup-word] Failed to trigger enrichment:', err.message));
  }
}

// =============================================================================
// Response Building
// =============================================================================

function buildLookupResponse(params: {
  globalDict: GlobalDictRow | null;
  raw_word: string;
  sentence: string;
  stage: string;
  is_new: boolean;
  vocabulary_id: string;
  nativeLang: string;
  fallbackLemma?: string;
  fallbackTranslation?: string | null;
}): LookupResponse {
  const { globalDict, raw_word, sentence, stage, is_new, vocabulary_id, nativeLang } = params;

  if (globalDict) {
    const translations = globalDict.translations?.[nativeLang];
    return {
      lemma: globalDict.stem,
      raw_word,
      translation: translations?.primary || raw_word,
      pronunciation: globalDict.pronunciation_ipa || '',
      part_of_speech: globalDict.part_of_speech || '',
      english_definition: globalDict.english_definition || '',
      context_original: sentence,
      context_translated: '',
      stage,
      is_new,
      vocabulary_id,
    };
  }

  return {
    lemma: params.fallbackLemma || raw_word,
    raw_word,
    translation: params.fallbackTranslation || raw_word,
    pronunciation: '',
    part_of_speech: '',
    english_definition: '',
    context_original: sentence,
    context_translated: '',
    stage,
    is_new,
    vocabulary_id,
  };
}

// =============================================================================
// GET /lookup-word/batch-status — Statistics
// =============================================================================

async function handleBatchStatus(req: Request, userId: string): Promise<Response> {
  const url = new URL(req.url);
  const pageUrl = url.searchParams.get('url');
  const client = createSupabaseClient(req);

  const { count: totalCount, error: totalErr } = await client
    .from('vocabulary')
    .select('id', { count: 'exact', head: true })
    .eq('user_id', userId)
    .is('deleted_at', null);

  if (totalErr) {
    console.error('[lookup-word] batch-status total count failed:', totalErr);
  }

  let pageWords: Array<{ lemma: string; translation: string; stage: string }> = [];

  if (pageUrl) {
    // Resolve source first, then filter encounters by source_id (avoids full table scan)
    const { data: sources, error: srcErr } = await client
      .from('sources')
      .select('id')
      .eq('user_id', userId)
      .eq('url', pageUrl)
      .eq('type', 'website')
      .is('deleted_at', null);

    if (srcErr) {
      console.error('[lookup-word] batch-status source lookup failed:', srcErr);
    }

    if (sources && sources.length > 0) {
      const sourceIds = sources.map((s: { id: string }) => s.id);

      const { data: encounters, error: encErr } = await client
        .from('encounters')
        .select('vocabulary_id')
        .eq('user_id', userId)
        .in('source_id', sourceIds)
        .is('deleted_at', null);

      if (encErr) {
        console.error('[lookup-word] batch-status encounters failed:', encErr);
      }

      if (encounters && encounters.length > 0) {
        const vocabIds = [...new Set(encounters.map((e: { vocabulary_id: string }) => e.vocabulary_id))];

        const [vocabResult, meaningResult, cardResult] = await Promise.all([
          client.from('vocabulary').select('id, stem').in('id', vocabIds).is('deleted_at', null),
          client.from('meanings').select('vocabulary_id, primary_translation').eq('user_id', userId).in('vocabulary_id', vocabIds).is('deleted_at', null),
          client.from('learning_cards').select('vocabulary_id, state, stability').eq('user_id', userId).in('vocabulary_id', vocabIds).is('deleted_at', null),
        ]);

        if (vocabResult.error) console.error('[lookup-word] batch-status vocab query failed:', vocabResult.error);
        if (meaningResult.error) console.error('[lookup-word] batch-status meanings query failed:', meaningResult.error);
        if (cardResult.error) console.error('[lookup-word] batch-status cards query failed:', cardResult.error);

        const vocabMap = new Map(
          (vocabResult.data as Array<{ id: string; stem: string }> || []).map(v => [v.id, v.stem])
        );
        const meaningMap = new Map(
          (meaningResult.data as Array<{ vocabulary_id: string; primary_translation: string }> || []).map(m => [m.vocabulary_id, m.primary_translation])
        );
        const cardMap = new Map(
          (cardResult.data as Array<{ vocabulary_id: string; state: number; stability: number }> || []).map(c => [c.vocabulary_id, mapCardToStage(c)])
        );

        pageWords = vocabIds
          .filter(id => vocabMap.has(id))
          .map(vocabId => ({
            lemma: vocabMap.get(vocabId) || vocabId,
            translation: meaningMap.get(vocabId) || '',
            stage: cardMap.get(vocabId) || 'new',
          }));
      }
    }
  }

  return jsonResponse({
    total_words: totalCount || 0,
    page_words: pageWords,
  });
}
