import { assertEquals, assertExists } from "https://deno.land/std@0.208.0/assert/mod.ts";
import { generateAudio, generateAllAudio, sanitizeLemmaForStorage } from "../_shared/audio.ts";

// =============================================================================
// Mock Helpers
// =============================================================================

/**
 * Creates a mock Supabase storage client for testing audio upload functionality.
 */
function createMockStorageClient(options: {
  uploadError?: { message: string } | null;
  publicUrl?: string;
} = {}) {
  const { uploadError = null, publicUrl = 'https://storage.example.com/word-audio/us/test.mp3' } = options;
  return {
    storage: {
      from: (_bucket: string) => ({
        upload: async (_path: string, _data: Uint8Array, _opts: unknown) => ({
          error: uploadError,
        }),
        getPublicUrl: (path: string) => ({
          data: { publicUrl: publicUrl || `https://storage.example.com/word-audio/${path}` },
        }),
      }),
    },
  } as any;
}

/**
 * Creates a mock fetch function that simulates Google TTS API responses.
 */
function createMockFetch(options: {
  status?: number;
  audioContent?: string;
  shouldThrow?: boolean;
  requestCapture?: { body: string }[];
}) {
  const { status = 200, audioContent = btoa('fake-audio-bytes'), shouldThrow = false, requestCapture } = options;

  return async (url: string | URL, init?: RequestInit): Promise<Response> => {
    if (shouldThrow) {
      throw new Error('Network error');
    }

    const urlStr = url.toString();
    if (urlStr.includes('texttospeech.googleapis.com')) {
      // Capture request body if requested
      if (requestCapture && init?.body) {
        requestCapture.push({ body: init.body as string });
      }

      if (status !== 200) {
        return new Response(null, { status });
      }

      return new Response(JSON.stringify({ audioContent }), {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    return new Response(null, { status: 404 });
  };
}

// =============================================================================
// sanitizeLemmaForStorage Tests
// =============================================================================

Deno.test("sanitizeLemmaForStorage - simple word", () => {
  assertEquals(sanitizeLemmaForStorage("abandon"), "abandon");
});

Deno.test("sanitizeLemmaForStorage - hyphenated word", () => {
  assertEquals(sanitizeLemmaForStorage("well-known"), "well-known");
});

Deno.test("sanitizeLemmaForStorage - word with apostrophe", () => {
  assertEquals(sanitizeLemmaForStorage("don't"), "don_t");
});

Deno.test("sanitizeLemmaForStorage - uppercase", () => {
  assertEquals(sanitizeLemmaForStorage("ABANDON"), "abandon");
});

Deno.test("sanitizeLemmaForStorage - special characters", () => {
  assertEquals(sanitizeLemmaForStorage("test@#$%word"), "test____word");
});

// =============================================================================
// generateAudio Tests
// =============================================================================

Deno.test("generateAudio - success path with US accent", async () => {
  const originalFetch = globalThis.fetch;
  globalThis.fetch = createMockFetch({}) as any;

  try {
    const mockClient = createMockStorageClient({
      publicUrl: 'https://storage.example.com/word-audio/us/test.mp3',
    });

    const result = await generateAudio('test', 'us', 'fake-api-key', mockClient);

    assertEquals(result, 'https://storage.example.com/word-audio/us/test.mp3');
  } finally {
    globalThis.fetch = originalFetch;
  }
});

Deno.test("generateAudio - success path with GB accent", async () => {
  const originalFetch = globalThis.fetch;
  globalThis.fetch = createMockFetch({}) as any;

  try {
    const mockClient = createMockStorageClient({
      publicUrl: 'https://storage.example.com/word-audio/gb/test.mp3',
    });

    const result = await generateAudio('test', 'gb', 'fake-api-key', mockClient);

    assertEquals(result, 'https://storage.example.com/word-audio/gb/test.mp3');
  } finally {
    globalThis.fetch = originalFetch;
  }
});

Deno.test("generateAudio - TTS API failure (500 error)", async () => {
  const originalFetch = globalThis.fetch;
  globalThis.fetch = createMockFetch({ status: 500 }) as any;

  try {
    const mockClient = createMockStorageClient();

    const result = await generateAudio('test', 'us', 'fake-api-key', mockClient);

    assertEquals(result, null);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

Deno.test("generateAudio - storage upload failure", async () => {
  const originalFetch = globalThis.fetch;
  globalThis.fetch = createMockFetch({}) as any;

  try {
    const mockClient = createMockStorageClient({
      uploadError: { message: 'Upload failed' },
    });

    const result = await generateAudio('test', 'us', 'fake-api-key', mockClient);

    assertEquals(result, null);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

Deno.test("generateAudio - network error", async () => {
  const originalFetch = globalThis.fetch;
  globalThis.fetch = createMockFetch({ shouldThrow: true }) as any;

  try {
    const mockClient = createMockStorageClient();

    const result = await generateAudio('test', 'us', 'fake-api-key', mockClient);

    assertEquals(result, null);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

Deno.test("generateAudio - US accent uses en-US-Chirp3-HD-Gacrux voice", async () => {
  const originalFetch = globalThis.fetch;
  const requestCapture: { body: string }[] = [];
  globalThis.fetch = createMockFetch({ requestCapture }) as any;

  try {
    const mockClient = createMockStorageClient();

    await generateAudio('test', 'us', 'fake-api-key', mockClient);

    assertEquals(requestCapture.length, 1);
    const requestBody = JSON.parse(requestCapture[0].body);
    assertEquals(requestBody.voice.name, 'en-US-Chirp3-HD-Gacrux');
    assertEquals(requestBody.voice.languageCode, 'en-US');
  } finally {
    globalThis.fetch = originalFetch;
  }
});

Deno.test("generateAudio - GB accent uses en-GB-Chirp3-HD-Gacrux voice", async () => {
  const originalFetch = globalThis.fetch;
  const requestCapture: { body: string }[] = [];
  globalThis.fetch = createMockFetch({ requestCapture }) as any;

  try {
    const mockClient = createMockStorageClient();

    await generateAudio('test', 'gb', 'fake-api-key', mockClient);

    assertEquals(requestCapture.length, 1);
    const requestBody = JSON.parse(requestCapture[0].body);
    assertEquals(requestBody.voice.name, 'en-GB-Chirp3-HD-Gacrux');
    assertEquals(requestBody.voice.languageCode, 'en-GB');
  } finally {
    globalThis.fetch = originalFetch;
  }
});

// =============================================================================
// generateAllAudio Tests
// =============================================================================

Deno.test("generateAllAudio - both accents succeed", async () => {
  const originalFetch = globalThis.fetch;
  globalThis.fetch = createMockFetch({}) as any;

  try {
    let callCount = 0;
    const mockClient = {
      storage: {
        from: (_bucket: string) => ({
          upload: async (_path: string, _data: Uint8Array, _opts: unknown) => ({
            error: null,
          }),
          getPublicUrl: (path: string) => {
            callCount++;
            const accent = path.startsWith('us/') ? 'us' : 'gb';
            return {
              data: { publicUrl: `https://storage.example.com/word-audio/${accent}/test.mp3` },
            };
          },
        }),
      },
    } as any;

    const result = await generateAllAudio('test', 'fake-api-key', mockClient);

    assertEquals(result.us, 'https://storage.example.com/word-audio/us/test.mp3');
    assertEquals(result.gb, 'https://storage.example.com/word-audio/gb/test.mp3');
    assertEquals(Object.keys(result).length, 2);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

Deno.test("generateAllAudio - partial failure (US succeeds, GB fails)", async () => {
  const originalFetch = globalThis.fetch;
  let callCount = 0;
  globalThis.fetch = createMockFetch({}) as any;

  try {
    const mockClient = {
      storage: {
        from: (_bucket: string) => ({
          upload: async (path: string, _data: Uint8Array, _opts: unknown) => {
            callCount++;
            // Fail GB upload
            if (path.startsWith('gb/')) {
              return { error: { message: 'Upload failed' } };
            }
            return { error: null };
          },
          getPublicUrl: (path: string) => ({
            data: { publicUrl: `https://storage.example.com/word-audio/${path}` },
          }),
        }),
      },
    } as any;

    const result = await generateAllAudio('test', 'fake-api-key', mockClient);

    assertEquals(result.us, 'https://storage.example.com/word-audio/us/test.mp3');
    assertEquals(result.gb, undefined);
    assertEquals(Object.keys(result).length, 1);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

Deno.test("generateAllAudio - total failure (both fail)", async () => {
  const originalFetch = globalThis.fetch;
  globalThis.fetch = createMockFetch({ status: 500 }) as any;

  try {
    const mockClient = createMockStorageClient();

    const result = await generateAllAudio('test', 'fake-api-key', mockClient);

    assertEquals(Object.keys(result).length, 0);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

// =============================================================================
// Static Content Checks (from original test file)
// =============================================================================

Deno.test("ENRICHMENT_VERSION is 5", async () => {
  const content = await Deno.readTextFile(
    new URL('./index.ts', import.meta.url).pathname
  );
  const match = content.match(/const ENRICHMENT_VERSION = (\d+)/);
  assertExists(match, 'ENRICHMENT_VERSION constant not found');
  assertEquals(match![1], '5', 'ENRICHMENT_VERSION should be 5');
});

Deno.test("buildEnrichmentPayload includes audio_urls field", async () => {
  const content = await Deno.readTextFile(
    new URL('./index.ts', import.meta.url).pathname
  );
  // Check that the function signature includes audioUrls parameter
  const hasAudioParam = content.includes('audioUrls?: Record<string, string>');
  assertEquals(hasAudioParam, true, 'buildEnrichmentPayload should accept audioUrls parameter');

  // Check that the payload includes audio_urls
  const hasAudioField = content.includes('audio_urls: audioUrls');
  assertEquals(hasAudioField, true, 'payload should include audio_urls field');
});

Deno.test("GlobalDictEntry includes audio_urls in select", async () => {
  const content = await Deno.readTextFile(
    new URL('../_shared/global-dictionary.ts', import.meta.url).pathname
  );
  const hasAudioUrls = content.includes('audio_urls');
  assertEquals(hasAudioUrls, true, 'GlobalDictEntry should reference audio_urls');
});
