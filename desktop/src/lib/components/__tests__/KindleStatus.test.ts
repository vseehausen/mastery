import { describe, it, expect, beforeEach } from 'vitest';
import { mockIPC, clearMocks } from '@tauri-apps/api/mocks';
import { getKindleStatus, getClippingsInfo, readClippings, countClippings } from '../../api/kindle';

beforeEach(() => {
  clearMocks();
});

describe('Kindle API Integration', () => {
  it('can check Kindle status', async () => {
    mockIPC((cmd) => {
      if (cmd === 'get_kindle_status') return true;
    });

    const status = await getKindleStatus();
    expect(status).toBe(true);
  });

  it('can get file info when connected', async () => {
    mockIPC((cmd) => {
      if (cmd === 'get_kindle_status') return true;
      if (cmd === 'get_clippings_info') {
        return ['/Volumes/Kindle/documents/My Clippings.txt', 2048];
      }
    });

    const status = await getKindleStatus();
    expect(status).toBe(true);

    const [path, size] = await getClippingsInfo();
    expect(path).toContain('My Clippings.txt');
    expect(size).toBe(2048);
  });

  it('can read and count clippings', async () => {
    const mockContent = 'Highlight 1\n==========\nHighlight 2\n==========\nHighlight 3';

    mockIPC((cmd, args) => {
      if (cmd === 'read_clippings') return mockContent;
      if (cmd === 'count_clippings') {
        return mockContent.split('==========').length - 1;
      }
    });

    const content = await readClippings();
    expect(content).toBe(mockContent);

    const count = await countClippings(content);
    expect(count).toBe(2);
  });
});
