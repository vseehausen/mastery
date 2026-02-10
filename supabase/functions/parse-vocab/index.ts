// Edge function: parse-vocab
// Parses a Kindle Vocabulary Builder SQLite database and imports words.

import { handleCors } from '../_shared/cors.ts';
import { createSupabaseClient, createServiceClient, getUserId } from '../_shared/supabase.ts';
import type { SupabaseClient } from '../_shared/supabase.ts';
import { jsonResponse, errorResponse, unauthorizedResponse } from '../_shared/response.ts';
import { normalize } from '../_shared/normalize.ts';
import { triggerEnrichment } from '../_shared/vocabulary-lifecycle.ts';
import initSqlJs, { type Database } from 'npm:sql.js@1.10.3';

// =============================================================================
// Types
// =============================================================================

interface KindleLookup {
  word: string;
  stem: string | null;
  context: string | null;
  lookupTimestamp: string | null;
  bookTitle: string | null;
  normalized: string;
}

interface KindleBook {
  kindleId: string;
  title: string;
  author: string | null;
  asin: string | null;
}

interface ClassifiedEntries {
  newEntries: KindleLookup[];
  reactivateEntries: KindleLookup[];
  existingEntries: KindleLookup[];
}

// =============================================================================
// Handler
// =============================================================================

Deno.serve(async (req) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;
  if (req.method !== 'POST') return errorResponse('Method not allowed', 405);

  const { userId, client } = await resolveAuth(req);
  if (!userId) return unauthorizedResponse();

  try {
    const { file, native_language_code } = await req.json();
    const fileBuffer = decodeFile(file);
    const { lookups, books } = await parseKindleDb(fileBuffer);

    const sourceIdMap = await upsertSources(client, userId, books);
    const session = await createImportSession(client, userId, lookups.length);

    const { activeWordMap, deletedWordMap } = await loadVocabularyMaps(client, userId);
    const { newEntries, reactivateEntries, existingEntries } = classifyEntries(
      lookups, activeWordMap, deletedWordMap,
    );

    let imported = await reactivateVocabulary(client, userId, reactivateEntries, deletedWordMap, activeWordMap);
    const { imported: insertedCount, errors } = await insertNewVocabulary(
      client, userId, newEntries, activeWordMap,
    );
    imported += insertedCount;

    const allEntries = [...newEntries, ...reactivateEntries, ...existingEntries];
    const { count: encountersCreated, errors: encounterErrors } = await createEncounters(
      client, userId, allEntries, activeWordMap, books, sourceIdMap,
    );
    errors.push(...encounterErrors);

    await finalizeSession(client, session?.id, imported, existingEntries.length, errors);

    const vocabIdsToEnrich = [...newEntries, ...reactivateEntries]
      .map(e => activeWordMap.get(e.normalized))
      .filter((id): id is string => !!id);
    if (vocabIdsToEnrich.length > 0) {
      triggerEnrichment(userId, vocabIdsToEnrich, native_language_code || 'de');
    }

    return jsonResponse({
      totalParsed: lookups.length,
      imported,
      encounters: encountersCreated,
      skipped: existingEntries.length,
      errors: errors.length > 0 ? errors : undefined,
    });
  } catch (error) {
    if (error instanceof BadRequest) return errorResponse(error.message, 400);
    console.error('Parse vocab error:', error);
    return errorResponse('Internal server error', 500);
  }
});

// =============================================================================
// Auth
// =============================================================================

async function resolveAuth(req: Request): Promise<{ userId: string | null; client: SupabaseClient }> {
  let userId = await getUserId(req);

  if (!userId) {
    const devSecret = Deno.env.get('DEV_SECRET');
    const providedSecret = req.headers.get('X-Dev-Secret');
    if (devSecret && providedSecret === devSecret) {
      try {
        const body = await req.clone().json();
        if (body.userId) {
          userId = body.userId;
          console.log('[dev mode] Using userId from request body:', userId);
          return { userId, client: createServiceClient() };
        }
      } catch { /* ignore */ }
    }
    return { userId: null, client: createSupabaseClient(req) };
  }

  return { userId, client: createSupabaseClient(req) };
}

// =============================================================================
// File Decoding + SQLite Parsing
// =============================================================================

function decodeFile(file: unknown): Uint8Array {
  if (!file || typeof file !== 'string') throw new BadRequest('Missing file parameter');
  if (file.length < 100) throw new BadRequest('File appears to be empty or too small');

  let buffer: Uint8Array;
  try {
    const bin = atob(file);
    buffer = new Uint8Array(bin.length);
    for (let i = 0; i < bin.length; i++) buffer[i] = bin.charCodeAt(i);
  } catch {
    throw new BadRequest('Invalid base64 encoding');
  }

  if (buffer.length > 6 * 1024 * 1024) throw new BadRequest('File too large (max 6MB)');
  return buffer;
}

async function parseKindleDb(fileBuffer: Uint8Array): Promise<{ lookups: KindleLookup[]; books: KindleBook[] }> {
  const SQL = await initSqlJs();
  let db: Database;
  try {
    db = new SQL.Database(fileBuffer);
  } catch {
    throw new BadRequest('Invalid SQLite database file');
  }

  try {
    return extractLookups(db);
  } catch (e) {
    console.error('SQL query error:', e);
    throw new BadRequest('Failed to parse vocab.db: invalid schema');
  } finally {
    db.close();
  }
}

function extractLookups(db: Database): { lookups: KindleLookup[]; books: KindleBook[] } {
  const result = db.exec(`
    SELECT w.word, w.stem, l.usage as context, l.timestamp,
           b.id as book_id, b.title as book_title, b.authors as book_author, b.asin
    FROM LOOKUPS l
    JOIN WORDS w ON l.word_key = w.id
    LEFT JOIN BOOK_INFO b ON l.book_key = b.id
    ORDER BY l.timestamp DESC
  `);

  if (result.length === 0) return { lookups: [], books: [] };

  const lookups: KindleLookup[] = [];
  const booksMap = new Map<string, KindleBook>();

  for (const row of result[0].values) {
    const [word, stem, context, timestamp, bookId, bookTitle, bookAuthor, bookAsin] = row;
    if (!word) continue;

    if (bookId && bookTitle && !booksMap.has(bookId as string)) {
      booksMap.set(bookId as string, {
        kindleId: bookId as string,
        title: bookTitle as string,
        author: (bookAuthor as string) || null,
        asin: (bookAsin as string) || null,
      });
    }

    const cleanedWord = sanitizeKindleWord(word as string);
    lookups.push({
      word: cleanedWord,
      stem: stem ? sanitizeKindleWord(stem as string) : null,
      context: (context as string) || null,
      lookupTimestamp: toISOTimestamp(timestamp as number | null),
      bookTitle: (bookTitle as string) || null,
      normalized: normalize(cleanedWord),
    });
  }

  return { lookups, books: Array.from(booksMap.values()) };
}

// =============================================================================
// Sources
// =============================================================================

/** Find or create book sources. Returns kindleBookId → database sourceId map. */
async function upsertSources(
  client: SupabaseClient, userId: string, books: KindleBook[],
): Promise<Map<string, string>> {
  const sourceIdMap = new Map<string, string>();

  for (const book of books) {
    const query = client.from('sources').select('id')
      .eq('user_id', userId).eq('type', 'book').eq('title', book.title);
    if (book.author) query.eq('author', book.author);

    const { data: existing } = await query.single();
    if (existing) {
      sourceIdMap.set(book.kindleId, existing.id);
      continue;
    }

    const { data: created, error } = await client.from('sources')
      .insert({ user_id: userId, type: 'book', title: book.title, author: book.author, asin: book.asin })
      .select('id').single();

    if (created) sourceIdMap.set(book.kindleId, created.id);
    else if (error) console.error('Source insert error:', error);
  }

  return sourceIdMap;
}

// =============================================================================
// Import Session
// =============================================================================

async function createImportSession(
  client: SupabaseClient, userId: string, totalFound: number,
): Promise<{ id: string } | null> {
  const { data, error } = await client.from('import_sessions')
    .insert({
      user_id: userId, source: 'device', device_name: 'Kindle',
      total_found: totalFound, imported: 0, skipped: 0, errors: 0,
      started_at: new Date().toISOString(),
    })
    .select('id').single();

  if (error) console.error('Failed to create import session:', error);
  return data;
}

async function finalizeSession(
  client: SupabaseClient, sessionId: string | undefined, imported: number,
  skipped: number, errors: string[],
): Promise<void> {
  if (!sessionId) return;
  await client.from('import_sessions').update({
    imported, skipped, errors: errors.length,
    error_details: errors.length > 0 ? { messages: errors } : null,
    completed_at: new Date().toISOString(),
  }).eq('id', sessionId);
}

// =============================================================================
// Vocabulary Classification
// =============================================================================

async function loadVocabularyMaps(client: SupabaseClient, userId: string): Promise<{
  activeWordMap: Map<string, string>;
  deletedWordMap: Map<string, string>;
}> {
  const { data } = await client.from('vocabulary').select('id, word, deleted_at').eq('user_id', userId);

  const activeWordMap = new Map<string, string>();
  const deletedWordMap = new Map<string, string>();
  for (const v of data || []) {
    if (v.deleted_at) {
      if (!deletedWordMap.has(v.word)) deletedWordMap.set(v.word, v.id);
    } else {
      activeWordMap.set(v.word, v.id);
    }
  }
  return { activeWordMap, deletedWordMap };
}

function classifyEntries(
  lookups: KindleLookup[],
  activeWordMap: Map<string, string>,
  deletedWordMap: Map<string, string>,
): ClassifiedEntries {
  const seen = new Set<string>();
  const newEntries: KindleLookup[] = [];
  const reactivateEntries: KindleLookup[] = [];
  const existingEntries: KindleLookup[] = [];

  for (const e of lookups) {
    if (activeWordMap.has(e.normalized)) {
      existingEntries.push(e);
    } else if (!seen.has(e.normalized)) {
      seen.add(e.normalized);
      (deletedWordMap.has(e.normalized) ? reactivateEntries : newEntries).push(e);
    } else {
      existingEntries.push(e);
    }
  }

  return { newEntries, reactivateEntries, existingEntries };
}

// =============================================================================
// Vocabulary Writes
// =============================================================================

async function reactivateVocabulary(
  client: SupabaseClient, userId: string, entries: KindleLookup[],
  deletedWordMap: Map<string, string>, activeWordMap: Map<string, string>,
): Promise<number> {
  for (const entry of entries) {
    const vocabId = deletedWordMap.get(entry.normalized)!;
    const now = new Date().toISOString();
    await client.from('vocabulary').update({ deleted_at: null, updated_at: now }).eq('id', vocabId);
    await client.from('learning_cards').update({ deleted_at: null, updated_at: now })
      .eq('vocabulary_id', vocabId).eq('user_id', userId);
    activeWordMap.set(entry.normalized, vocabId);
  }
  return entries.length;
}

const BATCH_SIZE = 100;

async function insertNewVocabulary(
  client: SupabaseClient, userId: string, entries: KindleLookup[],
  activeWordMap: Map<string, string>,
): Promise<{ imported: number; errors: string[] }> {
  let imported = 0;
  const errors: string[] = [];

  for (let i = 0; i < entries.length; i += BATCH_SIZE) {
    const batch = entries.slice(i, i + BATCH_SIZE);

    const { error } = await client.from('vocabulary').insert(
      batch.map(e => ({
        user_id: userId,
        word: e.normalized,
        stem: e.stem ? normalize(e.stem) : e.normalized,
        is_pending_sync: false,
        version: 1,
      })),
    );

    if (error) {
      console.error('Insert error:', error);
      errors.push(`Vocab batch ${i / BATCH_SIZE + 1}: ${error.message}`);
      continue;
    }

    imported += batch.length;

    const words = batch.map(e => e.normalized);
    const { data: inserted } = await client.from('vocabulary')
      .select('id, word').eq('user_id', userId).in('word', words).is('deleted_at', null);

    if (inserted) {
      for (const v of inserted) activeWordMap.set(v.word, v.id);

      const { error: cardError } = await client.from('learning_cards').insert(
        inserted.map(v => ({
          user_id: userId, vocabulary_id: v.id, state: 0,
          due: new Date().toISOString(), stability: 0.0, difficulty: 0.0,
          reps: 0, lapses: 0, is_leech: false, is_pending_sync: false, version: 1,
        })),
      );
      if (cardError) console.error('Learning card creation error:', cardError);
    }
  }

  return { imported, errors };
}

// =============================================================================
// Encounters
// =============================================================================

async function createEncounters(
  client: SupabaseClient, userId: string, entries: KindleLookup[],
  activeWordMap: Map<string, string>, books: KindleBook[],
  sourceIdMap: Map<string, string>,
): Promise<{ count: number; errors: string[] }> {
  const titleToSourceId = new Map<string, string>();
  for (const book of books) {
    const dbId = sourceIdMap.get(book.kindleId);
    if (dbId) titleToSourceId.set(book.title, dbId);
  }

  let count = 0;
  const errors: string[] = [];

  for (let i = 0; i < entries.length; i += BATCH_SIZE) {
    const batch = entries.slice(i, i + BATCH_SIZE);

    const records = batch
      .map(entry => {
        const vocabularyId = activeWordMap.get(entry.normalized);
        if (!vocabularyId) return null;
        return {
          user_id: userId,
          vocabulary_id: vocabularyId,
          source_id: entry.bookTitle ? (titleToSourceId.get(entry.bookTitle) ?? null) : null,
          context: entry.context,
          locator_json: entry.lookupTimestamp ? JSON.stringify({ kindle_date: entry.lookupTimestamp }) : null,
          occurred_at: entry.lookupTimestamp,
          is_pending_sync: false,
          version: 1,
        };
      })
      .filter((r): r is NonNullable<typeof r> => r !== null);

    if (records.length === 0) continue;

    const { error } = await client.from('encounters').insert(records);
    if (error) {
      console.error('Encounter insert error:', error);
      errors.push(`Encounter batch ${i / BATCH_SIZE + 1}: ${error.message}`);
    } else {
      count += records.length;
    }
  }

  return { count, errors };
}

// =============================================================================
// Utilities
// =============================================================================

function sanitizeKindleWord(raw: string): string {
  return raw.replace(/\s*\(\s*\)\s*$/, '').trim();
}

function toISOTimestamp(ms: number | null): string | null {
  if (!ms) return null;
  try { return new Date(ms).toISOString(); } catch { return null; }
}

class BadRequest extends Error {
  constructor(message: string) { super(message); this.name = 'BadRequest'; }
}
