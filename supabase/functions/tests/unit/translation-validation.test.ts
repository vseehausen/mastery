// Unit tests for translation validation logic.
//
// Both getDeepLTranslation and getGoogleTranslation in _shared/translation.ts
// apply the same quality validation:
//   - Reject < 2 chars
//   - Reject same as input word (case-insensitive)
//   - Reject punctuation-only strings
//
// Run:
//   deno test --allow-all supabase/functions/tests/unit/translation-validation-test.ts

import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

/**
 * Re-implementation of the validation logic from _shared/translation.ts.
 * Returns true if the translation should be accepted, false if rejected.
 */
function isValidTranslation(translation: string, inputWord: string): boolean {
  const cleaned = translation.trim();
  if (cleaned.length < 2) return false;
  if (cleaned.toLowerCase() === inputWord.toLowerCase()) return false;
  if (/^[\s\p{P}]+$/u.test(cleaned)) return false;
  return true;
}

// =============================================================================
// Accept valid translations
// =============================================================================

Deno.test("validation: accepts normal translation", () => {
  assert(isValidTranslation("Entwickler", "developer"));
});

Deno.test("validation: accepts 2-char translation", () => {
  assert(isValidTranslation("zu", "to"));
});

Deno.test("validation: accepts translation with punctuation mixed in", () => {
  assert(isValidTranslation("Hallo!", "hello"));
});

// =============================================================================
// Reject invalid translations
// =============================================================================

Deno.test("validation: rejects single char", () => {
  assertEquals(isValidTranslation("x", "test"), false);
});

Deno.test("validation: rejects empty string", () => {
  assertEquals(isValidTranslation("", "test"), false);
});

Deno.test("validation: rejects whitespace only", () => {
  assertEquals(isValidTranslation("   ", "test"), false);
});

Deno.test("validation: rejects same as input (exact match)", () => {
  assertEquals(isValidTranslation("developer", "developer"), false);
});

Deno.test("validation: rejects same as input (case-insensitive)", () => {
  assertEquals(isValidTranslation("Developer", "developer"), false);
});

Deno.test("validation: rejects punctuation-only", () => {
  assertEquals(isValidTranslation("...", "test"), false);
});

Deno.test("validation: rejects dash-only", () => {
  assertEquals(isValidTranslation("---", "test"), false);
});

Deno.test("validation: rejects mixed punctuation", () => {
  assertEquals(isValidTranslation("!?.", "test"), false);
});
