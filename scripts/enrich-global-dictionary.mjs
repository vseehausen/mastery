#!/usr/bin/env node

/**
 * Batch enrichment script for global_dictionary
 *
 * Usage:
 *   node scripts/enrich-global-dictionary.mjs --file words.txt --lang de
 *   node scripts/enrich-global-dictionary.mjs --words "hello,world" --lang de
 *
 * Requirements:
 * - DEEPL_API_KEY or GOOGLE_TRANSLATE_API_KEY for translation
 * - OPENAI_API_KEY for enrichment
 * - SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY for database access
 */

import { createClient } from '@supabase/supabase-js';
import { readFileSync } from 'fs';
import { exit } from 'process';
import { config } from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

// Load environment variables from supabase/.env.local
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
config({ path: join(__dirname, '../supabase/.env.local') });

// =============================================================================
// Configuration
// =============================================================================

const PARALLEL_WORKERS = 10;
const DEEPL_API_KEY = process.env.DEEPL_API_KEY;
const GOOGLE_TRANSLATE_API_KEY = process.env.GOOGLE_TRANSLATE_API_KEY;
const OPENAI_API_KEY = process.env.OPENAI_API_KEY;
const SUPABASE_URL = process.env.SUPABASE_URL || process.env.VITE_SUPABASE_URL;
const SUPABASE_PUBLISHABLE_KEY = process.env.SUPABASE_PUBLISHABLE_KEY || process.env.VITE_SUPABASE_PUBLISHABLE_KEY;

// Cost tracking (approximate)
let deeplCalls = 0;
let googleCalls = 0;
let openaiCalls = 0;
const DEEPL_COST_PER_CHAR = 0.00002; // $20 per 1M chars
const GOOGLE_COST_PER_CHAR = 0.00002; // $20 per 1M chars
const OPENAI_COST_PER_TOKEN = 0.00015 / 1000; // $0.15 per 1M tokens for gpt-4o-mini

// =============================================================================
// Validation
// =============================================================================

function validateEnv() {
  const errors = [];

  if (!OPENAI_API_KEY) {
    errors.push('OPENAI_API_KEY is required');
  }

  if (!DEEPL_API_KEY && !GOOGLE_TRANSLATE_API_KEY) {
    errors.push('Either DEEPL_API_KEY or GOOGLE_TRANSLATE_API_KEY is required');
  }

  if (!SUPABASE_URL) {
    errors.push('SUPABASE_URL is required');
  }

  if (!SUPABASE_PUBLISHABLE_KEY) {
    errors.push('SUPABASE_PUBLISHABLE_KEY is required');
  }

  if (errors.length > 0) {
    console.error('Environment validation failed:');
    errors.forEach(err => console.error(`  - ${err}`));
    exit(1);
  }
}

// =============================================================================
// Argument Parsing
// =============================================================================

function parseArgs() {
  const args = process.argv.slice(2);
  const parsed = { words: [], lang: 'de' };

  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--file' && args[i + 1]) {
      const content = readFileSync(args[i + 1], 'utf-8');
      parsed.words = content.split('\n')
        .map(w => w.trim())
        .filter(w => w.length > 0);
      i++;
    } else if (args[i] === '--words' && args[i + 1]) {
      parsed.words = args[i + 1].split(',').map(w => w.trim()).filter(w => w.length > 0);
      i++;
    } else if (args[i] === '--lang' && args[i + 1]) {
      parsed.lang = args[i + 1];
      i++;
    }
  }

  if (parsed.words.length === 0) {
    console.error('Usage: node enrich-global-dictionary.mjs --file words.txt --lang de');
    console.error('   OR: node enrich-global-dictionary.mjs --words "hello,world" --lang de');
    exit(1);
  }

  return parsed;
}

// =============================================================================
// Database Client
// =============================================================================

const supabase = createClient(SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY);

// =============================================================================
// Content Hash
// =============================================================================

async function generateContentHash(lemma) {
  const crypto = await import('crypto');
  const hash = crypto.createHash('sha256');
  hash.update(lemma.toLowerCase());
  return hash.digest('hex');
}

// =============================================================================
// Translation
// =============================================================================

async function getDeepLTranslation(word, targetLang) {
  const response = await fetch('https://api-free.deepl.com/v2/translate', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `DeepL-Auth-Key ${DEEPL_API_KEY}`,
    },
    body: JSON.stringify({
      text: [word],
      source_lang: 'EN',
      target_lang: targetLang.toUpperCase(),
    }),
  });

  if (!response.ok) {
    throw new Error(`DeepL API error: ${response.status}`);
  }

  const data = await response.json();
  const translation = data.translations?.[0]?.text || null;

  if (translation) {
    const cleaned = translation.trim();
    if (cleaned.length < 2 || cleaned.toLowerCase() === word.toLowerCase()) {
      return null;
    }
  }

  deeplCalls++;
  return translation;
}

async function getGoogleTranslation(word, targetLang) {
  const response = await fetch(
    `https://translation.googleapis.com/language/translate/v2?key=${GOOGLE_TRANSLATE_API_KEY}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        q: word,
        source: 'en',
        target: targetLang,
        format: 'text',
      }),
    }
  );

  if (!response.ok) {
    throw new Error(`Google Translate API error: ${response.status}`);
  }

  const data = await response.json();
  const translation = data.data?.translations?.[0]?.translatedText || null;

  if (translation) {
    const cleaned = translation.trim();
    if (cleaned.length < 2 || cleaned.toLowerCase() === word.toLowerCase()) {
      return null;
    }
  }

  googleCalls++;
  return translation;
}

async function translate(word, targetLang) {
  if (DEEPL_API_KEY) {
    try {
      const result = await getDeepLTranslation(word, targetLang);
      if (result) return result;
    } catch (err) {
      console.warn(`DeepL failed for "${word}": ${err.message}`);
    }
  }

  if (GOOGLE_TRANSLATE_API_KEY) {
    try {
      const result = await getGoogleTranslation(word, targetLang);
      if (result) return result;
    } catch (err) {
      console.warn(`Google Translate failed for "${word}": ${err.message}`);
    }
  }

  throw new Error('Translation failed');
}

// =============================================================================
// Enrichment (GPT-4o-mini)
// =============================================================================

async function enrichWord(word, translation, targetLang) {
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
          content: `You are a language learning assistant. Given an English word and its translation, provide:
1. lemma: the dictionary/base form of the word
2. pronunciation: IPA pronunciation of the lemma
3. english_definition: concise English definition (1-2 sentences)
4. part_of_speech: noun, verb, adjective, adverb, etc.

Respond as JSON with exactly these keys: lemma, pronunciation, english_definition, part_of_speech.`,
        },
        {
          role: 'user',
          content: `Word: "${word}"\nTranslation (${targetLang}): "${translation}"`,
        },
      ],
    }),
  });

  if (!response.ok) {
    const errorData = await response.text();
    throw new Error(`OpenAI API error: ${response.status} - ${errorData}`);
  }

  const data = await response.json();
  const content = data.choices?.[0]?.message?.content;

  if (!content) {
    throw new Error('No content in OpenAI response');
  }

  openaiCalls++;
  return JSON.parse(content);
}

// =============================================================================
// Worker
// =============================================================================

async function processWord(word, targetLang) {
  try {
    // Normalize word
    const lemma = word.toLowerCase().trim();
    const contentHash = await generateContentHash(lemma);

    // Check if already exists in global_dictionary
    const { data: existing } = await supabase
      .from('global_dictionary')
      .select('id')
      .eq('content_hash', contentHash)
      .single();

    if (existing) {
      return { status: 'skipped', word, reason: 'already_exists' };
    }

    // Translate
    const translation = await translate(word, targetLang);

    // Enrich
    const enriched = await enrichWord(word, translation, targetLang);

    // Insert to global_dictionary
    const { error} = await supabase
      .from('global_dictionary')
      .insert({
        word: enriched.lemma || lemma,
        stem: enriched.lemma || lemma,
        content_hash: contentHash,
        part_of_speech: enriched.part_of_speech || null,
        english_definition: enriched.english_definition || '',
        pronunciation_ipa: enriched.pronunciation || '',
        translations: {
          [targetLang]: {
            primary: translation,
            alternatives: [],
          }
        },
        synonyms: [],
        antonyms: [],
        confusables: [],
        example_sentences: [],
        confidence: 0.8,
      });

    if (error) {
      // Handle race condition with ON CONFLICT
      if (error.code === '23505') {
        return { status: 'skipped', word, reason: 'race_condition' };
      }
      throw error;
    }

    return { status: 'success', word, lemma: enriched.lemma || lemma };
  } catch (err) {
    return { status: 'error', word, error: err.message };
  }
}

// =============================================================================
// Worker Pool
// =============================================================================

async function processWordsInParallel(words, targetLang) {
  const results = {
    success: 0,
    skipped: 0,
    error: 0,
    errors: [],
  };

  const queue = [...words];
  const workers = [];

  async function worker() {
    while (queue.length > 0) {
      const word = queue.shift();
      if (!word) break;

      const result = await processWord(word, targetLang);

      if (result.status === 'success') {
        results.success++;
        console.log(`✓ ${result.word} → ${result.lemma}`);
      } else if (result.status === 'skipped') {
        results.skipped++;
        console.log(`⊘ ${result.word} (${result.reason})`);
      } else if (result.status === 'error') {
        results.error++;
        results.errors.push({ word: result.word, error: result.error });
        console.error(`✗ ${result.word}: ${result.error}`);
      }
    }
  }

  // Spawn workers
  for (let i = 0; i < PARALLEL_WORKERS; i++) {
    workers.push(worker());
  }

  // Wait for all workers to complete
  await Promise.all(workers);

  return results;
}

// =============================================================================
// Main
// =============================================================================

async function main() {
  console.log('🚀 Batch enrichment script for global_dictionary\n');

  validateEnv();
  const { words, lang } = parseArgs();

  console.log(`📝 Processing ${words.length} words (target language: ${lang})`);
  console.log(`⚙️  Using ${PARALLEL_WORKERS} parallel workers\n`);

  const startTime = Date.now();
  const results = await processWordsInParallel(words, lang);
  const duration = ((Date.now() - startTime) / 1000).toFixed(2);

  console.log('\n' + '='.repeat(60));
  console.log('📊 Summary');
  console.log('='.repeat(60));
  console.log(`✓ Success:       ${results.success}`);
  console.log(`⊘ Skipped:       ${results.skipped}`);
  console.log(`✗ Errors:        ${results.error}`);
  console.log(`⏱  Duration:      ${duration}s`);
  console.log('\n💰 Cost Estimates:');
  console.log(`   DeepL calls:   ${deeplCalls} (~$${(deeplCalls * 10 * DEEPL_COST_PER_CHAR).toFixed(4)})`);
  console.log(`   Google calls:  ${googleCalls} (~$${(googleCalls * 10 * GOOGLE_COST_PER_CHAR).toFixed(4)})`);
  console.log(`   OpenAI calls:  ${openaiCalls} (~$${(openaiCalls * 500 * OPENAI_COST_PER_TOKEN).toFixed(4)})`);

  if (results.errors.length > 0) {
    console.log('\n❌ Errors:');
    results.errors.forEach(({ word, error }) => {
      console.log(`   ${word}: ${error}`);
    });
  }
}

main().catch(err => {
  console.error('Fatal error:', err);
  exit(1);
});
