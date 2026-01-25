// Books Edge Function - CRUD operations for books

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
  const bookId = pathParts.length > 1 ? pathParts[pathParts.length - 1] : null;

  try {
    switch (req.method) {
      case 'GET':
        if (bookId && bookId !== 'books') {
          return await getBook(req, userId, bookId);
        }
        return await listBooks(req, userId);

      case 'POST':
        return await createBook(req, userId);

      case 'PATCH':
        if (!bookId) {
          return errorResponse('Book ID required', 400);
        }
        return await updateBook(req, userId, bookId);

      case 'DELETE':
        if (!bookId) {
          return errorResponse('Book ID required', 400);
        }
        return await deleteBook(req, userId, bookId);

      default:
        return errorResponse('Method not allowed', 405);
    }
  } catch (error) {
    console.error('Books error:', error);
    return errorResponse('Internal server error', 500);
  }
});

async function listBooks(req: Request, userId: string): Promise<Response> {
  const url = new URL(req.url);
  const limit = parseInt(url.searchParams.get('limit') || '50');
  const offset = parseInt(url.searchParams.get('offset') || '0');

  const client = createSupabaseClient(req);

  const { data, error, count } = await client
    .from('books')
    .select('*', { count: 'exact' })
    .eq('user_id', userId)
    .is('deleted_at', null)
    .order('updated_at', { ascending: false })
    .range(offset, offset + limit - 1);

  if (error) {
    return errorResponse('Failed to fetch books', 500);
  }

  return jsonResponse({
    data: data || [],
    total: count || 0,
  });
}

async function getBook(req: Request, userId: string, bookId: string): Promise<Response> {
  const client = createSupabaseClient(req);

  // Get book with highlights
  const { data: book, error: bookError } = await client
    .from('books')
    .select('*')
    .eq('id', bookId)
    .eq('user_id', userId)
    .is('deleted_at', null)
    .single();

  if (bookError || !book) {
    return notFoundResponse('Book not found');
  }

  const { data: highlights, error: highlightsError } = await client
    .from('highlights')
    .select('*')
    .eq('book_id', bookId)
    .eq('user_id', userId)
    .is('deleted_at', null)
    .order('page', { ascending: true, nullsFirst: false })
    .order('location', { ascending: true, nullsFirst: false });

  if (highlightsError) {
    return errorResponse('Failed to fetch highlights', 500);
  }

  return jsonResponse({
    ...book,
    highlights: highlights || [],
  });
}

async function createBook(req: Request, userId: string): Promise<Response> {
  const body = await req.json();
  const client = createSupabaseClient(req);

  const { data, error } = await client
    .from('books')
    .insert({
      ...body,
      user_id: userId,
    })
    .select()
    .single();

  if (error) {
    if (error.code === '23505') {
      return errorResponse('Book already exists', 409);
    }
    return errorResponse('Failed to create book', 500);
  }

  return jsonResponse(data, 201);
}

async function updateBook(req: Request, userId: string, bookId: string): Promise<Response> {
  const body = await req.json();
  const client = createSupabaseClient(req);

  const { data, error } = await client
    .from('books')
    .update({
      ...body,
      updated_at: new Date().toISOString(),
    })
    .eq('id', bookId)
    .eq('user_id', userId)
    .select()
    .single();

  if (error || !data) {
    return notFoundResponse('Book not found');
  }

  return jsonResponse(data);
}

async function deleteBook(req: Request, userId: string, bookId: string): Promise<Response> {
  const client = createSupabaseClient(req);

  const { error } = await client
    .from('books')
    .update({
      deleted_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    })
    .eq('id', bookId)
    .eq('user_id', userId);

  if (error) {
    return errorResponse('Failed to delete book', 500);
  }

  return new Response(null, { status: 204 });
}
