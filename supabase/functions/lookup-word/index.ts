// Edge function: lookup-word
// Handles word lookups from browser extension with OpenAI enrichment
// Two routes: POST /lookup-word for word lookups, GET /lookup-word/batch-status for statistics

import { handleCors } from '../_shared/cors.ts';
import { createServiceClient, getUserId } from '../_shared/supabase.ts';
import { jsonResponse, errorResponse, unauthorizedResponse } from '../_shared/response.ts';
import { getDeepLTranslation, getGoogleTranslation } from '../_shared/translation.ts';

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

  // Determine which handler based on path and method
  // POST /lookup-word or POST / routes to handleLookup
  // GET /lookup-word/batch-status routes to handleBatchStatus

  try {
    if (req.method === 'POST') {
      return await handleLookup(req, userId);
    } else if (req.method === 'GET' && pathSegments[pathSegments.length - 1] === 'batch-status') {
      return await handleBatchStatus(req, userId);
    }
    return errorResponse('Not found', 404);
  } catch (err) {
    console.error('lookup-word error:', err);
    return errorResponse(err instanceof Error ? err.message : 'Internal server error', 500);
  }
});

// =============================================================================
// POST /lookup-word — Word Lookup
// =============================================================================

interface LookupRequest {
  raw_word: string;
  sentence: string;
  url: string;
  title: string;
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

async function handleLookup(req: Request, userId: string): Promise<Response> {
  const startTime = Date.now();
  const body: LookupRequest = await req.json();

  // Validate request body
  const { raw_word, sentence, url, title } = body;

  if (!raw_word || typeof raw_word !== 'string' || raw_word.length === 0) {
    return errorResponse('raw_word is required', 400);
  }
  if (raw_word.length > 100) {
    return errorResponse('raw_word must be max 100 characters', 400);
  }

  if (!sentence || typeof sentence !== 'string' || sentence.length === 0) {
    return errorResponse('sentence is required', 400);
  }
  if (sentence.length > 500) {
    return errorResponse('sentence must be max 500 characters', 400);
  }

  if (!url || typeof url !== 'string') {
    return errorResponse('url is required', 400);
  }

  if (!title || typeof title !== 'string') {
    return errorResponse('title is required', 400);
  }

  console.log(JSON.stringify({ event: 'lookup_start', word: raw_word, userId }));

  const client = createServiceClient();

  try {
    // OPTIMIZATION: Check if word exists BEFORE calling OpenAI
    // This makes lookups for existing words instant (~100ms vs 5-10s)

    // First, get a quick lemma estimate (just normalize the word)
    const estimatedLemma = raw_word.toLowerCase().trim();
    const estimatedHash = await generateContentHash(estimatedLemma);

    // Check if we already have this word
    const dbCheckStart = Date.now();

    // Query 1: Get vocabulary by content_hash
    const { data: existingVocab } = await client
      .from('vocabulary')
      .select('id, stem')
      .eq('user_id', userId)
      .eq('content_hash', estimatedHash)
      .is('deleted_at', null)
      .single();

    let foundMeaning = false;
    let meaning: { primary_translation: string; part_of_speech: string; english_definition: string | null } | null = null;

    if (existingVocab) {
      // Query 2: Get meanings for this vocabulary
      const { data: meanings } = await client
        .from('meanings')
        .select('primary_translation, part_of_speech, english_definition')
        .eq('user_id', userId)
        .eq('vocabulary_id', existingVocab.id)
        .is('deleted_at', null)
        .eq('is_active', true)
        .order('sort_order', { ascending: true })
        .limit(1);

      if (meanings && meanings.length > 0) {
        foundMeaning = true;
        meaning = meanings[0];
      }
    }

    const dbCheckDuration = Date.now() - dbCheckStart;
    console.log(JSON.stringify({
      event: 'db_check',
      word: raw_word,
      found: foundMeaning,
      duration_ms: dbCheckDuration
    }));

    if (foundMeaning && meaning && existingVocab) {
      // Word exists with meaning! Return immediately without calling OpenAI
      const vocabularyId = existingVocab.id;

      const meaningCheckStart = Date.now();
      // Create new encounter for this lookup
      await createEncounter(client, vocabularyId, userId, url, title, sentence, raw_word);

      // Get current stage
      const stage = await getVocabularyStage(client, vocabularyId, userId);
      const meaningCheckDuration = Date.now() - meaningCheckStart;

      console.log(JSON.stringify({
        event: 'meaning_check',
        word: raw_word,
        found: true,
        duration_ms: meaningCheckDuration
      }));

      const totalMs = Date.now() - startTime;
      console.log(JSON.stringify({
        event: 'lookup_complete',
        word: raw_word,
        path: 'existing',
        total_ms: totalMs
      }));

      return jsonResponse({
        lemma: existingVocab.stem,
        raw_word,
        translation: meaning.primary_translation,
        pronunciation: '', // Not stored in meanings table
        part_of_speech: meaning.part_of_speech,
        english_definition: meaning.english_definition || '',
        context_original: sentence, // Use current sentence as context
        context_translated: '', // Not stored in meanings table
        stage,
        is_new: false,
        vocabulary_id: vocabularyId,
      });
    }

    // Word doesn't exist or has no meaning - use fast translation
    console.log('[lookup-word] New word detected, using fast translation:', raw_word);
    const translationStart = Date.now();

    // Get API keys
    const DEEPL_API_KEY = Deno.env.get('DEEPL_API_KEY');
    const GOOGLE_TRANSLATE_API_KEY = Deno.env.get('GOOGLE_TRANSLATE_API_KEY');

    // Try DeepL first, fallback to Google
    let translation: string | null = null;
    let translationSource = '';

    if (DEEPL_API_KEY) {
      try {
        translation = await getDeepLTranslation(raw_word, 'de', DEEPL_API_KEY);
        translationSource = 'deepl';
      } catch (err) {
        console.warn('[lookup-word] DeepL failed:', err);
      }
    }

    if (!translation && GOOGLE_TRANSLATE_API_KEY) {
      try {
        translation = await getGoogleTranslation(raw_word, 'de', GOOGLE_TRANSLATE_API_KEY);
        translationSource = 'google';
      } catch (err) {
        console.warn('[lookup-word] Google Translate failed:', err);
      }
    }

    if (!translation) {
      return errorResponse('Translation service unavailable', 503);
    }

    const translationDuration = Date.now() - translationStart;
    console.log(JSON.stringify({
      event: 'translation',
      word: raw_word,
      source: translationSource,
      duration_ms: translationDuration
    }));

    // Use normalized word as lemma (will be enriched later)
    const lemma = raw_word.toLowerCase().trim();
    const contentHash = await generateContentHash(lemma);

    // New word - insert vocabulary
    const vocabularyId = crypto.randomUUID();

    const { error: vocabError } = await client.from('vocabulary').insert({
      id: vocabularyId,
      user_id: userId,
      word: raw_word,
      stem: lemma,
      content_hash: contentHash,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    });

    if (vocabError) {
      console.error('Failed to insert vocabulary:', vocabError);
      return errorResponse('Failed to create vocabulary entry', 500);
    }

    // Insert minimal meaning (will be enriched later)
    const meaningId = crypto.randomUUID();
    const { error: meaningError } = await client.from('meanings').insert({
      id: meaningId,
      user_id: userId,
      vocabulary_id: vocabularyId,
      language_code: 'de',
      primary_translation: translation,
      alternative_translations: [],
      english_definition: '(pending)',
      extended_definition: null,
      part_of_speech: '',
      synonyms: [],
      confidence: 0.7,
      is_primary: true,
      is_active: true,
      sort_order: 0,
      source: 'translation',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
      version: 1,
    });

    if (meaningError) {
      console.error('Failed to insert meaning:', meaningError);
      return errorResponse('Failed to create meaning', 500);
    }

    // Insert learning card
    const cardId = crypto.randomUUID();
    const { error: cardError } = await client.from('learning_cards').insert({
      id: cardId,
      user_id: userId,
      vocabulary_id: vocabularyId,
      state: 0,
      progress_stage: 'new',
      due: new Date().toISOString(),
      stability: 0,
      difficulty: 0,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    });

    if (cardError) {
      console.error('Failed to insert learning card:', cardError);
      return errorResponse('Failed to create learning card', 500);
    }

    // Queue background enrichment
    const enrichmentId = crypto.randomUUID();
    const { error: enrichmentError } = await client.from('enrichment_queue').insert({
      id: enrichmentId,
      vocabulary_id: vocabularyId,
      status: 'pending',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    });

    if (enrichmentError) {
      console.warn('Failed to queue enrichment (non-fatal):', enrichmentError);
      // Don't fail the request if enrichment queue fails
    }

    const isNew = true;

    // Upsert source
    const domain = extractDomain(url);
    const { data: existingSource } = await client
      .from('sources')
      .select('id')
      .eq('user_id', userId)
      .eq('type', 'website')
      .eq('url', url)
      .is('deleted_at', null)
      .single();

    let sourceId: string;
    if (existingSource) {
      sourceId = existingSource.id;
    } else {
      sourceId = crypto.randomUUID();
      const { error: sourceError } = await client.from('sources').insert({
        id: sourceId,
        user_id: userId,
        type: 'website',
        title: title,
        url: url,
        domain: domain,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      });

      if (sourceError) {
        console.error('Failed to insert source:', sourceError);
        return errorResponse('Failed to create source', 500);
      }
    }

    // Insert encounter
    const encounterId = crypto.randomUUID();
    const { error: encounterError } = await client.from('encounters').insert({
      id: encounterId,
      user_id: userId,
      vocabulary_id: vocabularyId,
      source_id: sourceId,
      context: sentence,
      occurred_at: new Date().toISOString(),
      created_at: new Date().toISOString(),
    });

    if (encounterError) {
      console.error('Failed to insert encounter:', encounterError);
      return errorResponse('Failed to create encounter', 500);
    }

    const response: LookupResponse = {
      lemma,
      raw_word,
      translation,
      pronunciation: '',
      part_of_speech: '',
      english_definition: '(pending)',
      context_original: sentence,
      context_translated: '',
      stage: 'new',
      is_new: isNew,
      vocabulary_id: vocabularyId,
    };

    const totalMs = Date.now() - startTime;
    console.log(JSON.stringify({
      event: 'lookup_complete',
      word: raw_word,
      path: 'new',
      total_ms: totalMs
    }));

    return jsonResponse(response);
  } catch (err) {
    const errorMsg = err instanceof Error ? err.message : String(err);
    const totalMs = Date.now() - startTime;
    console.log(JSON.stringify({
      event: 'lookup_error',
      word: raw_word,
      error: errorMsg,
      total_ms: totalMs
    }));
    console.error('lookup-word POST error:', errorMsg);
    return errorResponse(errorMsg || 'Failed to lookup word', 500);
  }
}

// =============================================================================
// Helper Functions
// =============================================================================

async function getVocabularyStage(
  client: any,
  vocabularyId: string,
  userId: string
): Promise<string> {
  const { data: card } = await client
    .from('learning_cards')
    .select('progress_stage')
    .eq('user_id', userId)
    .eq('vocabulary_id', vocabularyId)
    .is('deleted_at', null)
    .single();

  return card?.progress_stage || 'new';
}

async function createEncounter(
  client: any,
  vocabularyId: string,
  userId: string,
  url: string,
  title: string,
  sentence: string,
  raw_word: string
): Promise<void> {
  // Upsert source
  const domain = extractDomain(url);
  const { data: existingSource } = await client
    .from('sources')
    .select('id')
    .eq('user_id', userId)
    .eq('type', 'website')
    .eq('url', url)
    .is('deleted_at', null)
    .single();

  let sourceId: string;
  if (existingSource) {
    sourceId = existingSource.id;
  } else {
    sourceId = crypto.randomUUID();
    const { error: sourceError } = await client.from('sources').insert({
      id: sourceId,
      user_id: userId,
      type: 'website',
      title: title,
      url: url,
      domain: domain,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    });

    if (sourceError) {
      console.error('Failed to insert source:', sourceError);
      throw new Error('Failed to create source');
    }
  }

  // Insert encounter
  const encounterId = crypto.randomUUID();
  const { error: encounterError } = await client.from('encounters').insert({
    id: encounterId,
    user_id: userId,
    vocabulary_id: vocabularyId,
    source_id: sourceId,
    context: sentence,
    occurred_at: new Date().toISOString(),
    created_at: new Date().toISOString(),
  });

  if (encounterError) {
    console.error('Failed to insert encounter:', encounterError);
    throw new Error('Failed to create encounter');
  }
}

// =============================================================================
// GET /lookup-word/batch-status — Statistics
// =============================================================================

interface BatchStatusResponse {
  total_words: number;
  page_words: Array<{
    lemma: string;
    translation: string;
    stage: string;
  }>;
}

async function handleBatchStatus(req: Request, userId: string): Promise<Response> {
  const url = new URL(req.url);
  const pageUrl = url.searchParams.get('url');

  const client = createServiceClient();

  try {
    // Get total vocabulary count for user
    const { count: totalCount } = await client
      .from('vocabulary')
      .select('id', { count: 'exact', head: true })
      .eq('user_id', userId)
      .is('deleted_at', null);

    const totalWords = totalCount || 0;

    // If URL provided, get words looked up on that page
    let pageWords: Array<{ lemma: string; translation: string; stage: string }> = [];

    if (pageUrl) {
      // Get encounters for this page
      const { data: encounters } = await client
        .from('encounters')
        .select(`
          vocabulary_id,
          vocabulary:vocabulary_id (
            stem
          ),
          source:source_id (
            url
          )
        `)
        .eq('user_id', userId)
        .is('deleted_at', null);

      // Filter by URL and get unique vocabulary
      const pageVocabMap = new Map<string, { lemma: string; sourceId: string }>();

      if (encounters) {
        for (const enc of encounters) {
          const source = Array.isArray(enc.source) ? enc.source[0] : enc.source;
          if (source && source.url === pageUrl) {
            const vocab = Array.isArray(enc.vocabulary) ? enc.vocabulary[0] : enc.vocabulary;
            if (vocab && !pageVocabMap.has(enc.vocabulary_id)) {
              pageVocabMap.set(enc.vocabulary_id, {
                lemma: vocab.stem || enc.vocabulary_id,
                sourceId: ''
              });
            }
          }
        }
      }

      // Get meanings and learning cards for page words
      if (pageVocabMap.size > 0) {
        const vocabIds = Array.from(pageVocabMap.keys());

        const { data: meanings } = await client
          .from('meanings')
          .select('vocabulary_id, primary_translation')
          .eq('user_id', userId)
          .in('vocabulary_id', vocabIds)
          .is('deleted_at', null);

        const { data: cards } = await client
          .from('learning_cards')
          .select('vocabulary_id, progress_stage')
          .eq('user_id', userId)
          .in('vocabulary_id', vocabIds)
          .is('deleted_at', null);

        // Build response
        const meaningMap = new Map(meanings?.map(m => [m.vocabulary_id, m.primary_translation]) || []);
        const cardMap = new Map(cards?.map(c => [c.vocabulary_id, c.progress_stage]) || []);

        pageWords = Array.from(pageVocabMap.entries()).map(([vocabId, info]) => ({
          lemma: info.lemma,
          translation: meaningMap.get(vocabId) || '',
          stage: cardMap.get(vocabId) || 'new',
        }));
      }
    }

    const response: BatchStatusResponse = {
      total_words: totalWords,
      page_words: pageWords,
    };

    return jsonResponse(response);
  } catch (err) {
    const errorMsg = err instanceof Error ? err.message : String(err);
    console.error('lookup-word batch-status error:', errorMsg);
    return errorResponse(errorMsg || 'Failed to get batch status', 500);
  }
}

// =============================================================================
// OpenAI Integration
// =============================================================================

interface AIResult {
  lemma: string;
  translation: string;
  pronunciation: string;
  english_definition: string;
  part_of_speech: string;
  context_original: string;
  context_translated: string;
}

async function callOpenAI(rawWord: string, sentence: string): Promise<AIResult> {
  const OPENAI_API_KEY = Deno.env.get('OPENAI_API_KEY');

  if (!OPENAI_API_KEY) {
    throw new Error('OPENAI_API_KEY environment variable not set');
  }

  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${OPENAI_API_KEY}`,
    },
    body: JSON.stringify({
      model: 'gpt-4o-mini',
      temperature: 0.2,
      response_format: { type: 'json_object' },
      messages: [
        {
          role: 'system',
          content: `You are a language learning assistant. Given an English word and its context sentence, provide:
1. lemma: the dictionary/base form of the word
2. translation: German translation of the lemma
3. pronunciation: IPA pronunciation of the lemma
4. english_definition: concise English definition
5. part_of_speech: noun, verb, adjective, adverb, etc.
6. context_original: the original sentence with the target word wrapped in *asterisks*
7. context_translated: the full sentence translated to German, with the corresponding translated word wrapped in *asterisks*

Respond as JSON with exactly these keys.`,
        },
        {
          role: 'user',
          content: `Word: "${rawWord}"\nSentence: "${sentence}"`,
        },
      ],
    }),
  });

  if (!response.ok) {
    const errorData = await response.text();
    console.error('OpenAI API error response:', errorData);
    throw new Error(`OpenAI API error: ${response.status}`);
  }

  const data = await response.json();
  const content = data.choices?.[0]?.message?.content;

  if (!content) {
    throw new Error('No content in OpenAI response');
  }

  const parsed = JSON.parse(content);

  return {
    lemma: parsed.lemma || rawWord,
    translation: parsed.translation || '',
    pronunciation: parsed.pronunciation || '',
    english_definition: parsed.english_definition || '',
    part_of_speech: parsed.part_of_speech || '',
    context_original: parsed.context_original || sentence,
    context_translated: parsed.context_translated || sentence,
  };
}

// =============================================================================
// Utilities
// =============================================================================

async function generateContentHash(lemma: string): Promise<string> {
  const encoder = new TextEncoder();
  const data = encoder.encode(lemma.toLowerCase());
  const hashBuffer = await crypto.subtle.digest('SHA-256', data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
}

function extractDomain(urlStr: string): string {
  try {
    const url = new URL(urlStr);
    return url.hostname.replace(/^www\./, '');
  } catch {
    return '';
  }
}
