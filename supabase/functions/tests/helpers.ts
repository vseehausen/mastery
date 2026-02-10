// Shared test utilities for Supabase edge function tests.
//
// Extracted from parse-vocab-test.ts and enrichment-feedback-test.ts
// to eliminate duplication and provide consistent test infrastructure.
//
// Usage:
//   import { serviceClient, ensureTestUser, ... } from "./helpers.ts";

import { createClient, SupabaseClient } from "jsr:@supabase/supabase-js@2";
import { load } from "jsr:@std/dotenv";

// Load test-specific .env
const testEnvPath = new URL("./.env", import.meta.url).pathname;
await load({ envPath: testEnvPath, export: true });

// ---------------------------------------------------------------------------
// Env
// ---------------------------------------------------------------------------

export const SUPABASE_URL =
  Deno.env.get("SUPABASE_URL") ?? "http://localhost:54321";
export const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
export const SUPABASE_SERVICE_ROLE_KEY =
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

export const DEV_SECRET = "test-dev-secret";

// ---------------------------------------------------------------------------
// Client factories
// ---------------------------------------------------------------------------

/** Service role client — bypasses RLS. Use for setup/teardown. */
export function serviceClient(): SupabaseClient {
  return createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
}

/** Anon client — respects RLS. Use for testing RLS policies. */
export function anonClient(): SupabaseClient {
  return createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
}

// ---------------------------------------------------------------------------
// User management
// ---------------------------------------------------------------------------

/** Create a test user if not already present. Returns userId. */
export async function ensureTestUser(
  email: string,
  password: string,
): Promise<string> {
  const client = serviceClient();

  const { data: existingUsers } = await client.auth.admin.listUsers();
  const existing = existingUsers?.users?.find((u) => u.email === email);

  if (existing) return existing.id;

  const { data, error } = await client.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
  });

  if (error) throw new Error(`Failed to create test user: ${error.message}`);

  // Ensure public.users row exists
  await client.from("users").upsert(
    { id: data.user.id, email },
    { onConflict: "id" },
  );

  return data.user.id;
}

// ---------------------------------------------------------------------------
// Data cleanup
// ---------------------------------------------------------------------------

const DEFAULT_CLEANUP_TABLES = [
  "enrichment_feedback",
  "encounters",
  "learning_cards",
  "import_sessions",
  "learning_sessions",
  "streaks",
  "user_learning_preferences",
  "vocabulary",
  "sources",
];

/** Clean up test data for a user. Respects FK ordering. */
export async function cleanupTestData(
  userId: string,
  tables: string[] = DEFAULT_CLEANUP_TABLES,
): Promise<void> {
  const client = serviceClient();
  for (const table of tables) {
    await client.from(table).delete().eq("user_id", userId);
  }
}

// ---------------------------------------------------------------------------
// Skip guards
// ---------------------------------------------------------------------------

/** Check if local Supabase is reachable. */
export async function isSupabaseRunning(): Promise<boolean> {
  try {
    const res = await fetch(`${SUPABASE_URL}/rest/v1/`, {
      headers: { apikey: SUPABASE_ANON_KEY },
    });
    return res.ok;
  } catch {
    return false;
  }
}

/** Check if a specific edge function is being served. */
export async function isFunctionServed(fnName: string): Promise<boolean> {
  try {
    const res = await fetch(`${SUPABASE_URL}/functions/v1/${fnName}`, {
      method: "OPTIONS",
    });
    return res.ok;
  } catch {
    return false;
  }
}

// ---------------------------------------------------------------------------
// Function invocation
// ---------------------------------------------------------------------------

/** Generic HTTP caller for edge functions. */
export async function invokeFunction(
  fnName: string,
  opts: {
    path?: string;
    method?: string;
    body?: unknown;
    authToken?: string;
    headers?: Record<string, string>;
  } = {},
  // deno-lint-ignore no-explicit-any
): Promise<{ status: number; data: any }> {
  const {
    path,
    method = "POST",
    body,
    authToken,
    headers: extraHeaders,
  } = opts;

  let url: string;
  if (path) {
    if (path.startsWith("?")) {
      url = `${SUPABASE_URL}/functions/v1/${fnName}${path}`;
    } else {
      url = `${SUPABASE_URL}/functions/v1/${fnName}/${path}`;
    }
  } else {
    url = `${SUPABASE_URL}/functions/v1/${fnName}`;
  }

  const headers: Record<string, string> = {
    "Content-Type": "application/json",
    ...extraHeaders,
  };

  if (authToken) {
    headers["Authorization"] = `Bearer ${authToken}`;
  }

  const response = await fetch(url, {
    method,
    headers,
    ...(body !== undefined ? { body: JSON.stringify(body) } : {}),
  });

  const data = await response.json();
  return { status: response.status, data };
}

/** Sign in as a user and return an authenticated client + access token. */
export async function signInAsUser(
  email: string,
  password: string,
): Promise<{ client: SupabaseClient; accessToken: string }> {
  const client = anonClient();
  const { data, error } = await client.auth.signInWithPassword({
    email,
    password,
  });

  if (error) throw new Error(`Failed to sign in: ${error.message}`);

  return { client, accessToken: data.session!.access_token };
}

// ---------------------------------------------------------------------------
// Test data factories
// ---------------------------------------------------------------------------

/** Create a test vocabulary entry. Returns vocabId. */
export async function createTestVocabulary(
  userId: string,
  word: string = "test",
  stem?: string,
): Promise<string> {
  const client = serviceClient();
  const normalized = word.trim().toLowerCase();
  const { data, error } = await client
    .from("vocabulary")
    .insert({
      user_id: userId,
      word: normalized,
      stem: stem ?? normalized,
    })
    .select("id")
    .single();

  if (error) throw new Error(`Failed to create vocabulary: ${error.message}`);
  return data.id;
}

/** Create test vocabulary with a learning card. Returns { vocabularyId, cardId }. */
export async function createTestVocabWithCard(
  userId: string,
  word: string = "test",
  cardOverrides: Record<string, unknown> = {},
): Promise<{ vocabularyId: string; cardId: string }> {
  const vocabularyId = await createTestVocabulary(userId, word);

  const client = serviceClient();
  const { data, error } = await client
    .from("learning_cards")
    .insert({
      user_id: userId,
      vocabulary_id: vocabularyId,
      state: 0,
      due: new Date().toISOString(),
      stability: 0,
      difficulty: 0,
      ...cardOverrides,
    })
    .select("id")
    .single();

  if (error)
    throw new Error(`Failed to create learning card: ${error.message}`);
  return { vocabularyId, cardId: data.id };
}

/** Create a global_dictionary entry. Returns its id. */
export async function createTestGlobalDictEntry(
  word: string,
  lemma?: string,
  overrides: Record<string, unknown> = {},
): Promise<string> {
  const client = serviceClient();
  const id = crypto.randomUUID();
  const now = new Date().toISOString();
  const resolvedLemma = lemma ?? word.trim().toLowerCase();

  const { error } = await client.from("global_dictionary").insert({
    id,
    word,
    stem: word,
    lemma: resolvedLemma,
    language_code: "en",
    part_of_speech: "noun",
    english_definition: `A test definition for ${word}`,
    synonyms: [],
    antonyms: [],
    confusables: [],
    example_sentences: [],
    pronunciation_ipa: "",
    translations: {
      de: { primary: `${word} (de)`, alternatives: [], source: "test" },
    },
    cefr_level: "B1",
    confidence: 0.9,
    created_at: now,
    updated_at: now,
    ...overrides,
  });

  if (error)
    throw new Error(
      `Failed to create global_dictionary entry: ${error.message}`,
    );
  return id;
}

/** Create a word_variants mapping. */
export async function createTestWordVariant(
  variant: string,
  globalDictId: string,
  languageCode: string = "en",
): Promise<string> {
  const client = serviceClient();
  const id = crypto.randomUUID();

  const { error } = await client.from("word_variants").insert({
    id,
    language_code: languageCode,
    variant: variant.trim().toLowerCase(),
    global_dictionary_id: globalDictId,
    method: "test",
  });

  if (error)
    throw new Error(`Failed to create word_variant: ${error.message}`);
  return id;
}

/** Clean up global_dictionary entries by id. */
export async function cleanupGlobalDictionary(ids: string[]): Promise<void> {
  if (ids.length === 0) return;
  const client = serviceClient();
  await client.from("global_dictionary").delete().in("id", ids);
}
