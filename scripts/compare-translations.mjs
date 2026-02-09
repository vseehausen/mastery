#!/usr/bin/env node

/**
 * Translation Comparison Script
 *
 * Compares DeepL vs Google Translate for vocabulary words.
 *
 * Usage: node scripts/compare-translations.mjs developer experience release
 *
 * Saves results to scripts/translations/<word>/deepl.json and google.json
 */

import { readFileSync, mkdirSync, writeFileSync, existsSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Load environment variables from supabase/.env.local
const envPath = join(__dirname, '../supabase/.env.local');
let DEEPL_API_KEY, GOOGLE_TRANSLATE_API_KEY, RAPIDAPI_KEY, OPENAI_API_KEY, ANTHROPIC_API_KEY;

try {
  const envContent = readFileSync(envPath, 'utf8');
  const lines = envContent.split('\n');

  for (const line of lines) {
    if (line.startsWith('DEEPL_API_KEY=')) {
      DEEPL_API_KEY = line.split('=')[1].trim();
    } else if (line.startsWith('GOOGLE_TRANSLATE_API_KEY=')) {
      GOOGLE_TRANSLATE_API_KEY = line.split('=')[1].trim();
    } else if (line.startsWith('RAPIDAPI_KEY=')) {
      RAPIDAPI_KEY = line.split('=')[1].trim();
    } else if (line.startsWith('OPENAI_API_KEY=')) {
      OPENAI_API_KEY = line.split('=')[1].trim();
    } else if (line.startsWith('ANTHROPIC_API_KEY=')) {
      ANTHROPIC_API_KEY = line.split('=')[1].trim();
    }
  }

  if (!DEEPL_API_KEY || !GOOGLE_TRANSLATE_API_KEY) {
    console.error('Error: Missing API keys in supabase/.env.local');
    process.exit(1);
  }

  if (!RAPIDAPI_KEY) {
    console.warn('Warning: RAPIDAPI_KEY not found - WordsAPI will be skipped');
  }

  if (!OPENAI_API_KEY) {
    console.warn('Warning: OPENAI_API_KEY not found - OpenAI enrichment will be skipped');
  }

  if (!ANTHROPIC_API_KEY) {
    console.warn('Warning: ANTHROPIC_API_KEY not found - Claude enrichment will be skipped');
  }
} catch (error) {
  console.error(`Error loading environment variables: ${error.message}`);
  process.exit(1);
}

const TARGET_LANG = 'de'; // German for testing

/**
 * Call DeepL API
 */
async function callDeepL(word) {
  const startTime = Date.now();

  try {
    const response = await fetch('https://api-free.deepl.com/v2/translate', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `DeepL-Auth-Key ${DEEPL_API_KEY}`
      },
      body: JSON.stringify({
        text: [word],
        source_lang: 'EN',
        target_lang: TARGET_LANG.toUpperCase(),
      }),
    });

    const duration_ms = Date.now() - startTime;

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }

    const data = await response.json();

    return {
      response: data,
      duration_ms,
      word,
      timestamp: new Date().toISOString(),
      success: true,
    };
  } catch (error) {
    const duration_ms = Date.now() - startTime;
    return {
      error: error.message,
      duration_ms,
      word,
      timestamp: new Date().toISOString(),
      success: false,
    };
  }
}

/**
 * Call Google Translate API
 */
async function callGoogleTranslate(word) {
  const startTime = Date.now();

  try {
    const response = await fetch(
      `https://translation.googleapis.com/language/translate/v2?key=${GOOGLE_TRANSLATE_API_KEY}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          q: word,
          source: 'en',
          target: TARGET_LANG,
          format: 'text',
        }),
      }
    );

    const duration_ms = Date.now() - startTime;

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }

    const data = await response.json();

    return {
      response: data,
      duration_ms,
      word,
      timestamp: new Date().toISOString(),
      success: true,
    };
  } catch (error) {
    const duration_ms = Date.now() - startTime;
    return {
      error: error.message,
      duration_ms,
      word,
      timestamp: new Date().toISOString(),
      success: false,
    };
  }
}

/**
 * Call Google Natural Language API - Syntax Analysis
 */
async function callGoogleSyntax(word) {
  const startTime = Date.now();

  try {
    const response = await fetch(
      `https://language.googleapis.com/v1/documents:analyzeSyntax?key=${GOOGLE_TRANSLATE_API_KEY}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          document: {
            type: 'PLAIN_TEXT',
            content: word,
            language: 'en',
          },
          encodingType: 'UTF8',
        }),
      }
    );

    const duration_ms = Date.now() - startTime;

    if (!response.ok) {
      const errorBody = await response.text();
      throw new Error(`HTTP ${response.status}: ${response.statusText} - ${errorBody}`);
    }

    const data = await response.json();

    return {
      response: data,
      duration_ms,
      word,
      timestamp: new Date().toISOString(),
      success: true,
    };
  } catch (error) {
    const duration_ms = Date.now() - startTime;
    return {
      error: error.message,
      duration_ms,
      word,
      timestamp: new Date().toISOString(),
      success: false,
    };
  }
}

/**
 * Call Free Dictionary API
 */
async function callFreeDictionary(word) {
  const startTime = Date.now();

  try {
    const response = await fetch(
      `https://api.dictionaryapi.dev/api/v2/entries/en/${word}`
    );

    const duration_ms = Date.now() - startTime;

    if (!response.ok) {
      const errorBody = await response.text();
      throw new Error(`HTTP ${response.status}: ${response.statusText} - ${errorBody}`);
    }

    const data = await response.json();

    return {
      response: data,
      duration_ms,
      word,
      timestamp: new Date().toISOString(),
      success: true,
    };
  } catch (error) {
    const duration_ms = Date.now() - startTime;
    return {
      error: error.message,
      duration_ms,
      word,
      timestamp: new Date().toISOString(),
      success: false,
    };
  }
}

/**
 * Call OpenAI for vocabulary enrichment (using production prompt)
 */
async function callOpenAI(word, primaryTranslation, nativeLanguageCode = 'de') {
  if (!OPENAI_API_KEY) {
    return {
      error: 'OPENAI_API_KEY not configured',
      duration_ms: 0,
      word,
      timestamp: new Date().toISOString(),
      success: false,
    };
  }

  const startTime = Date.now();

  const langNames = {
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
- part_of_speech: noun/verb/adjective/adverb/other (string)
- confusables: array of commonly confused words (max 3), each with:
  - word: the confusable English word
  - explanation: one-sentence distinction in English
  - example_sentence: English sentence demonstrating correct usage
- confidence: 0.0-1.0 indicating overall confidence
- native_alternatives: 2-4 alternative ${langName} translations (synonyms/near-synonyms in ${langName}, NOT "${primaryTranslation}", no trivial inflections like plural forms, no duplicates). If no good alternatives exist, return empty array [].

Word: ${word}
Stem: ${word}
Context: none
Primary ${langName} translation: ${primaryTranslation}`;

  try {
    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${OPENAI_API_KEY}`,
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

    const duration_ms = Date.now() - startTime;

    if (!response.ok) {
      const errorBody = await response.text();
      throw new Error(`HTTP ${response.status}: ${response.statusText} - ${errorBody}`);
    }

    const data = await response.json();
    const content = data.choices?.[0]?.message?.content;
    if (!content) throw new Error('No content in OpenAI response');

    const parsed = JSON.parse(content);

    return {
      response: parsed,
      duration_ms,
      word,
      timestamp: new Date().toISOString(),
      success: true,
    };
  } catch (error) {
    const duration_ms = Date.now() - startTime;
    return {
      error: error.message,
      duration_ms,
      word,
      timestamp: new Date().toISOString(),
      success: false,
    };
  }
}

/**
 * Call Claude API for vocabulary enrichment (using same prompt as OpenAI)
 */
async function callClaude(word, primaryTranslation, nativeLanguageCode = 'de') {
  if (!ANTHROPIC_API_KEY) {
    return {
      error: 'ANTHROPIC_API_KEY not configured',
      duration_ms: 0,
      word,
      timestamp: new Date().toISOString(),
      success: false,
    };
  }

  const startTime = Date.now();

  const langNames = {
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
- part_of_speech: noun/verb/adjective/adverb/other (string)
- confusables: array of commonly confused words (max 3), each with:
  - word: the confusable English word
  - explanation: one-sentence distinction in English
  - example_sentence: English sentence demonstrating correct usage
- confidence: 0.0-1.0 indicating overall confidence
- native_alternatives: 2-4 alternative ${langName} translations (synonyms/near-synonyms in ${langName}, NOT "${primaryTranslation}", no trivial inflections like plural forms, no duplicates). If no good alternatives exist, return empty array [].

Word: ${word}
Stem: ${word}
Context: none
Primary ${langName} translation: ${primaryTranslation}

Return ONLY valid JSON, no other text.`;

  try {
    const response = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'x-api-key': ANTHROPIC_API_KEY,
        'anthropic-version': '2023-06-01',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'claude-haiku-4-5-20251001',
        max_tokens: 1000,
        temperature: 0.3,
        messages: [{
          role: 'user',
          content: prompt,
        }],
      }),
    });

    const duration_ms = Date.now() - startTime;

    if (!response.ok) {
      const errorBody = await response.text();
      throw new Error(`HTTP ${response.status}: ${response.statusText} - ${errorBody}`);
    }

    const data = await response.json();
    const content = data.content?.[0]?.text;
    if (!content) throw new Error('No content in Claude response');

    // Strip markdown code fences if present
    const cleanContent = content.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();
    const parsed = JSON.parse(cleanContent);

    return {
      response: parsed,
      duration_ms,
      word,
      timestamp: new Date().toISOString(),
      success: true,
    };
  } catch (error) {
    const duration_ms = Date.now() - startTime;
    return {
      error: error.message,
      duration_ms,
      word,
      timestamp: new Date().toISOString(),
      success: false,
    };
  }
}

/**
 * Call OpenAI GPT-5-nano for vocabulary enrichment
 */
async function callGPT5Nano(word, primaryTranslation, nativeLanguageCode = 'de') {
  if (!OPENAI_API_KEY) {
    return {
      error: 'OPENAI_API_KEY not configured',
      duration_ms: 0,
      word,
      timestamp: new Date().toISOString(),
      success: false,
    };
  }

  const startTime = Date.now();

  const langNames = {
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
- part_of_speech: noun/verb/adjective/adverb/other (string)
- confusables: array of commonly confused words (max 3), each with:
  - word: the confusable English word
  - explanation: one-sentence distinction in English
  - example_sentence: English sentence demonstrating correct usage
- confidence: 0.0-1.0 indicating overall confidence
- native_alternatives: 2-4 alternative ${langName} translations (synonyms/near-synonyms in ${langName}, NOT "${primaryTranslation}", no trivial inflections like plural forms, no duplicates). If no good alternatives exist, return empty array [].

Word: ${word}
Stem: ${word}
Context: none
Primary ${langName} translation: ${primaryTranslation}`;

  try {
    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${OPENAI_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'gpt-5-nano',
        messages: [{ role: 'user', content: prompt }],
        response_format: {
          type: 'json_schema',
          json_schema: {
            name: 'VocabularyEnrichment',
            strict: true,
            schema: {
              type: 'object',
              properties: {
                stem: { type: 'string' },
                english_definition: { type: 'string' },
                synonyms: { type: 'array', items: { type: 'string' } },
                part_of_speech: { type: 'string', enum: ['noun', 'verb', 'adjective', 'adverb', 'other'] },
                confusables: {
                  type: 'array',
                  items: {
                    type: 'object',
                    properties: {
                      word: { type: 'string' },
                      explanation: { type: 'string' },
                      example_sentence: { type: 'string' }
                    },
                    required: ['word', 'explanation', 'example_sentence'],
                    additionalProperties: false
                  }
                },
                confidence: { type: 'number' },
                native_alternatives: { type: 'array', items: { type: 'string' } }
              },
              required: ['stem', 'english_definition', 'synonyms', 'part_of_speech', 'confusables', 'confidence', 'native_alternatives'],
              additionalProperties: false
            }
          }
        },
        max_completion_tokens: 2000,
      }),
    });

    const duration_ms = Date.now() - startTime;

    if (!response.ok) {
      const errorBody = await response.text();
      throw new Error(`HTTP ${response.status}: ${response.statusText} - ${errorBody}`);
    }

    const data = await response.json();
    const content = data.choices?.[0]?.message?.content;
    if (!content) {
      // Save full response for debugging GPT-5-nano
      return {
        error: 'No content in GPT-5-nano response',
        debug_response: data,
        duration_ms,
        word,
        timestamp: new Date().toISOString(),
        success: false,
      };
    }

    const parsed = JSON.parse(content);

    return {
      response: parsed,
      duration_ms,
      word,
      timestamp: new Date().toISOString(),
      success: true,
    };
  } catch (error) {
    const duration_ms = Date.now() - startTime;
    return {
      error: error.message,
      duration_ms,
      word,
      timestamp: new Date().toISOString(),
      success: false,
    };
  }
}

/**
 * Call OpenAI GPT-5-mini for vocabulary enrichment
 */
async function callGPT5Mini(word, primaryTranslation, nativeLanguageCode = 'de') {
  if (!OPENAI_API_KEY) {
    return {
      error: 'OPENAI_API_KEY not configured',
      duration_ms: 0,
      word,
      timestamp: new Date().toISOString(),
      success: false,
    };
  }

  const startTime = Date.now();

  const langNames = {
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
- part_of_speech: noun/verb/adjective/adverb/other (string)
- confusables: array of commonly confused words (max 3), each with:
  - word: the confusable English word
  - explanation: one-sentence distinction in English
  - example_sentence: English sentence demonstrating correct usage
- confidence: 0.0-1.0 indicating overall confidence
- native_alternatives: 2-4 alternative ${langName} translations (synonyms/near-synonyms in ${langName}, NOT "${primaryTranslation}", no trivial inflections like plural forms, no duplicates). If no good alternatives exist, return empty array [].

Word: ${word}
Stem: ${word}
Context: none
Primary ${langName} translation: ${primaryTranslation}`;

  try {
    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${OPENAI_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'gpt-5-mini',
        messages: [{ role: 'user', content: prompt }],
        response_format: {
          type: 'json_schema',
          json_schema: {
            name: 'VocabularyEnrichment',
            strict: true,
            schema: {
              type: 'object',
              properties: {
                stem: { type: 'string' },
                english_definition: { type: 'string' },
                synonyms: { type: 'array', items: { type: 'string' } },
                part_of_speech: { type: 'string', enum: ['noun', 'verb', 'adjective', 'adverb', 'other'] },
                confusables: {
                  type: 'array',
                  items: {
                    type: 'object',
                    properties: {
                      word: { type: 'string' },
                      explanation: { type: 'string' },
                      example_sentence: { type: 'string' }
                    },
                    required: ['word', 'explanation', 'example_sentence'],
                    additionalProperties: false
                  }
                },
                confidence: { type: 'number' },
                native_alternatives: { type: 'array', items: { type: 'string' } }
              },
              required: ['stem', 'english_definition', 'synonyms', 'part_of_speech', 'confusables', 'confidence', 'native_alternatives'],
              additionalProperties: false
            }
          }
        },
        max_completion_tokens: 2000,
      }),
    });

    const duration_ms = Date.now() - startTime;

    if (!response.ok) {
      const errorBody = await response.text();
      throw new Error(`HTTP ${response.status}: ${response.statusText} - ${errorBody}`);
    }

    const data = await response.json();
    const content = data.choices?.[0]?.message?.content;
    if (!content) {
      // Save full response for debugging GPT-5-mini
      return {
        error: 'No content in GPT-5-mini response',
        debug_response: data,
        duration_ms,
        word,
        timestamp: new Date().toISOString(),
        success: false,
      };
    }

    const parsed = JSON.parse(content);

    return {
      response: parsed,
      duration_ms,
      word,
      timestamp: new Date().toISOString(),
      success: true,
    };
  } catch (error) {
    const duration_ms = Date.now() - startTime;
    return {
      error: error.message,
      duration_ms,
      word,
      timestamp: new Date().toISOString(),
      success: false,
    };
  }
}

/**
 * Call WordsAPI via RapidAPI
 */
async function callWordsAPI(word) {
  if (!RAPIDAPI_KEY) {
    return {
      error: 'RAPIDAPI_KEY not configured',
      duration_ms: 0,
      word,
      timestamp: new Date().toISOString(),
      success: false,
    };
  }

  const startTime = Date.now();

  try {
    const response = await fetch(
      `https://wordsapiv1.p.rapidapi.com/words/${word}`,
      {
        method: 'GET',
        headers: {
          'X-RapidAPI-Key': RAPIDAPI_KEY,
          'X-RapidAPI-Host': 'wordsapiv1.p.rapidapi.com',
        },
      }
    );

    const duration_ms = Date.now() - startTime;

    if (!response.ok) {
      const errorBody = await response.text();
      throw new Error(`HTTP ${response.status}: ${response.statusText} - ${errorBody}`);
    }

    const data = await response.json();

    return {
      response: data,
      duration_ms,
      word,
      timestamp: new Date().toISOString(),
      success: true,
    };
  } catch (error) {
    const duration_ms = Date.now() - startTime;
    return {
      error: error.message,
      duration_ms,
      word,
      timestamp: new Date().toISOString(),
      success: false,
    };
  }
}

/**
 * Check if cached result exists and load it
 */
function getCachedResult(word, provider) {
  const outputPath = join(__dirname, 'translations', word, `${provider}.json`);
  if (existsSync(outputPath)) {
    try {
      const content = readFileSync(outputPath, 'utf8');
      return JSON.parse(content);
    } catch (error) {
      // If file is corrupted, return null to re-fetch
      return null;
    }
  }
  return null;
}

/**
 * Save results to file
 */
function saveResults(word, provider, results) {
  const outputDir = join(__dirname, 'translations', word);
  mkdirSync(outputDir, { recursive: true });

  const outputPath = join(outputDir, `${provider}.json`);
  writeFileSync(outputPath, JSON.stringify(results, null, 2), 'utf8');

  return outputPath;
}

/**
 * Main function
 */
async function main() {
  const words = process.argv.slice(2);

  if (words.length === 0) {
    console.error('Usage: node compare-translations.mjs <word1> <word2> ...');
    console.error('Example: node compare-translations.mjs developer experience release');
    process.exit(1);
  }

  console.log(`\nComparing translations for ${words.length} word(s)...\n`);

  for (const word of words) {
    console.log(`Processing: ${word}`);

    // Call translation APIs first to get primary translation for LLM enrichment
    const deeplResult = getCachedResult(word, 'deepl') || await callDeepL(word);
    const googleResult = getCachedResult(word, 'google') || await callGoogleTranslate(word);

    const primaryTranslation = deeplResult.success
      ? deeplResult.response.translations?.[0]?.text
      : googleResult.success
        ? googleResult.response.data?.translations?.[0]?.translatedText
        : word;

    // Call all other APIs in parallel - only if not cached
    const [syntaxResult, freeDictResult, wordsApiResult, openaiResult, gpt5NanoResult, gpt5MiniResult, claudeResult] = await Promise.all([
      getCachedResult(word, 'google-syntax') || callGoogleSyntax(word),
      getCachedResult(word, 'freedict') || callFreeDictionary(word),
      getCachedResult(word, 'wordsapi') || callWordsAPI(word),
      getCachedResult(word, 'openai') || callOpenAI(word, primaryTranslation, 'de'),
      getCachedResult(word, 'gpt5-nano') || callGPT5Nano(word, primaryTranslation, 'de'),
      getCachedResult(word, 'gpt5-mini') || callGPT5Mini(word, primaryTranslation, 'de'),
      getCachedResult(word, 'claude') || callClaude(word, primaryTranslation, 'de'),
    ]);

    // Save results
    const deeplPath = saveResults(word, 'deepl', deeplResult);
    const googlePath = saveResults(word, 'google', googleResult);
    const syntaxPath = saveResults(word, 'google-syntax', syntaxResult);
    const freeDictPath = saveResults(word, 'freedict', freeDictResult);
    const wordsApiPath = saveResults(word, 'wordsapi', wordsApiResult);
    const openaiPath = saveResults(word, 'openai', openaiResult);
    const gpt5NanoPath = saveResults(word, 'gpt5-nano', gpt5NanoResult);
    const gpt5MiniPath = saveResults(word, 'gpt5-mini', gpt5MiniResult);
    const claudePath = saveResults(word, 'claude', claudeResult);

    // Print summary
    console.log(`  DeepL:  ${deeplResult.success ? '✓' : '✗'} ${deeplResult.duration_ms}ms`);
    if (deeplResult.success) {
      const translation = deeplResult.response.translations?.[0]?.text || '(none)';
      console.log(`          → "${translation}"`);
    } else {
      console.log(`          Error: ${deeplResult.error}`);
    }

    console.log(`  Google: ${googleResult.success ? '✓' : '✗'} ${googleResult.duration_ms}ms`);
    if (googleResult.success) {
      const translation = googleResult.response.data?.translations?.[0]?.translatedText || '(none)';
      console.log(`          → "${translation}"`);
    } else {
      console.log(`          Error: ${googleResult.error}`);
    }

    console.log(`  Syntax: ${syntaxResult.success ? '✓' : '✗'} ${syntaxResult.duration_ms}ms`);
    if (syntaxResult.success) {
      const token = syntaxResult.response.tokens?.[0];
      if (token) {
        const pos = token.partOfSpeech?.tag || 'unknown';
        const lemma = token.lemma || word;
        console.log(`          → POS: ${pos}, Lemma: "${lemma}"`);
      }
    } else {
      console.log(`          Error: ${syntaxResult.error}`);
    }

    console.log(`  FreeDict: ${freeDictResult.success ? '✓' : '✗'} ${freeDictResult.duration_ms}ms`);
    if (freeDictResult.success) {
      const data = freeDictResult.response[0];
      const meaning = data?.meanings?.[0];
      if (meaning) {
        const definition = meaning.definitions[0]?.definition || '(none)';
        const partOfSpeech = meaning.partOfSpeech || 'unknown';
        const synonyms = meaning.synonyms?.slice(0, 3).join(', ') || 'none';
        console.log(`          → ${partOfSpeech}: ${definition}`);
        console.log(`          → Synonyms: ${synonyms}`);
      }
    } else {
      console.log(`          Error: ${freeDictResult.error}`);
    }

    console.log(`  WordsAPI: ${wordsApiResult.success ? '✓' : '✗'} ${wordsApiResult.duration_ms}ms`);
    if (wordsApiResult.success) {
      const data = wordsApiResult.response;
      const results = data.results?.[0];
      if (results) {
        const definition = results.definition || '(none)';
        const partOfSpeech = results.partOfSpeech || 'unknown';
        const synonyms = results.synonyms?.slice(0, 3).join(', ') || 'none';
        console.log(`          → ${partOfSpeech}: ${definition}`);
        console.log(`          → Synonyms: ${synonyms}`);
      }
    } else {
      console.log(`          Error: ${wordsApiResult.error}`);
    }

    console.log(`  OpenAI (4o-mini): ${openaiResult.success ? '✓' : '✗'} ${openaiResult.duration_ms}ms`);
    if (openaiResult.success) {
      const data = openaiResult.response;
      const definition = data.english_definition || '(none)';
      const partOfSpeech = data.part_of_speech || 'unknown';
      const synonyms = data.synonyms?.slice(0, 3).join(', ') || 'none';
      const confusables = data.confusables?.map(c => c.word).slice(0, 3).join(', ') || 'none';
      console.log(`          → ${partOfSpeech}: ${definition}`);
      console.log(`          → Synonyms: ${synonyms}`);
      console.log(`          → Confusables: ${confusables}`);
    } else {
      console.log(`          Error: ${openaiResult.error}`);
    }

    console.log(`  GPT-5-nano: ${gpt5NanoResult.success ? '✓' : '✗'} ${gpt5NanoResult.duration_ms}ms`);
    if (gpt5NanoResult.success) {
      const data = gpt5NanoResult.response;
      const definition = data.english_definition || '(none)';
      const partOfSpeech = data.part_of_speech || 'unknown';
      const synonyms = data.synonyms?.slice(0, 3).join(', ') || 'none';
      const confusables = data.confusables?.map(c => c.word).slice(0, 3).join(', ') || 'none';
      console.log(`          → ${partOfSpeech}: ${definition}`);
      console.log(`          → Synonyms: ${synonyms}`);
      console.log(`          → Confusables: ${confusables}`);
    } else {
      console.log(`          Error: ${gpt5NanoResult.error}`);
    }

    console.log(`  GPT-5-mini: ${gpt5MiniResult.success ? '✓' : '✗'} ${gpt5MiniResult.duration_ms}ms`);
    if (gpt5MiniResult.success) {
      const data = gpt5MiniResult.response;
      const definition = data.english_definition || '(none)';
      const partOfSpeech = data.part_of_speech || 'unknown';
      const synonyms = data.synonyms?.slice(0, 3).join(', ') || 'none';
      const confusables = data.confusables?.map(c => c.word).slice(0, 3).join(', ') || 'none';
      console.log(`          → ${partOfSpeech}: ${definition}`);
      console.log(`          → Synonyms: ${synonyms}`);
      console.log(`          → Confusables: ${confusables}`);
    } else {
      console.log(`          Error: ${gpt5MiniResult.error}`);
    }

    console.log(`  Claude (Haiku 4.5): ${claudeResult.success ? '✓' : '✗'} ${claudeResult.duration_ms}ms`);
    if (claudeResult.success) {
      const data = claudeResult.response;
      const definition = data.english_definition || '(none)';
      const partOfSpeech = data.part_of_speech || 'unknown';
      const synonyms = data.synonyms?.slice(0, 3).join(', ') || 'none';
      const confusables = data.confusables?.map(c => c.word).slice(0, 3).join(', ') || 'none';
      console.log(`          → ${partOfSpeech}: ${definition}`);
      console.log(`          → Synonyms: ${synonyms}`);
      console.log(`          → Confusables: ${confusables}`);
    } else {
      console.log(`          Error: ${claudeResult.error}`);
    }

    console.log(`  Saved: ${deeplPath.replace(__dirname + '/', '')}`);
    console.log(`         ${googlePath.replace(__dirname + '/', '')}`);
    console.log(`         ${syntaxPath.replace(__dirname + '/', '')}`);
    console.log(`         ${freeDictPath.replace(__dirname + '/', '')}`);
    console.log(`         ${wordsApiPath.replace(__dirname + '/', '')}`);
    console.log(`         ${openaiPath.replace(__dirname + '/', '')}`);
    console.log(`         ${gpt5NanoPath.replace(__dirname + '/', '')}`);
    console.log(`         ${gpt5MiniPath.replace(__dirname + '/', '')}`);
    console.log(`         ${claudePath.replace(__dirname + '/', '')}`);
    console.log();
  }

  console.log('Done!\n');
}

main().catch(error => {
  console.error('Fatal error:', error);
  process.exit(1);
});
