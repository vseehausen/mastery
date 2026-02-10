#!/usr/bin/env node

import { createClient } from '@supabase/supabase-js';
import { config } from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
config({ path: join(__dirname, '../supabase/.env.local') });

const SUPABASE_URL = process.env.VITE_SUPABASE_URL;
const SUPABASE_SECRET_KEY = process.env.SUPABASE_SECRET_KEY;

const supabase = createClient(SUPABASE_URL, SUPABASE_SECRET_KEY);

const { data, error } = await supabase
  .from('vocabulary')
  .select(`
    word,
    stem,
    global_dictionary_id,
    created_at,
    global_dictionary:global_dictionary_id (
      english_definition,
      part_of_speech,
      pronunciation_ipa
    )
  `)
  .is('deleted_at', null)
  .order('created_at', { ascending: false })
  .limit(10);

if (error) {
  console.error('Error:', error);
  process.exit(1);
}

console.log('Recent vocabulary entries:\n');
data.forEach(v => {
  console.log(`Word: ${v.word} (stem: ${v.stem})`);
  console.log(`  Enriched: ${v.global_dictionary_id ? 'YES' : 'NO'}`);
  if (v.global_dictionary) {
    console.log(`  Definition: ${v.global_dictionary.english_definition?.substring(0, 60)}...`);
    console.log(`  Part of speech: ${v.global_dictionary.part_of_speech}`);
    console.log(`  IPA: ${v.global_dictionary.pronunciation_ipa}`);
  }
  console.log('');
});
