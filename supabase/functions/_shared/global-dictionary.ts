import { normalize } from './normalize.ts';
import type { SupabaseClient } from './supabase.ts';

export interface GlobalDictEntry {
  id: string;
  lemma: string;
  translations: Record<string, { primary?: string }> | null;
  pronunciation_ipa: string | null;
  part_of_speech: string | null;
  english_definition: string | null;
}

const GLOBAL_DICT_SELECT = 'id, lemma, translations, pronunciation_ipa, part_of_speech, english_definition';

/** Look up a word via word_variants → global_dictionary. */
export async function resolveGlobalEntry(
  client: SupabaseClient,
  word: string,
  languageCode: string = 'en',
): Promise<GlobalDictEntry | null> {
  const variant = normalize(word);
  const { data, error } = await client
    .from('word_variants')
    .select(`global_dictionary_id, global_dictionary!inner(${GLOBAL_DICT_SELECT})`)
    .eq('variant', variant)
    .eq('language_code', languageCode)
    .single();

  if (error) {
    if (error.code === 'PGRST116') return null;
    throw new Error(`Failed to resolve global entry: ${error.message}`);
  }

  // deno-lint-ignore no-explicit-any
  return (data as any).global_dictionary as GlobalDictEntry;
}

/** Direct lookup of global_dictionary by lemma (for enrichment). */
export async function resolveByLemma(
  client: SupabaseClient,
  lemma: string,
  languageCode: string = 'en',
): Promise<GlobalDictEntry | null> {
  const { data, error } = await client
    .from('global_dictionary')
    .select(GLOBAL_DICT_SELECT)
    .eq('lemma', normalize(lemma))
    .eq('language_code', languageCode)
    .single();

  if (error) {
    if (error.code === 'PGRST116') return null;
    throw new Error(`Failed to resolve by lemma: ${error.message}`);
  }
  return data;
}

/** Link a vocabulary entry to a global_dictionary entry. */
export async function linkVocabulary(
  client: SupabaseClient,
  vocabularyId: string,
  globalDictId: string,
): Promise<void> {
  const { error } = await client
    .from('vocabulary')
    .update({
      global_dictionary_id: globalDictId,
      updated_at: new Date().toISOString(),
    })
    .eq('id', vocabularyId);

  if (error) {
    console.error(`[global-dictionary] Failed to link vocabulary ${vocabularyId}:`, error);
  }
}

/** Create or update a word_variants mapping. */
export async function upsertVariant(
  client: SupabaseClient,
  languageCode: string,
  variant: string,
  globalDictId: string,
  method: string = 'enrichment',
): Promise<void> {
  const { error } = await client
    .from('word_variants')
    .upsert({
      language_code: languageCode,
      variant: normalize(variant),
      global_dictionary_id: globalDictId,
      method,
    }, {
      onConflict: 'language_code,variant',
    });

  if (error) {
    console.error(`[global-dictionary] Failed to upsert variant "${variant}":`, error);
  }
}
