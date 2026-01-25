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

  // Fetch books modified since lastSyncedAt
  const { data: books, error: booksError } = await client
    .from('books')
    .select('*')
    .eq('user_id', userId)
    .gt('updated_at', since);

  if (booksError) {
    return errorResponse('Failed to fetch books', 500);
  }

  // Fetch highlights modified since lastSyncedAt
  const { data: highlights, error: highlightsError } = await client
    .from('highlights')
    .select('*')
    .eq('user_id', userId)
    .gt('updated_at', since);

  if (highlightsError) {
    return errorResponse('Failed to fetch highlights', 500);
  }

  const syncedAt = new Date().toISOString();

  return jsonResponse({
    books: books || [],
    highlights: highlights || [],
    syncedAt,
  });
}
