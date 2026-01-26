/**
 * Kindle connection API
 */

import { invoke } from '@tauri-apps/api/core';

export interface KindleStatus {
  connected: boolean;
  connectionType: 'mounted' | 'mtp' | null;
}

/**
 * Check Kindle connection status
 */
export async function checkKindleStatus(): Promise<KindleStatus> {
  return invoke<KindleStatus>('check_kindle_status');
}
