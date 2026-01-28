import { beforeAll } from 'vitest';
import { randomFillSync } from 'crypto';
import '@testing-library/jest-dom';
import { config } from 'dotenv';
import { resolve } from 'path';

config({ path: resolve(process.cwd(), '.env') });

// jsdom doesn't come with a WebCrypto implementation
beforeAll(() => {
  Object.defineProperty(window, 'crypto', {
    value: {
      getRandomValues: <T extends ArrayBufferView | null>(buffer: T): T => {
        if (buffer) {
          randomFillSync(buffer as NodeJS.ArrayBufferView);
        }
        return buffer;
      },
    },
  });
});
