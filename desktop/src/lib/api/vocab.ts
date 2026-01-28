import { supabase } from '$lib/supabase';
import { invoke } from '@tauri-apps/api/core';

export interface ImportResult {
  totalParsed: number;
  imported: number;
  skipped: number;
  books: number;
  error?: string;
}

export interface ImportSession {
  id: string;
  timestamp: string;
  totalParsed: number;
  imported: number;
  skipped: number;
  books: number;
  status: 'success' | 'error';
  error?: string;
}

function bytesToBase64(bytes: number[]): string {
  const binary = String.fromCharCode(...bytes);
  return btoa(binary);
}

export async function importFromKindle(): Promise<ImportResult> {
  try {
    const vocabBytes: number[] = await invoke('read_kindle_vocab_db');
    
    if (!vocabBytes || vocabBytes.length === 0) {
      throw new Error('No data read from Kindle');
    }

    const base64 = bytesToBase64(vocabBytes);

    const { data, error } = await supabase.functions.invoke('parse-vocab', {
      body: { file: base64 },
    });

    if (error) {
      throw new Error(error.message || 'Failed to parse vocabulary');
    }

    if (!data) {
      throw new Error('No data returned from server');
    }

    return {
      totalParsed: data.totalParsed || 0,
      imported: data.imported || 0,
      skipped: data.skipped || 0,
      books: data.books || 0,
      error: data.errors ? data.errors.join('; ') : undefined,
    };
  } catch (error) {
    throw error instanceof Error ? error : new Error(String(error));
  }
}

export async function getImportHistory(): Promise<ImportSession[]> {
  try {
    const { data, error } = await supabase
      .from('import_sessions')
      .select('*')
      .order('started_at', { ascending: false })
      .limit(50);

    if (error) {
      throw new Error(error.message || 'Failed to fetch import history');
    }

    if (!data) {
      return [];
    }

    return data.map((row: any) => {
      const hasErrors = (row.errors || 0) > 0;
      return {
        id: row.id,
        timestamp: row.started_at || '',
        totalParsed: row.total_found || 0,
        imported: row.imported || 0,
        skipped: row.skipped || 0,
        books: 0,
        status: hasErrors ? 'error' : 'success',
        error: hasErrors ? `${row.errors} errors` : undefined,
      };
    });
  } catch (error) {
    throw error instanceof Error ? error : new Error(String(error));
  }
}

export function formatTimestamp(isoString: string): string {
  const date = new Date(isoString);
  return date.toLocaleDateString(undefined, {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
}
