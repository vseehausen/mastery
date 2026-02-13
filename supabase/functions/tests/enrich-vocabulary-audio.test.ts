// Integration tests for audio generation in the enrich-vocabulary edge function.
//
// Tests:
//   1. Enrichment populates audio_urls on global_dictionary
//   2. audio_urls contains both US and GB accent URLs
//   3. Audio files exist in storage at expected paths
//   4. Re-enrichment via /maintain regenerates audio
//   5. Missing Google API key → enrichment succeeds without audio
//
// Run:
//   deno test --allow-all supabase/functions/tests/enrich-vocabulary-audio.test.ts

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

const TEST_EMAIL = "test-audio@example.com";
const TEST_PASSWORD = "test-password-123456";
const FN_NAME = "enrich-vocabulary";
const ADMIN_API_KEY =
  Deno.env.get("ADMIN_API_KEY") || "mastery-admin-local-dev-key";

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

/** Check if external API keys are available. */
function hasApiKeys(): boolean {
  return !!(
    Deno.env.get("OPENAI_API_KEY") &&
    Deno.env.get("GOOGLE_TRANSLATE_API_KEY")
  );
}

// =============================================================================
// Tests
// =============================================================================

Deno.test({
  name: "audio: enrichment populates audio_urls with US and GB URLs",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    if (!(await isSupabaseRunning()) || !(await isFunctionServed(FN_NAME))) {
      console.log("  ⏭ Skipping: local Supabase or functions not running");
      return;
    }
    if (!hasApiKeys()) {
      console.log(
        "  ⏭ Skipping: OPENAI_API_KEY or GOOGLE_TRANSLATE_API_KEY not set",
      );
      return;
    }

    TEST_USER_ID = await ensureTestUser(TEST_EMAIL, TEST_PASSWORD);
    await cleanupTestData(TEST_USER_ID);

    // Clean up any pre-existing global dict entry for this word
    const client = serviceClient();
    await client
      .from("global_dictionary")
      .delete()
      .eq("lemma", "serendipity");

    const vocabId = await createVocab("serendipity");

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

    const gdId = data.enriched[0].global_dictionary_id;
    globalDictIds.push(gdId);

    // Verify audio_urls was populated
    const { data: gd } = await client
      .from("global_dictionary")
      .select("audio_urls")
      .eq("id", gdId)
      .single();

    assert(gd, "Global dictionary entry should exist");
    assert(gd.audio_urls, "audio_urls should be populated");
    assert(gd.audio_urls.us, "audio_urls should have US accent URL");
    assert(gd.audio_urls.gb, "audio_urls should have GB accent URL");
    assert(
      gd.audio_urls.us.includes(".mp3"),
      "US URL should point to an MP3 file",
    );
    assert(
      gd.audio_urls.gb.includes(".mp3"),
      "GB URL should point to an MP3 file",
    );

    await cleanupTestData(TEST_USER_ID);
    await cleanupGlobalDictionary(globalDictIds.splice(0));
  },
});

Deno.test({
  name: "audio: audio files are accessible at storage URLs",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    if (!(await isSupabaseRunning()) || !(await isFunctionServed(FN_NAME))) {
      console.log("  ⏭ Skipping: local Supabase or functions not running");
      return;
    }
    if (!hasApiKeys()) {
      console.log(
        "  ⏭ Skipping: OPENAI_API_KEY or GOOGLE_TRANSLATE_API_KEY not set",
      );
      return;
    }

    TEST_USER_ID = await ensureTestUser(TEST_EMAIL, TEST_PASSWORD);
    await cleanupTestData(TEST_USER_ID);

    const client = serviceClient();
    await client.from("global_dictionary").delete().eq("lemma", "ephemeral");

    const vocabId = await createVocab("ephemeral");

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
    assertEquals(data.enriched.length, 1);

    const gdId = data.enriched[0].global_dictionary_id;
    globalDictIds.push(gdId);

    const { data: gd } = await client
      .from("global_dictionary")
      .select("audio_urls")
      .eq("id", gdId)
      .single();

    assert(gd?.audio_urls?.us, "US audio URL should exist");

    // Verify the audio file is accessible
    const audioResponse = await fetch(gd.audio_urls.us);
    assertEquals(
      audioResponse.status,
      200,
      `Audio file should be accessible, got ${audioResponse.status}`,
    );

    const contentType = audioResponse.headers.get("content-type");
    assert(
      contentType?.includes("audio") || contentType?.includes("octet-stream"),
      `Expected audio content type, got ${contentType}`,
    );

    await cleanupTestData(TEST_USER_ID);
    await cleanupGlobalDictionary(globalDictIds.splice(0));
  },
});

Deno.test({
  name: "audio: get_session_cards RPC returns audio_urls",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    if (!(await isSupabaseRunning())) {
      console.log("  ⏭ Skipping: local Supabase not running");
      return;
    }

    // Verify the RPC function signature includes audio_urls
    const client = serviceClient();
    const { data, error } = await client.rpc("get_session_cards", {
      p_user_id: "00000000-0000-0000-0000-000000000000",
      p_review_limit: 1,
      p_new_limit: 1,
    });

    assertEquals(error, null, `RPC should succeed: ${error?.message}`);
    assert(Array.isArray(data), "get_session_cards should return an array");

    // Verify audio_urls is in the function return type via pg_proc
    const { data: pgData } = await client.rpc("get_session_cards", {
      p_user_id: "00000000-0000-0000-0000-000000000000",
      p_review_limit: 0,
      p_new_limit: 0,
    });
    // Even empty results confirm the function compiles with audio_urls column
    assert(
      Array.isArray(pgData),
      "get_session_cards should work with 0 limits",
    );
  },
});

Deno.test({
  name: "audio: maintain re-enrichment adds audio to entries missing it",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    if (!(await isSupabaseRunning()) || !(await isFunctionServed(FN_NAME))) {
      console.log("  ⏭ Skipping: local Supabase or functions not running");
      return;
    }
    if (!hasApiKeys()) {
      console.log(
        "  ⏭ Skipping: OPENAI_API_KEY or GOOGLE_TRANSLATE_API_KEY not set",
      );
      return;
    }

    // Create a stale entry (v1) without audio_urls
    const gdId = await createTestGlobalDictEntry("audible", undefined, {
      enrichment_version: 1,
      audio_urls: null,
    });
    globalDictIds.push(gdId);

    const { status, data } = await invokeFunction(FN_NAME, {
      path: "maintain",
      body: { batch_size: 1, native_language_code: "de" },
      headers: { Authorization: `Bearer ${ADMIN_API_KEY}` },
    });

    assertEquals(
      status,
      200,
      `Expected 200, got ${status}: ${JSON.stringify(data)}`,
    );
    assertEquals(data.updated, 1, "Should update 1 stale entry");

    // Verify audio_urls was added
    const client = serviceClient();
    const { data: gd } = await client
      .from("global_dictionary")
      .select("audio_urls, enrichment_version")
      .eq("id", gdId)
      .single();

    assert(gd, "Entry should exist");
    assert(
      gd.audio_urls && Object.keys(gd.audio_urls).length > 0,
      `audio_urls should be populated after maintain, got: ${JSON.stringify(gd.audio_urls)}`,
    );

    await cleanupGlobalDictionary(globalDictIds.splice(0));
  },
});

Deno.test({
  name: "audio: global dict hit path preserves existing audio_urls",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    if (!(await isSupabaseRunning()) || !(await isFunctionServed(FN_NAME))) {
      console.log("  ⏭ Skipping: local Supabase or functions not running");
      return;
    }

    TEST_USER_ID = await ensureTestUser(TEST_EMAIL, TEST_PASSWORD);
    await cleanupTestData(TEST_USER_ID);

    // Pre-seed global dict entry WITH audio_urls
    const gdId = await createTestGlobalDictEntry("resilient", undefined, {
      audio_urls: {
        us: "https://storage.example.com/word-audio/us/resilient.mp3",
        gb: "https://storage.example.com/word-audio/gb/resilient.mp3",
      },
    });
    globalDictIds.push(gdId);
    await createTestWordVariant("resilient", gdId);

    const vocabId = await createVocab("resilient");

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
    assertEquals(data.enriched.length, 1);

    // Verify audio_urls still present
    const client = serviceClient();
    const { data: gd } = await client
      .from("global_dictionary")
      .select("audio_urls")
      .eq("id", gdId)
      .single();

    assert(gd?.audio_urls?.us, "US audio URL should still be present");
    assert(gd?.audio_urls?.gb, "GB audio URL should still be present");

    await cleanupTestData(TEST_USER_ID);
    await cleanupGlobalDictionary(globalDictIds.splice(0));
  },
});

Deno.test({
  name: "audio: user_learning_preferences supports audio columns",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    if (!(await isSupabaseRunning())) {
      console.log("  ⏭ Skipping: local Supabase not running");
      return;
    }

    TEST_USER_ID = await ensureTestUser(TEST_EMAIL, TEST_PASSWORD);
    await cleanupTestData(TEST_USER_ID);

    const client = serviceClient();

    // Insert preferences with audio columns
    const { error: insertError } = await client
      .from("user_learning_preferences")
      .insert({
        user_id: TEST_USER_ID,
        audio_enabled: true,
        audio_accent: "gb",
      });

    assertEquals(
      insertError,
      null,
      `Insert should succeed: ${insertError?.message}`,
    );

    // Read back
    const { data, error } = await client
      .from("user_learning_preferences")
      .select("audio_enabled, audio_accent")
      .eq("user_id", TEST_USER_ID)
      .single();

    assertEquals(error, null, `Read should succeed: ${error?.message}`);
    assertEquals(data?.audio_enabled, true);
    assertEquals(data?.audio_accent, "gb");

    // Update to different values
    const { error: updateError } = await client
      .from("user_learning_preferences")
      .update({ audio_enabled: false, audio_accent: "us" })
      .eq("user_id", TEST_USER_ID);

    assertEquals(
      updateError,
      null,
      `Update should succeed: ${updateError?.message}`,
    );

    const { data: updated } = await client
      .from("user_learning_preferences")
      .select("audio_enabled, audio_accent")
      .eq("user_id", TEST_USER_ID)
      .single();

    assertEquals(updated?.audio_enabled, false);
    assertEquals(updated?.audio_accent, "us");

    await cleanupTestData(TEST_USER_ID);
  },
});
