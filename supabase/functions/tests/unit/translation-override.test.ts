// Unit tests for the confidence-gated AI translation override logic.
//
// Tests the resolveTranslation() function from _shared/translation.ts which
// decides whether to use the AI's best_native_translation or keep the machine
// translation as primary.
//
// Run:
//   deno test --allow-all supabase/functions/tests/unit/translation-override.test.ts

import {
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import { resolveTranslation } from "../../_shared/translation.ts";

// =============================================================================
// AI confidence >= 0.6 + best_native_translation provided → uses AI
// =============================================================================

Deno.test("override: high-confidence AI translation becomes primary", () => {
  const result = resolveTranslation("Quecksilber", "deepl", {
    best_native_translation: "launisch",
    confidence: 0.9,
  });
  assertEquals(result.primary, "launisch");
  assertEquals(result.source, "openai");
});

Deno.test("override: confidence exactly 0.6 uses AI translation", () => {
  const result = resolveTranslation("Quecksilber", "deepl", {
    best_native_translation: "wechselhaft",
    confidence: 0.6,
  });
  assertEquals(result.primary, "wechselhaft");
  assertEquals(result.source, "openai");
});

// =============================================================================
// AI confidence < 0.6 → keeps machine translation
// =============================================================================

Deno.test("override: low-confidence AI keeps machine translation", () => {
  const result = resolveTranslation("Quecksilber", "deepl", {
    best_native_translation: "launisch",
    confidence: 0.5,
  });
  assertEquals(result.primary, "Quecksilber");
  assertEquals(result.source, "deepl");
});

Deno.test("override: zero confidence keeps machine translation", () => {
  const result = resolveTranslation("Entwickler", "deepl", {
    best_native_translation: "Programmierer",
    confidence: 0,
  });
  assertEquals(result.primary, "Entwickler");
  assertEquals(result.source, "deepl");
});

// =============================================================================
// best_native_translation is null → keeps machine translation
// =============================================================================

Deno.test("override: null AI translation keeps machine translation", () => {
  const result = resolveTranslation("Quecksilber", "deepl", {
    best_native_translation: null,
    confidence: 0.9,
  });
  assertEquals(result.primary, "Quecksilber");
  assertEquals(result.source, "deepl");
});

Deno.test("override: no AI enhancement keeps machine translation", () => {
  const result = resolveTranslation("Quecksilber", "deepl", null);
  assertEquals(result.primary, "Quecksilber");
  assertEquals(result.source, "deepl");
  assertEquals(result.alternatives.length, 0);
});

// =============================================================================
// AI overrides machine → old machine translation demoted to alternatives
// =============================================================================

Deno.test("override: machine translation demoted to alternatives when AI overrides", () => {
  const result = resolveTranslation("Quecksilber", "deepl", {
    best_native_translation: "launisch",
    confidence: 0.9,
  });
  assertEquals(result.primary, "launisch");
  assertEquals(result.alternatives.includes("Quecksilber"), true);
});

// =============================================================================
// AI translation same as machine → no duplicate in alternatives
// =============================================================================

Deno.test("override: no duplicate when AI matches machine translation", () => {
  const result = resolveTranslation("launisch", "deepl", {
    best_native_translation: "launisch",
    confidence: 0.9,
  });
  assertEquals(result.primary, "launisch");
  assertEquals(result.alternatives.length, 0);
});

Deno.test("override: case-insensitive dedup between AI and machine", () => {
  const result = resolveTranslation("Launisch", "deepl", {
    best_native_translation: "launisch",
    confidence: 0.9,
  });
  assertEquals(result.primary, "launisch");
  assertEquals(result.alternatives.length, 0);
});

// =============================================================================
// Mercurial example: full scenario
// =============================================================================

Deno.test("override: mercurial example — machine=Quecksilber, AI=launisch, confidence=0.9", () => {
  const result = resolveTranslation("Quecksilber", "deepl", {
    best_native_translation: "launisch",
    confidence: 0.9,
  });
  assertEquals(result.primary, "launisch");
  assertEquals(result.source, "openai");
  assertEquals(result.alternatives.includes("Quecksilber"), true);
});

// =============================================================================
// Edge cases
// =============================================================================

Deno.test("override: missing confidence field defaults to 0 (keeps machine)", () => {
  const result = resolveTranslation("Quecksilber", "deepl", {
    best_native_translation: "launisch",
  });
  assertEquals(result.primary, "Quecksilber");
  assertEquals(result.source, "deepl");
});

Deno.test("override: google source preserved when AI confidence low", () => {
  const result = resolveTranslation("Quecksilber", "google", {
    best_native_translation: "launisch",
    confidence: 0.3,
  });
  assertEquals(result.primary, "Quecksilber");
  assertEquals(result.source, "google");
});
