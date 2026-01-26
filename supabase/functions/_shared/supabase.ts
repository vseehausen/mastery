// Supabase client utilities for edge functions

import { createClient } from 'jsr:@supabase/supabase-js@2';

export function createSupabaseClient(req: Request) {
  const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
  const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY')!;

  const authHeader = req.headers.get('Authorization');

  return createClient(supabaseUrl, supabaseAnonKey, {
    global: {
      headers: {
        Authorization: authHeader || '',
      },
    },
  });
}

export function createServiceClient() {
  const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

  return createClient(supabaseUrl, serviceRoleKey);
}

export async function getUserId(req: Request): Promise<string | null> {
  const client = createSupabaseClient(req);
  const { data: { user }, error } = await client.auth.getUser();

  if (error || !user) {
    return null;
  }

  return user.id;
}
