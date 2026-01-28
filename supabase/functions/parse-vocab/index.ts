// Parse vocab.db Edge Function - parses Kindle Vocabulary Builder SQLite database
// and stores entries directly in the vocabulary table

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

interface ParsedBook {
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
  // This is safer than using the service role key
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
    const booksMap = new Map<string, ParsedBook>();

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

          // Track unique books
          if (bookId && bookTitle && !booksMap.has(bookId as string)) {
            booksMap.set(bookId as string, {
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

          // Generate content hash for deduplication
          const contentHash = await generateContentHash(
            word as string,
            context as string | null,
            bookTitle as string | null
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

    const books = Array.from(booksMap.values());

    // Upsert books and build a map of kindle_book_id -> database book_id
    const bookIdMap = new Map<string, string>();
    
    for (const book of books) {
      // Check if book exists by ASIN or title+author
      let existingBook = null;
      
      if (book.asin) {
        const { data } = await client
          .from('books')
          .select('id')
          .eq('user_id', userId)
          .eq('asin', book.asin)
          .single();
        existingBook = data;
      }
      
      if (!existingBook && book.title) {
        const query = client
          .from('books')
          .select('id')
          .eq('user_id', userId)
          .eq('title', book.title);
        
        if (book.author) {
          query.eq('author', book.author);
        }
        
        const { data } = await query.single();
        existingBook = data;
      }
      
      if (existingBook) {
        bookIdMap.set(book.id, existingBook.id);
      } else {
        // Insert new book
        const { data: newBook, error } = await client
          .from('books')
          .insert({
            user_id: userId,
            title: book.title,
            author: book.author,
            asin: book.asin,
            source: 'kindle',
          })
          .select('id')
          .single();
        
        if (newBook) {
          bookIdMap.set(book.id, newBook.id);
        } else if (error) {
          console.error('Book insert error:', error);
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
      .select('content_hash')
      .eq('user_id', userId);

    const existingHashes = new Set(existingVocab?.map(v => v.content_hash) || []);

    // Filter out duplicates
    const newEntries = entries.filter(e => !existingHashes.has(e.contentHash));
    const skipped = entries.length - newEntries.length;

    // Insert new vocabulary entries
    let imported = 0;
    const errors: string[] = [];

    // Process in batches of 100 for efficiency
    const batchSize = 100;
    for (let i = 0; i < newEntries.length; i += batchSize) {
      const batch = newEntries.slice(i, i + batchSize);
      
      const vocabRecords = batch.map(entry => {
        // Find book_id from the map using the kindle book key
        let bookId: string | null = null;
        if (entry.bookTitle) {
          // Find the book by matching title
          for (const [kindleId, book] of booksMap.entries()) {
            if (book.title === entry.bookTitle) {
              bookId = bookIdMap.get(kindleId) || null;
              break;
            }
          }
        }
        
        return {
          user_id: userId,
          word: entry.word,
          stem: entry.stem,
          context: entry.context,
          book_id: bookId,
          lookup_timestamp: entry.lookupTimestamp,
          content_hash: entry.contentHash,
          is_pending_sync: false,
          version: 1,
        };
      });

      const { error } = await client
        .from('vocabulary')
        .insert(vocabRecords);

      if (error) {
        console.error('Insert error:', error);
        errors.push(`Batch ${i / batchSize + 1}: ${error.message}`);
      } else {
        imported += batch.length;
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
      skipped,
      books: books.length,
      errors: errors.length > 0 ? errors : undefined,
    });
  } catch (error) {
    console.error('Parse vocab error:', error);
    return errorResponse('Internal server error', 500);
  }
});

async function generateContentHash(
  word: string,
  context: string | null,
  bookTitle: string | null
): Promise<string> {
  const normalized = [
    word.toLowerCase().trim(),
    (context || '').trim(),
    (bookTitle || '').trim(),
  ].join('|');

  const encoder = new TextEncoder();
  const data = encoder.encode(normalized);
  const hashBuffer = await crypto.subtle.digest('SHA-256', data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map((b) => b.toString(16).padStart(2, '0')).join('');
}
