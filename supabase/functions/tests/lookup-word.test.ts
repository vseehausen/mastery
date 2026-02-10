// Integration tests for the lookup-word edge function.
//
// Tests:
//   1. New word (global dict hit) → creates vocab + card + encounter
//   2. Repeat word → adds encounter, is_new=false
//   3. Batch status endpoint
//   4. Missing raw_word → 400
//   5. No auth → 401
//
// Run:
//   deno test --allow-all supabase/functions/tests/lookup-word-test.ts

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
  createTestWordVariant,
  cleanupGlobalDictionary,
} from "./helpers.ts";

const TEST_EMAIL = "test-lookup-word@example.com";
const TEST_PASSWORD = "test-password-123456";
const FN_NAME = "lookup-word";

let TEST_USER_ID = "";
const globalDictIds: string[] = [];

// =============================================================================
// Tests
// =============================================================================

Deno.test({
  name: "lookup-word: new word (global dict hit) → creates vocab + card + encounter",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    if (!(await isSupabaseRunning()) || !(await isFunctionServed(FN_NAME))) {
      console.log("  ⏭ Skipping: local Supabase or functions not running");
      return;
    }

    TEST_USER_ID = await ensureTestUser(TEST_EMAIL, TEST_PASSWORD);
    await cleanupTestData(TEST_USER_ID);
    await cleanupGlobalDictionary(globalDictIds.splice(0));

    // Pre-seed global dictionary + word_variants mapping
    const gdId = await createTestGlobalDictEntry("developer");
    await createTestWordVariant("developer", gdId);
    globalDictIds.push(gdId);

    const { accessToken } = await signInAsUser(TEST_EMAIL, TEST_PASSWORD);
    const { status, data } = await invokeFunction(FN_NAME, {
      body: {
        raw_word: "developer",
        sentence: "The developer wrote clean code.",
        url: "https://example.com/article",
        title: "Test Article",
      },
      authToken: accessToken,
    });

    assertEquals(
      status,
      200,
      `Expected 200, got ${status}: ${JSON.stringify(data)}`,
    );
    assertEquals(data.is_new, true);
    assertExists(data.vocabulary_id);
    assertEquals(data.lemma, "developer");
    assertEquals(data.stage, "new");

    // Verify vocabulary was created
    const client = serviceClient();
    const { data: vocab } = await client
      .from("vocabulary")
      .select("id, global_dictionary_id")
      .eq("id", data.vocabulary_id)
      .single();

    assertExists(vocab);
    assertEquals(vocab.global_dictionary_id, gdId);

    // Verify learning card was created
    const { data: card } = await client
      .from("learning_cards")
      .select("state")
      .eq("vocabulary_id", data.vocabulary_id)
      .eq("user_id", TEST_USER_ID)
      .single();

    assertExists(card);
    assertEquals(card.state, 0);

    // Verify encounter was created
    const { data: encounters } = await client
      .from("encounters")
      .select("context")
      .eq("vocabulary_id", data.vocabulary_id)
      .eq("user_id", TEST_USER_ID);

    assertEquals(encounters?.length, 1);
    assertEquals(encounters![0].context, "The developer wrote clean code.");

    await cleanupTestData(TEST_USER_ID);
    await cleanupGlobalDictionary(globalDictIds.splice(0));
  },
});

Deno.test({
  name: "lookup-word: repeat word → adds encounter, is_new=false",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    if (!(await isSupabaseRunning()) || !(await isFunctionServed(FN_NAME))) {
      console.log("  ⏭ Skipping: local Supabase or functions not running");
      return;
    }

    TEST_USER_ID = await ensureTestUser(TEST_EMAIL, TEST_PASSWORD);
    await cleanupTestData(TEST_USER_ID);
    await cleanupGlobalDictionary(globalDictIds.splice(0));

    // Pre-seed global dictionary + word_variants mapping
    const gdId = await createTestGlobalDictEntry("resilient");
    await createTestWordVariant("resilient", gdId);
    globalDictIds.push(gdId);

    const { accessToken } = await signInAsUser(TEST_EMAIL, TEST_PASSWORD);

    // First lookup
    const first = await invokeFunction(FN_NAME, {
      body: {
        raw_word: "resilient",
        sentence: "She was resilient in the face of adversity.",
        url: "https://example.com/page1",
        title: "Page 1",
      },
      authToken: accessToken,
    });

    assertEquals(first.status, 200);
    assertEquals(first.data.is_new, true);

    // Second lookup — same word, different context
    const second = await invokeFunction(FN_NAME, {
      body: {
        raw_word: "resilient",
        sentence: "The resilient material bounced back.",
        url: "https://example.com/page2",
        title: "Page 2",
      },
      authToken: accessToken,
    });

    assertEquals(second.status, 200);
    assertEquals(second.data.is_new, false);
    assertEquals(second.data.vocabulary_id, first.data.vocabulary_id);

    // Verify 2 encounters
    const client = serviceClient();
    const { data: encounters } = await client
      .from("encounters")
      .select("context")
      .eq("vocabulary_id", first.data.vocabulary_id)
      .eq("user_id", TEST_USER_ID);

    assertEquals(encounters?.length, 2);

    await cleanupTestData(TEST_USER_ID);
    await cleanupGlobalDictionary(globalDictIds.splice(0));
  },
});

Deno.test({
  name: "lookup-word: batch status endpoint",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    if (!(await isSupabaseRunning()) || !(await isFunctionServed(FN_NAME))) {
      console.log("  ⏭ Skipping: local Supabase or functions not running");
      return;
    }

    TEST_USER_ID = await ensureTestUser(TEST_EMAIL, TEST_PASSWORD);
    await cleanupTestData(TEST_USER_ID);
    await cleanupGlobalDictionary(globalDictIds.splice(0));

    // Pre-seed and look up a word
    const gdId = await createTestGlobalDictEntry("algorithm");
    await createTestWordVariant("algorithm", gdId);
    globalDictIds.push(gdId);

    const { accessToken } = await signInAsUser(TEST_EMAIL, TEST_PASSWORD);
    await invokeFunction(FN_NAME, {
      body: {
        raw_word: "algorithm",
        sentence: "The algorithm was efficient.",
        url: "https://example.com/cs",
        title: "CS Article",
      },
      authToken: accessToken,
    });

    // Get batch status
    const pageUrl = encodeURIComponent("https://example.com/cs");
    const { status, data } = await invokeFunction(FN_NAME, {
      path: `batch-status?url=${pageUrl}`,
      method: "GET",
      authToken: accessToken,
    });

    assertEquals(status, 200);
    assert(data.total_words >= 1, "Should have at least 1 total word");
    assert(data.page_words.length >= 1, "Should have at least 1 page word");

    await cleanupTestData(TEST_USER_ID);
    await cleanupGlobalDictionary(globalDictIds.splice(0));
  },
});

Deno.test({
  name: "lookup-word: returns context-aware translation for polysemous word",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    if (!(await isSupabaseRunning()) || !(await isFunctionServed(FN_NAME))) {
      console.log("  ⏭ Skipping: local Supabase or functions not running");
      return;
    }

    // Skip if DeepL API key is not configured
    const deeplKey = Deno.env.get("DEEPL_API_KEY");
    if (!deeplKey) {
      console.log("  ⏭ Skipping: DEEPL_API_KEY not set");
      return;
    }

    TEST_USER_ID = await ensureTestUser(TEST_EMAIL, TEST_PASSWORD);
    await cleanupTestData(TEST_USER_ID);
    await cleanupGlobalDictionary(globalDictIds.splice(0));

    // No global dict entry for "mercurial" — forces fallback translation path
    const { accessToken } = await signInAsUser(TEST_EMAIL, TEST_PASSWORD);
    const { status, data } = await invokeFunction(FN_NAME, {
      body: {
        raw_word: "mercurial",
        sentence: "As a mercurial figure, he signifies negotiation and changeability.",
        url: "https://example.com/hermes",
        title: "Hermes Article",
      },
      authToken: accessToken,
    });

    assertEquals(
      status,
      200,
      `Expected 200, got ${status}: ${JSON.stringify(data)}`,
    );

    // The translation should NOT be "Quecksilber" (mercury the element)
    // with sentence context, DeepL should pick the figurative sense
    assert(
      data.translation.toLowerCase() !== "quecksilber",
      `Expected context-aware translation, got "${data.translation}" (Quecksilber = wrong sense)`,
    );

    // Should be marked as provisional (no global dict match)
    assertEquals(data.provisional, true, "New word without global dict should be provisional");

    await cleanupTestData(TEST_USER_ID);
    await cleanupGlobalDictionary(globalDictIds.splice(0));
  },
});

Deno.test({
  name: "lookup-word: global dict hit returns provisional=false",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    if (!(await isSupabaseRunning()) || !(await isFunctionServed(FN_NAME))) {
      console.log("  ⏭ Skipping: local Supabase or functions not running");
      return;
    }

    TEST_USER_ID = await ensureTestUser(TEST_EMAIL, TEST_PASSWORD);
    await cleanupTestData(TEST_USER_ID);
    await cleanupGlobalDictionary(globalDictIds.splice(0));

    const gdId = await createTestGlobalDictEntry("ephemeral");
    await createTestWordVariant("ephemeral", gdId);
    globalDictIds.push(gdId);

    const { accessToken } = await signInAsUser(TEST_EMAIL, TEST_PASSWORD);
    const { status, data } = await invokeFunction(FN_NAME, {
      body: {
        raw_word: "ephemeral",
        sentence: "The ephemeral beauty of cherry blossoms.",
        url: "https://example.com/nature",
        title: "Nature Article",
      },
      authToken: accessToken,
    });

    assertEquals(status, 200);
    assertEquals(data.provisional, false, "Global dict hit should not be provisional");

    await cleanupTestData(TEST_USER_ID);
    await cleanupGlobalDictionary(globalDictIds.splice(0));
  },
});

Deno.test({
  name: "lookup-word: missing raw_word → 400",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    if (!(await isSupabaseRunning()) || !(await isFunctionServed(FN_NAME))) {
      console.log("  ⏭ Skipping: local Supabase or functions not running");
      return;
    }

    TEST_USER_ID = await ensureTestUser(TEST_EMAIL, TEST_PASSWORD);
    const { accessToken } = await signInAsUser(TEST_EMAIL, TEST_PASSWORD);

    const { status } = await invokeFunction(FN_NAME, {
      body: {
        sentence: "Some sentence.",
        url: "https://example.com",
        title: "Test",
      },
      authToken: accessToken,
    });

    assertEquals(status, 400);
  },
});

Deno.test({
  name: "lookup-word: no auth → 401",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    if (!(await isSupabaseRunning()) || !(await isFunctionServed(FN_NAME))) {
      console.log("  ⏭ Skipping: local Supabase or functions not running");
      return;
    }

    const { status } = await invokeFunction(FN_NAME, {
      body: {
        raw_word: "test",
        sentence: "Test sentence.",
        url: "https://example.com",
        title: "Test",
      },
    });

    assertEquals(status, 401);
  },
});
