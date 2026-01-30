// Sync edge function - handles push and pull operations

import { handleCors } from '../_shared/cors.ts';
import { createSupabaseClient, getUserId } from '../_shared/supabase.ts';
import { jsonResponse, errorResponse, unauthorizedResponse } from '../_shared/response.ts';

Deno.serve(async (req) => {
  // Handle CORS preflight
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  // Get user ID from auth
  const userId = await getUserId(req);
  if (!userId) {
    return unauthorizedResponse();
  }

  const url = new URL(req.url);
  const path = url.pathname.split('/').pop();

  try {
    if (req.method === 'POST' && path === 'push') {
      return await handlePush(req, userId);
    } else if (req.method === 'POST' && path === 'pull') {
      return await handlePull(req, userId);
    }

    return errorResponse('Method not allowed', 405);
  } catch (error) {
    console.error('Sync error:', error);
    return errorResponse('Internal server error', 500);
  }
});

async function handlePush(req: Request, userId: string): Promise<Response> {
  const { changes } = await req.json();
  const client = createSupabaseClient(req);

  let applied = 0;
  const conflicts: unknown[] = [];

  for (const change of changes) {
    const { table, operation, id, data, version } = change;

    try {
      if (operation === 'insert') {
        const { error } = await client
          .from(table)
          .insert({ ...data, id, user_id: userId });

        if (!error) applied++;
      } else if (operation === 'upsert') {
        // Upsert - insert or update based on id
        const { error } = await client
          .from(table)
          .upsert({ ...data, id, user_id: userId, last_synced_at: new Date().toISOString() });

        if (!error) applied++;
      } else if (operation === 'update') {
        const { data: existing } = await client
          .from(table)
          .select('version, updated_at')
          .eq('id', id)
          .eq('user_id', userId)
          .single();

        // Last-write-wins based on version
        if (existing && existing.version > version) {
          conflicts.push({
            id,
            table,
            serverVersion: existing.version,
            serverUpdatedAt: existing.updated_at,
          });
          continue;
        }

        const { error } = await client
          .from(table)
          .update({ ...data, version: (version || 1) + 1, last_synced_at: new Date().toISOString() })
          .eq('id', id)
          .eq('user_id', userId);

        if (!error) applied++;
      } else if (operation === 'delete') {
        const { error } = await client
          .from(table)
          .update({ deleted_at: new Date().toISOString() })
          .eq('id', id)
          .eq('user_id', userId);

        if (!error) applied++;
      }
    } catch (err) {
      console.error(`Error processing change for ${table}:${id}:`, err);
    }
  }

  const syncedAt = new Date().toISOString();

  if (conflicts.length > 0) {
    return jsonResponse({ applied, conflicts, syncedAt }, 409);
  }

  return jsonResponse({ applied, syncedAt });
}

async function handlePull(req: Request, userId: string): Promise<Response> {
  const { lastSyncedAt } = await req.json();
  const client = createSupabaseClient(req);

  const since = lastSyncedAt || '1970-01-01T00:00:00Z';
  console.log(`[sync/pull] userId=${userId}, since=${since}`);

  // Fetch sources modified since lastSyncedAt
  const { data: sources, error: sourcesError } = await client
    .from('sources')
    .select('*')
    .eq('user_id', userId)
    .gt('updated_at', since);

  if (sourcesError) {
    return errorResponse('Failed to fetch sources', 500);
  }

  // Fetch encounters modified since lastSyncedAt
  const { data: encounters, error: encountersError } = await client
    .from('encounters')
    .select('*')
    .eq('user_id', userId)
    .gt('updated_at', since);

  if (encountersError) {
    return errorResponse('Failed to fetch encounters', 500);
  }

  // Fetch vocabulary modified since lastSyncedAt
  const { data: vocabulary, error: vocabularyError } = await client
    .from('vocabulary')
    .select('*')
    .eq('user_id', userId)
    .gt('updated_at', since);

  if (vocabularyError) {
    return errorResponse('Failed to fetch vocabulary', 500);
  }

  // Fetch learning_cards modified since lastSyncedAt
  const { data: learning_cards, error: learningCardsError } = await client
    .from('learning_cards')
    .select('*')
    .eq('user_id', userId)
    .gt('updated_at', since);

  if (learningCardsError) {
    return errorResponse('Failed to fetch learning cards', 500);
  }

  // Fetch learning_sessions modified since lastSyncedAt
  const { data: learning_sessions, error: learningSessionsError } = await client
    .from('learning_sessions')
    .select('*')
    .eq('user_id', userId)
    .gt('updated_at', since);

  if (learningSessionsError) {
    return errorResponse('Failed to fetch learning sessions', 500);
  }

  // Fetch streaks modified since lastSyncedAt
  const { data: streaks, error: streaksError } = await client
    .from('streaks')
    .select('*')
    .eq('user_id', userId)
    .gt('updated_at', since);

  if (streaksError) {
    return errorResponse('Failed to fetch streaks', 500);
  }

  // Fetch user_learning_preferences modified since lastSyncedAt
  const { data: user_learning_preferences, error: prefsError } = await client
    .from('user_learning_preferences')
    .select('*')
    .eq('user_id', userId)
    .gt('updated_at', since);

  if (prefsError) {
    return errorResponse('Failed to fetch user preferences', 500);
  }

  const syncedAt = new Date().toISOString();

  console.log(`[sync/pull] Returning: sources=${sources?.length || 0}, encounters=${encounters?.length || 0}, vocab=${vocabulary?.length || 0}, learning_cards=${learning_cards?.length || 0}`);

  return jsonResponse({
    sources: sources || [],
    encounters: encounters || [],
    vocabulary: vocabulary || [],
    learning_cards: learning_cards || [],
    learning_sessions: learning_sessions || [],
    streaks: streaks || [],
    user_learning_preferences: user_learning_preferences || [],
    syncedAt,
  });
}
