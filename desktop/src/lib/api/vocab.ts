/**
 * TypeScript API for vocabulary parsing and sync
 */

import { invoke } from '@tauri-apps/api/core';

export interface ParsedVocabularyEntry {
  word: string;
  stem: string | null;
  context: string | null;
  lookupTimestamp: string | null;
  bookTitle: string | null;
  bookAuthor: string | null;
  bookAsin: string | null;
  contentHash: string;
}

export interface ParsedBook {
  id: string;
  title: string;
  author: string | null;
  asin: string | null;
}

export interface ParseVocabResponse {
  totalParsed: number;
  entries: ParsedVocabularyEntry[];
  books: ParsedBook[];
}

export interface ImportResult {
  totalParsed: number;
  imported: number;
  skipped: number;
  books: number;
  error?: string;
}

/**
 * Import vocabulary directly from Kindle
 * Single step: reads from Kindle → uploads to server → done
 */
export async function importFromKindle(): Promise<ImportResult> {
  return invoke<ImportResult>('import_from_kindle');
}

/**
 * Get vocabulary import history
 */
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

export async function getImportHistory(): Promise<ImportSession[]> {
  return invoke<ImportSession[]>('get_import_history');
}

/**
 * Check if there are vocabulary entries pending sync
 */
export async function hasPendingVocabularySync(): Promise<boolean> {
  return invoke<boolean>('has_pending_vocabulary_sync');
}

/**
 * Format timestamp for display
 */
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

/**
 * Truncate context string for list display
 */
export function truncateContext(context: string | null, maxLength = 50): string {
  if (!context) return '';
  if (context.length <= maxLength) return context;
  return context.substring(0, maxLength - 3) + '...';
}
