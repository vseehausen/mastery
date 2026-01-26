import { describe, it, expect, beforeEach } from 'vitest';
import { mockIPC, clearMocks } from '@tauri-apps/api/mocks';
import { checkKindleStatus, type KindleStatus } from './kindle';

beforeEach(() => {
  clearMocks();
});

describe('checkKindleStatus', () => {
  it('returns connected status when Kindle is connected via USB', async () => {
    const mockStatus: KindleStatus = { connected: true, connectionType: 'mounted' };
    mockIPC((cmd) => {
      if (cmd === 'check_kindle_status') return mockStatus;
    });

    const result = await checkKindleStatus();
    expect(result.connected).toBe(true);
    expect(result.connectionType).toBe('mounted');
  });

  it('returns connected status when Kindle is connected via MTP', async () => {
    const mockStatus: KindleStatus = { connected: true, connectionType: 'mtp' };
    mockIPC((cmd) => {
      if (cmd === 'check_kindle_status') return mockStatus;
    });

    const result = await checkKindleStatus();
    expect(result.connected).toBe(true);
    expect(result.connectionType).toBe('mtp');
  });

  it('returns disconnected status when Kindle is not connected', async () => {
    const mockStatus: KindleStatus = { connected: false, connectionType: null };
    mockIPC((cmd) => {
      if (cmd === 'check_kindle_status') return mockStatus;
    });

    const result = await checkKindleStatus();
    expect(result.connected).toBe(false);
    expect(result.connectionType).toBeNull();
  });
});
