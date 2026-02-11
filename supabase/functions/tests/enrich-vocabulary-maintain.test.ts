// Integration tests for the /maintain endpoint of enrich-vocabulary.
//
// Tests:
//   1. Unauthorized without admin key → 401
//   2. Empty batch → returns 0 updated
//   3. Stale entries (v1) are updated to current version
//   4. Fresh entries (v2) are not touched
//   5. NULL version entries are updated
//
// Run:
//   deno test --allow-all supabase/functions/tests/enrich-vocabulary-maintain.test.ts

import {
  assertEquals,
  assert,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  serviceClient,
  isSupabaseRunning,
  isFunctionServed,
  invokeFunction,
  createTestGlobalDictEntry,
  cleanupGlobalDictionary,
} from "./helpers.ts";

const FN_NAME = "enrich-vocabulary";
const ADMIN_API_KEY = Deno.env.get("ADMIN_API_KEY") || "mastery-admin-local-dev-key";

const globalDictIds: string[] = [];

// =============================================================================
// Tests
// =============================================================================

Deno.test({
  name: "maintain: unauthorized without admin key → 401",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    if (!(await isSupabaseRunning()) || !(await isFunctionServed(FN_NAME))) {
      console.log("  ⏭ Skipping: local Supabase or functions not running");
      return;
    }

    // No auth header
    const { status: status1 } = await invokeFunction(FN_NAME, {
      path: "maintain",
      body: { batch_size: 1 },
    });
    assertEquals(status1, 401, "Should reject with no auth");

    // Wrong key
    const { status: status2 } = await invokeFunction(FN_NAME, {
      path: "maintain",
      body: { batch_size: 1 },
      headers: { Authorization: "Bearer wrong-key" },
    });
    assertEquals(status2, 401, "Should reject with wrong key");
  },
});

Deno.test({
  name: "maintain: empty batch → returns 0 updated",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    if (!(await isSupabaseRunning()) || !(await isFunctionServed(FN_NAME))) {
      console.log("  ⏭ Skipping: local Supabase or functions not running");
      return;
    }

    // Skip if API keys are not configured (maintenance needs translation + AI)
    const deeplKey = Deno.env.get("DEEPL_API_KEY");
    const openaiKey = Deno.env.get("OPENAI_API_KEY");
    if (!deeplKey || !openaiKey) {
      console.log("  ⏭ Skipping: DEEPL_API_KEY or OPENAI_API_KEY not set");
      return;
    }

    const { status, data } = await invokeFunction(FN_NAME, {
      path: "maintain",
      body: { batch_size: 1 },
      headers: { Authorization: `Bearer ${ADMIN_API_KEY}` },
    });

    assertEquals(status, 200);
    assertEquals(data.updated, 0);
    assertEquals(data.failed, 0);
    assertEquals(data.remaining, 0);
  },
});

Deno.test({
  name: "maintain: stale entries (v1) are updated to current version",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    if (!(await isSupabaseRunning()) || !(await isFunctionServed(FN_NAME))) {
      console.log("  ⏭ Skipping: local Supabase or functions not running");
      return;
    }

    // Skip if API keys are not configured
    const deeplKey = Deno.env.get("DEEPL_API_KEY");
    const openaiKey = Deno.env.get("OPENAI_API_KEY");
    if (!deeplKey || !openaiKey) {
      console.log("  ⏭ Skipping: DEEPL_API_KEY or OPENAI_API_KEY not set");
      return;
    }

    // Create a stale global_dictionary entry (v1)
    const gdId = await createTestGlobalDictEntry("stale", undefined, {
      enrichment_version: 1,
    });
    globalDictIds.push(gdId);

    // Call maintain
    const { status, data } = await invokeFunction(FN_NAME, {
      path: "maintain",
      body: { batch_size: 1, native_language_code: "de" },
      headers: { Authorization: `Bearer ${ADMIN_API_KEY}` },
    });

    assertEquals(status, 200);
    assertEquals(data.updated, 1, "Should update 1 stale entry");
    assertEquals(data.failed, 0, "Should have no failures");

    // Verify enrichment_version was updated to 2
    const client = serviceClient();
    const { data: gd } = await client
      .from("global_dictionary")
      .select("enrichment_version")
      .eq("id", gdId)
      .single();

    assertEquals(gd?.enrichment_version, 2, "Should be updated to v2");

    await cleanupGlobalDictionary(globalDictIds.splice(0));
  },
});

Deno.test({
  name: "maintain: fresh entries (v2) are not touched",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    if (!(await isSupabaseRunning()) || !(await isFunctionServed(FN_NAME))) {
      console.log("  ⏭ Skipping: local Supabase or functions not running");
      return;
    }

    // Skip if API keys are not configured
    const deeplKey = Deno.env.get("DEEPL_API_KEY");
    const openaiKey = Deno.env.get("OPENAI_API_KEY");
    if (!deeplKey || !openaiKey) {
      console.log("  ⏭ Skipping: DEEPL_API_KEY or OPENAI_API_KEY not set");
      return;
    }

    // Create a fresh entry (v2)
    const gdId = await createTestGlobalDictEntry("fresh", undefined, {
      enrichment_version: 2,
    });
    globalDictIds.push(gdId);

    const client = serviceClient();
    const { data: before } = await client
      .from("global_dictionary")
      .select("updated_at")
      .eq("id", gdId)
      .single();

    // Call maintain
    const { status, data } = await invokeFunction(FN_NAME, {
      path: "maintain",
      body: { batch_size: 1, native_language_code: "de" },
      headers: { Authorization: `Bearer ${ADMIN_API_KEY}` },
    });

    assertEquals(status, 200);
    assertEquals(data.updated, 0, "Should not update fresh entries");

    // Verify updated_at was NOT changed
    const { data: after } = await client
      .from("global_dictionary")
      .select("updated_at")
      .eq("id", gdId)
      .single();

    assertEquals(after?.updated_at, before?.updated_at, "Should not touch fresh entries");

    await cleanupGlobalDictionary(globalDictIds.splice(0));
  },
});

Deno.test({
  name: "maintain: NULL version entries are updated",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    if (!(await isSupabaseRunning()) || !(await isFunctionServed(FN_NAME))) {
      console.log("  ⏭ Skipping: local Supabase or functions not running");
      return;
    }

    // Skip if API keys are not configured
    const deeplKey = Deno.env.get("DEEPL_API_KEY");
    const openaiKey = Deno.env.get("OPENAI_API_KEY");
    if (!deeplKey || !openaiKey) {
      console.log("  ⏭ Skipping: DEEPL_API_KEY or OPENAI_API_KEY not set");
      return;
    }

    // Create an entry with NULL enrichment_version (legacy)
    const gdId = await createTestGlobalDictEntry("legacy", undefined, {
      enrichment_version: null,
    });
    globalDictIds.push(gdId);

    // Call maintain
    const { status, data } = await invokeFunction(FN_NAME, {
      path: "maintain",
      body: { batch_size: 1, native_language_code: "de" },
      headers: { Authorization: `Bearer ${ADMIN_API_KEY}` },
    });

    assertEquals(status, 200);
    assertEquals(data.updated, 1, "Should update NULL version entry");
    assertEquals(data.failed, 0, "Should have no failures");

    // Verify enrichment_version was set to 2
    const client = serviceClient();
    const { data: gd } = await client
      .from("global_dictionary")
      .select("enrichment_version")
      .eq("id", gdId)
      .single();

    assertEquals(gd?.enrichment_version, 2, "Should be updated to v2");

    await cleanupGlobalDictionary(globalDictIds.splice(0));
  },
});

Deno.test({
  name: "maintain: batch processing with mixed versions",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    if (!(await isSupabaseRunning()) || !(await isFunctionServed(FN_NAME))) {
      console.log("  ⏭ Skipping: local Supabase or functions not running");
      return;
    }

    // Skip if API keys are not configured
    const deeplKey = Deno.env.get("DEEPL_API_KEY");
    const openaiKey = Deno.env.get("OPENAI_API_KEY");
    if (!deeplKey || !openaiKey) {
      console.log("  ⏭ Skipping: DEEPL_API_KEY or OPENAI_API_KEY not set");
      return;
    }

    // Create mixed entries: 2 stale (v1), 1 fresh (v2), 1 NULL
    const stale1 = await createTestGlobalDictEntry("mixstale1", undefined, {
      enrichment_version: 1,
    });
    const stale2 = await createTestGlobalDictEntry("mixstale2", undefined, {
      enrichment_version: 1,
    });
    const fresh = await createTestGlobalDictEntry("mixfresh", undefined, {
      enrichment_version: 2,
    });
    const legacy = await createTestGlobalDictEntry("mixlegacy", undefined, {
      enrichment_version: null,
    });

    globalDictIds.push(stale1, stale2, fresh, legacy);

    // Call maintain with batch_size=5 (should update 3 out of 4)
    const { status, data } = await invokeFunction(FN_NAME, {
      path: "maintain",
      body: { batch_size: 5, native_language_code: "de" },
      headers: { Authorization: `Bearer ${ADMIN_API_KEY}` },
    });

    assertEquals(status, 200);
    assert(data.updated === 3, `Expected 3 updated, got ${data.updated}`);
    assertEquals(data.failed, 0, "Should have no failures");

    // Verify all stale entries are now v2
    const client = serviceClient();
    const { data: entries } = await client
      .from("global_dictionary")
      .select("id, enrichment_version")
      .in("id", [stale1, stale2, legacy]);

    for (const entry of entries || []) {
      assertEquals(entry.enrichment_version, 2, `Entry ${entry.id} should be v2`);
    }

    // Fresh entry should still be v2 and untouched
    const { data: freshEntry } = await client
      .from("global_dictionary")
      .select("enrichment_version")
      .eq("id", fresh)
      .single();

    assertEquals(freshEntry?.enrichment_version, 2);

    await cleanupGlobalDictionary(globalDictIds.splice(0));
  },
});
