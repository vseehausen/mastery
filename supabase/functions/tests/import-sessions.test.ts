// Integration tests for the import-sessions edge function.
//
// Tests:
//   1. Create session → returns id + timestamps
//   2. List empty → returns [], count=0
//   3. List paginated → limit=2 of 3 → returns 2
//   4. RLS isolation → User B can't see User A's sessions
//
// Run:
//   deno test --allow-all supabase/functions/tests/import-sessions-test.ts

import {
  assertEquals,
  assertExists,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  ensureTestUser,
  cleanupTestData,
  isSupabaseRunning,
  isFunctionServed,
  invokeFunction,
  signInAsUser,
} from "./helpers.ts";

const TEST_USER_A_EMAIL = "test-import-a@example.com";
const TEST_USER_A_PASSWORD = "test-password-123456";
const TEST_USER_B_EMAIL = "test-import-b@example.com";
const TEST_USER_B_PASSWORD = "test-password-123456";
const FN_NAME = "import-sessions";

let USER_A_ID = "";
let USER_B_ID = "";

// =============================================================================
// Tests
// =============================================================================

Deno.test({
  name: "import-sessions: create session",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    if (!(await isSupabaseRunning()) || !(await isFunctionServed(FN_NAME))) {
      console.log("  ⏭ Skipping: local Supabase or functions not running");
      return;
    }

    USER_A_ID = await ensureTestUser(TEST_USER_A_EMAIL, TEST_USER_A_PASSWORD);
    await cleanupTestData(USER_A_ID);

    const { accessToken } = await signInAsUser(
      TEST_USER_A_EMAIL,
      TEST_USER_A_PASSWORD,
    );
    const now = new Date().toISOString();

    const { status, data } = await invokeFunction(FN_NAME, {
      body: {
        source: "vocab_db",
        filename: "vocab.db",
        deviceName: "Test Kindle",
        totalFound: 100,
        imported: 80,
        skipped: 20,
        errors: 0,
        startedAt: now,
        completedAt: now,
      },
      authToken: accessToken,
    });

    assertEquals(
      status,
      201,
      `Expected 201, got ${status}: ${JSON.stringify(data)}`,
    );
    assertExists(data.id);
    assertEquals(data.source, "vocab_db");
    assertEquals(data.imported, 80);
    assertEquals(data.skipped, 20);
    assertExists(data.started_at);
    assertExists(data.completed_at);

    await cleanupTestData(USER_A_ID);
  },
});

Deno.test({
  name: "import-sessions: list empty",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    if (!(await isSupabaseRunning()) || !(await isFunctionServed(FN_NAME))) {
      console.log("  ⏭ Skipping: local Supabase or functions not running");
      return;
    }

    USER_A_ID = await ensureTestUser(TEST_USER_A_EMAIL, TEST_USER_A_PASSWORD);
    await cleanupTestData(USER_A_ID);

    const { accessToken } = await signInAsUser(
      TEST_USER_A_EMAIL,
      TEST_USER_A_PASSWORD,
    );

    const { status, data } = await invokeFunction(FN_NAME, {
      method: "GET",
      authToken: accessToken,
    });

    assertEquals(status, 200);
    assertEquals(data.data.length, 0);
    assertEquals(data.total, 0);

    await cleanupTestData(USER_A_ID);
  },
});

Deno.test({
  name: "import-sessions: list paginated",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    if (!(await isSupabaseRunning()) || !(await isFunctionServed(FN_NAME))) {
      console.log("  ⏭ Skipping: local Supabase or functions not running");
      return;
    }

    USER_A_ID = await ensureTestUser(TEST_USER_A_EMAIL, TEST_USER_A_PASSWORD);
    await cleanupTestData(USER_A_ID);

    const { accessToken } = await signInAsUser(
      TEST_USER_A_EMAIL,
      TEST_USER_A_PASSWORD,
    );
    const now = new Date().toISOString();

    // Create 3 sessions
    for (let i = 0; i < 3; i++) {
      await invokeFunction(FN_NAME, {
        body: {
          source: "vocab_db",
          filename: `vocab-${i}.db`,
          deviceName: "Test",
          totalFound: 10,
          imported: 10,
          skipped: 0,
          startedAt: now,
          completedAt: now,
        },
        authToken: accessToken,
      });
    }

    // List with limit=2
    const { status, data } = await invokeFunction(FN_NAME, {
      path: "?limit=2&offset=0",
      method: "GET",
      authToken: accessToken,
    });

    assertEquals(status, 200);
    assertEquals(data.data.length, 2);
    assertEquals(data.total, 3);
    assertEquals(data.limit, 2);

    await cleanupTestData(USER_A_ID);
  },
});

Deno.test({
  name: "import-sessions: RLS isolation",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    if (!(await isSupabaseRunning()) || !(await isFunctionServed(FN_NAME))) {
      console.log("  ⏭ Skipping: local Supabase or functions not running");
      return;
    }

    USER_A_ID = await ensureTestUser(TEST_USER_A_EMAIL, TEST_USER_A_PASSWORD);
    USER_B_ID = await ensureTestUser(TEST_USER_B_EMAIL, TEST_USER_B_PASSWORD);
    await cleanupTestData(USER_A_ID);
    await cleanupTestData(USER_B_ID);

    // User A creates a session
    const { accessToken: tokenA } = await signInAsUser(
      TEST_USER_A_EMAIL,
      TEST_USER_A_PASSWORD,
    );
    const now = new Date().toISOString();
    await invokeFunction(FN_NAME, {
      body: {
        source: "kindle",
        filename: "private.db",
        deviceName: "Test",
        totalFound: 50,
        imported: 50,
        skipped: 0,
        startedAt: now,
        completedAt: now,
      },
      authToken: tokenA,
    });

    // User B lists sessions — should see nothing
    const { accessToken: tokenB } = await signInAsUser(
      TEST_USER_B_EMAIL,
      TEST_USER_B_PASSWORD,
    );
    const { status, data } = await invokeFunction(FN_NAME, {
      method: "GET",
      authToken: tokenB,
    });

    assertEquals(status, 200);
    assertEquals(
      data.data.length,
      0,
      "User B should not see User A's sessions",
    );

    await cleanupTestData(USER_A_ID);
    await cleanupTestData(USER_B_ID);
  },
});
