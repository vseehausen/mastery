/**
 * TypeScript API wrapper for Kindle Tauri commands
 */

import { invoke } from '@tauri-apps/api/core';

/**
 * Get current Kindle connection status
 */
export async function getKindleStatus(): Promise<boolean> {
  return invoke<boolean>('get_kindle_status');
}

/**
 * Sync vocab.db from Kindle
 * This will prompt for admin password if needed (for MTP devices)
 */
export async function syncKindleVocab(): Promise<string> {
  return invoke<string>('sync_kindle_vocab');
}

/**
 * Get path to synced vocab.db if it exists
 */
export async function getVocabDbPath(): Promise<string> {
  return invoke<string>('get_vocab_db_path');
}

/**
 * Format file size in human-readable format
 */
export function formatFileSize(bytes: number): string {
  if (bytes === 0) return '0 B';
  const k = 1024;
  const sizes = ['B', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return `${parseFloat((bytes / Math.pow(k, i)).toFixed(1))} ${sizes[i]}`;
}
