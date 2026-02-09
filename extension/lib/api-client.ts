import { createClient, SupabaseClient } from '@supabase/supabase-js';
import type { LookupRequest, LookupResponse, StatsResponse } from './types';

const SUPABASE_URL = import.meta.env.WXT_SUPABASE_URL;
const SUPABASE_ANON_KEY = import.meta.env.WXT_SUPABASE_ANON_KEY;

let client: SupabaseClient | null = null;

export function getSupabaseClient(): SupabaseClient {
  if (!client) {
    client = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      auth: {
        storage: {
          getItem: async (key: string): Promise<string | null> => {
            const result = await browser.storage.local.get(key);
            return (result[key] as string) ?? null;
          },
          setItem: async (key: string, value: string) => {
            await browser.storage.local.set({ [key]: value });
          },
          removeItem: async (key: string) => {
            await browser.storage.local.remove(key);
          },
        },
        autoRefreshToken: true,
        persistSession: true,
      },
    });
  }
  return client;
}

export async function lookupWord(request: LookupRequest): Promise<LookupResponse> {
  const supabase = getSupabaseClient();
  const { data, error } = await supabase.functions.invoke('lookup-word', {
    body: request,
  });
  if (error) throw new Error(error.message || 'Lookup failed');
  return data as LookupResponse;
}

export async function getStats(url?: string): Promise<StatsResponse> {
  const supabase = getSupabaseClient();
  const params = url ? `?url=${encodeURIComponent(url)}` : '';
  const { data, error } = await supabase.functions.invoke(`lookup-word/batch-status${params}`, {
    method: 'GET',
  });
  if (error) throw new Error(error.message || 'Failed to fetch stats');
  return data as StatsResponse;
}
