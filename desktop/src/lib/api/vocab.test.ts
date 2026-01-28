import { describe, it, expect, vi, beforeEach } from 'vitest';
import { mockIPC, clearMocks } from '@tauri-apps/api/mocks';
import { importFromKindle, getImportHistory } from './vocab';

vi.mock('$lib/supabase', () => ({
  supabase: {
    functions: {
      invoke: vi.fn()
    },
    from: vi.fn()
  }
}));

describe('vocab API', () => {
  beforeEach(() => {
    clearMocks();
    vi.clearAllMocks();
  });

  it('importFromKindle reads from Rust and uploads to Supabase', async () => {
    const mockBytes = [83, 81, 76, 105, 116, 101];
    mockIPC((cmd) => {
      if (cmd === 'read_kindle_vocab_db') return mockBytes;
    });

    const { supabase } = await import('$lib/supabase');
    vi.mocked(supabase.functions.invoke).mockResolvedValue({
      data: { totalParsed: 100, imported: 50, skipped: 50, books: 5 },
      error: null
    });

    const result = await importFromKindle();
    
    expect(supabase.functions.invoke).toHaveBeenCalledWith('parse-vocab', {
      body: { file: expect.any(String) }
    });
    expect(result.imported).toBe(50);
    expect(result.skipped).toBe(50);
    expect(result.books).toBe(5);
  });

  it('importFromKindle handles Kindle not connected error', async () => {
    mockIPC((cmd) => {
      if (cmd === 'read_kindle_vocab_db') {
        throw new Error('Kindle not connected');
      }
    });

    await expect(importFromKindle()).rejects.toThrow('Kindle not connected');
  });

  it('importFromKindle handles empty data error', async () => {
    mockIPC((cmd) => {
      if (cmd === 'read_kindle_vocab_db') return [];
    });

    await expect(importFromKindle()).rejects.toThrow('No data read from Kindle');
  });

  it('getImportHistory fetches from Supabase', async () => {
    const { supabase } = await import('$lib/supabase');
    const mockData = [
      {
        id: '1',
        started_at: '2024-01-01T00:00:00Z',
        total_found: 100,
        imported: 50,
        skipped: 50,
        errors: 0
      }
    ];
    
    const mockQuery = {
      select: vi.fn().mockReturnThis(),
      order: vi.fn().mockReturnThis(),
      limit: vi.fn().mockResolvedValue({ data: mockData, error: null })
    };
    
    vi.mocked(supabase.from).mockReturnValue(mockQuery as any);

    const result = await getImportHistory();
    expect(supabase.from).toHaveBeenCalledWith('import_sessions');
    expect(result).toHaveLength(1);
    expect(result[0].id).toBe('1');
    expect(result[0].status).toBe('success');
  });

  it('getImportHistory handles errors', async () => {
    const { supabase } = await import('$lib/supabase');
    const mockQuery = {
      select: vi.fn().mockReturnThis(),
      order: vi.fn().mockReturnThis(),
      limit: vi.fn().mockResolvedValue({
        data: null,
        error: { message: 'Failed to fetch' }
      })
    };
    
    vi.mocked(supabase.from).mockReturnValue(mockQuery as any);

    await expect(getImportHistory()).rejects.toThrow('Failed to fetch');
  });
});
