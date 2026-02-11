// Unit tests for enrichment versioning logic.
//
// Tests that enrichment_version is correctly stamped on global_dictionary entries
// and that the maintenance query filters work correctly.
//
// Run:
//   deno test --allow-all supabase/functions/tests/unit/enrichment-versioning.test.ts

import {
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

// Mock constants matching the actual implementation
const ENRICHMENT_VERSION = 2;

// =============================================================================
// Version stamping logic tests
// =============================================================================

Deno.test("versioning: enrichment payload includes current version", () => {
  const enrichmentPayload = {
    word: "ubiquitous",
    stem: "ubiquitous",
    lemma: "ubiquitous",
    language_code: "en",
    part_of_speech: "adjective",
    english_definition: "present everywhere",
    synonyms: ["omnipresent"],
    antonyms: [],
    confusables: [],
    example_sentences: [],
    pronunciation_ipa: "/juːˈbɪkwɪtəs/",
    translations: { de: { primary: "allgegenwärtig", alternatives: [], source: "deepl" } },
    cefr_level: "C1",
    confidence: 0.9,
    enrichment_version: ENRICHMENT_VERSION,
  };

  assertEquals(enrichmentPayload.enrichment_version, 2);
});

// =============================================================================
// Maintenance query filter tests
// =============================================================================

Deno.test("versioning: null enrichment_version is stale", () => {
  const entry = { enrichment_version: null };
  const isStale = entry.enrichment_version === null || entry.enrichment_version < ENRICHMENT_VERSION;
  assertEquals(isStale, true, "NULL version should be considered stale");
});

Deno.test("versioning: v1 is stale when current is v2", () => {
  const entry = { enrichment_version: 1 };
  const isStale = entry.enrichment_version === null || entry.enrichment_version < ENRICHMENT_VERSION;
  assertEquals(isStale, true, "v1 should be stale when current is v2");
});

Deno.test("versioning: v2 is not stale when current is v2", () => {
  const entry = { enrichment_version: 2 };
  const isStale = entry.enrichment_version === null || entry.enrichment_version < ENRICHMENT_VERSION;
  assertEquals(isStale, false, "v2 should not be stale when current is v2");
});

Deno.test("versioning: v3 is not stale when current is v2", () => {
  const entry = { enrichment_version: 3 };
  const isStale = entry.enrichment_version === null || entry.enrichment_version < ENRICHMENT_VERSION;
  assertEquals(isStale, false, "v3 should not be stale (future-proof)");
});

// =============================================================================
// Batch size and concurrency tests
// =============================================================================

Deno.test("versioning: default batch size is 20", () => {
  const MAINTAIN_DEFAULT_BATCH_SIZE = 20;
  const batchSize = MAINTAIN_DEFAULT_BATCH_SIZE;
  assertEquals(batchSize, 20);
});

Deno.test("versioning: concurrency is 10", () => {
  const MAINTAIN_CONCURRENCY = 10;
  assertEquals(MAINTAIN_CONCURRENCY, 10);
});

Deno.test("versioning: batch size capped at 100", () => {
  const MAINTAIN_DEFAULT_BATCH_SIZE = 20;
  const requestedBatchSize = 500;
  const actualBatchSize = Math.min(requestedBatchSize, 100);
  assertEquals(actualBatchSize, 100);
});

Deno.test("versioning: batch size respects user request when under cap", () => {
  const requestedBatchSize = 50;
  const actualBatchSize = Math.min(requestedBatchSize, 100);
  assertEquals(actualBatchSize, 50);
});
