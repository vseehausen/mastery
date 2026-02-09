import { createClient, SupabaseClient } from '@supabase/supabase-js';
import type { LookupRequest, LookupResponse, StatsResponse } from './types';

const SUPABASE_URL = import.meta.env.WXT_SUPABASE_URL;
const SUPABASE_PUBLISHABLE_KEY = import.meta.env.WXT_SUPABASE_PUBLISHABLE_KEY;

let client: SupabaseClient | null = null;

export function getSupabaseClient(): SupabaseClient {
  console.log('[Mastery] Initializing Supabase client', {
    url: SUPABASE_URL,
    hasKey: !!SUPABASE_PUBLISHABLE_KEY,
  });
  if (!client) {
    client = createClient(SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, {
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
  console.log('[Mastery] lookupWord API call starting:', request.raw_word);
  const supabase = getSupabaseClient();
  console.log('[Mastery] Invoking Edge Function: lookup-word');
  const response = await supabase.functions.invoke('lookup-word', {
    body: request,
  });
  console.log('[Mastery] Raw Edge Function response:', response);

  const { data, error } = response;
  if (error) {
    console.error('[Mastery] Edge Function error:', error);
    console.error('[Mastery] Error context:', error.context);
    throw new Error(error.message || 'Lookup failed');
  }
  console.log('[Mastery] Edge Function success, data:', data);
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

export async function triggerEnrichmentIfNeeded(): Promise<void> {
  try {
    const supabase = getSupabaseClient();

    // Check if enrichment is needed
    const { data: status, error: statusError } = await supabase.functions.invoke(
      'enrich-vocabulary/status',
      { method: 'GET' }
    );

    if (statusError) {
      console.error('[Mastery] Failed to check enrichment status:', statusError);
      return;
    }

    // If buffer needs replenishment, trigger enrichment
    if (status?.needs_replenishment) {
      console.log('[Mastery] Buffer needs replenishment, triggering enrichment');
      const { error: requestError } = await supabase.functions.invoke(
        'enrich-vocabulary/request',
        {
          method: 'POST',
          body: { native_language_code: 'de' },
        }
      );

      if (requestError) {
        console.error('[Mastery] Failed to trigger enrichment:', requestError);
      } else {
        console.log('[Mastery] Enrichment triggered successfully');
      }
    }
  } catch (err) {
    console.error('[Mastery] Error in triggerEnrichmentIfNeeded:', err);
  }
}
