import { describe, it, expect, beforeEach } from 'vitest';
import { mockIPC, clearMocks } from '@tauri-apps/api/mocks';
import {
  getKindleStatus,
  getClippingsInfo,
  readClippings,
  countClippings,
  formatFileSize,
} from './kindle';

beforeEach(() => {
  clearMocks();
});

describe('getKindleStatus', () => {
  it('returns true when Kindle is connected', async () => {
    mockIPC((cmd) => {
      if (cmd === 'get_kindle_status') return true;
    });

    const result = await getKindleStatus();
    expect(result).toBe(true);
  });

  it('returns false when Kindle is not connected', async () => {
    mockIPC((cmd) => {
      if (cmd === 'get_kindle_status') return false;
    });

    const result = await getKindleStatus();
    expect(result).toBe(false);
  });
});

describe('getClippingsInfo', () => {
  it('returns file path and size when file exists', async () => {
    const mockPath = '/Volumes/Kindle/documents/My Clippings.txt';
    const mockSize = 1024;

    mockIPC((cmd) => {
      if (cmd === 'get_clippings_info') {
        return [mockPath, mockSize];
      }
    });

    const result = await getClippingsInfo();
    expect(result).toEqual([mockPath, mockSize]);
  });

  it('handles errors gracefully', async () => {
    mockIPC((cmd) => {
      if (cmd === 'get_clippings_info') {
        throw new Error('File not found');
      }
    });

    await expect(getClippingsInfo()).rejects.toThrow();
  });
});

describe('readClippings', () => {
  it('returns file content when file exists', async () => {
    const mockContent = 'Sample clippings content';

    mockIPC((cmd) => {
      if (cmd === 'read_clippings') {
        return mockContent;
      }
    });

    const result = await readClippings();
    expect(result).toBe(mockContent);
  });

  it('handles errors gracefully', async () => {
    mockIPC((cmd) => {
      if (cmd === 'read_clippings') {
        throw new Error('Failed to read file');
      }
    });

    await expect(readClippings()).rejects.toThrow();
  });
});

describe('countClippings', () => {
  it('returns correct count for content with separators', async () => {
    const mockContent = 'Highlight 1\n==========\nHighlight 2\n==========\nHighlight 3';

    mockIPC((cmd, args) => {
      if (cmd === 'count_clippings') {
        return mockContent.split('==========').length - 1;
      }
    });

    const result = await countClippings(mockContent);
    expect(result).toBe(2);
  });

  it('returns 0 for empty content', async () => {
    mockIPC((cmd, args) => {
      if (cmd === 'count_clippings') {
        return 0;
      }
    });

    const result = await countClippings('');
    expect(result).toBe(0);
  });
});

describe('formatFileSize', () => {
  it('formats bytes correctly', () => {
    expect(formatFileSize(0)).toBe('0 B');
    expect(formatFileSize(1024)).toBe('1 KB');
    expect(formatFileSize(1048576)).toBe('1 MB');
    expect(formatFileSize(1073741824)).toBe('1 GB');
  });

  it('handles decimal sizes', () => {
    expect(formatFileSize(1536)).toBe('1.5 KB');
    expect(formatFileSize(2621440)).toBe('2.5 MB');
  });
});
