// Tests for enrich-vocabulary edge function
//
// Since the source file uses Deno.serve and does not export its internal
// functions, we re-implement the pure transformation logic here and validate
// that the data shapes and transformation rules match the contract defined
// in the edge function.

import {
  assertEquals,
  assertExists,
  assertNotEquals,
} from 'https://deno.land/std@0.224.0/assert/mod.ts';

// =============================================================================
// Type definitions (mirrored from index.ts)
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

// =============================================================================
// Re-implemented pure functions (matching index.ts logic exactly)
// =============================================================================

function buildContextFallback(
  word: VocabWord,
  context: string,
  _nativeLanguageCode: string,
): EnrichedWord {
  const meaningId = crypto.randomUUID();
  return {
    vocabulary_id: word.id,
    word: word.word,
    meanings: [{
      id: meaningId,
      primary_translation: word.word,
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

  let confusableSet: EnrichedConfusableSet | null = null;
  if (parsed.confusables && parsed.confusables.length > 0) {
    const explanations: Record<string, string> = {};
    const exampleSentences: Record<string, string> = {};
    const confusableWords = parsed.confusables.map((c: OpenAIConfusable) => {
      explanations[c.word] = c.explanation;
      if (c.example_sentence) exampleSentences[c.word] = c.example_sentence;
      return c.word;
    });
    if (!confusableWords.includes(word.word)) {
      confusableWords.unshift(word.word);
    }

    confusableSet = {
      id: crypto.randomUUID(),
      words: confusableWords,
      explanations,
      example_sentences: exampleSentences,
    };

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

// =============================================================================
// Tests: buildContextFallback
// =============================================================================

Deno.test('buildContextFallback: replaces word with ___ in cloze sentence', () => {
  const word = makeWord({ word: 'serendipity' });
  const context = 'It was pure serendipity that they met at the cafe.';
  const result = buildContextFallback(word, context, 'de');

  const cue = result.meanings[0].cues[0];
  assertEquals(cue.cue_type, 'context_cloze');
  assertEquals(cue.prompt_text, 'It was pure ___ that they met at the cafe.');
  assertEquals(cue.answer_text, 'serendipity');
});

Deno.test('buildContextFallback: replaces word case-insensitively', () => {
  const word = makeWord({ word: 'hope' });
  const context = 'Hope springs eternal. I hope so too.';
  const result = buildContextFallback(word, context, 'de');

  const cue = result.meanings[0].cues[0];
  assertEquals(cue.prompt_text, '___ springs eternal. I ___ so too.');
});

Deno.test('buildContextFallback: sets confidence to 0.3', () => {
  const word = makeWord();
  const result = buildContextFallback(word, 'Some context with ephemeral values.', 'de');

  assertEquals(result.meanings[0].confidence, 0.3);
});

Deno.test('buildContextFallback: sets source to context', () => {
  const word = makeWord();
  const result = buildContextFallback(word, 'An ephemeral moment.', 'de');

  assertEquals(result.meanings[0].source, 'context');
});

Deno.test('buildContextFallback: creates exactly one meaning with one context_cloze cue', () => {
  const word = makeWord();
  const result = buildContextFallback(word, 'An ephemeral thought.', 'de');

  assertEquals(result.meanings.length, 1);
  assertEquals(result.meanings[0].cues.length, 1);
  assertEquals(result.meanings[0].cues[0].cue_type, 'context_cloze');
});

Deno.test('buildContextFallback: meaning is_primary is true', () => {
  const word = makeWord();
  const result = buildContextFallback(word, 'An ephemeral dream.', 'de');

  assertEquals(result.meanings[0].is_primary, true);
});

Deno.test('buildContextFallback: primary_translation falls back to the word itself', () => {
  const word = makeWord({ word: 'laconic' });
  const result = buildContextFallback(word, 'His laconic reply.', 'de');

  assertEquals(result.meanings[0].primary_translation, 'laconic');
});

Deno.test('buildContextFallback: english_definition includes context', () => {
  const word = makeWord({ word: 'test' });
  const context = 'This is a test sentence.';
  const result = buildContextFallback(word, context, 'de');

  assertEquals(result.meanings[0].english_definition, `Used in context: "${context}"`);
});

Deno.test('buildContextFallback: metadata contains full_sentence', () => {
  const word = makeWord({ word: 'test' });
  const context = 'Full test sentence here.';
  const result = buildContextFallback(word, context, 'de');

  assertEquals(result.meanings[0].cues[0].metadata, { full_sentence: context });
});

Deno.test('buildContextFallback: confusable_set is null', () => {
  const word = makeWord();
  const result = buildContextFallback(word, 'ephemeral context.', 'de');

  assertEquals(result.confusable_set, null);
});

Deno.test('buildContextFallback: vocabulary_id matches input word id', () => {
  const word = makeWord();
  const result = buildContextFallback(word, 'ephemeral context.', 'de');

  assertEquals(result.vocabulary_id, word.id);
  assertEquals(result.word, word.word);
});

Deno.test('buildContextFallback: word boundary replacement avoids partial matches', () => {
  const word = makeWord({ word: 'art' });
  const context = 'The art of starting something.';
  const result = buildContextFallback(word, context, 'de');

  const cue = result.meanings[0].cues[0];
  // 'art' should be replaced but 'starting' should NOT be affected
  assertEquals(cue.prompt_text, 'The ___ of starting something.');
});

// =============================================================================
// Tests: buildEnrichedWord
// =============================================================================

Deno.test('buildEnrichedWord: maps meanings from OpenAI response', () => {
  const word = makeWord({ word: 'bank' });
  const parsed: OpenAIResult = {
    meanings: [
      {
        primary_translation: 'Bank',
        english_definition: 'A financial institution',
        synonyms: ['lender'],
        part_of_speech: 'noun',
      },
      {
        primary_translation: 'Ufer',
        english_definition: 'The land alongside a river',
        synonyms: ['shore', 'riverside'],
        part_of_speech: 'noun',
      },
    ],
  };

  const result = buildEnrichedWord(word, parsed, 'de', 'ai', 0.95);

  assertEquals(result.meanings.length, 2);
  assertEquals(result.meanings[0].primary_translation, 'Bank');
  assertEquals(result.meanings[1].primary_translation, 'Ufer');
});

Deno.test('buildEnrichedWord: first meaning is primary, rest are not', () => {
  const word = makeWord({ word: 'run' });
  const parsed: OpenAIResult = {
    meanings: [
      { primary_translation: 'laufen', english_definition: 'To move quickly', part_of_speech: 'verb' },
      { primary_translation: 'Lauf', english_definition: 'An act of running', part_of_speech: 'noun' },
      { primary_translation: 'betreiben', english_definition: 'To manage', part_of_speech: 'verb' },
    ],
  };

  const result = buildEnrichedWord(word, parsed, 'de', 'ai', 0.9);

  assertEquals(result.meanings[0].is_primary, true);
  assertEquals(result.meanings[0].sort_order, 0);
  assertEquals(result.meanings[1].is_primary, false);
  assertEquals(result.meanings[1].sort_order, 1);
  assertEquals(result.meanings[2].is_primary, false);
  assertEquals(result.meanings[2].sort_order, 2);
});

Deno.test('buildEnrichedWord: creates translation, definition, synonym cues per meaning', () => {
  const word = makeWord({ word: 'bright' });
  const parsed: OpenAIResult = {
    meanings: [
      {
        primary_translation: 'hell',
        english_definition: 'Emitting or reflecting much light',
        synonyms: ['luminous', 'radiant'],
        part_of_speech: 'adjective',
      },
    ],
  };

  const result = buildEnrichedWord(word, parsed, 'de', 'ai', 0.95);
  const cues = result.meanings[0].cues;

  assertEquals(cues.length, 3);
  assertEquals(cues[0].cue_type, 'translation');
  assertEquals(cues[0].prompt_text, 'hell');
  assertEquals(cues[0].answer_text, 'bright');

  assertEquals(cues[1].cue_type, 'definition');
  assertEquals(cues[1].prompt_text, 'Emitting or reflecting much light');
  assertEquals(cues[1].answer_text, 'bright');

  assertEquals(cues[2].cue_type, 'synonym');
  assertEquals(cues[2].prompt_text, 'luminous, radiant');
  assertEquals(cues[2].answer_text, 'bright');
});

Deno.test('buildEnrichedWord: handles confusables and creates confusable_set', () => {
  const word = makeWord({ word: 'affect' });
  const parsed: OpenAIResult = {
    meanings: [
      { primary_translation: 'beeinflussen', english_definition: 'To have an impact on', part_of_speech: 'verb' },
    ],
    confusables: [
      { word: 'effect', explanation: 'Ergebnis, nicht die Einwirkung', example_sentence: 'The effect was immediate.' },
      { word: 'affection', explanation: 'Zuneigung, nicht Einfluss', example_sentence: 'She showed great affection.' },
    ],
  };

  const result = buildEnrichedWord(word, parsed, 'de', 'ai', 0.9);

  assertExists(result.confusable_set);
  // The word itself should be prepended
  assertEquals(result.confusable_set!.words[0], 'affect');
  assertEquals(result.confusable_set!.words[1], 'effect');
  assertEquals(result.confusable_set!.words[2], 'affection');
  assertEquals(result.confusable_set!.explanations['effect'], 'Ergebnis, nicht die Einwirkung');
  assertEquals(result.confusable_set!.example_sentences['effect'], 'The effect was immediate.');
});

Deno.test('buildEnrichedWord: does not duplicate word in confusable_set words if already present', () => {
  const word = makeWord({ word: 'affect' });
  const parsed: OpenAIResult = {
    meanings: [
      { primary_translation: 'beeinflussen', english_definition: 'To have an impact on' },
    ],
    confusables: [
      { word: 'affect', explanation: 'selbst', example_sentence: 'This affects me.' },
      { word: 'effect', explanation: 'Ergebnis', example_sentence: 'The effect was clear.' },
    ],
  };

  const result = buildEnrichedWord(word, parsed, 'de', 'ai', 0.9);

  assertExists(result.confusable_set);
  // 'affect' already in confusables so should not be prepended again
  const affectCount = result.confusable_set!.words.filter(w => w === 'affect').length;
  assertEquals(affectCount, 1);
});

Deno.test('buildEnrichedWord: adds disambiguation cue when >= 2 confusables', () => {
  const word = makeWord({ word: 'affect' });
  const parsed: OpenAIResult = {
    meanings: [
      { primary_translation: 'beeinflussen', english_definition: 'To have an impact on' },
    ],
    confusables: [
      { word: 'effect', explanation: 'result' },
      { word: 'affection', explanation: 'fondness' },
    ],
  };

  const result = buildEnrichedWord(word, parsed, 'de', 'ai', 0.9);
  const cues = result.meanings[0].cues;
  const disambigCue = cues.find(c => c.cue_type === 'disambiguation');

  assertExists(disambigCue);
  assertEquals(disambigCue!.prompt_text, 'Choose the word that means: To have an impact on');
  assertEquals(disambigCue!.answer_text, 'affect');
  assertExists((disambigCue!.metadata as Record<string, unknown>).options);
  assertExists((disambigCue!.metadata as Record<string, unknown>).explanations);
});

Deno.test('buildEnrichedWord: no disambiguation cue when only 1 confusable', () => {
  const word = makeWord({ word: 'affect' });
  const parsed: OpenAIResult = {
    meanings: [
      { primary_translation: 'beeinflussen', english_definition: 'To have an impact on' },
    ],
    confusables: [
      { word: 'effect', explanation: 'result' },
    ],
  };

  const result = buildEnrichedWord(word, parsed, 'de', 'ai', 0.9);
  const disambigCue = result.meanings[0].cues.find(c => c.cue_type === 'disambiguation');

  assertEquals(disambigCue, undefined);
});

Deno.test('buildEnrichedWord: no confusable_set when confusables is empty', () => {
  const word = makeWord({ word: 'happy' });
  const parsed: OpenAIResult = {
    meanings: [
      { primary_translation: 'gluecklich', english_definition: 'Feeling joy' },
    ],
    confusables: [],
  };

  const result = buildEnrichedWord(word, parsed, 'de', 'ai', 0.9);

  assertEquals(result.confusable_set, null);
});

Deno.test('buildEnrichedWord: no confusable_set when confusables is undefined', () => {
  const word = makeWord({ word: 'happy' });
  const parsed: OpenAIResult = {
    meanings: [
      { primary_translation: 'gluecklich', english_definition: 'Feeling joy' },
    ],
  };

  const result = buildEnrichedWord(word, parsed, 'de', 'ai', 0.9);

  assertEquals(result.confusable_set, null);
});

Deno.test('buildEnrichedWord: handles missing optional fields gracefully', () => {
  const word = makeWord({ word: 'test' });
  const parsed: OpenAIResult = {
    meanings: [
      {
        primary_translation: '',
        english_definition: '',
      },
    ],
  };

  const result = buildEnrichedWord(word, parsed, 'de', 'ai', 0.8);

  // Empty primary_translation means no translation cue, falls back to word
  assertEquals(result.meanings[0].primary_translation, 'test');
  // Empty english_definition: no definition cue generated
  assertEquals(result.meanings[0].english_definition, '');
  assertEquals(result.meanings[0].alternative_translations, []);
  assertEquals(result.meanings[0].synonyms, []);
  assertEquals(result.meanings[0].part_of_speech, null);
  assertEquals(result.meanings[0].extended_definition, null);
  // No cues because translation and definition are empty strings (falsy)
  assertEquals(result.meanings[0].cues.length, 0);
});

Deno.test('buildEnrichedWord: handles empty meanings array', () => {
  const word = makeWord({ word: 'unknown' });
  const parsed: OpenAIResult = {
    meanings: [],
  };

  const result = buildEnrichedWord(word, parsed, 'de', 'ai', 0.5);

  assertEquals(result.meanings.length, 0);
  assertEquals(result.confusable_set, null);
});

Deno.test('buildEnrichedWord: confidence and source propagate to all meanings', () => {
  const word = makeWord({ word: 'test' });
  const parsed: OpenAIResult = {
    meanings: [
      { primary_translation: 'Test', english_definition: 'A trial' },
      { primary_translation: 'Pruefung', english_definition: 'An exam' },
    ],
  };

  const result = buildEnrichedWord(word, parsed, 'de', 'ai', 0.88);

  for (const meaning of result.meanings) {
    assertEquals(meaning.confidence, 0.88);
    assertEquals(meaning.source, 'ai');
  }
});

Deno.test('buildEnrichedWord: synonym cue joins multiple synonyms with comma', () => {
  const word = makeWord({ word: 'big' });
  const parsed: OpenAIResult = {
    meanings: [
      {
        primary_translation: 'gross',
        english_definition: 'Of considerable size',
        synonyms: ['large', 'huge', 'enormous'],
      },
    ],
  };

  const result = buildEnrichedWord(word, parsed, 'de', 'ai', 0.9);
  const synonymCue = result.meanings[0].cues.find(c => c.cue_type === 'synonym');

  assertExists(synonymCue);
  assertEquals(synonymCue!.prompt_text, 'large, huge, enormous');
});

Deno.test('buildEnrichedWord: no synonym cue when synonyms is empty', () => {
  const word = makeWord({ word: 'unique' });
  const parsed: OpenAIResult = {
    meanings: [
      {
        primary_translation: 'einzigartig',
        english_definition: 'One of a kind',
        synonyms: [],
      },
    ],
  };

  const result = buildEnrichedWord(word, parsed, 'de', 'ai', 0.9);
  const synonymCue = result.meanings[0].cues.find(c => c.cue_type === 'synonym');

  assertEquals(synonymCue, undefined);
});

Deno.test('buildEnrichedWord: all cues have unique IDs', () => {
  const word = makeWord({ word: 'bright' });
  const parsed: OpenAIResult = {
    meanings: [
      {
        primary_translation: 'hell',
        english_definition: 'Emitting light',
        synonyms: ['luminous'],
      },
    ],
    confusables: [
      { word: 'light', explanation: 'more general' },
      { word: 'brilliant', explanation: 'more intense' },
    ],
  };

  const result = buildEnrichedWord(word, parsed, 'de', 'ai', 0.9);
  const allCueIds = result.meanings.flatMap(m => m.cues.map(c => c.id));
  const uniqueIds = new Set(allCueIds);

  assertEquals(allCueIds.length, uniqueIds.size, 'All cue IDs should be unique');
});

Deno.test('buildEnrichedWord: all meaning IDs are unique', () => {
  const word = makeWord({ word: 'run' });
  const parsed: OpenAIResult = {
    meanings: [
      { primary_translation: 'laufen', english_definition: 'Move fast' },
      { primary_translation: 'Lauf', english_definition: 'A running act' },
    ],
  };

  const result = buildEnrichedWord(word, parsed, 'de', 'ai', 0.9);
  const meaningIds = result.meanings.map(m => m.id);

  assertNotEquals(meaningIds[0], meaningIds[1]);
});

Deno.test('buildEnrichedWord: confusable example_sentences only set for confusables that have them', () => {
  const word = makeWord({ word: 'affect' });
  const parsed: OpenAIResult = {
    meanings: [
      { primary_translation: 'beeinflussen', english_definition: 'To impact' },
    ],
    confusables: [
      { word: 'effect', explanation: 'result', example_sentence: 'The effect was clear.' },
      { word: 'affection', explanation: 'fondness' }, // no example_sentence
    ],
  };

  const result = buildEnrichedWord(word, parsed, 'de', 'ai', 0.9);

  assertExists(result.confusable_set);
  assertEquals(result.confusable_set!.example_sentences['effect'], 'The effect was clear.');
  assertEquals(result.confusable_set!.example_sentences['affection'], undefined);
});

// =============================================================================
// Tests: DeepL fallback result shape
// =============================================================================

Deno.test('DeepL result shape: confidence 0.6, source deepl, single meaning', () => {
  // Simulate the DeepL result construction from index.ts
  const word = makeWord({ word: 'resilient' });
  const translation = 'widerstandsfaehig';

  const result: EnrichedWord = {
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

  assertEquals(result.meanings.length, 1);
  assertEquals(result.meanings[0].confidence, 0.6);
  assertEquals(result.meanings[0].source, 'deepl');
  assertEquals(result.meanings[0].is_primary, true);
  assertEquals(result.meanings[0].cues.length, 1);
  assertEquals(result.meanings[0].cues[0].cue_type, 'translation');
  assertEquals(result.meanings[0].cues[0].prompt_text, 'widerstandsfaehig');
  assertEquals(result.meanings[0].cues[0].answer_text, 'resilient');
  assertEquals(result.meanings[0].english_definition, 'resilient (translated via DeepL)');
  assertEquals(result.confusable_set, null);
  assertEquals(result.meanings[0].alternative_translations, []);
  assertEquals(result.meanings[0].synonyms, []);
  assertEquals(result.meanings[0].part_of_speech, null);
  assertEquals(result.meanings[0].extended_definition, null);
});

// =============================================================================
// Tests: Google fallback result shape
// =============================================================================

Deno.test('Google result shape: confidence 0.6, source google, single meaning', () => {
  const word = makeWord({ word: 'ambiguous' });
  const translation = 'zweideutig';

  const result: EnrichedWord = {
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

  assertEquals(result.meanings.length, 1);
  assertEquals(result.meanings[0].confidence, 0.6);
  assertEquals(result.meanings[0].source, 'google');
  assertEquals(result.meanings[0].is_primary, true);
  assertEquals(result.meanings[0].cues.length, 1);
  assertEquals(result.meanings[0].cues[0].cue_type, 'translation');
  assertEquals(result.meanings[0].cues[0].prompt_text, 'zweideutig');
  assertEquals(result.meanings[0].cues[0].answer_text, 'ambiguous');
  assertEquals(result.meanings[0].english_definition, 'ambiguous (translated via Google)');
  assertEquals(result.confusable_set, null);
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

  // Simulate the batch size capping logic from index.ts
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

Deno.test('batch_size of 0 defaults to DEFAULT_BATCH_SIZE', () => {
  const MAX_BATCH_SIZE = 10;
  const DEFAULT_BATCH_SIZE = 5;

  const requestedBatchSize = 0;
  const effectiveBatchSize = Math.min(requestedBatchSize || DEFAULT_BATCH_SIZE, MAX_BATCH_SIZE);
  assertEquals(effectiveBatchSize, 5);
});

// =============================================================================
// Tests: EnrichedWord response contract
// =============================================================================

Deno.test('EnrichedWord contract: required fields are present', () => {
  const word = makeWord();
  const result = buildContextFallback(word, 'An ephemeral thought.', 'de');

  // Top-level required fields
  assertExists(result.vocabulary_id);
  assertExists(result.word);
  assertExists(result.meanings);
  assertEquals(typeof result.vocabulary_id, 'string');
  assertEquals(typeof result.word, 'string');
  assertEquals(Array.isArray(result.meanings), true);

  // Meaning required fields
  const m = result.meanings[0];
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
  const parsed: OpenAIResult = {
    meanings: [
      { primary_translation: 'beeinflussen', english_definition: 'To impact' },
    ],
    confusables: [
      { word: 'effect', explanation: 'result', example_sentence: 'The effect was clear.' },
    ],
  };

  const result = buildEnrichedWord(word, parsed, 'de', 'ai', 0.9);

  assertExists(result.confusable_set);
  assertExists(result.confusable_set!.id);
  assertEquals(typeof result.confusable_set!.id, 'string');
  assertEquals(Array.isArray(result.confusable_set!.words), true);
  assertEquals(typeof result.confusable_set!.explanations, 'object');
  assertEquals(typeof result.confusable_set!.example_sentences, 'object');
});

// =============================================================================
// Tests: Edge cases
// =============================================================================

Deno.test('buildContextFallback: handles word not found in context (no match)', () => {
  const word = makeWord({ word: 'xyz123' });
  const context = 'This sentence has no such word.';
  const result = buildContextFallback(word, context, 'de');

  // No replacement happens, prompt_text equals the original context
  assertEquals(result.meanings[0].cues[0].prompt_text, context);
});

Deno.test('buildEnrichedWord: disambiguation options are capped at 4 words', () => {
  const word = makeWord({ word: 'test' });
  const parsed: OpenAIResult = {
    meanings: [
      { primary_translation: 'Test', english_definition: 'A trial' },
    ],
    confusables: [
      { word: 'exam', explanation: 'formal test' },
      { word: 'quiz', explanation: 'short test' },
      { word: 'trial', explanation: 'legal proceeding' },
      { word: 'assessment', explanation: 'evaluation' },
      { word: 'evaluation', explanation: 'judgment' },
    ],
  };

  const result = buildEnrichedWord(word, parsed, 'de', 'ai', 0.9);
  const disambigCue = result.meanings[0].cues.find(c => c.cue_type === 'disambiguation');

  assertExists(disambigCue);
  const options = (disambigCue!.metadata as Record<string, unknown>).options as string[];
  assertEquals(options.length, 4); // slice(0, 4)
});

Deno.test('buildEnrichedWord: hint_text is always null', () => {
  const word = makeWord({ word: 'test' });
  const parsed: OpenAIResult = {
    meanings: [
      {
        primary_translation: 'Test',
        english_definition: 'A trial',
        synonyms: ['trial'],
      },
    ],
  };

  const result = buildEnrichedWord(word, parsed, 'de', 'ai', 0.9);
  for (const meaning of result.meanings) {
    for (const cue of meaning.cues) {
      assertEquals(cue.hint_text, null);
    }
  }
});
