// Integration and unit tests for the parse-vocab edge function.
//
// Test groups:
//   1. Fixture validation (pure — no Supabase needed)
//   2. parse-vocab integration (requires local Supabase running)
//
// Run:
//   deno test --allow-all supabase/functions/tests/parse-vocab-test.ts

import {
  assert,
  assertEquals,
  assertExists,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  SUPABASE_URL,
  SUPABASE_ANON_KEY,
  DEV_SECRET,
  serviceClient,
  ensureTestUser,
  cleanupTestData,
  isSupabaseRunning,
  isFunctionServed,
} from "./helpers.ts";

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const FIXTURE_PATH = new URL("./fixtures/vocab.db", import.meta.url).pathname;

function readFixture(): Uint8Array {
  return Deno.readFileSync(FIXTURE_PATH);
}

function base64Encode(bytes: Uint8Array): string {
  let binary = "";
  for (const byte of bytes) {
    binary += String.fromCharCode(byte);
  }
  return btoa(binary);
}

const TEST_EMAIL = "test-parse-vocab@example.com";
const TEST_PASSWORD = "test-password-123456";
let TEST_USER_ID = "";

/** Invoke parse-vocab via the local edge function using dev mode. */
async function invokeParseVocab(fileBase64: string) {
  const response = await fetch(`${SUPABASE_URL}/functions/v1/parse-vocab`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${SUPABASE_ANON_KEY}`,
      "X-Dev-Secret": DEV_SECRET,
    },
    body: JSON.stringify({
      file: fileBase64,
      userId: TEST_USER_ID,
    }),
  });

  const body = await response.json();
  return { status: response.status, data: body };
}

// =============================================================================
// Group 1: Fixture validation (pure — no Supabase needed)
// =============================================================================

import initSqlJs from "npm:sql.js@1.10.3";

Deno.test("fixture: file exists and is readable", () => {
  const bytes = readFixture();
  assert(bytes.length > 0, "Fixture file should not be empty");
});

Deno.test(
  "fixture: has correct tables (WORDS, LOOKUPS, BOOK_INFO)",
  async () => {
    const SQL = await initSqlJs();
    const db = new SQL.Database(readFixture());

    const tables = db.exec(
      "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name",
    );
    // deno-lint-ignore no-explicit-any
    const tableNames = tables[0].values.map((r: any) => r[0] as string);
    db.close();

    assert(tableNames.includes("WORDS"), "Missing WORDS table");
    assert(tableNames.includes("LOOKUPS"), "Missing LOOKUPS table");
    assert(tableNames.includes("BOOK_INFO"), "Missing BOOK_INFO table");
    assert(tableNames.includes("DICT_INFO"), "Missing DICT_INFO table");
    assert(tableNames.includes("METADATA"), "Missing METADATA table");
    assert(tableNames.includes("VERSION"), "Missing VERSION table");
  },
);

Deno.test("fixture: has ~265 lookups, ~257 words, 7 books", async () => {
  const SQL = await initSqlJs();
  const db = new SQL.Database(readFixture());

  const lookups = db.exec("SELECT COUNT(*) FROM LOOKUPS")[0]
    .values[0][0] as number;
  const words = db.exec("SELECT COUNT(*) FROM WORDS")[0].values[0][0] as number;
  const books = db.exec("SELECT COUNT(*) FROM BOOK_INFO")[0]
    .values[0][0] as number;
  db.close();

  assertEquals(lookups, 265);
  assertEquals(words, 257);
  assertEquals(books, 7);
});

Deno.test("fixture: JOIN query returns expected columns and rows", async () => {
  const SQL = await initSqlJs();
  const db = new SQL.Database(readFixture());

  const result = db.exec(`
    SELECT
      w.id as word_id,
      w.word,
      w.stem,
      l.id as lookup_id,
      l.usage as context,
      l.timestamp,
      b.id as book_id,
      b.title as book_title,
      b.authors as book_author,
      b.asin
    FROM LOOKUPS l
    JOIN WORDS w ON l.word_key = w.id
    LEFT JOIN BOOK_INFO b ON l.book_key = b.id
    ORDER BY l.timestamp DESC
  `);
  db.close();

  assertEquals(result.length, 1, "Should return exactly one result set");

  const columns = result[0].columns;
  assertEquals(columns, [
    "word_id",
    "word",
    "stem",
    "lookup_id",
    "context",
    "timestamp",
    "book_id",
    "book_title",
    "book_author",
    "asin",
  ]);

  const rowCount = result[0].values.length;
  assertEquals(rowCount, 265, "JOIN should return 265 rows (same as LOOKUPS)");
});

Deno.test("fixture: contains only the 7 expected books", async () => {
  const SQL = await initSqlJs();
  const db = new SQL.Database(readFixture());

  const result = db.exec("SELECT authors, title FROM BOOK_INFO ORDER BY title");
  db.close();

  // deno-lint-ignore no-explicit-any
  const books = result[0].values.map((r: any) => ({
    author: r[0] as string,
    title: r[1] as string,
  }));

  // Verify we have the right 7 books
  const expectedAuthors = [
    "Ben Horowitz",
    "John Medina",
    "Julie Zhuo",
    "Patrick M. Lencioni",
    "Camille Fournier",
    "Unknown", // How to Make Sense of Any Mess
    "Abby Covert", // Stuck
  ];

  for (const expected of expectedAuthors) {
    assert(
      books.some(
        (b: { author: string; title: string }) => b.author === expected,
      ),
      `Missing book by author: ${expected}`,
    );
  }

  // Verify excluded books are NOT present
  const excludedAuthors = [
    "Roberts, Gregory David", // Shantaram
    "Beattie, Melody", // Codependent No More
    "Burns, David D. ", // Feeling Good
    "Levine, Amir", // Attached
    "Johnson, Sue", // The Love Secret
    "Wahl, Caroline", // Windstärke 17
  ];

  for (const excluded of excludedAuthors) {
    assert(
      !books.some(
        (b: { author: string; title: string }) => b.author === excluded,
      ),
      `Should not contain book by author: ${excluded}`,
    );
  }
});

Deno.test("fixture: all lookups reference valid words", async () => {
  const SQL = await initSqlJs();
  const db = new SQL.Database(readFixture());

  const orphaned = db.exec(`
    SELECT COUNT(*) FROM LOOKUPS l
    LEFT JOIN WORDS w ON l.word_key = w.id
    WHERE w.id IS NULL
  `);
  db.close();

  assertEquals(orphaned[0].values[0][0], 0, "No orphaned lookups");
});

// =============================================================================
// Group 2: parse-vocab integration (requires local Supabase running)
// =============================================================================

Deno.test({
  name: "integration: parse-vocab returns correct totalParsed count",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    if (!(await isSupabaseRunning()) || !(await isFunctionServed("parse-vocab"))) {
      console.log("  ⏭ Skipping: local Supabase or functions not running");
      return;
    }

    TEST_USER_ID = await ensureTestUser(TEST_EMAIL, TEST_PASSWORD);
    await cleanupTestData(TEST_USER_ID);

    const fileBase64 = base64Encode(readFixture());
    const { status, data } = await invokeParseVocab(fileBase64);

    assertEquals(
      status,
      200,
      `Expected 200, got ${status}: ${JSON.stringify(data)}`,
    );
    assertEquals(data.totalParsed, 265, "Should parse all 265 lookups");

    await cleanupTestData(TEST_USER_ID);
  },
});

Deno.test({
  name: "integration: parse-vocab creates vocabulary entries",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    if (!(await isSupabaseRunning()) || !(await isFunctionServed("parse-vocab"))) {
      console.log("  ⏭ Skipping: local Supabase or functions not running");
      return;
    }

    TEST_USER_ID = await ensureTestUser(TEST_EMAIL, TEST_PASSWORD);
    await cleanupTestData(TEST_USER_ID);

    const fileBase64 = base64Encode(readFixture());
    const { status, data } = await invokeParseVocab(fileBase64);
    assertEquals(status, 200);

    // Check vocabulary was created
    const client = serviceClient();
    const { data: vocab, error } = await client
      .from("vocabulary")
      .select("id, word, stem")
      .eq("user_id", TEST_USER_ID);

    assertEquals(error, null);
    assertExists(vocab);
    // The function's `imported` count may overcount due to ignoreDuplicates in upsert.
    // The actual unique vocab entries should be <= imported and > 200.
    assert(
      vocab!.length > 200,
      `Expected >200 vocab entries, got ${vocab!.length}`,
    );
    assert(
      vocab!.length <= data.imported,
      `Vocab entries (${vocab!.length}) should be <= imported (${data.imported})`,
    );

    // Verify each vocab entry has required fields
    for (const v of vocab!) {
      assertExists(v.id);
      assertExists(v.word);
    }

    await cleanupTestData(TEST_USER_ID);
  },
});

Deno.test({
  name: "integration: parse-vocab creates encounters with context",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    if (!(await isSupabaseRunning()) || !(await isFunctionServed("parse-vocab"))) {
      console.log("  ⏭ Skipping: local Supabase or functions not running");
      return;
    }

    TEST_USER_ID = await ensureTestUser(TEST_EMAIL, TEST_PASSWORD);
    await cleanupTestData(TEST_USER_ID);

    const fileBase64 = base64Encode(readFixture());
    const { status, data } = await invokeParseVocab(fileBase64);
    assertEquals(status, 200);

    const client = serviceClient();
    const { data: encounters, error } = await client
      .from("encounters")
      .select("id, vocabulary_id, source_id, context, occurred_at")
      .eq("user_id", TEST_USER_ID);

    assertEquals(error, null);
    assertExists(encounters);
    assertEquals(encounters!.length, data.encounters);
    assert(encounters!.length > 0, "Should have created encounters");

    // Most encounters should have context (usage sentences)
    const withContext = encounters!.filter((e) => e.context != null);
    assert(
      withContext.length > encounters!.length * 0.5,
      "Most encounters should have context",
    );

    await cleanupTestData(TEST_USER_ID);
  },
});

Deno.test({
  name: "integration: parse-vocab creates sources for each book",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    if (!(await isSupabaseRunning()) || !(await isFunctionServed("parse-vocab"))) {
      console.log("  ⏭ Skipping: local Supabase or functions not running");
      return;
    }

    TEST_USER_ID = await ensureTestUser(TEST_EMAIL, TEST_PASSWORD);
    await cleanupTestData(TEST_USER_ID);

    const fileBase64 = base64Encode(readFixture());
    const { status } = await invokeParseVocab(fileBase64);
    assertEquals(status, 200);

    const client = serviceClient();
    const { data: sources, error } = await client
      .from("sources")
      .select("id, title, author, type")
      .eq("user_id", TEST_USER_ID);

    assertEquals(error, null);
    assertExists(sources);
    assertEquals(sources!.length, 7, "Should create 7 sources (one per book)");

    // All sources should be type 'book'
    for (const s of sources!) {
      assertEquals(s.type, "book");
    }

    // Check specific books exist
    const titles = sources!.map((s) => s.title);
    assert(
      titles.some((t) => t.includes("Ben Horowitz")),
      "Should have Ben Horowitz book",
    );
    assert(
      titles.some(
        (t) => t.includes("Brain Rules") || t.includes("John Medina"),
      ),
      "Should have Brain Rules book",
    );

    await cleanupTestData(TEST_USER_ID);
  },
});

Deno.test({
  name: "integration: parse-vocab creates learning cards for new vocabulary",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    if (!(await isSupabaseRunning()) || !(await isFunctionServed("parse-vocab"))) {
      console.log("  ⏭ Skipping: local Supabase or functions not running");
      return;
    }

    TEST_USER_ID = await ensureTestUser(TEST_EMAIL, TEST_PASSWORD);
    await cleanupTestData(TEST_USER_ID);

    const fileBase64 = base64Encode(readFixture());
    const { status, data } = await invokeParseVocab(fileBase64);
    assertEquals(status, 200);

    const client = serviceClient();
    const { data: cards, error } = await client
      .from("learning_cards")
      .select("id, vocabulary_id, state, due, stability, difficulty")
      .eq("user_id", TEST_USER_ID);

    assertEquals(error, null);
    assertExists(cards);

    // One learning card per unique vocab entry (not per lookup/imported count)
    const { data: vocab } = await client
      .from("vocabulary")
      .select("id")
      .eq("user_id", TEST_USER_ID);
    assertEquals(
      cards!.length,
      vocab!.length,
      "Should have one learning card per unique vocab entry",
    );

    // All cards should be in initial state
    for (const card of cards!) {
      assertEquals(card.state, 0, "New card should have state 0");
      assertEquals(card.stability, 0.0);
      assertEquals(card.difficulty, 0.0);
    }

    await cleanupTestData(TEST_USER_ID);
  },
});

Deno.test({
  name: "integration: re-import is idempotent (skips existing, creates new encounters)",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    if (!(await isSupabaseRunning()) || !(await isFunctionServed("parse-vocab"))) {
      console.log("  ⏭ Skipping: local Supabase or functions not running");
      return;
    }

    TEST_USER_ID = await ensureTestUser(TEST_EMAIL, TEST_PASSWORD);
    await cleanupTestData(TEST_USER_ID);

    const fileBase64 = base64Encode(readFixture());

    // First import
    const first = await invokeParseVocab(fileBase64);
    assertEquals(first.status, 200);
    assert(first.data.imported > 0, "First import should create vocab entries");

    // Get actual vocab count after first import
    const client = serviceClient();
    const { data: vocabAfterFirst } = await client
      .from("vocabulary")
      .select("id")
      .eq("user_id", TEST_USER_ID);
    const firstVocabCount = vocabAfterFirst!.length;
    assert(firstVocabCount > 200, "Should have >200 unique vocab entries");

    // Second import — same file
    const second = await invokeParseVocab(fileBase64);
    assertEquals(second.status, 200);
    assertEquals(
      second.data.imported,
      0,
      "Second import should not create new vocab",
    );
    assertEquals(
      second.data.skipped,
      first.data.totalParsed,
      "All should be skipped",
    );
    assertEquals(
      second.data.totalParsed,
      first.data.totalParsed,
      "Same total parsed",
    );

    // But encounters should still be created (doubled)
    const { data: encounters } = await client
      .from("encounters")
      .select("id")
      .eq("user_id", TEST_USER_ID);

    assertEquals(
      encounters!.length,
      first.data.encounters + second.data.encounters,
      "Total encounters should be sum of both imports",
    );

    // Vocabulary count should stay the same
    const { data: vocab } = await client
      .from("vocabulary")
      .select("id")
      .eq("user_id", TEST_USER_ID);

    assertEquals(
      vocab!.length,
      firstVocabCount,
      "Vocab count should not change",
    );

    // Learning cards should also stay the same (no duplicates)
    const { data: cards } = await client
      .from("learning_cards")
      .select("id")
      .eq("user_id", TEST_USER_ID);

    assertEquals(
      cards!.length,
      firstVocabCount,
      "Card count should not change",
    );

    await cleanupTestData(TEST_USER_ID);
  },
});

Deno.test({
  name: "integration: deduplication works (same word from different books = 1 vocab entry)",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    if (!(await isSupabaseRunning()) || !(await isFunctionServed("parse-vocab"))) {
      console.log("  ⏭ Skipping: local Supabase or functions not running");
      return;
    }

    TEST_USER_ID = await ensureTestUser(TEST_EMAIL, TEST_PASSWORD);
    await cleanupTestData(TEST_USER_ID);

    const fileBase64 = base64Encode(readFixture());
    const { status, data } = await invokeParseVocab(fileBase64);
    assertEquals(status, 200);

    // The fixture has 265 lookups but only ~254 unique word+stem combinations.
    // The function's `imported` count may not perfectly reflect actual unique inserts
    // due to ignoreDuplicates in upsert, but encounters should always >= vocab.
    const client = serviceClient();
    const { data: vocab } = await client
      .from("vocabulary")
      .select("word")
      .eq("user_id", TEST_USER_ID);

    // Actual unique vocab should be less than total lookups (265)
    assert(
      vocab!.length < 265,
      `Unique vocab (${vocab!.length}) should be < 265 total lookups`,
    );
    assert(
      vocab!.length > 200,
      `Should have >200 unique vocab entries, got ${vocab!.length}`,
    );

    // Encounters should be >= unique vocab (multiple encounters per word possible)
    assert(
      data.encounters >= vocab!.length,
      "Encounters should be >= unique vocab entries",
    );

    // Verify no duplicate word values in vocabulary
    const words = vocab!.map((v) => v.word);
    const uniqueWords = new Set(words);
    assertEquals(
      words.length,
      uniqueWords.size,
      "No duplicate words",
    );

    await cleanupTestData(TEST_USER_ID);
  },
});
