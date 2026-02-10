// Integration tests for enrichment_feedback table and RLS policies.
//
// Test groups:
//   1. Basic CRUD operations (service role)
//   2. CHECK constraints validation
//   3. RLS policies (user isolation)
//   4. CASCADE delete behavior
//
// Run:
//   deno test --allow-all supabase/functions/tests/enrichment-feedback-test.ts

import {
  assert,
  assertEquals,
  assertExists,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  serviceClient,
  anonClient,
  ensureTestUser,
  cleanupTestData,
  isSupabaseRunning,
  createTestVocabAndMeaning,
} from "./helpers.ts";

const TEST_USER_A_EMAIL = "test-feedback-a@example.com";
const TEST_USER_A_PASSWORD = "test-password-123456";
const TEST_USER_B_EMAIL = "test-feedback-b@example.com";
const TEST_USER_B_PASSWORD = "test-password-123456";

let TEST_USER_A_ID = "";
let TEST_USER_B_ID = "";

async function ensureTestUsers() {
  TEST_USER_A_ID = await ensureTestUser(TEST_USER_A_EMAIL, TEST_USER_A_PASSWORD);
  TEST_USER_B_ID = await ensureTestUser(TEST_USER_B_EMAIL, TEST_USER_B_PASSWORD);
}

async function cleanupAllTestData() {
  await cleanupTestData(TEST_USER_A_ID);
  await cleanupTestData(TEST_USER_B_ID);
}

// =============================================================================
// Test 1: Insert + read feedback (service role)
// =============================================================================

Deno.test({
  name: 'integration: insert and read enrichment feedback',
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    if (!(await isSupabaseRunning())) {
      console.log('  ⏭ Skipping: local Supabase not running');
      return;
    }

    await ensureTestUsers();
    await cleanupAllTestData();

    const { meaningId } = await createTestVocabAndMeaning(TEST_USER_A_ID);

    // Insert feedback via service role
    const client = serviceClient();
    const { data: feedback, error: insertError } = await client
      .from('enrichment_feedback')
      .insert({
        user_id: TEST_USER_A_ID,
        meaning_id: meaningId,
        field_name: 'definition',
        rating: 'up',
      })
      .select('id, user_id, meaning_id, field_name, rating, flag_category, comment, created_at')
      .single();

    assertEquals(insertError, null, 'Should insert without error');
    assertExists(feedback);
    assertEquals(feedback.user_id, TEST_USER_A_ID);
    assertEquals(feedback.meaning_id, meaningId);
    assertEquals(feedback.field_name, 'definition');
    assertEquals(feedback.rating, 'up');
    assertEquals(feedback.flag_category, null);
    assertEquals(feedback.comment, null);
    assertExists(feedback.created_at);

    // Read back via service role
    const { data: readFeedback, error: readError } = await client
      .from('enrichment_feedback')
      .select('*')
      .eq('id', feedback.id)
      .single();

    assertEquals(readError, null);
    assertExists(readFeedback);
    assertEquals(readFeedback.id, feedback.id);
    assertEquals(readFeedback.rating, 'up');

    await cleanupAllTestData();
  },
});

// =============================================================================
// Test 2: CHECK constraint validation
// =============================================================================

Deno.test({
  name: 'integration: CHECK constraint rejects invalid rating',
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    if (!(await isSupabaseRunning())) {
      console.log('  ⏭ Skipping: local Supabase not running');
      return;
    }

    await ensureTestUsers();
    await cleanupAllTestData();

    const { meaningId } = await createTestVocabAndMeaning(TEST_USER_A_ID);

    const client = serviceClient();
    const { error } = await client
      .from('enrichment_feedback')
      .insert({
        user_id: TEST_USER_A_ID,
        meaning_id: meaningId,
        field_name: 'definition',
        rating: 'invalid', // Should fail CHECK constraint
      });

    assertExists(error, 'Should fail with CHECK constraint violation');
    assert(
      error.message.includes('check constraint') ||
        error.message.includes('violates check') ||
        error.code === '23514',
      `Expected CHECK constraint error, got: ${error.message}`,
    );

    await cleanupAllTestData();
  },
});

// =============================================================================
// Test 3: RLS - user can read own feedback
// =============================================================================

Deno.test({
  name: 'integration: RLS allows user to read own feedback',
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    if (!(await isSupabaseRunning())) {
      console.log('  ⏭ Skipping: local Supabase not running');
      return;
    }

    await ensureTestUsers();
    await cleanupAllTestData();

    const { meaningId } = await createTestVocabAndMeaning(TEST_USER_A_ID);

    // Insert feedback via service role
    const serviceRoleClient = serviceClient();
    const { data: feedback } = await serviceRoleClient
      .from('enrichment_feedback')
      .insert({
        user_id: TEST_USER_A_ID,
        meaning_id: meaningId,
        field_name: 'synonym',
        rating: 'down',
        flag_category: 'wrong_translation',
        comment: 'Not accurate',
      })
      .select('id')
      .single();

    assertExists(feedback);

    // Sign in as user A
    const userClient = anonClient();
    const { error: signInError } = await userClient.auth.signInWithPassword({
      email: TEST_USER_A_EMAIL,
      password: TEST_USER_A_PASSWORD,
    });
    assertEquals(signInError, null, 'User A should sign in successfully');

    // Read feedback as user A
    const { data: readFeedback, error: readError } = await userClient
      .from('enrichment_feedback')
      .select('*')
      .eq('id', feedback.id)
      .single();

    assertEquals(readError, null, 'User A should read own feedback');
    assertExists(readFeedback);
    assertEquals(readFeedback.user_id, TEST_USER_A_ID);
    assertEquals(readFeedback.rating, 'down');
    assertEquals(readFeedback.flag_category, 'wrong_translation');
    assertEquals(readFeedback.comment, 'Not accurate');

    await cleanupAllTestData();
  },
});

// =============================================================================
// Test 4: RLS - user cannot read other user's feedback
// =============================================================================

Deno.test({
  name: 'integration: RLS prevents user from reading other user feedback',
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    if (!(await isSupabaseRunning())) {
      console.log('  ⏭ Skipping: local Supabase not running');
      return;
    }

    await ensureTestUsers();
    await cleanupAllTestData();

    // Create feedback for user A
    const { meaningId } = await createTestVocabAndMeaning(TEST_USER_A_ID);
    const serviceRoleClient = serviceClient();
    const { data: feedback } = await serviceRoleClient
      .from('enrichment_feedback')
      .insert({
        user_id: TEST_USER_A_ID,
        meaning_id: meaningId,
        field_name: 'definition',
        rating: 'up',
      })
      .select('id')
      .single();

    assertExists(feedback);

    // Sign in as user B
    const userBClient = anonClient();
    const { error: signInError } = await userBClient.auth.signInWithPassword({
      email: TEST_USER_B_EMAIL,
      password: TEST_USER_B_PASSWORD,
    });
    assertEquals(signInError, null, 'User B should sign in successfully');

    // Try to read user A's feedback as user B
    const { data: readFeedback, error: readError } = await userBClient
      .from('enrichment_feedback')
      .select('*')
      .eq('id', feedback.id)
      .single();

    // Should get no results (RLS filters it out) or PGRST116 (no rows returned)
    assert(
      readError !== null || readFeedback === null,
      'User B should not see user A feedback',
    );

    // Try to read all feedback as user B (should return empty)
    const { data: allFeedback } = await userBClient
      .from('enrichment_feedback')
      .select('*');

    assertEquals(
      allFeedback?.length ?? 0,
      0,
      'User B should not see any feedback',
    );

    await cleanupAllTestData();
  },
});

// =============================================================================
// Test 5: Flag category storage
// =============================================================================

Deno.test({
  name: 'integration: flag_category is stored correctly',
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    if (!(await isSupabaseRunning())) {
      console.log('  ⏭ Skipping: local Supabase not running');
      return;
    }

    await ensureTestUsers();
    await cleanupAllTestData();

    const { meaningId } = await createTestVocabAndMeaning(TEST_USER_A_ID);

    const client = serviceClient();
    const { data: feedback, error } = await client
      .from('enrichment_feedback')
      .insert({
        user_id: TEST_USER_A_ID,
        meaning_id: meaningId,
        field_name: 'translation',
        rating: 'down',
        flag_category: 'wrong_translation',
      })
      .select('id, flag_category')
      .single();

    assertEquals(error, null);
    assertExists(feedback);
    assertEquals(feedback.flag_category, 'wrong_translation');

    await cleanupAllTestData();
  },
});

// =============================================================================
// Test 6: CASCADE delete behavior
// =============================================================================

Deno.test({
  name: 'integration: CASCADE delete removes feedback when meaning is deleted',
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    if (!(await isSupabaseRunning())) {
      console.log('  ⏭ Skipping: local Supabase not running');
      return;
    }

    await ensureTestUsers();
    await cleanupAllTestData();

    const { meaningId } = await createTestVocabAndMeaning(TEST_USER_A_ID);

    const client = serviceClient();

    // Insert feedback
    const { data: feedback, error: insertError } = await client
      .from('enrichment_feedback')
      .insert({
        user_id: TEST_USER_A_ID,
        meaning_id: meaningId,
        field_name: 'definition',
        rating: 'up',
      })
      .select('id')
      .single();

    assertEquals(insertError, null);
    assertExists(feedback);

    // Verify feedback exists
    const { data: beforeDelete } = await client
      .from('enrichment_feedback')
      .select('id')
      .eq('id', feedback.id);

    assertEquals(beforeDelete?.length, 1, 'Feedback should exist before delete');

    // Delete the meaning (should cascade to feedback)
    const { error: deleteError } = await client
      .from('meanings')
      .delete()
      .eq('id', meaningId);

    assertEquals(deleteError, null, 'Should delete meaning without error');

    // Verify feedback was cascade deleted
    const { data: afterDelete } = await client
      .from('enrichment_feedback')
      .select('id')
      .eq('id', feedback.id);

    assertEquals(
      afterDelete?.length ?? 0,
      0,
      'Feedback should be cascade deleted',
    );

    await cleanupAllTestData();
  },
});
