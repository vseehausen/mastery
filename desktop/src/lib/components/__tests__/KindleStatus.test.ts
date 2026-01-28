import { describe, it, expect, beforeEach, vi } from 'vitest';
import { mockIPC, clearMocks } from '@tauri-apps/api/mocks';
import { checkKindleStatus, type KindleStatus } from '../../api/kindle';
import { importFromKindle } from '../../api/vocab';

vi.mock('$lib/supabase', () => ({
  supabase: {
    functions: {
      invoke: vi.fn()
    }
  }
}));

beforeEach(() => {
  clearMocks();
  vi.clearAllMocks();
});

describe('Kindle API Integration', () => {
  it('can check Kindle status when connected', async () => {
    const mockStatus: KindleStatus = { connected: true, connectionType: 'mounted' };
    mockIPC((cmd) => {
      if (cmd === 'check_kindle_status') return mockStatus;
    });

    const status = await checkKindleStatus();
    expect(status.connected).toBe(true);
    expect(status.connectionType).toBe('mounted');
  });

  it('can check Kindle status when disconnected', async () => {
    const mockStatus: KindleStatus = { connected: false, connectionType: null };
    mockIPC((cmd) => {
      if (cmd === 'check_kindle_status') return mockStatus;
    });

    const status = await checkKindleStatus();
    expect(status.connected).toBe(false);
    expect(status.connectionType).toBeNull();
  });

  it('can import from Kindle when connected', async () => {
    const mockBytes = [83, 81, 76, 105, 116, 101];
    mockIPC((cmd) => {
      if (cmd === 'read_kindle_vocab_db') return mockBytes;
    });

    const { supabase } = await import('$lib/supabase');
    vi.mocked(supabase.functions.invoke).mockResolvedValue({
      data: {
        totalParsed: 100,
        imported: 95,
        skipped: 5,
        books: 10,
      },
      error: null
    });

    const result = await importFromKindle();
    expect(result.imported).toBe(95);
    expect(result.skipped).toBe(5);
    expect(result.books).toBe(10);
  });

  it('handles import errors gracefully', async () => {
    mockIPC((cmd) => {
      if (cmd === 'read_kindle_vocab_db') {
        throw new Error('Kindle not connected');
      }
    });

    await expect(importFromKindle()).rejects.toThrow('Kindle not connected');
  });
});
