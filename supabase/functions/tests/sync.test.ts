// Integration tests for the sync edge function.
//
// Tests:
//   1. Push insert
//   2. Push update
//   3. Push version conflict → 409
//   4. Push soft delete
//   5. Pull full sync
//   6. Pull incremental
//   7. Pull RLS — User A only gets own data
//
// Run:
//   deno test --allow-all supabase/functions/tests/sync-test.ts

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
} from "./helpers.ts";

const TEST_USER_A_EMAIL = "test-sync-a@example.com";
const TEST_USER_A_PASSWORD = "test-password-123456";
const TEST_USER_B_EMAIL = "test-sync-b@example.com";
const TEST_USER_B_PASSWORD = "test-password-123456";
const FN_NAME = "sync";

let USER_A_ID = "";
let USER_B_ID = "";

// =============================================================================
// Tests
// =============================================================================

Deno.test({
  name: "sync: push insert",
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
    const sourceId = crypto.randomUUID();
    const now = new Date().toISOString();

    const { status, data } = await invokeFunction(FN_NAME, {
      path: "push",
      body: {
        changes: [
          {
            table: "sources",
            operation: "insert",
            id: sourceId,
            data: {
              type: "website",
              title: "Test Source",
              url: "https://example.com",
              domain: "example.com",
              created_at: now,
              updated_at: now,
            },
          },
        ],
      },
      authToken: accessToken,
    });

    assertEquals(
      status,
      200,
      `Expected 200, got ${status}: ${JSON.stringify(data)}`,
    );
    assertEquals(data.applied, 1);
    assertExists(data.syncedAt);

    // Verify in DB
    const client = serviceClient();
    const { data: source } = await client
      .from("sources")
      .select("id, title")
      .eq("id", sourceId)
      .eq("user_id", USER_A_ID)
      .single();

    assertExists(source);
    assertEquals(source.title, "Test Source");

    await cleanupTestData(USER_A_ID);
  },
});

Deno.test({
  name: "sync: push update",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    if (!(await isSupabaseRunning()) || !(await isFunctionServed(FN_NAME))) {
      console.log("  ⏭ Skipping: local Supabase or functions not running");
      return;
    }

    USER_A_ID = await ensureTestUser(TEST_USER_A_EMAIL, TEST_USER_A_PASSWORD);
    await cleanupTestData(USER_A_ID);

    // Insert a source first
    const client = serviceClient();
    const sourceId = crypto.randomUUID();
    const now = new Date().toISOString();
    await client.from("sources").insert({
      id: sourceId,
      user_id: USER_A_ID,
      type: "website",
      title: "Original Title",
      url: "https://example.com",
      domain: "example.com",
      version: 1,
      created_at: now,
      updated_at: now,
    });

    const { accessToken } = await signInAsUser(
      TEST_USER_A_EMAIL,
      TEST_USER_A_PASSWORD,
    );

    const { status, data } = await invokeFunction(FN_NAME, {
      path: "push",
      body: {
        changes: [
          {
            table: "sources",
            operation: "update",
            id: sourceId,
            version: 1,
            data: {
              title: "Updated Title",
              updated_at: new Date().toISOString(),
            },
          },
        ],
      },
      authToken: accessToken,
    });

    assertEquals(status, 200);
    assertEquals(data.applied, 1);

    // Verify update
    const { data: source } = await client
      .from("sources")
      .select("title, version")
      .eq("id", sourceId)
      .single();

    assertEquals(source?.title, "Updated Title");
    assertEquals(source?.version, 2);

    await cleanupTestData(USER_A_ID);
  },
});

Deno.test({
  name: "sync: push version conflict → 409",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    if (!(await isSupabaseRunning()) || !(await isFunctionServed(FN_NAME))) {
      console.log("  ⏭ Skipping: local Supabase or functions not running");
      return;
    }

    USER_A_ID = await ensureTestUser(TEST_USER_A_EMAIL, TEST_USER_A_PASSWORD);
    await cleanupTestData(USER_A_ID);

    // Insert a source with version 5 (server ahead)
    const client = serviceClient();
    const sourceId = crypto.randomUUID();
    const now = new Date().toISOString();
    await client.from("sources").insert({
      id: sourceId,
      user_id: USER_A_ID,
      type: "website",
      title: "Server Version",
      url: "https://example.com",
      domain: "example.com",
      version: 5,
      created_at: now,
      updated_at: now,
    });

    const { accessToken } = await signInAsUser(
      TEST_USER_A_EMAIL,
      TEST_USER_A_PASSWORD,
    );

    // Try to update with version 3 (client behind)
    const { status, data } = await invokeFunction(FN_NAME, {
      path: "push",
      body: {
        changes: [
          {
            table: "sources",
            operation: "update",
            id: sourceId,
            version: 3,
            data: {
              title: "Client Version",
              updated_at: new Date().toISOString(),
            },
          },
        ],
      },
      authToken: accessToken,
    });

    assertEquals(status, 409, "Should return 409 for version conflict");
    assertEquals(data.conflicts.length, 1);
    assertEquals(data.conflicts[0].serverVersion, 5);

    await cleanupTestData(USER_A_ID);
  },
});

Deno.test({
  name: "sync: push soft delete",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    if (!(await isSupabaseRunning()) || !(await isFunctionServed(FN_NAME))) {
      console.log("  ⏭ Skipping: local Supabase or functions not running");
      return;
    }

    USER_A_ID = await ensureTestUser(TEST_USER_A_EMAIL, TEST_USER_A_PASSWORD);
    await cleanupTestData(USER_A_ID);

    // Insert a source
    const client = serviceClient();
    const sourceId = crypto.randomUUID();
    const now = new Date().toISOString();
    await client.from("sources").insert({
      id: sourceId,
      user_id: USER_A_ID,
      type: "website",
      title: "To Delete",
      url: "https://delete.example.com",
      domain: "delete.example.com",
      created_at: now,
      updated_at: now,
    });

    const { accessToken } = await signInAsUser(
      TEST_USER_A_EMAIL,
      TEST_USER_A_PASSWORD,
    );

    const { status, data } = await invokeFunction(FN_NAME, {
      path: "push",
      body: {
        changes: [
          {
            table: "sources",
            operation: "delete",
            id: sourceId,
          },
        ],
      },
      authToken: accessToken,
    });

    assertEquals(status, 200);
    assertEquals(data.applied, 1);

    // Verify soft delete (deleted_at is set, row still exists)
    const { data: source } = await client
      .from("sources")
      .select("id, deleted_at")
      .eq("id", sourceId)
      .single();

    assertExists(source);
    assertExists(source.deleted_at, "Should have deleted_at set");

    await cleanupTestData(USER_A_ID);
  },
});

Deno.test({
  name: "sync: pull full sync",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    if (!(await isSupabaseRunning()) || !(await isFunctionServed(FN_NAME))) {
      console.log("  ⏭ Skipping: local Supabase or functions not running");
      return;
    }

    USER_A_ID = await ensureTestUser(TEST_USER_A_EMAIL, TEST_USER_A_PASSWORD);
    await cleanupTestData(USER_A_ID);

    // Create some data
    const client = serviceClient();
    const now = new Date().toISOString();
    await client.from("sources").insert({
      id: crypto.randomUUID(),
      user_id: USER_A_ID,
      type: "website",
      title: "Pull Test",
      url: "https://pull.example.com",
      domain: "pull.example.com",
      created_at: now,
      updated_at: now,
    });

    const { accessToken } = await signInAsUser(
      TEST_USER_A_EMAIL,
      TEST_USER_A_PASSWORD,
    );

    const { status, data } = await invokeFunction(FN_NAME, {
      path: "pull",
      body: { lastSyncedAt: null },
      authToken: accessToken,
    });

    assertEquals(status, 200);
    assertExists(data.syncedAt);
    assert(data.sources.length >= 1, "Should have at least 1 source");
    assertExists(data.vocabulary);
    assertExists(data.learning_cards);
    assertExists(data.encounters);

    await cleanupTestData(USER_A_ID);
  },
});

Deno.test({
  name: "sync: pull incremental",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    if (!(await isSupabaseRunning()) || !(await isFunctionServed(FN_NAME))) {
      console.log("  ⏭ Skipping: local Supabase or functions not running");
      return;
    }

    USER_A_ID = await ensureTestUser(TEST_USER_A_EMAIL, TEST_USER_A_PASSWORD);
    await cleanupTestData(USER_A_ID);

    const client = serviceClient();
    const oldTime = new Date(Date.now() - 60000).toISOString();
    const cutoff = new Date(Date.now() - 30000).toISOString();
    const newTime = new Date().toISOString();

    // Create old source (before cutoff)
    await client.from("sources").insert({
      id: crypto.randomUUID(),
      user_id: USER_A_ID,
      type: "website",
      title: "Old Source",
      url: "https://old.example.com",
      domain: "old.example.com",
      created_at: oldTime,
      updated_at: oldTime,
    });

    // Create new source (after cutoff)
    await client.from("sources").insert({
      id: crypto.randomUUID(),
      user_id: USER_A_ID,
      type: "website",
      title: "New Source",
      url: "https://new.example.com",
      domain: "new.example.com",
      created_at: newTime,
      updated_at: newTime,
    });

    const { accessToken } = await signInAsUser(
      TEST_USER_A_EMAIL,
      TEST_USER_A_PASSWORD,
    );

    const { status, data } = await invokeFunction(FN_NAME, {
      path: "pull",
      body: { lastSyncedAt: cutoff },
      authToken: accessToken,
    });

    assertEquals(status, 200);
    assertEquals(
      data.sources.length,
      1,
      "Should only return source after cutoff",
    );
    assertEquals(data.sources[0].title, "New Source");

    await cleanupTestData(USER_A_ID);
  },
});

Deno.test({
  name: "sync: pull RLS — user A only gets own data",
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

    // Create data for User A
    const client = serviceClient();
    const now = new Date().toISOString();
    await client.from("sources").insert({
      id: crypto.randomUUID(),
      user_id: USER_A_ID,
      type: "website",
      title: "User A Source",
      url: "https://a.example.com",
      domain: "a.example.com",
      created_at: now,
      updated_at: now,
    });

    // Create data for User B
    await client.from("sources").insert({
      id: crypto.randomUUID(),
      user_id: USER_B_ID,
      type: "website",
      title: "User B Source",
      url: "https://b.example.com",
      domain: "b.example.com",
      created_at: now,
      updated_at: now,
    });

    // Pull as User A
    const { accessToken } = await signInAsUser(
      TEST_USER_A_EMAIL,
      TEST_USER_A_PASSWORD,
    );
    const { status, data } = await invokeFunction(FN_NAME, {
      path: "pull",
      body: { lastSyncedAt: null },
      authToken: accessToken,
    });

    assertEquals(status, 200);
    // deno-lint-ignore no-explicit-any
    const sourceTitles = data.sources.map((s: any) => s.title);
    assert(
      sourceTitles.includes("User A Source"),
      "Should include User A data",
    );
    assert(
      !sourceTitles.includes("User B Source"),
      "Should NOT include User B data",
    );

    await cleanupTestData(USER_A_ID);
    await cleanupTestData(USER_B_ID);
  },
});
