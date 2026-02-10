import { createClient } from '@supabase/supabase-js';
import { config } from 'dotenv';
config({ path: '../supabase/.env.local' });

const supabase = createClient(
  process.env.VITE_SUPABASE_URL,
  process.env.SUPABASE_SECRET_KEY
);

const { data: vocab } = await supabase
  .from('vocabulary')
  .select('word, stem, global_dictionary_id')
  .is('deleted_at', null)
  .order('created_at', { ascending: false })
  .limit(10);

console.log('=== Vocabulary ===');
for (const v of vocab) {
  console.log(v.word, '| enriched:', v.global_dictionary_id ? 'YES' : 'NO');
}

const { data: gd } = await supabase
  .from('global_dictionary')
  .select('word, stem, english_definition')
  .order('created_at', { ascending: false })
  .limit(15);

console.log('\n=== Global Dictionary ===');
for (const g of gd) {
  const def = g.english_definition || '';
  console.log(g.word, '|', def.substring(0, 60));
}

const { data: eq } = await supabase
  .from('enrichment_queue')
  .select('vocabulary_id, status, last_error, attempts')
  .order('created_at', { ascending: false })
  .limit(10);

console.log('\n=== Enrichment Queue ===');
for (const e of eq) {
  const err = e.last_error || 'none';
  console.log(e.status, '| attempts:', e.attempts, '| error:', err.substring(0, 60));
}
