// Unit tests for normalize — trim + lowercase normalization.
//
// Run:
//   deno test --allow-all supabase/functions/tests/unit/normalize.test.ts

import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";

import { normalize } from "../../_shared/normalize.ts";

Deno.test("normalize: trims whitespace", () => {
  assertEquals(normalize("  hello  "), "hello");
});

Deno.test("normalize: lowercases", () => {
  assertEquals(normalize("Hello"), "hello");
  assertEquals(normalize("WORLD"), "world");
});

Deno.test("normalize: trims and lowercases together", () => {
  assertEquals(normalize("  Developer  "), "developer");
});

Deno.test("normalize: empty string", () => {
  assertEquals(normalize(""), "");
  assertEquals(normalize("   "), "");
});

Deno.test("normalize: preserves accents", () => {
  assertEquals(normalize("Café"), "café");
  assertEquals(normalize("naïve"), "naïve");
});

Deno.test("normalize: preserves hyphens and apostrophes", () => {
  assertEquals(normalize("well-known"), "well-known");
  assertEquals(normalize("don't"), "don't");
});
