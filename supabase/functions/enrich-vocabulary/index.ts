// Edge function: enrich-vocabulary
// Enriches vocabulary words with meanings, cues, and confusable sets
// using a 3-tier fallback chain: OpenAI → DeepL → Google → encounter context

import { handleCors } from '../_shared/cors.ts';
import { createServiceClient, getUserId } from '../_shared/supabase.ts';
import { jsonResponse, errorResponse, unauthorizedResponse } from '../_shared/response.ts';

const MAX_BATCH_SIZE = 10;
const DEFAULT_BATCH_SIZE = 5;
const MAX_RETRY_ATTEMPTS = 3;
const BUFFER_TARGET = 10;

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

  // Get vocabulary words to enrich
  let wordsToEnrich: VocabWord[];

  if (vocabularyIds && vocabularyIds.length > 0) {
    // Specific words requested - bypass buffer logic
    const { data, error } = await client
      .from('vocabulary')
      .select('id, word, stem')
      .eq('user_id', userId)
      .in_('id', vocabularyIds.slice(0, batchSize))
      .is_('deleted_at', null);

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

  // Process each word through the fallback chain
  const enriched: EnrichedWord[] = [];
  const failed: FailedWord[] = [];

  for (const word of wordsToEnrich) {
    try {
      // Mark as processing in enrichment queue
      await upsertQueueEntry(client, userId, word.id, 'processing');

      const context = wordContexts[word.id];
      const result = await enrichWord(word, nativeLanguageCode, context, client, userId);

      if (result) {
        enriched.push(result);
        await upsertQueueEntry(client, userId, word.id, 'completed');
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
// Enrichment fallback chain
// =============================================================================

async function enrichWord(
  word: VocabWord,
  nativeLanguageCode: string,
  context: string | null,
  client: ReturnType<typeof createServiceClient>,
  userId: string,
): Promise<EnrichedWord | null> {
  // Tier 1: OpenAI
  const openaiKey = Deno.env.get('OPENAI_API_KEY');
  if (openaiKey) {
    try {
      const result = await enrichWithOpenAI(word, nativeLanguageCode, context, openaiKey);
      if (result) {
        await storeEnrichmentResults(client, userId, word.id, result, nativeLanguageCode);
        console.log(`[enrich-vocabulary] Tier 1 (OpenAI) success for "${word.word}"`);
        return result;
      }
    } catch (err) {
      console.warn(`[enrich-vocabulary] Tier 1 (OpenAI) failed for "${word.word}":`, err);
    }
  }

  // Tier 2: DeepL
  const deeplKey = Deno.env.get('DEEPL_API_KEY');
  if (deeplKey) {
    try {
      const result = await enrichWithDeepL(word, nativeLanguageCode, deeplKey);
      if (result) {
        await storeEnrichmentResults(client, userId, word.id, result, nativeLanguageCode);
        console.log(`[enrich-vocabulary] Tier 2 (DeepL) success for "${word.word}"`);
        return result;
      }
    } catch (err) {
      console.warn(`[enrich-vocabulary] Tier 2 (DeepL) failed for "${word.word}":`, err);
    }
  }

  // Tier 2b: Google Cloud Translation
  const googleKey = Deno.env.get('GOOGLE_TRANSLATE_API_KEY');
  if (googleKey) {
    try {
      const result = await enrichWithGoogle(word, nativeLanguageCode, googleKey);
      if (result) {
        await storeEnrichmentResults(client, userId, word.id, result, nativeLanguageCode);
        console.log(`[enrich-vocabulary] Tier 2b (Google) success for "${word.word}"`);
        return result;
      }
    } catch (err) {
      console.warn(`[enrich-vocabulary] Tier 2b (Google) failed for "${word.word}":`, err);
    }
  }

  // Tier 3: Encounter context extraction
  if (context) {
    try {
      const result = buildContextFallback(word, context, nativeLanguageCode);
      await storeEnrichmentResults(client, userId, word.id, result, nativeLanguageCode);
      console.log(`[enrich-vocabulary] Tier 3 (context) fallback for "${word.word}"`);
      return result;
    } catch (err) {
      console.warn(`[enrich-vocabulary] Tier 3 (context) failed for "${word.word}":`, err);
    }
  }

  return null;
}

// =============================================================================
// Tier 1: OpenAI GPT-4o-mini
// =============================================================================

async function enrichWithOpenAI(
  word: VocabWord,
  nativeLanguageCode: string,
  context: string | null,
  apiKey: string,
): Promise<EnrichedWord | null> {
  const prompt = `You are a vocabulary enrichment assistant for language learners.

Given an English word and optional context sentence, return a JSON object with:
- meanings: array of distinct senses (max 3), each with:
  - primary_translation: best translation in ${nativeLanguageCode}
  - alternative_translations: up to 3 alternatives in ${nativeLanguageCode}
  - english_definition: one-sentence plain English definition
  - synonyms: up to 3 English synonyms
  - part_of_speech: noun/verb/adjective/adverb/other
- confusables: array of commonly confused words (max 3), each with:
  - word: the confusable English word
  - explanation: one-sentence distinction in ${nativeLanguageCode}
  - example_sentence: English sentence demonstrating correct usage
- confidence: 0.0-1.0 indicating overall confidence

Word: ${word.word}
Stem: ${word.stem || word.word}
Context: ${context || 'none'}
Native language: ${nativeLanguageCode}`;

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
      max_tokens: 2000,
    }),
  });

  if (!response.ok) {
    throw new Error(`OpenAI API error: ${response.status} ${response.statusText}`);
  }

  const data = await response.json();
  const content = data.choices?.[0]?.message?.content;
  if (!content) throw new Error('No content in OpenAI response');

  const parsed = JSON.parse(content);
  return buildEnrichedWord(word, parsed, nativeLanguageCode, 'ai', parsed.confidence || 0.95);
}

// =============================================================================
// Tier 2: DeepL
// =============================================================================

async function enrichWithDeepL(
  word: VocabWord,
  nativeLanguageCode: string,
  apiKey: string,
): Promise<EnrichedWord | null> {
  const targetLang = nativeLanguageCode.toUpperCase();

  const response = await fetch('https://api-free.deepl.com/v2/translate', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Authorization': `DeepL-Auth-Key ${apiKey}` },
    body: JSON.stringify({
      text: [word.word],
      source_lang: 'EN',
      target_lang: targetLang,
    }),
  });

  if (!response.ok) throw new Error(`DeepL API error: ${response.status}`);

  const data = await response.json();
  const translation = data.translations?.[0]?.text;
  if (!translation) throw new Error('No translation in DeepL response');

  return {
    vocabulary_id: word.id,
    word: word.word,
    meanings: [{
      id: crypto.randomUUID(),
      primary_translation: translation,
      alternative_translations: [],
      english_definition: `${word.word} (translated via DeepL)`,
      extended_definition: null,
      part_of_speech: null,
      synonyms: [],
      confidence: 0.6,
      is_primary: true,
      sort_order: 0,
      source: 'deepl',
      cues: [
        {
          id: crypto.randomUUID(),
          cue_type: 'translation',
          prompt_text: translation,
          answer_text: word.word,
          hint_text: null,
          metadata: {},
        },
      ],
    }],
    confusable_set: null,
  };
}

// =============================================================================
// Tier 2b: Google Cloud Translation
// =============================================================================

async function enrichWithGoogle(
  word: VocabWord,
  nativeLanguageCode: string,
  apiKey: string,
): Promise<EnrichedWord | null> {
  const response = await fetch(
    `https://translation.googleapis.com/language/translate/v2?key=${apiKey}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        q: word.word,
        source: 'en',
        target: nativeLanguageCode,
        format: 'text',
      }),
    },
  );

  if (!response.ok) throw new Error(`Google Translate API error: ${response.status}`);

  const data = await response.json();
  const translation = data.data?.translations?.[0]?.translatedText;
  if (!translation) throw new Error('No translation in Google response');

  return {
    vocabulary_id: word.id,
    word: word.word,
    meanings: [{
      id: crypto.randomUUID(),
      primary_translation: translation,
      alternative_translations: [],
      english_definition: `${word.word} (translated via Google)`,
      extended_definition: null,
      part_of_speech: null,
      synonyms: [],
      confidence: 0.6,
      is_primary: true,
      sort_order: 0,
      source: 'google',
      cues: [
        {
          id: crypto.randomUUID(),
          cue_type: 'translation',
          prompt_text: translation,
          answer_text: word.word,
          hint_text: null,
          metadata: {},
        },
      ],
    }],
    confusable_set: null,
  };
}

// =============================================================================
// Tier 3: Encounter context extraction
// =============================================================================

function buildContextFallback(
  word: VocabWord,
  context: string,
  nativeLanguageCode: string,
): EnrichedWord {
  const meaningId = crypto.randomUUID();
  return {
    vocabulary_id: word.id,
    word: word.word,
    meanings: [{
      id: meaningId,
      primary_translation: word.word, // No translation available
      alternative_translations: [],
      english_definition: `Used in context: "${context}"`,
      extended_definition: null,
      part_of_speech: null,
      synonyms: [],
      confidence: 0.3,
      is_primary: true,
      sort_order: 0,
      source: 'context',
      cues: [
        {
          id: crypto.randomUUID(),
          cue_type: 'context_cloze',
          prompt_text: context.replace(new RegExp(`\\b${word.word}\\b`, 'gi'), '___'),
          answer_text: word.word,
          hint_text: null,
          metadata: { full_sentence: context },
        },
      ],
    }],
    confusable_set: null,
  };
}

// =============================================================================
// Helpers
// =============================================================================

function buildEnrichedWord(
  word: VocabWord,
  parsed: OpenAIResult,
  _nativeLanguageCode: string,
  source: string,
  confidence: number,
): EnrichedWord {
  const meanings: EnrichedMeaning[] = (parsed.meanings || []).map((m: OpenAIMeaning, i: number) => {
    const meaningId = crypto.randomUUID();
    const cues: EnrichedCue[] = [];

    // Translation cue
    if (m.primary_translation) {
      cues.push({
        id: crypto.randomUUID(),
        cue_type: 'translation',
        prompt_text: m.primary_translation,
        answer_text: word.word,
        hint_text: null,
        metadata: {},
      });
    }

    // Definition cue
    if (m.english_definition) {
      cues.push({
        id: crypto.randomUUID(),
        cue_type: 'definition',
        prompt_text: m.english_definition,
        answer_text: word.word,
        hint_text: null,
        metadata: {},
      });
    }

    // Synonym cue
    if (m.synonyms && m.synonyms.length > 0) {
      cues.push({
        id: crypto.randomUUID(),
        cue_type: 'synonym',
        prompt_text: m.synonyms.join(', '),
        answer_text: word.word,
        hint_text: null,
        metadata: {},
      });
    }

    return {
      id: meaningId,
      primary_translation: m.primary_translation || word.word,
      alternative_translations: m.alternative_translations || [],
      english_definition: m.english_definition || '',
      extended_definition: null,
      part_of_speech: m.part_of_speech || null,
      synonyms: m.synonyms || [],
      confidence,
      is_primary: i === 0,
      sort_order: i,
      source,
      cues,
    };
  });

  // Build confusable set
  let confusableSet: EnrichedConfusableSet | null = null;
  if (parsed.confusables && parsed.confusables.length > 0) {
    const explanations: Record<string, string> = {};
    const exampleSentences: Record<string, string> = {};
    const confusableWords = parsed.confusables.map((c: OpenAIConfusable) => {
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

    // Add disambiguation cue to first meaning if confusables exist
    if (meanings.length > 0 && parsed.confusables.length >= 2) {
      const disambigOptions = confusableWords.slice(0, 4);
      meanings[0].cues.push({
        id: crypto.randomUUID(),
        cue_type: 'disambiguation',
        prompt_text: `Choose the word that means: ${meanings[0].english_definition}`,
        answer_text: word.word,
        hint_text: null,
        metadata: {
          options: disambigOptions,
          explanations,
        },
      });
    }
  }

  return {
    vocabulary_id: word.id,
    word: word.word,
    meanings,
    confusable_set: confusableSet,
  };
}

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
    .is_('deleted_at', null);

  const enrichedSet = new Set((enrichedIds || []).map((r: { vocabulary_id: string }) => r.vocabulary_id));

  // Get all vocabulary, filter out enriched ones
  const { data: allVocab, error } = await client
    .from('vocabulary')
    .select('id, word, stem')
    .eq('user_id', userId)
    .is_('deleted_at', null)
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
    .in_('vocabulary_id', vocabIds)
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

async function storeEnrichmentResults(
  client: ReturnType<typeof createServiceClient>,
  userId: string,
  vocabularyId: string,
  result: EnrichedWord,
  nativeLanguageCode: string,
): Promise<void> {
  const now = new Date().toISOString();

  for (const meaning of result.meanings) {
    // Insert meaning
    await client.from('meanings').upsert({
      id: meaning.id,
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

    // Insert cues
    for (const cue of meaning.cues) {
      await client.from('cues').upsert({
        id: cue.id,
        user_id: userId,
        meaning_id: meaning.id,
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
  }

  // Insert confusable set
  if (result.confusable_set) {
    const cs = result.confusable_set;
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

async function upsertQueueEntry(
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
    ...(status === 'processing' ? { last_attempted_at: now } : {}),
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

async function getBufferStatus(
  client: ReturnType<typeof createServiceClient>,
  userId: string,
): Promise<{ enriched_count: number; un_enriched_count: number; buffer_target: number; pending_in_queue: number }> {
  // Count enriched (have meanings)
  const { count: enrichedCount } = await client
    .from('meanings')
    .select('vocabulary_id', { count: 'exact', head: true })
    .eq('user_id', userId)
    .is_('deleted_at', null);

  // Count total vocab
  const { count: totalCount } = await client
    .from('vocabulary')
    .select('id', { count: 'exact', head: true })
    .eq('user_id', userId)
    .is_('deleted_at', null);

  // Count pending in queue
  const { count: pendingCount } = await client
    .from('enrichment_queue')
    .select('id', { count: 'exact', head: true })
    .eq('user_id', userId)
    .in_('status', ['pending', 'processing']);

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

interface OpenAIMeaning {
  primary_translation: string;
  alternative_translations?: string[];
  english_definition: string;
  synonyms?: string[];
  part_of_speech?: string;
}

interface OpenAIConfusable {
  word: string;
  explanation: string;
  example_sentence?: string;
}

interface OpenAIResult {
  meanings: OpenAIMeaning[];
  confusables?: OpenAIConfusable[];
  confidence?: number;
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
  meanings: EnrichedMeaning[];
  confusable_set: EnrichedConfusableSet | null;
}

interface FailedWord {
  vocabulary_id: string;
  error: string;
  will_retry: boolean;
}
