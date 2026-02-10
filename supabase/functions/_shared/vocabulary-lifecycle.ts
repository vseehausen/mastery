import { normalize } from './normalize.ts';
import type { SupabaseClient } from './supabase.ts';

/** Ensure a vocabulary entry exists for this user+word. Deduplicates on (user_id, word).
 *  If a soft-deleted entry exists, reactivates it instead of creating a new row. */
export async function ensureVocabularyIdentity(
  client: SupabaseClient,
  userId: string,
  word: string,
  globalDictId?: string | null,
): Promise<{ vocabularyId: string; isNew: boolean }> {
  const now = new Date().toISOString();
  const normalized = normalize(word);

  // Check for soft-deleted entry to reactivate
  const { data: deleted } = await client
    .from('vocabulary')
    .select('id')
    .eq('user_id', userId)
    .eq('word', normalized)
    .not('deleted_at', 'is', null)
    .order('created_at', { ascending: true })
    .limit(1)
    .single();

  if (deleted) {
    console.log(`[vocabulary] Reactivating soft-deleted "${word}"`);
    const update: Record<string, unknown> = { deleted_at: null, updated_at: now };
    if (globalDictId) update.global_dictionary_id = globalDictId;
    await client.from('vocabulary').update(update).eq('id', deleted.id);
    return { vocabularyId: deleted.id, isNew: false };
  }

  // Try INSERT
  const vocabularyId = crypto.randomUUID();
  const { error } = await client.from('vocabulary').insert({
    id: vocabularyId,
    user_id: userId,
    word: normalized,
    stem: normalized,
    global_dictionary_id: globalDictId ?? null,
    created_at: now,
    updated_at: now,
  });

  if (!error) return { vocabularyId, isNew: true };

  if (error.code !== '23505') {
    throw new Error(`Failed to create vocabulary: ${error.message}`);
  }

  // Race: active entry appeared between our check and insert
  console.log(`[vocabulary] Race on "${word}", resolving existing`);

  if (globalDictId) {
    const { data: existing, error: updateError } = await client
      .from('vocabulary')
      .update({
        global_dictionary_id: globalDictId,
        updated_at: now,
      })
      .eq('user_id', userId)
      .eq('word', normalized)
      .is('deleted_at', null)
      .select('id')
      .single();

    if (updateError || !existing) {
      throw new Error(`Failed to link vocabulary: ${updateError?.message || 'not found'}`);
    }
    return { vocabularyId: existing.id, isNew: false };
  }

  const { data: existing, error: fetchError } = await client
    .from('vocabulary')
    .select('id')
    .eq('user_id', userId)
    .eq('word', normalized)
    .is('deleted_at', null)
    .single();

  if (fetchError || !existing) {
    throw new Error(`Failed to fetch vocabulary: ${fetchError?.message || 'not found'}`);
  }
  return { vocabularyId: existing.id, isNew: false };
}

/** Ensure a learning card exists for a vocabulary entry.
 *  Reactivates soft-deleted cards. Creates new if none exists. */
export async function ensureLearningCard(
  client: SupabaseClient,
  userId: string,
  vocabularyId: string,
): Promise<void> {
  // Check for soft-deleted card to reactivate
  const { data: deleted } = await client
    .from('learning_cards')
    .select('id')
    .eq('user_id', userId)
    .eq('vocabulary_id', vocabularyId)
    .not('deleted_at', 'is', null)
    .limit(1)
    .single();

  if (deleted) {
    await client.from('learning_cards').update({
      deleted_at: null,
      updated_at: new Date().toISOString(),
    }).eq('id', deleted.id);
    return;
  }

  const now = new Date().toISOString();
  const { error } = await client.from('learning_cards').insert({
    id: crypto.randomUUID(),
    user_id: userId,
    vocabulary_id: vocabularyId,
    state: 0,
    due: now,
    stability: 0,
    difficulty: 0,
    created_at: now,
    updated_at: now,
  });

  if (!error || error.code === '23505') return;
  throw new Error(`Failed to create learning card: ${error.message}`);
}

/** Fire-and-forget enrichment trigger for unresolved vocabulary. */
export function triggerEnrichment(
  vocabularyIds: string[],
  nativeLang: string,
): void {
  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!supabaseUrl || !serviceRoleKey) return;

  fetch(`${supabaseUrl}/functions/v1/enrich-vocabulary/request`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${serviceRoleKey}`,
    },
    body: JSON.stringify({
      native_language_code: nativeLang,
      vocabulary_ids: vocabularyIds,
      batch_size: vocabularyIds.length,
    }),
  }).catch(err => console.warn('[vocabulary] Failed to trigger enrichment:', err.message));
}

/**
 * After enrichment links a vocab entry, check if another vocab for the same user
 * already points to the same global_dictionary_id. If so, merge: move encounters
 * to the older entry, soft-delete the duplicate and its learning card.
 */
export async function mergeIfDuplicate(
  client: SupabaseClient,
  userId: string,
  globalDictId: string,
): Promise<void> {
  // Find all active vocab entries for this user pointing to the same global_dictionary_id
  const { data: duplicates, error } = await client
    .from('vocabulary')
    .select('id, created_at')
    .eq('user_id', userId)
    .eq('global_dictionary_id', globalDictId)
    .is('deleted_at', null)
    .order('created_at', { ascending: true });

  if (error || !duplicates || duplicates.length <= 1) return;

  // Keep the oldest entry, merge all others into it
  const keeper = duplicates[0];
  const toMerge = duplicates.filter(d => d.id !== keeper.id);

  for (const dup of toMerge) {
    // Move encounters to keeper
    await client
      .from('encounters')
      .update({ vocabulary_id: keeper.id })
      .eq('vocabulary_id', dup.id);

    // Unlink from global_dictionary first (avoids partial-index constraint issues)
    await client
      .from('vocabulary')
      .update({ global_dictionary_id: null, updated_at: new Date().toISOString() })
      .eq('id', dup.id);

    // Soft-delete the duplicate vocabulary
    await client
      .from('vocabulary')
      .update({ deleted_at: new Date().toISOString() })
      .eq('id', dup.id);

    // Soft-delete its learning card
    await client
      .from('learning_cards')
      .update({ deleted_at: new Date().toISOString() })
      .eq('vocabulary_id', dup.id)
      .eq('user_id', userId);

    console.log(`[vocabulary] Merged duplicate vocab ${dup.id} into ${keeper.id}`);
  }
}
