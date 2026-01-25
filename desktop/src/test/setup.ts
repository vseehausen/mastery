import { beforeAll } from 'vitest';
import { randomFillSync } from 'crypto';
import '@testing-library/jest-dom';

// jsdom doesn't come with a WebCrypto implementation
beforeAll(() => {
  Object.defineProperty(window, 'crypto', {
    value: {
      // @ts-ignore
      getRandomValues: (buffer: ArrayBufferView) => {
        return randomFillSync(buffer);
      },
    },
  });
});
