// Unit tests for DeepL context parameter propagation.
//
// Verifies that the DeepL request body includes the `context` field when
// provided and omits it when not. Uses the same re-implementation pattern
// as translation-validation.test.ts.
//
// Run:
//   deno test --allow-all supabase/functions/tests/unit/translation-context.test.ts

import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

/**
 * Re-implementation of the DeepL request body construction from
 * _shared/translation.ts getDeepLTranslation().
 */
function buildDeepLRequestBody(
  word: string,
  targetLang: string,
  context?: string,
): Record<string, unknown> {
  const body: Record<string, unknown> = {
    text: [word],
    source_lang: 'EN',
    target_lang: targetLang.toUpperCase(),
  };
  if (context) body.context = context;
  return body;
}

// =============================================================================
// With context → body has `context` field
// =============================================================================

Deno.test("context: DeepL body includes context when provided", () => {
  const body = buildDeepLRequestBody("mercurial", "de", "As a mercurial figure, he signifies negotiation");
  assertEquals(body.context, "As a mercurial figure, he signifies negotiation");
  assertEquals(body.text, ["mercurial"]);
  assertEquals(body.target_lang, "DE");
});

Deno.test("context: context field is a string value", () => {
  const body = buildDeepLRequestBody("bank", "de", "She sat on the bank of the river");
  assert(typeof body.context === "string");
  assertEquals(body.context, "She sat on the bank of the river");
});

// =============================================================================
// Without context → body has no `context` field
// =============================================================================

Deno.test("context: DeepL body omits context when undefined", () => {
  const body = buildDeepLRequestBody("developer", "de");
  assertEquals("context" in body, false);
});

Deno.test("context: DeepL body omits context when empty string", () => {
  const body = buildDeepLRequestBody("developer", "de", "");
  assertEquals("context" in body, false);
});

// =============================================================================
// Target language normalization
// =============================================================================

Deno.test("context: target_lang is uppercased", () => {
  const body = buildDeepLRequestBody("test", "de", "some context");
  assertEquals(body.target_lang, "DE");
});

Deno.test("context: source_lang is always EN", () => {
  const body = buildDeepLRequestBody("test", "fr", "un contexte");
  assertEquals(body.source_lang, "EN");
});
