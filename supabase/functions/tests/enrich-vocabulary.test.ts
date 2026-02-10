// Integration tests for the enrich-vocabulary edge function.
//
// Tests:
//   1. Global dict hit via word_variants → link only (no API calls)
//   2. Already enriched → skip
//   3. Buffer status endpoint
//   4. No auth → 401
//
// Run:
//   deno test --allow-all supabase/functions/tests/enrich-vocabulary.test.ts

import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  serviceClient,
  ensureTestUser,
  cleanupTestData,
  isSupabaseRunning,
  isFunctionServed,
  invokeFunction,
  signInAsUser,
  createTestGlobalDictEntry,
  createTestWordVariant,
  cleanupGlobalDictionary,
} from "./helpers.ts";

import { normalize } from "../_shared/normalize.ts";

const TEST_EMAIL = "test-enrich-vocab@example.com";
const TEST_PASSWORD = "test-password-123456";
const FN_NAME = "enrich-vocabulary";

let TEST_USER_ID = "";
const globalDictIds: string[] = [];

/** Create a vocabulary entry for the test user. */
async function createVocab(
  word: string,
  opts: { globalDictId?: string } = {},
): Promise<string> {
  const client = serviceClient();
  const normalized = normalize(word);
  const id = crypto.randomUUID();

  const { error } = await client.from("vocabulary").insert({
    id,
    user_id: TEST_USER_ID,
    word: normalized,
    stem: normalized,
    global_dictionary_id: opts.globalDictId || null,
  });

  if (error) throw new Error(`Failed to create vocab: ${error.message}`);
  return id;
}

// =============================================================================
// Tests
// =============================================================================

Deno.test({
  name: "enrich-vocabulary: global dict hit via word_variants → link only (no API calls)",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    if (!(await isSupabaseRunning()) || !(await isFunctionServed(FN_NAME))) {
      console.log("  ⏭ Skipping: local Supabase or functions not running");
      return;
    }

    TEST_USER_ID = await ensureTestUser(TEST_EMAIL, TEST_PASSWORD);
    await cleanupTestData(TEST_USER_ID);

    // Pre-seed global dictionary and word_variants
    const gdId = await createTestGlobalDictEntry("ubiquitous");
    globalDictIds.push(gdId);
    await createTestWordVariant("ubiquitous", gdId);

    // Create vocab without linking to global dict
    const vocabId = await createVocab("ubiquitous");

    // Sign in and invoke
    const { accessToken } = await signInAsUser(TEST_EMAIL, TEST_PASSWORD);
    const { status, data } = await invokeFunction(FN_NAME, {
      path: "request",
      body: {
        native_language_code: "de",
        vocabulary_ids: [vocabId],
        batch_size: 1,
      },
      authToken: accessToken,
    });

    assertEquals(
      status,
      200,
      `Expected 200, got ${status}: ${JSON.stringify(data)}`,
    );
    assertEquals(data.enriched.length, 1, "Should have 1 enriched word");
    assertEquals(data.enriched[0].vocabulary_id, vocabId);
    assertEquals(data.enriched[0].global_dictionary_id, gdId);

    // Verify vocabulary is now linked
    const client = serviceClient();
    const { data: vocab } = await client
      .from("vocabulary")
      .select("global_dictionary_id")
      .eq("id", vocabId)
      .single();

    assertEquals(vocab?.global_dictionary_id, gdId);

    await cleanupTestData(TEST_USER_ID);
    await cleanupGlobalDictionary(globalDictIds.splice(0));
  },
});

Deno.test({
  name: "enrich-vocabulary: already enriched → skip",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    if (!(await isSupabaseRunning()) || !(await isFunctionServed(FN_NAME))) {
      console.log("  ⏭ Skipping: local Supabase or functions not running");
      return;
    }

    TEST_USER_ID = await ensureTestUser(TEST_EMAIL, TEST_PASSWORD);
    await cleanupTestData(TEST_USER_ID);

    // Create global dict entry and vocab already linked to it
    const gdId = await createTestGlobalDictEntry("paradigm");
    globalDictIds.push(gdId);
    const vocabId = await createVocab("paradigm", { globalDictId: gdId });

    const { accessToken } = await signInAsUser(TEST_EMAIL, TEST_PASSWORD);
    const { status, data } = await invokeFunction(FN_NAME, {
      path: "request",
      body: {
        native_language_code: "de",
        vocabulary_ids: [vocabId],
        batch_size: 1,
      },
      authToken: accessToken,
    });

    assertEquals(status, 200);
    assertEquals(data.skipped.length, 1, "Should skip already enriched");
    assert(data.skipped.includes(vocabId));

    await cleanupTestData(TEST_USER_ID);
    await cleanupGlobalDictionary(globalDictIds.splice(0));
  },
});

Deno.test({
  name: "enrich-vocabulary: buffer status endpoint",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    if (!(await isSupabaseRunning()) || !(await isFunctionServed(FN_NAME))) {
      console.log("  ⏭ Skipping: local Supabase or functions not running");
      return;
    }

    TEST_USER_ID = await ensureTestUser(TEST_EMAIL, TEST_PASSWORD);
    await cleanupTestData(TEST_USER_ID);

    // Create some vocab entries — some enriched, some not
    const gdId = await createTestGlobalDictEntry("enriched");
    globalDictIds.push(gdId);
    await createVocab("enriched", { globalDictId: gdId });
    await createVocab("unenriched1");
    await createVocab("unenriched2");

    const { accessToken } = await signInAsUser(TEST_EMAIL, TEST_PASSWORD);
    const { status, data } = await invokeFunction(FN_NAME, {
      path: "status",
      method: "GET",
      authToken: accessToken,
    });

    assertEquals(status, 200);
    assertEquals(data.enriched_count, 1);
    assertEquals(data.un_enriched_count, 2);
    assertEquals(data.needs_replenishment, true);

    await cleanupTestData(TEST_USER_ID);
    await cleanupGlobalDictionary(globalDictIds.splice(0));
  },
});

Deno.test({
  name: "enrich-vocabulary: no auth → 401",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    if (!(await isSupabaseRunning()) || !(await isFunctionServed(FN_NAME))) {
      console.log("  ⏭ Skipping: local Supabase or functions not running");
      return;
    }

    const { status } = await invokeFunction(FN_NAME, {
      path: "request",
      body: { native_language_code: "de" },
    });

    assertEquals(status, 401);
  },
});
