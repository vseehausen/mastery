// Sync edge function - handles push and pull operations

import { handleCors } from '../_shared/cors.ts';
import { createSupabaseClient, getUserId, type SupabaseClient } from '../_shared/supabase.ts';
import { jsonResponse, errorResponse, unauthorizedResponse } from '../_shared/response.ts';

// Tables allowed for push operations — reject anything not in this list
const ALLOWED_PUSH_TABLES = new Set([
  'sources',
  'encounters',
  'vocabulary',
  'learning_cards',
  'learning_sessions',
  'streaks',
  'user_learning_preferences',
  'confusable_sets',
  'confusable_set_members',
]);

// Pull table configs: each defines a table name and its timestamp field
interface PullTableConfig {
  table: string;
  timeField: 'updated_at' | 'created_at';
  filterByUserId: boolean;
}

const PULL_TABLES: PullTableConfig[] = [
  { table: 'sources', timeField: 'updated_at', filterByUserId: true },
  { table: 'encounters', timeField: 'updated_at', filterByUserId: true },
  { table: 'vocabulary', timeField: 'updated_at', filterByUserId: true },
  { table: 'learning_cards', timeField: 'updated_at', filterByUserId: true },
  { table: 'learning_sessions', timeField: 'updated_at', filterByUserId: true },
  { table: 'streaks', timeField: 'updated_at', filterByUserId: true },
  { table: 'user_learning_preferences', timeField: 'updated_at', filterByUserId: true },
  { table: 'confusable_sets', timeField: 'updated_at', filterByUserId: true },
];

Deno.serve(async (req) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  const userId = await getUserId(req);
  if (!userId) return unauthorizedResponse();

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

    if (!ALLOWED_PUSH_TABLES.has(table)) {
      console.error(`[sync/push] Rejected push to disallowed table: ${table}`);
      continue;
    }

    try {
      if (operation === 'insert') {
        const { error } = await client
          .from(table)
          .insert({ ...data, id, user_id: userId });

        if (!error) applied++;
      } else if (operation === 'upsert') {
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

  // Fetch all standard tables in parallel
  const tableResults = await Promise.all(
    PULL_TABLES.map(config => pullTable(client, userId, config, since)),
  );

  // Build results map from parallel fetches
  const results: Record<string, unknown[]> = {};
  for (let i = 0; i < PULL_TABLES.length; i++) {
    const { table } = PULL_TABLES[i];
    const { data, error } = tableResults[i];
    if (error) {
      return errorResponse(`Failed to fetch ${table}`, 500);
    }
    results[table] = data || [];
  }

  // Special case: confusable_set_members (join table, fetched by set IDs, no user_id)
  const confusableSetIds = (results['confusable_sets'] as Array<{ id: string }>).map(s => s.id);
  let confusable_set_members: unknown[] = [];
  if (confusableSetIds.length > 0) {
    const { data: members, error: membersError } = await client
      .from('confusable_set_members')
      .select('*')
      .in('confusable_set_id', confusableSetIds);

    if (membersError) {
      return errorResponse('Failed to fetch confusable set members', 500);
    }
    confusable_set_members = members || [];
  }

  const syncedAt = new Date().toISOString();

  console.log(`[sync/pull] Returning: sources=${results['sources'].length}, encounters=${results['encounters'].length}, vocab=${results['vocabulary'].length}, learning_cards=${results['learning_cards'].length}`);

  return jsonResponse({
    sources: results['sources'],
    encounters: results['encounters'],
    vocabulary: results['vocabulary'],
    learning_cards: results['learning_cards'],
    learning_sessions: results['learning_sessions'],
    streaks: results['streaks'],
    user_learning_preferences: results['user_learning_preferences'],
    confusable_sets: results['confusable_sets'],
    confusable_set_members,
    syncedAt,
  });
}

function pullTable(
  client: SupabaseClient,
  userId: string,
  config: PullTableConfig,
  since: string,
) {
  let query = client.from(config.table).select('*');
  if (config.filterByUserId) {
    query = query.eq('user_id', userId);
  }
  return query.gt(config.timeField, since);
}
