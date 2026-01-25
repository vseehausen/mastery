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
 * Get clippings file information
 * Returns: [file_path, file_size_bytes]
 */
export async function getClippingsInfo(): Promise<[string, number]> {
  return invoke<[string, number]>('get_clippings_info');
}

/**
 * Read the entire clippings file content
 */
export async function readClippings(): Promise<string> {
  return invoke<string>('read_clippings');
}

/**
 * Count highlights in clippings content
 */
export async function countClippings(content: string): Promise<number> {
  return invoke<number>('count_clippings', { content });
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
