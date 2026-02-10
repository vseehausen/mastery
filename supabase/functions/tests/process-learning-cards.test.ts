// Integration tests for the process-learning-cards edge function.
//
// Tests:
//   1. All cards exist → processed=0
//   2. Missing cards → creates them
//   3. Idempotent — run twice → second: processed=0
//
// Run:
//   deno test --allow-all supabase/functions/tests/process-learning-cards-test.ts

import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  serviceClient,
  ensureTestUser,
  cleanupTestData,
  isSupabaseRunning,
  isFunctionServed,
  invokeFunction,
  signInAsUser,
  createTestVocabulary,
  createTestVocabWithCard,
} from "./helpers.ts";

const TEST_EMAIL = "test-process-cards@example.com";
const TEST_PASSWORD = "test-password-123456";
const FN_NAME = "process-learning-cards";

let TEST_USER_ID = "";

// =============================================================================
// Tests
// =============================================================================

Deno.test({
  name: "process-learning-cards: all cards exist → processed=0",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    if (!(await isSupabaseRunning()) || !(await isFunctionServed(FN_NAME))) {
      console.log("  ⏭ Skipping: local Supabase or functions not running");
      return;
    }

    TEST_USER_ID = await ensureTestUser(TEST_EMAIL, TEST_PASSWORD);
    await cleanupTestData(TEST_USER_ID);

    // Create 5 vocab items with cards
    for (let i = 0; i < 5; i++) {
      await createTestVocabWithCard(TEST_USER_ID, `word${i}`);
    }

    const { accessToken } = await signInAsUser(TEST_EMAIL, TEST_PASSWORD);
    const { status, data } = await invokeFunction(FN_NAME, {
      body: {},
      authToken: accessToken,
    });

    assertEquals(
      status,
      200,
      `Expected 200, got ${status}: ${JSON.stringify(data)}`,
    );
    assertEquals(data.processed, 0, "No new cards should be created");

    await cleanupTestData(TEST_USER_ID);
  },
});

Deno.test({
  name: "process-learning-cards: missing cards → creates them",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    if (!(await isSupabaseRunning()) || !(await isFunctionServed(FN_NAME))) {
      console.log("  ⏭ Skipping: local Supabase or functions not running");
      return;
    }

    TEST_USER_ID = await ensureTestUser(TEST_EMAIL, TEST_PASSWORD);
    await cleanupTestData(TEST_USER_ID);

    // Create 5 vocab: 2 with cards, 3 without
    await createTestVocabWithCard(TEST_USER_ID, "hascard1");
    await createTestVocabWithCard(TEST_USER_ID, "hascard2");
    await createTestVocabulary(TEST_USER_ID, "nocard1");
    await createTestVocabulary(TEST_USER_ID, "nocard2");
    await createTestVocabulary(TEST_USER_ID, "nocard3");

    const { accessToken } = await signInAsUser(TEST_EMAIL, TEST_PASSWORD);
    const { status, data } = await invokeFunction(FN_NAME, {
      body: {},
      authToken: accessToken,
    });

    assertEquals(status, 200);
    assertEquals(data.processed, 3, "Should create 3 missing cards");
    assertEquals(data.totalVocabulary, 5, "Total vocab should be 5");

    // Verify all 5 now have cards
    const client = serviceClient();
    const { data: cards } = await client
      .from("learning_cards")
      .select("id")
      .eq("user_id", TEST_USER_ID);

    assertEquals(cards?.length, 5, "All 5 should have cards now");

    await cleanupTestData(TEST_USER_ID);
  },
});

Deno.test({
  name: "process-learning-cards: idempotent",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    if (!(await isSupabaseRunning()) || !(await isFunctionServed(FN_NAME))) {
      console.log("  ⏭ Skipping: local Supabase or functions not running");
      return;
    }

    TEST_USER_ID = await ensureTestUser(TEST_EMAIL, TEST_PASSWORD);
    await cleanupTestData(TEST_USER_ID);

    // Create vocab without cards
    for (let i = 0; i < 3; i++) {
      await createTestVocabulary(TEST_USER_ID, `idempotent${i}`);
    }

    const { accessToken } = await signInAsUser(TEST_EMAIL, TEST_PASSWORD);

    // First run
    const first = await invokeFunction(FN_NAME, {
      body: {},
      authToken: accessToken,
    });

    assertEquals(first.status, 200);
    assertEquals(first.data.processed, 3);

    // Second run — should process 0
    const second = await invokeFunction(FN_NAME, {
      body: {},
      authToken: accessToken,
    });

    assertEquals(second.status, 200);
    assertEquals(second.data.processed, 0, "Second run should process 0");

    await cleanupTestData(TEST_USER_ID);
  },
});
