/**
 * TypeScript API wrapper for Kindle Tauri commands
 */

import { invoke } from '@tauri-apps/api/core';

/** Kindle device status */
export interface KindleStatus {
  connected: boolean;
  mountPoint: string | null;
  clippingsSize: number | null;
}

/** Import result from manual trigger */
export interface ImportResult {
  totalFound: number;
  imported: number;
  skipped: number;
  errors: number;
}

/**
 * Get current Kindle device status
 */
export async function getKindleStatus(): Promise<KindleStatus> {
  return invoke<KindleStatus>('get_kindle_status');
}

/**
 * Start monitoring for Kindle device connection
 */
export async function startMonitoring(): Promise<void> {
  return invoke('start_monitoring');
}

/**
 * Stop monitoring for Kindle device connection
 */
export async function stopMonitoring(): Promise<void> {
  return invoke('stop_monitoring');
}

/**
 * Manually trigger import from connected Kindle
 */
export async function triggerImport(): Promise<ImportResult> {
  return invoke<ImportResult>('trigger_import');
}

/**
 * Get auto-import enabled setting
 */
export async function getAutoImportEnabled(): Promise<boolean> {
  return invoke<boolean>('get_auto_import_enabled');
}

/**
 * Set auto-import enabled setting
 */
export async function setAutoImportEnabled(enabled: boolean): Promise<void> {
  return invoke('set_auto_import_enabled', { enabled });
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
