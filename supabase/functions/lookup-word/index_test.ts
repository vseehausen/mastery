import { assertEquals, assertExists } from 'https://deno.land/std@0.208.0/assert/mod.ts';

const BASE_URL = 'http://localhost:54321/functions/v1/lookup-word';

// Helper to create authenticated request
function makeRequest(
  path: string,
  options: RequestInit & { token?: string } = {},
): Request {
  const { token, ...init } = options;
  const headers = new Headers(init.headers);
  headers.set('Content-Type', 'application/json');
  if (token) {
    headers.set('Authorization', `Bearer ${token}`);
  }
  return new Request(`${BASE_URL}${path}`, { ...init, headers });
}

Deno.test('POST /lookup-word — missing auth returns 401', async () => {
  const req = makeRequest('', {
    method: 'POST',
    body: JSON.stringify({
      raw_word: 'ubiquitous',
      sentence: 'The ubiquitous smartphone has transformed how we consume information.',
      url: 'https://example.com/article',
      title: 'Test Article',
    }),
  });

  const res = await fetch(req);
  assertEquals(res.status, 401);
  const body = await res.json();
  assertExists(body.error);
});

Deno.test('POST /lookup-word — missing raw_word returns 400', async () => {
  const req = makeRequest('', {
    method: 'POST',
    token: 'test-token',
    body: JSON.stringify({
      sentence: 'Some sentence.',
      url: 'https://example.com',
      title: 'Test',
    }),
  });

  const res = await fetch(req);
  assertEquals(res.status, 400);
  const body = await res.json();
  assertEquals(body.message, 'raw_word is required');
});

Deno.test('POST /lookup-word — raw_word too long returns 400', async () => {
  const req = makeRequest('', {
    method: 'POST',
    token: 'test-token',
    body: JSON.stringify({
      raw_word: 'a'.repeat(101),
      sentence: 'Some sentence.',
      url: 'https://example.com',
      title: 'Test',
    }),
  });

  const res = await fetch(req);
  assertEquals(res.status, 400);
  const body = await res.json();
  assertEquals(body.message, 'raw_word must be max 100 characters');
});

Deno.test('POST /lookup-word — missing sentence returns 400', async () => {
  const req = makeRequest('', {
    method: 'POST',
    token: 'test-token',
    body: JSON.stringify({
      raw_word: 'test',
      url: 'https://example.com',
      title: 'Test',
    }),
  });

  const res = await fetch(req);
  assertEquals(res.status, 400);
  const body = await res.json();
  assertEquals(body.message, 'sentence is required');
});

Deno.test('POST /lookup-word — missing url returns 400', async () => {
  const req = makeRequest('', {
    method: 'POST',
    token: 'test-token',
    body: JSON.stringify({
      raw_word: 'test',
      sentence: 'A test sentence.',
      title: 'Test',
    }),
  });

  const res = await fetch(req);
  assertEquals(res.status, 400);
  const body = await res.json();
  assertEquals(body.message, 'url is required');
});

Deno.test('POST /lookup-word — missing title returns 400', async () => {
  const req = makeRequest('', {
    method: 'POST',
    token: 'test-token',
    body: JSON.stringify({
      raw_word: 'test',
      sentence: 'A test sentence.',
      url: 'https://example.com',
    }),
  });

  const res = await fetch(req);
  assertEquals(res.status, 400);
  const body = await res.json();
  assertEquals(body.message, 'title is required');
});

// NOTE: Integration tests below require a running Supabase instance with
// proper auth tokens and OpenAI API key. They are included for documentation
// and should be run in a full test environment.

// Deno.test('POST /lookup-word — new word lookup', async () => {
//   const res = await fetch(makeRequest('', {
//     method: 'POST',
//     token: VALID_TOKEN,
//     body: JSON.stringify({
//       raw_word: 'ubiquitous',
//       sentence: 'The ubiquitous smartphone has transformed how we consume information.',
//       url: 'https://economist.com/article/digital-revolution',
//       title: 'The Digital Revolution',
//     }),
//   }));
//   assertEquals(res.status, 200);
//   const body = await res.json();
//   assertEquals(body.is_new, true);
//   assertEquals(body.stage, 'new');
//   assertExists(body.lemma);
//   assertExists(body.translation);
//   assertExists(body.pronunciation);
//   assertExists(body.vocabulary_id);
// });

// Deno.test('POST /lookup-word — repeat word lookup adds encounter', async () => {
//   // Second lookup of same word
//   const res = await fetch(makeRequest('', {
//     method: 'POST',
//     token: VALID_TOKEN,
//     body: JSON.stringify({
//       raw_word: 'ubiquitous',
//       sentence: 'Smart devices are ubiquitous in modern offices.',
//       url: 'https://techcrunch.com/article/modern-offices',
//       title: 'Modern Offices',
//     }),
//   }));
//   assertEquals(res.status, 200);
//   const body = await res.json();
//   assertEquals(body.is_new, false);
//   assertExists(body.vocabulary_id);
// });

// Deno.test('POST /lookup-word — multi-word phrase', async () => {
//   const res = await fetch(makeRequest('', {
//     method: 'POST',
//     token: VALID_TOKEN,
//     body: JSON.stringify({
//       raw_word: 'break down',
//       sentence: 'Let me break down the key findings from the report.',
//       url: 'https://medium.com/article/research-findings',
//       title: 'Research Findings',
//     }),
//   }));
//   assertEquals(res.status, 200);
//   const body = await res.json();
//   assertExists(body.lemma);
// });

// Deno.test('GET /lookup-word/batch-status — returns stats', async () => {
//   const res = await fetch(makeRequest('/batch-status', {
//     method: 'GET',
//     token: VALID_TOKEN,
//   }));
//   assertEquals(res.status, 200);
//   const body = await res.json();
//   assertExists(body.total_words);
//   assertEquals(Array.isArray(body.page_words), true);
// });
