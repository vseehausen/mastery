// Unit tests for content hash generation.
//
// Two hash variants exist in the codebase:
//   1. parse-vocab: hash(word.toLowerCase() + "|" + (stem || "").toLowerCase())
//   2. enrich-vocabulary/lookup-word: hash(stem.toLowerCase().trim())
//
// Run:
//   deno test --allow-all supabase/functions/tests/unit/content-hash-test.ts

import {
  assert,
  assertEquals,
  assertNotEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

/** Re-implementation of parse-vocab's generateContentHash. */
async function parseVocabHash(
  word: string,
  stem: string | null,
): Promise<string> {
  const normalized = [
    word.toLowerCase().trim(),
    (stem || "").toLowerCase().trim(),
  ].join("|");

  const data = new TextEncoder().encode(normalized);
  const hashBuffer = await crypto.subtle.digest("SHA-256", data);
  return Array.from(new Uint8Array(hashBuffer))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

/** Re-implementation of enrich-vocabulary/lookup-word's generateContentHash. */
async function globalDictHash(stem: string): Promise<string> {
  const data = new TextEncoder().encode(stem.toLowerCase().trim());
  const hashBuffer = await crypto.subtle.digest("SHA-256", data);
  return Array.from(new Uint8Array(hashBuffer))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

// =============================================================================
// parse-vocab hash variant
// =============================================================================

Deno.test("parseVocabHash: deterministic output", async () => {
  const h1 = await parseVocabHash("hello", "hell");
  const h2 = await parseVocabHash("hello", "hell");
  assertEquals(h1, h2);
});

Deno.test("parseVocabHash: case-insensitive", async () => {
  const h1 = await parseVocabHash("Hello", "Hell");
  const h2 = await parseVocabHash("hello", "hell");
  assertEquals(h1, h2);
});

Deno.test("parseVocabHash: trims whitespace", async () => {
  const h1 = await parseVocabHash("  hello  ", "  hell  ");
  const h2 = await parseVocabHash("hello", "hell");
  assertEquals(h1, h2);
});

Deno.test("parseVocabHash: null stem differs from non-null", async () => {
  const h1 = await parseVocabHash("hello", null);
  const h2 = await parseVocabHash("hello", "hell");
  assertNotEquals(h1, h2);
});

Deno.test("parseVocabHash: null stem is deterministic", async () => {
  const h1 = await parseVocabHash("hello", null);
  const h2 = await parseVocabHash("hello", null);
  assertEquals(h1, h2);
});

Deno.test("parseVocabHash: different words produce different hashes", async () => {
  const h1 = await parseVocabHash("hello", "hello");
  const h2 = await parseVocabHash("world", "world");
  assertNotEquals(h1, h2);
});

Deno.test("parseVocabHash: returns 64-char hex string", async () => {
  const h = await parseVocabHash("test", "test");
  assertEquals(h.length, 64);
  assert(/^[0-9a-f]{64}$/.test(h));
});

// =============================================================================
// global dictionary hash variant (enrich-vocabulary / lookup-word)
// =============================================================================

Deno.test("globalDictHash: deterministic output", async () => {
  const h1 = await globalDictHash("developer");
  const h2 = await globalDictHash("developer");
  assertEquals(h1, h2);
});

Deno.test("globalDictHash: case-insensitive", async () => {
  const h1 = await globalDictHash("Developer");
  const h2 = await globalDictHash("developer");
  assertEquals(h1, h2);
});

Deno.test("globalDictHash: trims whitespace", async () => {
  const h1 = await globalDictHash("  developer  ");
  const h2 = await globalDictHash("developer");
  assertEquals(h1, h2);
});

Deno.test("globalDictHash: different words produce different hashes", async () => {
  const h1 = await globalDictHash("hello");
  const h2 = await globalDictHash("world");
  assertNotEquals(h1, h2);
});

Deno.test("globalDictHash: returns 64-char hex string", async () => {
  const h = await globalDictHash("test");
  assertEquals(h.length, 64);
  assert(/^[0-9a-f]{64}$/.test(h));
});

// =============================================================================
// Cross-variant comparison
// =============================================================================

Deno.test("hash variants: produce different results for same input", async () => {
  // parse-vocab uses "word|stem", global dict uses just "stem"
  const pvHash = await parseVocabHash("developer", "developer");
  const gdHash = await globalDictHash("developer");
  assertNotEquals(
    pvHash,
    gdHash,
    "Different hash algorithms should produce different results",
  );
});
