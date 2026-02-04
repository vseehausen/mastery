// Tests for enrich-vocabulary edge function
//
// Since the source file uses Deno.serve and does not export its internal
// functions, we re-implement the pure transformation logic here and validate
// that the data shapes and transformation rules match the contract defined
// in the edge function.
//
// Updated for Phase 3.1a: Single meaning per vocabulary, native_alternatives

import {
  assertEquals,
  assertExists,
  assertNotEquals,
} from 'https://deno.land/std@0.224.0/assert/mod.ts';

// =============================================================================
// Type definitions (mirrored from index.ts - updated for single meaning)
// =============================================================================

interface VocabWord {
  id: string;
  word: string;
  stem: string | null;
}

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
  native_alternatives: string[];
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
  meaning: EnrichedMeaning; // Single meaning, not array
  confusable_set: EnrichedConfusableSet | null;
}

// =============================================================================
// Re-implemented pure functions (matching index.ts logic exactly)
// Updated for 2-phase approach: DeepL/Google translation + OpenAI enhancement
// =============================================================================

function buildEnrichedWord(
  word: VocabWord,
  translation: string,
  translationSource: string,
  aiEnhancement: AIEnhancement | null,
  _nativeLanguageCode: string,
): EnrichedWord {
  const meaningId = crypto.randomUUID();
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

    // Add disambiguation cue if we have >= 2 confusables
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
      alternative_translations: aiEnhancement?.native_alternatives || [],
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

// Simulates parsing OpenAI response for native_alternatives
function parseOpenAIResponse(content: string): AIEnhancement {
  const parsed = JSON.parse(content);
  return {
    english_definition: parsed.english_definition || '',
    synonyms: parsed.synonyms || [],
    part_of_speech: parsed.part_of_speech || null,
    confusables: parsed.confusables || [],
    confidence: parsed.confidence || 0.9,
    native_alternatives: Array.isArray(parsed.native_alternatives)
      ? parsed.native_alternatives.filter((a: string) => a && typeof a === 'string')
      : [],
  };
}

// =============================================================================
// Test helpers
// =============================================================================

function makeWord(overrides?: Partial<VocabWord>): VocabWord {
  return {
    id: crypto.randomUUID(),
    word: 'ephemeral',
    stem: 'ephemer',
    ...overrides,
  };
}

function makeAIEnhancement(overrides?: Partial<AIEnhancement>): AIEnhancement {
  return {
    english_definition: 'Lasting for a very short time',
    synonyms: ['fleeting', 'transient'],
    part_of_speech: 'adjective',
    confusables: [],
    confidence: 0.95,
    native_alternatives: [],
    ...overrides,
  };
}

// =============================================================================
// Tests: buildEnrichedWord - Basic structure
// =============================================================================

Deno.test('buildEnrichedWord: creates single meaning (not array)', () => {
  const word = makeWord({ word: 'resilient' });
  const result = buildEnrichedWord(word, 'widerstandsfähig', 'deepl', null, 'de');

  // Should be single meaning object, not array
  assertExists(result.meaning);
  assertEquals(typeof result.meaning, 'object');
  assertEquals(result.meaning.primary_translation, 'widerstandsfähig');
});

Deno.test('buildEnrichedWord: vocabulary_id and word match input', () => {
  const word = makeWord({ word: 'test' });
  const result = buildEnrichedWord(word, 'Test', 'deepl', null, 'de');

  assertEquals(result.vocabulary_id, word.id);
  assertEquals(result.word, 'test');
});

Deno.test('buildEnrichedWord: meaning is always primary with sort_order 0', () => {
  const word = makeWord();
  const result = buildEnrichedWord(word, 'vergänglich', 'deepl', null, 'de');

  assertEquals(result.meaning.is_primary, true);
  assertEquals(result.meaning.sort_order, 0);
});

// =============================================================================
// Tests: Phase 3.1a - native_alternatives / alternative_translations
// =============================================================================

Deno.test('buildEnrichedWord: populates alternative_translations from native_alternatives', () => {
  const word = makeWord({ word: 'ephemeral' });
  const aiEnhancement = makeAIEnhancement({
    native_alternatives: ['flüchtig', 'kurzlebig', 'vorübergehend'],
  });

  const result = buildEnrichedWord(word, 'vergänglich', 'deepl', aiEnhancement, 'de');

  assertEquals(result.meaning.alternative_translations, ['flüchtig', 'kurzlebig', 'vorübergehend']);
});

Deno.test('buildEnrichedWord: alternative_translations empty when no native_alternatives', () => {
  const word = makeWord({ word: 'test' });
  const aiEnhancement = makeAIEnhancement({
    native_alternatives: [],
  });

  const result = buildEnrichedWord(word, 'Test', 'deepl', aiEnhancement, 'de');

  assertEquals(result.meaning.alternative_translations, []);
});

Deno.test('buildEnrichedWord: alternative_translations empty when aiEnhancement is null', () => {
  const word = makeWord({ word: 'test' });
  const result = buildEnrichedWord(word, 'Test', 'deepl', null, 'de');

  assertEquals(result.meaning.alternative_translations, []);
});

Deno.test('parseOpenAIResponse: extracts native_alternatives array', () => {
  const response = JSON.stringify({
    english_definition: 'Lasting for a short time',
    synonyms: ['fleeting'],
    part_of_speech: 'adjective',
    confidence: 0.95,
    native_alternatives: ['flüchtig', 'kurzlebig'],
    confusables: [],
  });

  const parsed = parseOpenAIResponse(response);

  assertEquals(parsed.native_alternatives, ['flüchtig', 'kurzlebig']);
});

Deno.test('parseOpenAIResponse: filters out null/empty native_alternatives', () => {
  const response = JSON.stringify({
    english_definition: 'Test',
    synonyms: [],
    native_alternatives: ['valid', null, '', 'also-valid', undefined],
    confusables: [],
  });

  const parsed = parseOpenAIResponse(response);

  assertEquals(parsed.native_alternatives, ['valid', 'also-valid']);
});

Deno.test('parseOpenAIResponse: handles missing native_alternatives', () => {
  const response = JSON.stringify({
    english_definition: 'Test',
    synonyms: [],
    confusables: [],
  });

  const parsed = parseOpenAIResponse(response);

  assertEquals(parsed.native_alternatives, []);
});

Deno.test('parseOpenAIResponse: handles non-array native_alternatives', () => {
  const response = JSON.stringify({
    english_definition: 'Test',
    native_alternatives: 'not an array',
    confusables: [],
  });

  const parsed = parseOpenAIResponse(response);

  assertEquals(parsed.native_alternatives, []);
});

Deno.test('buildEnrichedWord: preserves 2-4 native alternatives from OpenAI', () => {
  const word = makeWord({ word: 'beautiful' });
  const aiEnhancement = makeAIEnhancement({
    native_alternatives: ['wunderschön', 'hübsch', 'attraktiv', 'ansprechend'],
  });

  const result = buildEnrichedWord(word, 'schön', 'deepl', aiEnhancement, 'de');

  assertEquals(result.meaning.alternative_translations.length, 4);
  assertEquals(result.meaning.alternative_translations[0], 'wunderschön');
  assertEquals(result.meaning.alternative_translations[3], 'ansprechend');
});

// =============================================================================
// Tests: Translation sources and confidence
// =============================================================================

Deno.test('buildEnrichedWord: source is deepl when no AI enhancement', () => {
  const word = makeWord();
  const result = buildEnrichedWord(word, 'vergänglich', 'deepl', null, 'de');

  assertEquals(result.meaning.source, 'deepl');
});

Deno.test('buildEnrichedWord: source is google when no AI enhancement', () => {
  const word = makeWord();
  const result = buildEnrichedWord(word, 'vergänglich', 'google', null, 'de');

  assertEquals(result.meaning.source, 'google');
});

Deno.test('buildEnrichedWord: source is deepl+ai when AI enhancement present', () => {
  const word = makeWord();
  const aiEnhancement = makeAIEnhancement();
  const result = buildEnrichedWord(word, 'vergänglich', 'deepl', aiEnhancement, 'de');

  assertEquals(result.meaning.source, 'deepl+ai');
});

Deno.test('buildEnrichedWord: source is google+ai when AI enhancement present', () => {
  const word = makeWord();
  const aiEnhancement = makeAIEnhancement();
  const result = buildEnrichedWord(word, 'vergänglich', 'google', aiEnhancement, 'de');

  assertEquals(result.meaning.source, 'google+ai');
});

Deno.test('buildEnrichedWord: confidence from AI enhancement when present', () => {
  const word = makeWord();
  const aiEnhancement = makeAIEnhancement({ confidence: 0.92 });
  const result = buildEnrichedWord(word, 'vergänglich', 'deepl', aiEnhancement, 'de');

  assertEquals(result.meaning.confidence, 0.92);
});

Deno.test('buildEnrichedWord: confidence 0.7 when translation source available but no AI', () => {
  const word = makeWord();
  const result = buildEnrichedWord(word, 'vergänglich', 'deepl', null, 'de');

  assertEquals(result.meaning.confidence, 0.7);
});

Deno.test('buildEnrichedWord: confidence 0.3 when no translation source', () => {
  const word = makeWord();
  const result = buildEnrichedWord(word, 'ephemeral', 'none', null, 'de');

  assertEquals(result.meaning.confidence, 0.3);
});

// =============================================================================
// Tests: Cue generation
// =============================================================================

Deno.test('buildEnrichedWord: creates translation cue with source metadata', () => {
  const word = makeWord({ word: 'test' });
  const result = buildEnrichedWord(word, 'Test', 'deepl', null, 'de');

  const translationCue = result.meaning.cues.find(c => c.cue_type === 'translation');
  assertExists(translationCue);
  assertEquals(translationCue!.prompt_text, 'Test');
  assertEquals(translationCue!.answer_text, 'test');
  assertEquals(translationCue!.metadata, { source: 'deepl' });
});

Deno.test('buildEnrichedWord: creates definition cue from AI enhancement', () => {
  const word = makeWord({ word: 'ephemeral' });
  const aiEnhancement = makeAIEnhancement({
    english_definition: 'Lasting for a very short time',
  });
  const result = buildEnrichedWord(word, 'vergänglich', 'deepl', aiEnhancement, 'de');

  const definitionCue = result.meaning.cues.find(c => c.cue_type === 'definition');
  assertExists(definitionCue);
  assertEquals(definitionCue!.prompt_text, 'Lasting for a very short time');
  assertEquals(definitionCue!.answer_text, 'ephemeral');
});

Deno.test('buildEnrichedWord: creates synonym cue from AI enhancement', () => {
  const word = makeWord({ word: 'ephemeral' });
  const aiEnhancement = makeAIEnhancement({
    synonyms: ['fleeting', 'transient', 'momentary'],
  });
  const result = buildEnrichedWord(word, 'vergänglich', 'deepl', aiEnhancement, 'de');

  const synonymCue = result.meaning.cues.find(c => c.cue_type === 'synonym');
  assertExists(synonymCue);
  assertEquals(synonymCue!.prompt_text, 'fleeting, transient, momentary');
  assertEquals(synonymCue!.answer_text, 'ephemeral');
});

Deno.test('buildEnrichedWord: no synonym cue when synonyms empty', () => {
  const word = makeWord({ word: 'unique' });
  const aiEnhancement = makeAIEnhancement({ synonyms: [] });
  const result = buildEnrichedWord(word, 'einzigartig', 'deepl', aiEnhancement, 'de');

  const synonymCue = result.meaning.cues.find(c => c.cue_type === 'synonym');
  assertEquals(synonymCue, undefined);
});

Deno.test('buildEnrichedWord: all cues have unique IDs', () => {
  const word = makeWord({ word: 'test' });
  const aiEnhancement = makeAIEnhancement({
    english_definition: 'A trial',
    synonyms: ['trial', 'exam'],
    confusables: [
      { word: 'exam', explanation: 'formal test' },
      { word: 'quiz', explanation: 'short test' },
    ],
  });
  const result = buildEnrichedWord(word, 'Test', 'deepl', aiEnhancement, 'de');

  const cueIds = result.meaning.cues.map(c => c.id);
  const uniqueIds = new Set(cueIds);
  assertEquals(cueIds.length, uniqueIds.size, 'All cue IDs should be unique');
});

Deno.test('buildEnrichedWord: hint_text is always null', () => {
  const word = makeWord({ word: 'test' });
  const aiEnhancement = makeAIEnhancement({
    english_definition: 'A trial',
    synonyms: ['trial'],
  });
  const result = buildEnrichedWord(word, 'Test', 'deepl', aiEnhancement, 'de');

  for (const cue of result.meaning.cues) {
    assertEquals(cue.hint_text, null);
  }
});

// =============================================================================
// Tests: Confusable sets
// =============================================================================

Deno.test('buildEnrichedWord: creates confusable_set from AI enhancement', () => {
  const word = makeWord({ word: 'affect' });
  const aiEnhancement = makeAIEnhancement({
    english_definition: 'To have an impact on',
    confusables: [
      { word: 'effect', explanation: 'The result, not the action', example_sentence: 'The effect was immediate.' },
      { word: 'affection', explanation: 'Fondness, not impact' },
    ],
  });
  const result = buildEnrichedWord(word, 'beeinflussen', 'deepl', aiEnhancement, 'de');

  assertExists(result.confusable_set);
  // Word itself is prepended
  assertEquals(result.confusable_set!.words[0], 'affect');
  assertEquals(result.confusable_set!.words[1], 'effect');
  assertEquals(result.confusable_set!.words[2], 'affection');
  assertEquals(result.confusable_set!.explanations['effect'], 'The result, not the action');
  assertEquals(result.confusable_set!.example_sentences['effect'], 'The effect was immediate.');
  assertEquals(result.confusable_set!.example_sentences['affection'], undefined);
});

Deno.test('buildEnrichedWord: no duplicate word in confusable_set', () => {
  const word = makeWord({ word: 'affect' });
  const aiEnhancement = makeAIEnhancement({
    confusables: [
      { word: 'affect', explanation: 'self' },
      { word: 'effect', explanation: 'result' },
    ],
  });
  const result = buildEnrichedWord(word, 'beeinflussen', 'deepl', aiEnhancement, 'de');

  const affectCount = result.confusable_set!.words.filter(w => w === 'affect').length;
  assertEquals(affectCount, 1);
});

Deno.test('buildEnrichedWord: disambiguation cue when >= 2 confusables', () => {
  const word = makeWord({ word: 'affect' });
  const aiEnhancement = makeAIEnhancement({
    english_definition: 'To have an impact on',
    confusables: [
      { word: 'effect', explanation: 'result' },
      { word: 'affection', explanation: 'fondness' },
    ],
  });
  const result = buildEnrichedWord(word, 'beeinflussen', 'deepl', aiEnhancement, 'de');

  const disambigCue = result.meaning.cues.find(c => c.cue_type === 'disambiguation');
  assertExists(disambigCue);
  assertEquals(disambigCue!.prompt_text, 'Choose the word that means: To have an impact on');
  assertEquals(disambigCue!.answer_text, 'affect');
  assertExists((disambigCue!.metadata as Record<string, unknown>).options);
});

Deno.test('buildEnrichedWord: no disambiguation cue when only 1 confusable', () => {
  const word = makeWord({ word: 'affect' });
  const aiEnhancement = makeAIEnhancement({
    english_definition: 'To have an impact on',
    confusables: [
      { word: 'effect', explanation: 'result' },
    ],
  });
  const result = buildEnrichedWord(word, 'beeinflussen', 'deepl', aiEnhancement, 'de');

  const disambigCue = result.meaning.cues.find(c => c.cue_type === 'disambiguation');
  assertEquals(disambigCue, undefined);
});

Deno.test('buildEnrichedWord: disambiguation options capped at 4', () => {
  const word = makeWord({ word: 'test' });
  const aiEnhancement = makeAIEnhancement({
    english_definition: 'A trial',
    confusables: [
      { word: 'exam', explanation: 'formal' },
      { word: 'quiz', explanation: 'short' },
      { word: 'trial', explanation: 'legal' },
      { word: 'assessment', explanation: 'evaluation' },
      { word: 'evaluation', explanation: 'judgment' },
    ],
  });
  const result = buildEnrichedWord(word, 'Test', 'deepl', aiEnhancement, 'de');

  const disambigCue = result.meaning.cues.find(c => c.cue_type === 'disambiguation');
  const options = (disambigCue!.metadata as Record<string, unknown>).options as string[];
  assertEquals(options.length, 4);
});

Deno.test('buildEnrichedWord: confusable_set null when no confusables', () => {
  const word = makeWord({ word: 'happy' });
  const aiEnhancement = makeAIEnhancement({ confusables: [] });
  const result = buildEnrichedWord(word, 'glücklich', 'deepl', aiEnhancement, 'de');

  assertEquals(result.confusable_set, null);
});

// =============================================================================
// Tests: Fallback english_definition
// =============================================================================

Deno.test('buildEnrichedWord: fallback english_definition with translation source', () => {
  const word = makeWord({ word: 'test' });
  const result = buildEnrichedWord(word, 'Test', 'deepl', null, 'de');

  assertEquals(result.meaning.english_definition, 'test (deepl translation)');
});

Deno.test('buildEnrichedWord: fallback english_definition with google source', () => {
  const word = makeWord({ word: 'test' });
  const result = buildEnrichedWord(word, 'Test', 'google', null, 'de');

  assertEquals(result.meaning.english_definition, 'test (google translation)');
});

Deno.test('buildEnrichedWord: uses AI english_definition when available', () => {
  const word = makeWord({ word: 'test' });
  const aiEnhancement = makeAIEnhancement({
    english_definition: 'A procedure to assess performance',
  });
  const result = buildEnrichedWord(word, 'Test', 'deepl', aiEnhancement, 'de');

  assertEquals(result.meaning.english_definition, 'A procedure to assess performance');
});

// =============================================================================
// Tests: Part of speech and synonyms
// =============================================================================

Deno.test('buildEnrichedWord: part_of_speech from AI enhancement', () => {
  const word = makeWord({ word: 'run' });
  const aiEnhancement = makeAIEnhancement({ part_of_speech: 'verb' });
  const result = buildEnrichedWord(word, 'laufen', 'deepl', aiEnhancement, 'de');

  assertEquals(result.meaning.part_of_speech, 'verb');
});

Deno.test('buildEnrichedWord: part_of_speech null when no AI enhancement', () => {
  const word = makeWord({ word: 'run' });
  const result = buildEnrichedWord(word, 'laufen', 'deepl', null, 'de');

  assertEquals(result.meaning.part_of_speech, null);
});

Deno.test('buildEnrichedWord: synonyms from AI enhancement', () => {
  const word = makeWord({ word: 'big' });
  const aiEnhancement = makeAIEnhancement({
    synonyms: ['large', 'huge', 'enormous'],
  });
  const result = buildEnrichedWord(word, 'groß', 'deepl', aiEnhancement, 'de');

  assertEquals(result.meaning.synonyms, ['large', 'huge', 'enormous']);
});

Deno.test('buildEnrichedWord: synonyms empty when no AI enhancement', () => {
  const word = makeWord({ word: 'big' });
  const result = buildEnrichedWord(word, 'groß', 'deepl', null, 'de');

  assertEquals(result.meaning.synonyms, []);
});

// =============================================================================
// Tests: Extended definition always null
// =============================================================================

Deno.test('buildEnrichedWord: extended_definition is always null', () => {
  const word = makeWord();
  const aiEnhancement = makeAIEnhancement();
  const result = buildEnrichedWord(word, 'vergänglich', 'deepl', aiEnhancement, 'de');

  assertEquals(result.meaning.extended_definition, null);
});

// =============================================================================
// Tests: Input validation constants
// =============================================================================

Deno.test('MAX_BATCH_SIZE constant is 10', () => {
  const MAX_BATCH_SIZE = 10;
  assertEquals(MAX_BATCH_SIZE, 10);
});

Deno.test('batch_size is capped at MAX_BATCH_SIZE', () => {
  const MAX_BATCH_SIZE = 10;
  const DEFAULT_BATCH_SIZE = 5;

  const requestedBatchSize = 50;
  const effectiveBatchSize = Math.min(requestedBatchSize || DEFAULT_BATCH_SIZE, MAX_BATCH_SIZE);
  assertEquals(effectiveBatchSize, 10);
});

Deno.test('batch_size defaults to DEFAULT_BATCH_SIZE when not provided', () => {
  const MAX_BATCH_SIZE = 10;
  const DEFAULT_BATCH_SIZE = 5;

  const requestedBatchSize = undefined;
  const effectiveBatchSize = Math.min(requestedBatchSize || DEFAULT_BATCH_SIZE, MAX_BATCH_SIZE);
  assertEquals(effectiveBatchSize, 5);
});

// =============================================================================
// Tests: EnrichedWord response contract
// =============================================================================

Deno.test('EnrichedWord contract: required fields are present', () => {
  const word = makeWord();
  const result = buildEnrichedWord(word, 'vergänglich', 'deepl', null, 'de');

  // Top-level required fields
  assertExists(result.vocabulary_id);
  assertExists(result.word);
  assertExists(result.meaning);
  assertEquals(typeof result.vocabulary_id, 'string');
  assertEquals(typeof result.word, 'string');
  assertEquals(typeof result.meaning, 'object');

  // Meaning required fields
  const m = result.meaning;
  assertExists(m.id);
  assertExists(m.primary_translation);
  assertEquals(typeof m.confidence, 'number');
  assertEquals(typeof m.is_primary, 'boolean');
  assertEquals(typeof m.sort_order, 'number');
  assertExists(m.source);
  assertEquals(Array.isArray(m.cues), true);
  assertEquals(Array.isArray(m.alternative_translations), true);
  assertEquals(Array.isArray(m.synonyms), true);

  // Cue required fields
  const c = m.cues[0];
  assertExists(c.id);
  assertExists(c.cue_type);
  assertExists(c.prompt_text);
  assertExists(c.answer_text);
  assertEquals(typeof c.metadata, 'object');
});

Deno.test('EnrichedWord contract: confusable_set fields when present', () => {
  const word = makeWord({ word: 'affect' });
  const aiEnhancement = makeAIEnhancement({
    confusables: [
      { word: 'effect', explanation: 'result', example_sentence: 'The effect was clear.' },
    ],
  });
  const result = buildEnrichedWord(word, 'beeinflussen', 'deepl', aiEnhancement, 'de');

  assertExists(result.confusable_set);
  assertExists(result.confusable_set!.id);
  assertEquals(typeof result.confusable_set!.id, 'string');
  assertEquals(Array.isArray(result.confusable_set!.words), true);
  assertEquals(typeof result.confusable_set!.explanations, 'object');
  assertEquals(typeof result.confusable_set!.example_sentences, 'object');
});

// =============================================================================
// Tests: Translation quality validation (simulated)
// =============================================================================

Deno.test('Translation validation: rejects same-as-input translations', () => {
  // Simulates the validation logic from index.ts
  function isValidTranslation(word: string, translation: string | null): boolean {
    if (!translation) return false;
    const cleaned = translation.trim();
    if (cleaned.length < 2) return false;
    if (cleaned.toLowerCase() === word.toLowerCase()) return false;
    if (/^[\s\p{P}]+$/u.test(cleaned)) return false;
    return true;
  }

  assertEquals(isValidTranslation('test', 'test'), false);
  assertEquals(isValidTranslation('Test', 'test'), false);
  assertEquals(isValidTranslation('test', 'TEST'), false);
  assertEquals(isValidTranslation('test', 'Test'), false);
});

Deno.test('Translation validation: rejects too short translations', () => {
  function isValidTranslation(word: string, translation: string | null): boolean {
    if (!translation) return false;
    const cleaned = translation.trim();
    if (cleaned.length < 2) return false;
    if (cleaned.toLowerCase() === word.toLowerCase()) return false;
    if (/^[\s\p{P}]+$/u.test(cleaned)) return false;
    return true;
  }

  assertEquals(isValidTranslation('test', 'a'), false);
  assertEquals(isValidTranslation('test', ''), false);
  assertEquals(isValidTranslation('test', ' '), false);
});

Deno.test('Translation validation: rejects punctuation-only translations', () => {
  function isValidTranslation(word: string, translation: string | null): boolean {
    if (!translation) return false;
    const cleaned = translation.trim();
    if (cleaned.length < 2) return false;
    if (cleaned.toLowerCase() === word.toLowerCase()) return false;
    if (/^[\s\p{P}]+$/u.test(cleaned)) return false;
    return true;
  }

  assertEquals(isValidTranslation('test', '...'), false);
  assertEquals(isValidTranslation('test', '!!!'), false);
  assertEquals(isValidTranslation('test', '  .  '), false);
});

Deno.test('Translation validation: accepts valid translations', () => {
  function isValidTranslation(word: string, translation: string | null): boolean {
    if (!translation) return false;
    const cleaned = translation.trim();
    if (cleaned.length < 2) return false;
    if (cleaned.toLowerCase() === word.toLowerCase()) return false;
    if (/^[\s\p{P}]+$/u.test(cleaned)) return false;
    return true;
  }

  assertEquals(isValidTranslation('test', 'Test (Prüfung)'), true);
  assertEquals(isValidTranslation('ephemeral', 'vergänglich'), true);
  assertEquals(isValidTranslation('big', 'groß'), true);
});

// =============================================================================
// Tests: User edit protection (simulated logic)
// =============================================================================

Deno.test('User edit protection: skip update when edits exist', () => {
  // Simulates the logic in storeEnrichmentResult
  function shouldUpdateMeaning(editCount: number | null): boolean {
    if (editCount && editCount > 0) {
      return false; // Skip update, preserve user edits
    }
    return true; // OK to update
  }

  assertEquals(shouldUpdateMeaning(0), true);
  assertEquals(shouldUpdateMeaning(null), true);
  assertEquals(shouldUpdateMeaning(1), false);
  assertEquals(shouldUpdateMeaning(5), false);
});

Deno.test('User edit protection: update allowed when no edits', () => {
  function shouldUpdateMeaning(editCount: number | null): boolean {
    if (editCount && editCount > 0) {
      return false;
    }
    return true;
  }

  assertEquals(shouldUpdateMeaning(0), true);
  assertEquals(shouldUpdateMeaning(null), true);
  assertEquals(shouldUpdateMeaning(undefined as unknown as null), true);
});

// =============================================================================
// Tests: Language code mapping
// =============================================================================

Deno.test('Language code mapping: common languages', () => {
  const langNames: Record<string, string> = {
    de: 'German', es: 'Spanish', fr: 'French', it: 'Italian',
    pt: 'Portuguese', nl: 'Dutch', pl: 'Polish', ru: 'Russian',
    ja: 'Japanese', zh: 'Chinese', ko: 'Korean',
  };

  assertEquals(langNames['de'], 'German');
  assertEquals(langNames['es'], 'Spanish');
  assertEquals(langNames['fr'], 'French');
  assertEquals(langNames['ja'], 'Japanese');
  assertEquals(langNames['zh'], 'Chinese');
});

Deno.test('Language code mapping: unknown code falls back to uppercase', () => {
  const langNames: Record<string, string> = {
    de: 'German', es: 'Spanish',
  };
  const nativeLanguageCode = 'sv';
  const langName = langNames[nativeLanguageCode] || nativeLanguageCode.toUpperCase();

  assertEquals(langName, 'SV');
});

// =============================================================================
// Tests: Complete enrichment flow simulation
// =============================================================================

Deno.test('Complete flow: DeepL + OpenAI with native alternatives', () => {
  const word = makeWord({ word: 'serendipity' });
  const translation = 'glücklicher Zufall';
  const aiEnhancement: AIEnhancement = {
    english_definition: 'The occurrence of events by chance in a happy way',
    synonyms: ['luck', 'fortune', 'chance'],
    part_of_speech: 'noun',
    confusables: [
      { word: 'coincidence', explanation: 'Not necessarily happy', example_sentence: 'It was just a coincidence.' },
      { word: 'luck', explanation: 'General good fortune', example_sentence: 'Good luck to you.' },
    ],
    confidence: 0.94,
    native_alternatives: ['Fügung', 'glückliche Fügung', 'Zufall'],
  };

  const result = buildEnrichedWord(word, translation, 'deepl', aiEnhancement, 'de');

  // Basic structure
  assertEquals(result.vocabulary_id, word.id);
  assertEquals(result.word, 'serendipity');

  // Meaning populated correctly
  assertEquals(result.meaning.primary_translation, 'glücklicher Zufall');
  assertEquals(result.meaning.alternative_translations, ['Fügung', 'glückliche Fügung', 'Zufall']);
  assertEquals(result.meaning.english_definition, 'The occurrence of events by chance in a happy way');
  assertEquals(result.meaning.part_of_speech, 'noun');
  assertEquals(result.meaning.synonyms, ['luck', 'fortune', 'chance']);
  assertEquals(result.meaning.confidence, 0.94);
  assertEquals(result.meaning.source, 'deepl+ai');

  // Cues generated
  const cueTypes = result.meaning.cues.map(c => c.cue_type);
  assertEquals(cueTypes.includes('translation'), true);
  assertEquals(cueTypes.includes('definition'), true);
  assertEquals(cueTypes.includes('synonym'), true);
  assertEquals(cueTypes.includes('disambiguation'), true);

  // Confusable set
  assertExists(result.confusable_set);
  assertEquals(result.confusable_set!.words.includes('serendipity'), true);
  assertEquals(result.confusable_set!.words.includes('coincidence'), true);
  assertEquals(result.confusable_set!.words.includes('luck'), true);
});

Deno.test('Complete flow: Google only (no OpenAI)', () => {
  const word = makeWord({ word: 'test' });
  const translation = 'prueba';

  const result = buildEnrichedWord(word, translation, 'google', null, 'es');

  assertEquals(result.meaning.primary_translation, 'prueba');
  assertEquals(result.meaning.alternative_translations, []);
  assertEquals(result.meaning.english_definition, 'test (google translation)');
  assertEquals(result.meaning.part_of_speech, null);
  assertEquals(result.meaning.synonyms, []);
  assertEquals(result.meaning.confidence, 0.7);
  assertEquals(result.meaning.source, 'google');
  assertEquals(result.confusable_set, null);

  // Only translation cue
  assertEquals(result.meaning.cues.length, 1);
  assertEquals(result.meaning.cues[0].cue_type, 'translation');
});

Deno.test('Complete flow: No translation service (fallback)', () => {
  const word = makeWord({ word: 'esoteric' });

  const result = buildEnrichedWord(word, 'esoteric', 'none', null, 'de');

  assertEquals(result.meaning.primary_translation, 'esoteric');
  assertEquals(result.meaning.alternative_translations, []);
  assertEquals(result.meaning.english_definition, 'esoteric (none translation)');
  assertEquals(result.meaning.confidence, 0.3);
  assertEquals(result.meaning.source, 'none');
});
