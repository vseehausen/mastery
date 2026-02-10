// Edge function: lookup-word
// Two routes: POST /lookup-word for word lookups, GET /lookup-word/batch-status for statistics

import { handleCors } from '../_shared/cors.ts';
import { createSupabaseClient, getUserId } from '../_shared/supabase.ts';
import type { SupabaseClient } from '../_shared/supabase.ts';
import { jsonResponse, errorResponse, unauthorizedResponse } from '../_shared/response.ts';
import { extractDomain } from '../_shared/url.ts';
import { mapCardToStage } from '../_shared/stage.ts';
import { normalize } from '../_shared/normalize.ts';
import { resolveGlobalEntry, type GlobalDictEntry } from '../_shared/global-dictionary.ts';
import { ensureVocabularyIdentity, ensureLearningCard, triggerEnrichment } from '../_shared/vocabulary-lifecycle.ts';
import { translateWord } from '../_shared/translation.ts';

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
  if (!SUPPORTED_LANGS.has(nativeLang)) return errorResponse(`Unsupported language: ${nativeLang}`, 400);

  const client = createSupabaseClient(req);
  const normalized = normalize(raw_word);

  // Check if user already has this word
  const { data: existingVocab, error: vocabErr } = await client
    .from('vocabulary')
    .select('id, global_dictionary_id')
    .eq('user_id', userId)
    .eq('word', normalized)
    .is('deleted_at', null)
    .single();

  if (vocabErr && vocabErr.code !== 'PGRST116') {
    throw new Error(`Failed to check vocabulary: ${vocabErr.message}`);
  }

  if (existingVocab) {
    await createEncounter(client, existingVocab.id, userId, url, title, sentence);
    let globalDict: GlobalDictEntry | null = null;
    if (existingVocab.global_dictionary_id) {
      const { data: gd } = await client
        .from('global_dictionary')
        .select('id, lemma, translations, pronunciation_ipa, part_of_speech, english_definition')
        .eq('id', existingVocab.global_dictionary_id)
        .single();
      globalDict = gd;
    }
    const stage = await getVocabularyStage(client, existingVocab.id, userId);
    return jsonResponse(buildLookupResponse({
      globalDict, raw_word, sentence, stage, nativeLang,
      is_new: false, vocabulary_id: existingVocab.id,
    }));
  }

  // New word
  const globalEntry = await resolveGlobalEntry(client, raw_word, 'en');
  const { vocabularyId, isNew } = await ensureVocabularyIdentity(client, userId, raw_word, globalEntry?.id);
  if (isNew) await ensureLearningCard(client, userId, vocabularyId);
  await createEncounter(client, vocabularyId, userId, url, title, sentence);

  if (!globalEntry) {
    const { translation } = await translateWord(raw_word, nativeLang);
    triggerEnrichment(userId, [vocabularyId], nativeLang);
    const stage = isNew ? 'new' : await getVocabularyStage(client, vocabularyId, userId);
    return jsonResponse(buildLookupResponse({
      globalDict: null, raw_word, sentence, stage, nativeLang,
      is_new: isNew, vocabulary_id: vocabularyId,
      fallbackLemma: normalized,
      fallbackTranslation: translation,
    }));
  }

  const stage = isNew ? 'new' : await getVocabularyStage(client, vocabularyId, userId);
  return jsonResponse(buildLookupResponse({
    globalDict: globalEntry, raw_word, sentence, stage, nativeLang,
    is_new: isNew, vocabulary_id: vocabularyId,
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
// Response Building
// =============================================================================

function buildLookupResponse(params: {
  globalDict: GlobalDictEntry | null;
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
      lemma: globalDict.lemma,
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

        const [vocabResult, cardResult] = await Promise.all([
          client.from('vocabulary').select('id, word, global_dictionary_id').in('id', vocabIds).is('deleted_at', null),
          client.from('learning_cards').select('vocabulary_id, state, stability').eq('user_id', userId).in('vocabulary_id', vocabIds).is('deleted_at', null),
        ]);

        if (vocabResult.error) console.error('[lookup-word] batch-status vocab query failed:', vocabResult.error);
        if (cardResult.error) console.error('[lookup-word] batch-status cards query failed:', cardResult.error);

        const vocabMap = new Map<string, { word: string; globalDictId: string | null }>(
          (vocabResult.data || []).map((v: { id: string; word: string; global_dictionary_id: string | null }) =>
            [v.id, { word: v.word, globalDictId: v.global_dictionary_id }])
        );

        // Fetch translations from global_dictionary
        const globalDictIds = [...new Set(
          (vocabResult.data || [])
            .filter((v: { global_dictionary_id: string | null }) => v.global_dictionary_id)
            .map((v: { global_dictionary_id: string }) => v.global_dictionary_id)
        )];

        const translationMap = new Map<string, { lemma: string; translation: string }>();
        if (globalDictIds.length > 0) {
          const { data: gdEntries } = await client
            .from('global_dictionary')
            .select('id, lemma, translations')
            .in('id', globalDictIds);

          for (const gd of (gdEntries || [])) {
            const primary = gd.translations?.de?.primary;
            translationMap.set(gd.id, { lemma: gd.lemma, translation: primary || '' });
          }
        }

        const cardMap = new Map(
          (cardResult.data || []).map((c: { vocabulary_id: string; state: number; stability: number }) => [c.vocabulary_id, mapCardToStage(c)])
        );

        pageWords = vocabIds
          .filter(id => vocabMap.has(id))
          .map(vocabId => {
            const vocab = vocabMap.get(vocabId)!;
            const gdInfo = vocab.globalDictId ? translationMap.get(vocab.globalDictId) : null;
            return {
              lemma: gdInfo?.lemma || vocab.word || vocabId,
              translation: gdInfo?.translation || '',
              stage: cardMap.get(vocabId) || 'new',
            };
          });
      }
    }
  }

  return jsonResponse({
    total_words: totalCount || 0,
    page_words: pageWords,
  });
}
