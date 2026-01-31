// Parse vocab.db Edge Function - parses Kindle Vocabulary Builder SQLite database
// and stores entries in vocabulary + encounters + sources tables

import { handleCors } from '../_shared/cors.ts';
import { createSupabaseClient, createServiceClient, getUserId } from '../_shared/supabase.ts';
import { jsonResponse, errorResponse, unauthorizedResponse } from '../_shared/response.ts';
import initSqlJs, { type Database } from 'npm:sql.js@1.10.3';

interface ParsedVocabularyEntry {
  word: string;
  stem: string | null;
  context: string | null;
  lookupTimestamp: string | null;
  bookTitle: string | null;
  bookAuthor: string | null;
  bookAsin: string | null;
  contentHash: string;
}

interface ParsedSource {
  id: string;
  title: string;
  author: string | null;
  asin: string | null;
}

Deno.serve(async (req) => {
  // Handle CORS preflight
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  // Only accept POST
  if (req.method !== 'POST') {
    return errorResponse('Method not allowed', 405);
  }

  // Get user ID from auth
  let userId = await getUserId(req);
  let isDevMode = false;

  // For development: allow passing userId with a dev secret header
  if (!userId) {
    const devSecret = Deno.env.get('DEV_SECRET');
    const providedSecret = req.headers.get('X-Dev-Secret');

    if (devSecret && providedSecret === devSecret) {
      try {
        const body = await req.clone().json();
        if (body.userId) {
          userId = body.userId;
          isDevMode = true;
          console.log('[dev mode] Using userId from request body:', userId);
        }
      } catch {
        // Ignore parse errors
      }
    }
  }

  if (!userId) {
    return unauthorizedResponse();
  }

  // Use service client in dev mode to bypass RLS, regular client otherwise
  const client = isDevMode ? createServiceClient() : createSupabaseClient(req);

  try {
    const { file } = await req.json();

    if (!file) {
      return errorResponse('Missing file parameter', 400);
    }

    // Check for empty/minimal file
    if (file.length < 100) {
      return errorResponse('File appears to be empty or too small', 400);
    }

    // Decode base64 file content
    let fileBuffer: Uint8Array;
    try {
      const binaryString = atob(file);
      fileBuffer = new Uint8Array(binaryString.length);
      for (let i = 0; i < binaryString.length; i++) {
        fileBuffer[i] = binaryString.charCodeAt(i);
      }
    } catch {
      return errorResponse('Invalid base64 encoding', 400);
    }

    // Check file size (max 6MB)
    if (fileBuffer.length > 6 * 1024 * 1024) {
      return errorResponse('File too large (max 6MB)', 413);
    }

    // Initialize sql.js
    const SQL = await initSqlJs();

    let db: Database;
    try {
      db = new SQL.Database(fileBuffer);
    } catch {
      return errorResponse('Invalid SQLite database file', 400);
    }

    // Parse vocabulary entries
    const entries: ParsedVocabularyEntry[] = [];
    const sourcesMap = new Map<string, ParsedSource>();

    try {
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

      if (result.length > 0) {
        const rows = result[0].values;

        for (const row of rows) {
          const [
            _wordId,
            word,
            stem,
            _lookupId,
            context,
            timestamp,
            bookId,
            bookTitle,
            bookAuthor,
            bookAsin,
          ] = row;

          // Skip entries without a word
          if (!word) continue;

          // Track unique sources (books)
          if (bookId && bookTitle && !sourcesMap.has(bookId as string)) {
            sourcesMap.set(bookId as string, {
              id: bookId as string,
              title: bookTitle as string,
              author: (bookAuthor as string) || null,
              asin: (bookAsin as string) || null,
            });
          }

          // Convert timestamp (Unix milliseconds to ISO string)
          let lookupTimestamp: string | null = null;
          if (timestamp) {
            try {
              lookupTimestamp = new Date(timestamp as number).toISOString();
            } catch {
              // Invalid timestamp, leave as null
            }
          }

          // Generate content hash for deduplication: hash(word|stem)
          const contentHash = await generateContentHash(
            word as string,
            (stem as string) || null,
          );

          entries.push({
            word: word as string,
            stem: (stem as string) || null,
            context: (context as string) || null,
            lookupTimestamp,
            bookTitle: (bookTitle as string) || null,
            bookAuthor: (bookAuthor as string) || null,
            bookAsin: (bookAsin as string) || null,
            contentHash,
          });
        }
      }
    } catch (e) {
      console.error('SQL query error:', e);
      return errorResponse('Failed to parse vocab.db: invalid schema', 400);
    } finally {
      db.close();
    }

    const sources = Array.from(sourcesMap.values());

    // Upsert sources and build a map of kindle_book_id -> database source_id
    const sourceIdMap = new Map<string, string>();

    for (const source of sources) {
      // Try to find existing source by type+title+author
      const query = client
        .from('sources')
        .select('id')
        .eq('user_id', userId)
        .eq('type', 'book')
        .eq('title', source.title);

      if (source.author) {
        query.eq('author', source.author);
      }

      const { data: existingSource } = await query.single();

      if (existingSource) {
        sourceIdMap.set(source.id, existingSource.id);
      } else {
        // Insert new source
        const { data: newSource, error } = await client
          .from('sources')
          .insert({
            user_id: userId,
            type: 'book',
            title: source.title,
            author: source.author,
            asin: source.asin,
          })
          .select('id')
          .single();

        if (newSource) {
          sourceIdMap.set(source.id, newSource.id);
        } else if (error) {
          console.error('Source insert error:', error);
        }
      }
    }

    // Create import session record
    const startedAt = new Date().toISOString();
    const { data: importSession, error: sessionError } = await client
      .from('import_sessions')
      .insert({
        user_id: userId,
        source: 'device',
        device_name: 'Kindle',
        total_found: entries.length,
        imported: 0,
        skipped: 0,
        errors: 0,
        started_at: startedAt,
      })
      .select('id')
      .single();

    if (sessionError) {
      console.error('Failed to create import session:', sessionError);
    }

    // Get existing vocabulary hashes for deduplication
    const { data: existingVocab } = await client
      .from('vocabulary')
      .select('id, content_hash')
      .eq('user_id', userId);

    const existingHashMap = new Map<string, string>();
    for (const v of existingVocab || []) {
      existingHashMap.set(v.content_hash, v.id);
    }

    // Separate new vocab entries from existing ones
    const newEntries = entries.filter(e => !existingHashMap.has(e.contentHash));
    const existingEntries = entries.filter(e => existingHashMap.has(e.contentHash));
    const skipped = existingEntries.length; // Existing vocab - encounters still created

    // Insert new vocabulary entries (word identity only)
    let imported = 0;
    let encountersCreated = 0;
    const errors: string[] = [];

    // Process new vocabulary in batches of 100
    const batchSize = 100;
    for (let i = 0; i < newEntries.length; i += batchSize) {
      const batch = newEntries.slice(i, i + batchSize);

      const vocabRecords = batch.map(entry => ({
        user_id: userId,
        word: entry.word,
        stem: entry.stem,
        content_hash: entry.contentHash,
        is_pending_sync: false,
        version: 1,
      }));

      const { error } = await client
        .from('vocabulary')
        .upsert(vocabRecords, {
          onConflict: 'user_id,content_hash',
          ignoreDuplicates: true
        });

      if (error) {
        console.error('Insert error:', error);
        errors.push(`Vocab batch ${i / batchSize + 1}: ${error.message}`);
      } else {
        imported += batch.length;

        // Fetch inserted vocab IDs
        const contentHashes = batch.map(e => e.contentHash);
        const { data: insertedVocab } = await client
          .from('vocabulary')
          .select('id, content_hash')
          .eq('user_id', userId)
          .in('content_hash', contentHashes);

        // Update hash map with newly inserted vocab
        if (insertedVocab) {
          for (const v of insertedVocab) {
            existingHashMap.set(v.content_hash, v.id);
          }
        }

        // Create learning cards for new vocabulary
        if (insertedVocab && insertedVocab.length > 0) {
          const learningCards = insertedVocab.map(v => ({
            user_id: userId,
            vocabulary_id: v.id,
            state: 0,
            due: new Date().toISOString(),
            stability: 0.0,
            difficulty: 0.0,
            reps: 0,
            lapses: 0,
            is_leech: false,
            is_pending_sync: false,
            version: 1,
          }));

          const { error: cardError } = await client
            .from('learning_cards')
            .upsert(learningCards, {
              onConflict: 'user_id,vocabulary_id',
              ignoreDuplicates: true
            });

          if (cardError) {
            console.error('Learning card creation error:', cardError);
          }
        }
      }
    }

    // Create encounters for ALL entries (both new and existing vocab)
    const allEntries = [...newEntries, ...existingEntries];
    for (let i = 0; i < allEntries.length; i += batchSize) {
      const batch = allEntries.slice(i, i + batchSize);

      const encounterRecords = batch.map(entry => {
        // Find source_id for this entry's book
        let sourceId: string | null = null;
        if (entry.bookTitle) {
          for (const [kindleId, source] of sourcesMap.entries()) {
            if (source.title === entry.bookTitle) {
              sourceId = sourceIdMap.get(kindleId) || null;
              break;
            }
          }
        }

        const vocabularyId = existingHashMap.get(entry.contentHash);

        return {
          user_id: userId,
          vocabulary_id: vocabularyId,
          source_id: sourceId,
          context: entry.context,
          locator_json: entry.lookupTimestamp ? JSON.stringify({ kindle_date: entry.lookupTimestamp }) : null,
          occurred_at: entry.lookupTimestamp,
          is_pending_sync: false,
          version: 1,
        };
      }).filter(r => r.vocabulary_id != null);

      if (encounterRecords.length > 0) {
        const { error: encError } = await client
          .from('encounters')
          .insert(encounterRecords);

        if (encError) {
          console.error('Encounter insert error:', encError);
          errors.push(`Encounter batch ${i / batchSize + 1}: ${encError.message}`);
        } else {
          encountersCreated += encounterRecords.length;
        }
      }
    }

    // Update import session with results
    if (importSession?.id) {
      await client
        .from('import_sessions')
        .update({
          imported,
          skipped,
          errors: errors.length,
          error_details: errors.length > 0 ? { messages: errors } : null,
          completed_at: new Date().toISOString(),
        })
        .eq('id', importSession.id);
    }

    return jsonResponse({
      totalParsed: entries.length,
      imported,
      encounters: encountersCreated,
      skipped,
      errors: errors.length > 0 ? errors : undefined,
    });
  } catch (error) {
    console.error('Parse vocab error:', error);
    return errorResponse('Internal server error', 500);
  }
});

async function generateContentHash(
  word: string,
  stem: string | null,
): Promise<string> {
  const normalized = [
    word.toLowerCase().trim(),
    (stem || '').toLowerCase().trim(),
  ].join('|');

  const encoder = new TextEncoder();
  const data = encoder.encode(normalized);
  const hashBuffer = await crypto.subtle.digest('SHA-256', data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map((b) => b.toString(16).padStart(2, '0')).join('');
}
