// Highlights Edge Function - CRUD operations for highlights

import { handleCors } from '../_shared/cors.ts';
import { createSupabaseClient, getUserId } from '../_shared/supabase.ts';
import { jsonResponse, errorResponse, unauthorizedResponse, notFoundResponse } from '../_shared/response.ts';

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
  const pathParts = url.pathname.split('/').filter(Boolean);
  const highlightId = pathParts.length > 1 ? pathParts[pathParts.length - 1] : null;

  try {
    switch (req.method) {
      case 'GET':
        if (highlightId && highlightId !== 'highlights') {
          return await getHighlight(req, userId, highlightId);
        }
        return await listHighlights(req, userId);

      case 'POST':
        return await createHighlight(req, userId);

      case 'PATCH':
        if (!highlightId) {
          return errorResponse('Highlight ID required', 400);
        }
        return await updateHighlight(req, userId, highlightId);

      case 'DELETE':
        if (!highlightId) {
          return errorResponse('Highlight ID required', 400);
        }
        return await deleteHighlight(req, userId, highlightId);

      default:
        return errorResponse('Method not allowed', 405);
    }
  } catch (error) {
    console.error('Highlights error:', error);
    return errorResponse('Internal server error', 500);
  }
});

async function listHighlights(req: Request, userId: string): Promise<Response> {
  const url = new URL(req.url);
  const bookId = url.searchParams.get('bookId');
  const search = url.searchParams.get('search');
  const limit = parseInt(url.searchParams.get('limit') || '50');
  const offset = parseInt(url.searchParams.get('offset') || '0');

  const client = createSupabaseClient(req);

  let query = client
    .from('highlights')
    .select('*', { count: 'exact' })
    .eq('user_id', userId)
    .is('deleted_at', null)
    .order('created_at', { ascending: false })
    .range(offset, offset + limit - 1);

  if (bookId) {
    query = query.eq('book_id', bookId);
  }

  if (search) {
    query = query.textSearch('content', search);
  }

  const { data, error, count } = await query;

  if (error) {
    return errorResponse('Failed to fetch highlights', 500);
  }

  return jsonResponse({
    data: data || [],
    total: count || 0,
    limit,
    offset,
  });
}

async function getHighlight(req: Request, userId: string, highlightId: string): Promise<Response> {
  const client = createSupabaseClient(req);

  const { data, error } = await client
    .from('highlights')
    .select('*')
    .eq('id', highlightId)
    .eq('user_id', userId)
    .is('deleted_at', null)
    .single();

  if (error || !data) {
    return notFoundResponse('Highlight not found');
  }

  return jsonResponse(data);
}

async function createHighlight(req: Request, userId: string): Promise<Response> {
  const body = await req.json();
  const client = createSupabaseClient(req);

  const { data, error } = await client
    .from('highlights')
    .insert({
      ...body,
      user_id: userId,
    })
    .select()
    .single();

  if (error) {
    if (error.code === '23505') {
      return errorResponse('Duplicate highlight', 409);
    }
    return errorResponse('Failed to create highlight', 500);
  }

  return jsonResponse(data, 201);
}

async function updateHighlight(req: Request, userId: string, highlightId: string): Promise<Response> {
  const body = await req.json();
  const client = createSupabaseClient(req);

  // Check version for optimistic locking if provided
  if (body.version !== undefined) {
    const { data: existing } = await client
      .from('highlights')
      .select('version')
      .eq('id', highlightId)
      .eq('user_id', userId)
      .single();

    if (existing && existing.version > body.version) {
      return errorResponse('Version conflict', 409, {
        serverVersion: existing.version,
      });
    }
  }

  const { data, error } = await client
    .from('highlights')
    .update({
      ...body,
      version: (body.version || 1) + 1,
      updated_at: new Date().toISOString(),
    })
    .eq('id', highlightId)
    .eq('user_id', userId)
    .select()
    .single();

  if (error || !data) {
    return notFoundResponse('Highlight not found');
  }

  return jsonResponse(data);
}

async function deleteHighlight(req: Request, userId: string, highlightId: string): Promise<Response> {
  const client = createSupabaseClient(req);

  const { error } = await client
    .from('highlights')
    .update({
      deleted_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    })
    .eq('id', highlightId)
    .eq('user_id', userId);

  if (error) {
    return errorResponse('Failed to delete highlight', 500);
  }

  return new Response(null, { status: 204 });
}
