#!/usr/bin/env node

/**
 * Data migration script for global_dictionary
 *
 * Migrates existing vocabulary from the meanings table to global_dictionary:
 * 1. SELECT DISTINCT ON (stem) from meanings, deduplicate by lemma picking highest-confidence
 * 2. For each unique lemma: compute content_hash(stem), INSERT INTO global_dictionary with ON CONFLICT DO NOTHING
 * 3. UPDATE vocabulary SET global_dictionary_id from global_dictionary where stem or word matches
 * 4. Report migration stats: X meanings migrated, Y vocabulary rows linked, Z orphaned
 *
 * Usage:
 *   node scripts/migrate-to-global-dictionary.mjs
 *
 * Requirements:
 * - SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY for database access
 */

import { createClient } from '@supabase/supabase-js';
import { createHash } from 'crypto';
import { exit } from 'process';

// =============================================================================
// Configuration
// =============================================================================

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

// =============================================================================
// Validation
// =============================================================================

function validateEnv() {
  const errors = [];

  if (!SUPABASE_URL) {
    errors.push('SUPABASE_URL is required');
  }

  if (!SUPABASE_SERVICE_ROLE_KEY) {
    errors.push('SUPABASE_SERVICE_ROLE_KEY is required');
  }

  if (errors.length > 0) {
    console.error('Environment validation failed:');
    errors.forEach(err => console.error(`  - ${err}`));
    exit(1);
  }
}

// =============================================================================
// Database Client
// =============================================================================

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

// =============================================================================
// Content Hash
// =============================================================================

function generateContentHash(lemma) {
  const hash = createHash('sha256');
  hash.update(lemma.toLowerCase());
  return hash.digest('hex');
}

// =============================================================================
// Migration Steps
// =============================================================================

async function getMeaningsToMigrate() {
  console.log('📥 Fetching meanings to migrate...');

  // Query to get distinct meanings by vocabulary stem, picking highest confidence
  // This uses a window function to rank meanings by confidence per vocabulary
  const { data, error } = await supabase.rpc('get_distinct_meanings_by_stem', {});

  if (error) {
    // Fallback: manual query if RPC doesn't exist
    console.log('⚠️  RPC not found, using fallback query');

    const { data: vocabularyData, error: vocabError } = await supabase
      .from('vocabulary')
      .select('id, stem, word')
      .not('stem', 'is', null)
      .is('deleted_at', null);

    if (vocabError) throw vocabError;

    // For each vocabulary, get the highest confidence meaning
    const meanings = [];
    for (const vocab of vocabularyData || []) {
      const { data: meaningData, error: meaningError } = await supabase
        .from('meanings')
        .select('vocabulary_id, primary_translation, part_of_speech, english_definition, confidence')
        .eq('vocabulary_id', vocab.id)
        .is('deleted_at', null)
        .eq('is_active', true)
        .order('confidence', { ascending: false })
        .limit(1)
        .single();

      if (!meaningError && meaningData) {
        meanings.push({
          stem: vocab.stem,
          word: vocab.word,
          vocabulary_id: vocab.id,
          primary_translation: meaningData.primary_translation,
          part_of_speech: meaningData.part_of_speech,
          english_definition: meaningData.english_definition,
          confidence: meaningData.confidence,
        });
      }
    }

    return meanings;
  }

  return data;
}

async function deduplicateByStem(meanings) {
  console.log('🔍 Deduplicating by stem...');

  // Group by stem, keep highest confidence
  const stemMap = new Map();

  for (const meaning of meanings) {
    const stem = meaning.stem?.toLowerCase().trim();
    if (!stem) continue;

    const existing = stemMap.get(stem);
    if (!existing || meaning.confidence > existing.confidence) {
      stemMap.set(stem, meaning);
    }
  }

  const deduplicated = Array.from(stemMap.values());
  console.log(`   Found ${meanings.length} meanings, deduplicated to ${deduplicated.length} unique stems`);

  return deduplicated;
}

async function insertToGlobalDictionary(meanings) {
  console.log('📝 Inserting to global_dictionary...');

  const results = {
    inserted: 0,
    skipped: 0,
    errors: [],
  };

  for (const meaning of meanings) {
    try {
      const stem = meaning.stem.toLowerCase().trim();
      const contentHash = generateContentHash(stem);

      const { error } = await supabase
        .from('global_dictionary')
        .insert({
          stem,
          content_hash: contentHash,
          language_code: 'en', // Assuming English vocabulary
          primary_translation: meaning.primary_translation || '',
          part_of_speech: meaning.part_of_speech || '',
          english_definition: meaning.english_definition || '',
          pronunciation: '',
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
        });

      if (error) {
        if (error.code === '23505') {
          // Duplicate key - ON CONFLICT DO NOTHING behavior
          results.skipped++;
        } else {
          results.errors.push({ stem, error: error.message });
        }
      } else {
        results.inserted++;
      }

      if ((results.inserted + results.skipped) % 100 === 0) {
        console.log(`   Progress: ${results.inserted + results.skipped} / ${meanings.length}`);
      }
    } catch (err) {
      results.errors.push({ stem: meaning.stem, error: err.message });
    }
  }

  console.log(`   ✓ Inserted: ${results.inserted}`);
  console.log(`   ⊘ Skipped (already exists): ${results.skipped}`);
  if (results.errors.length > 0) {
    console.log(`   ✗ Errors: ${results.errors.length}`);
  }

  return results;
}

async function linkVocabularyToGlobalDictionary() {
  console.log('🔗 Linking vocabulary to global_dictionary...');

  // Get all vocabulary entries
  const { data: vocabularyData, error: vocabError } = await supabase
    .from('vocabulary')
    .select('id, stem, word')
    .is('deleted_at', null);

  if (vocabError) throw vocabError;

  const results = {
    linked: 0,
    orphaned: 0,
    errors: [],
  };

  for (const vocab of vocabularyData || []) {
    try {
      const stem = vocab.stem?.toLowerCase().trim();
      if (!stem) {
        results.orphaned++;
        continue;
      }

      const contentHash = generateContentHash(stem);

      // Find matching global_dictionary entry
      const { data: globalEntry, error: globalError } = await supabase
        .from('global_dictionary')
        .select('id')
        .eq('content_hash', contentHash)
        .single();

      if (globalError || !globalEntry) {
        results.orphaned++;
        continue;
      }

      // Update vocabulary with global_dictionary_id
      const { error: updateError } = await supabase
        .from('vocabulary')
        .update({ global_dictionary_id: globalEntry.id })
        .eq('id', vocab.id);

      if (updateError) {
        results.errors.push({ vocabulary_id: vocab.id, error: updateError.message });
      } else {
        results.linked++;
      }

      if ((results.linked + results.orphaned) % 100 === 0) {
        console.log(`   Progress: ${results.linked + results.orphaned} / ${vocabularyData.length}`);
      }
    } catch (err) {
      results.errors.push({ vocabulary_id: vocab.id, error: err.message });
    }
  }

  console.log(`   ✓ Linked: ${results.linked}`);
  console.log(`   ⊘ Orphaned (no match): ${results.orphaned}`);
  if (results.errors.length > 0) {
    console.log(`   ✗ Errors: ${results.errors.length}`);
  }

  return results;
}

// =============================================================================
// Main
// =============================================================================

async function main() {
  console.log('🚀 Data migration script for global_dictionary\n');

  validateEnv();

  const startTime = Date.now();

  // Step 1: Get meanings to migrate
  const meanings = await getMeaningsToMigrate();

  // Step 2: Deduplicate by stem
  const deduplicated = await deduplicateByStem(meanings);

  // Step 3: Insert to global_dictionary
  const insertResults = await insertToGlobalDictionary(deduplicated);

  // Step 4: Link vocabulary to global_dictionary
  const linkResults = await linkVocabularyToGlobalDictionary();

  const duration = ((Date.now() - startTime) / 1000).toFixed(2);

  // Report
  console.log('\n' + '='.repeat(60));
  console.log('📊 Migration Summary');
  console.log('='.repeat(60));
  console.log(`✓ Meanings migrated:        ${insertResults.inserted}`);
  console.log(`⊘ Meanings skipped:         ${insertResults.skipped}`);
  console.log(`✓ Vocabulary rows linked:   ${linkResults.linked}`);
  console.log(`⊘ Vocabulary rows orphaned: ${linkResults.orphaned}`);
  console.log(`⏱  Duration:                 ${duration}s`);

  if (insertResults.errors.length > 0 || linkResults.errors.length > 0) {
    console.log('\n❌ Errors:');
    [...insertResults.errors, ...linkResults.errors].forEach(({ stem, vocabulary_id, error }) => {
      if (stem) {
        console.log(`   [global_dictionary] ${stem}: ${error}`);
      } else if (vocabulary_id) {
        console.log(`   [vocabulary] ${vocabulary_id}: ${error}`);
      }
    });
  }
}

main().catch(err => {
  console.error('Fatal error:', err);
  exit(1);
});
