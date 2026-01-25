// Import Sessions Edge Function - Record import operations for analytics

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

  try {
    switch (req.method) {
      case 'GET':
        return await listImportSessions(req, userId);

      case 'POST':
        return await createImportSession(req, userId);

      default:
        return errorResponse('Method not allowed', 405);
    }
  } catch (error) {
    console.error('Import sessions error:', error);
    return errorResponse('Internal server error', 500);
  }
});

async function listImportSessions(req: Request, userId: string): Promise<Response> {
  const url = new URL(req.url);
  const limit = parseInt(url.searchParams.get('limit') || '20');
  const offset = parseInt(url.searchParams.get('offset') || '0');

  const client = createSupabaseClient(req);

  const { data, error, count } = await client
    .from('import_sessions')
    .select('*', { count: 'exact' })
    .eq('user_id', userId)
    .order('started_at', { ascending: false })
    .range(offset, offset + limit - 1);

  if (error) {
    return errorResponse('Failed to fetch import sessions', 500);
  }

  return jsonResponse({
    data: data || [],
    total: count || 0,
    limit,
    offset,
  });
}

async function createImportSession(req: Request, userId: string): Promise<Response> {
  const body = await req.json();
  const client = createSupabaseClient(req);

  const { data, error } = await client
    .from('import_sessions')
    .insert({
      user_id: userId,
      source: body.source,
      filename: body.filename,
      device_name: body.deviceName,
      total_found: body.totalFound,
      imported: body.imported,
      skipped: body.skipped,
      errors: body.errors || 0,
      error_details: body.errorDetails,
      started_at: body.startedAt,
      completed_at: body.completedAt,
    })
    .select()
    .single();

  if (error) {
    return errorResponse('Failed to create import session', 500);
  }

  return jsonResponse(data, 201);
}
