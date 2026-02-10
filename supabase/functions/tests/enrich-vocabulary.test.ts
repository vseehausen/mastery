// Integration tests for the enrich-vocabulary edge function.
//
// Tests:
//   1. Global dict hit → link only (no API calls)
//   2. Already enriched → skip
//   3. Queue claim blocks double processing
//   4. Stale processing reset
//   5. Buffer status endpoint
//   6. No auth → 401
//
// Run:
//   deno test --allow-all supabase/functions/tests/enrich-vocabulary-test.ts

import {
  assert,
  assertEquals,
  assertExists,
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
  cleanupGlobalDictionary,
} from "./helpers.ts";

const TEST_EMAIL = "test-enrich-vocab@example.com";
const TEST_PASSWORD = "test-password-123456";
const FN_NAME = "enrich-vocabulary";

let TEST_USER_ID = "";
const globalDictIds: string[] = [];

/** Generate the same content hash as enrich-vocabulary/lookup-word. */
async function generateContentHash(stem: string): Promise<string> {
  const data = new TextEncoder().encode(stem.toLowerCase().trim());
  const hashBuffer = await crypto.subtle.digest("SHA-256", data);
  return Array.from(new Uint8Array(hashBuffer))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

/** Create a vocabulary entry for the test user. */
async function createVocab(
  word: string,
  opts: { globalDictId?: string } = {},
): Promise<string> {
  const client = serviceClient();
  const hash = await generateContentHash(word);
  const id = crypto.randomUUID();

  const { error } = await client.from("vocabulary").insert({
    id,
    user_id: TEST_USER_ID,
    word,
    stem: word,
    content_hash: hash,
    global_dictionary_id: opts.globalDictId || null,
  });

  if (error) throw new Error(`Failed to create vocab: ${error.message}`);
  return id;
}

// =============================================================================
// Tests
// =============================================================================

Deno.test({
  name: "enrich-vocabulary: global dict hit → link only (no API calls)",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    if (!(await isSupabaseRunning()) || !(await isFunctionServed(FN_NAME))) {
      console.log("  ⏭ Skipping: local Supabase or functions not running");
      return;
    }

    TEST_USER_ID = await ensureTestUser(TEST_EMAIL, TEST_PASSWORD);
    await cleanupTestData(TEST_USER_ID);

    // Pre-seed global dictionary
    const hash = await generateContentHash("ubiquitous");
    const gdId = await createTestGlobalDictEntry("ubiquitous", hash);
    globalDictIds.push(gdId);

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
    const hash = await generateContentHash("paradigm");
    const gdId = await createTestGlobalDictEntry("paradigm", hash);
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
  name: "enrich-vocabulary: queue claim blocks double processing",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    if (!(await isSupabaseRunning()) || !(await isFunctionServed(FN_NAME))) {
      console.log("  ⏭ Skipping: local Supabase or functions not running");
      return;
    }

    TEST_USER_ID = await ensureTestUser(TEST_EMAIL, TEST_PASSWORD);
    await cleanupTestData(TEST_USER_ID);

    const vocabId = await createVocab("ephemeral");

    // Manually set queue entry to "processing"
    const client = serviceClient();
    await client.from("enrichment_queue").upsert(
      {
        user_id: TEST_USER_ID,
        vocabulary_id: vocabId,
        status: "processing",
        last_attempted_at: new Date().toISOString(),
      },
      { onConflict: "user_id,vocabulary_id" },
    );

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
    assert(
      data.skipped.includes(vocabId),
      "Should skip word already being processed",
    );

    await cleanupTestData(TEST_USER_ID);
  },
});

Deno.test({
  name: "enrich-vocabulary: stale processing entries are reset",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    if (!(await isSupabaseRunning()) || !(await isFunctionServed(FN_NAME))) {
      console.log("  ⏭ Skipping: local Supabase or functions not running");
      return;
    }

    TEST_USER_ID = await ensureTestUser(TEST_EMAIL, TEST_PASSWORD);
    await cleanupTestData(TEST_USER_ID);

    const vocabId = await createVocab("staleword");

    // Set queue entry to "processing" with stale timestamp (>5 min ago)
    const client = serviceClient();
    const staleTime = new Date(Date.now() - 10 * 60 * 1000).toISOString();
    await client.from("enrichment_queue").upsert(
      {
        user_id: TEST_USER_ID,
        vocabulary_id: vocabId,
        status: "processing",
        last_attempted_at: staleTime,
      },
      { onConflict: "user_id,vocabulary_id" },
    );

    // The function should reset stale entries on any request.
    // Pass a non-existent vocabulary_ids so the function doesn't pick up
    // un-enriched words (batch_size: 0 is falsy → defaults to 5).
    const { accessToken } = await signInAsUser(TEST_EMAIL, TEST_PASSWORD);
    await invokeFunction(FN_NAME, {
      path: "request",
      body: {
        native_language_code: "de",
        vocabulary_ids: ["00000000-0000-0000-0000-000000000000"],
        batch_size: 1,
      },
      authToken: accessToken,
    });

    // Check that queue status was reset to pending
    const { data: queueEntry } = await client
      .from("enrichment_queue")
      .select("status")
      .eq("user_id", TEST_USER_ID)
      .eq("vocabulary_id", vocabId)
      .single();

    assertEquals(
      queueEntry?.status,
      "pending",
      "Stale processing entry should be reset to pending",
    );

    await cleanupTestData(TEST_USER_ID);
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
    const hash = await generateContentHash("enriched");
    const gdId = await createTestGlobalDictEntry("enriched", hash);
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
