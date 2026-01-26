# Research: Vocabulary Import & Display

**Feature**: 002-vocabulary-import-display
**Date**: 2026-01-26

## 1. Kindle vocab.db Schema

### Decision
Parse vocab.db using the standard Kindle Vocabulary Builder SQLite schema with three main tables: WORDS, LOOKUPS, and BOOK_INFO.

### Database Structure

**Location**: `/system/vocabulary/vocab.db` on Kindle device

**Tables**:

| Table | Description |
|-------|-------------|
| WORDS | Unique words looked up |
| LOOKUPS | Lookup instances with context |
| BOOK_INFO | Book metadata |

### Schema Details (verified from actual vocab.db)

```sql
-- WORDS table
CREATE TABLE WORDS (
    id TEXT PRIMARY KEY NOT NULL,
    word TEXT,
    stem TEXT,
    lang TEXT,
    category INTEGER DEFAULT 0,
    timestamp INTEGER DEFAULT 0,
    profileid TEXT
);
CREATE INDEX wordprofileid ON WORDS (profileid);

-- LOOKUPS table  
CREATE TABLE LOOKUPS (
    id TEXT PRIMARY KEY NOT NULL,
    word_key TEXT,        -- References WORDS(id)
    book_key TEXT,        -- References BOOK_INFO(id)
    dict_key TEXT,
    pos TEXT,
    usage TEXT,           -- Context sentence
    timestamp INTEGER DEFAULT 0
);
CREATE INDEX lookupwordkey ON LOOKUPS (word_key);
CREATE INDEX lookupbookkey ON LOOKUPS (book_key);

-- BOOK_INFO table
CREATE TABLE BOOK_INFO (
    id TEXT PRIMARY KEY NOT NULL,
    asin TEXT,
    guid TEXT,
    lang TEXT,
    title TEXT,           -- May contain ID-like strings, not clean titles
    authors TEXT          -- May be "Unknown"
);

-- Additional tables (not used for vocabulary)
CREATE TABLE DICT_INFO (id TEXT PRIMARY KEY NOT NULL, asin TEXT, langin TEXT, langout TEXT);
CREATE TABLE METADATA (id TEXT PRIMARY KEY NOT NULL, dsname TEXT, sscnt INTEGER, profileid TEXT);
CREATE TABLE VERSION (id TEXT PRIMARY KEY NOT NULL, dsname TEXT, value INTEGER);
```

### Sample Data (from actual Kindle)

| word | usage (context) | title | authors |
|------|-----------------|-------|---------|
| gaudy | "...many designers would describe the busy, colorful patterns..." | HowtoMakeSenseofAnyMess-AbbyCovert-wjkeyy | Unknown |
| pliable | "When you're making a diagram, keep the structure pliable." | HowtoMakeSenseofAnyMess-AbbyCovert-wjkeyy | Unknown |
| innocuous | "...even over something relatively innocuous, she should..." | Lencioni, Patrick M - The advantage... | Patrick M. Lencioni |

**Note**: Book titles may contain ID-like strings instead of clean titles. The parser should handle both formats gracefully.

### Extraction Query

```sql
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
```

### Rationale
Direct SQLite parsing provides complete access to all vocabulary data including context sentences, which are critical for vocabulary learning.

### Alternatives Considered
- **Kindle API**: No public API exists for Vocabulary Builder
- **Text export**: Kindle doesn't support vocabulary export
- **Direct SQLite parsing**: ✅ Chosen - complete data access, offline capable

---

## 2. Server-Side SQLite Parsing in Deno

### Decision
Use sql.js (SQLite compiled to WebAssembly) in Supabase Edge Functions to parse vocab.db without native dependencies.

### Implementation Approach

**Library**: `sql.js` - SQLite compiled to WebAssembly
- No native binaries required
- Runs in Deno/Edge Functions
- Handles SQLite file format directly

**Process**:
1. Desktop uploads vocab.db as binary file (base64 encoded)
2. Edge Function decodes and loads into sql.js
3. Runs extraction query
4. Returns parsed vocabulary entries as JSON

### Code Pattern

```typescript
import initSqlJs from 'sql.js';

async function parseVocabDb(fileBuffer: ArrayBuffer): Promise<VocabularyEntry[]> {
  const SQL = await initSqlJs();
  const db = new SQL.Database(new Uint8Array(fileBuffer));
  
  const results = db.exec(`
    SELECT w.word, l.usage, l.timestamp, b.title, b.authors
    FROM LOOKUPS l
    JOIN WORDS w ON l.word_key = w.id
    LEFT JOIN BOOK_INFO b ON l.book_key = b.id
    ORDER BY l.timestamp DESC
  `);
  
  db.close();
  return transformResults(results);
}
```

### File Size Considerations
- Typical vocab.db: 100KB - 5MB
- Supabase Edge Function limit: 6MB request body
- Base64 encoding adds ~33% overhead
- Max supported: ~4MB vocab.db (5000+ words typical)

### Rationale
sql.js provides full SQLite compatibility in serverless environment without native dependencies. Base64 encoding ensures safe binary transfer.

### Alternatives Considered
- **Native SQLite in Rust (desktop-side)**: Violates server-side parsing requirement
- **SQLite REST API**: No suitable service exists
- **sql.js in Deno**: ✅ Chosen - proven, full SQLite support, no native deps

---

## 3. Deduplication Strategy

### Decision
Deduplicate vocabulary entries using a composite hash of word + context + book, consistent with existing highlight deduplication.

### Hash Calculation

```typescript
function generateVocabHash(word: string, context: string, bookTitle: string): string {
  const normalized = `${word.toLowerCase()}|${context}|${bookTitle}`;
  return crypto.createHash('sha256').update(normalized).digest('hex');
}
```

### Deduplication Flow
1. Desktop sends all vocab entries from vocab.db
2. Server parses and generates hashes
3. Server queries existing vocabulary for user
4. Server filters out entries with matching hashes
5. Server returns only new entries to desktop
6. Desktop stores new entries and syncs to cloud

### Rationale
Hash-based deduplication is efficient and deterministic. Matching existing pattern from highlights feature.

---

## 4. Mobile Vocabulary List UX

### Decision
Implement vocabulary list as a scrollable list with word + truncated context, sorted newest first, with tap-to-expand detail view.

### List Item Layout

```
┌─────────────────────────────────┐
│ **word**                        │
│ "The context sentence where..." │
└─────────────────────────────────┘
```

- Word: Bold, larger font
- Context: Truncated to ~50 characters with ellipsis
- No book info in list view (shown on tap)

### Detail View Layout

```
┌─────────────────────────────────┐
│ ← Back                          │
│                                 │
│ **word**                        │
│                                 │
│ "Full context sentence where    │
│  the word was looked up while   │
│  reading the book."             │
│                                 │
│ 📚 Book Title                   │
│ 👤 Author Name                  │
│ 📅 January 26, 2026             │
└─────────────────────────────────┘
```

### Rationale
Truncated list provides quick scanning while preserving context visibility. Detail view provides complete information without cluttering the list.

---

## 5. Sync Strategy

### Decision
Reuse existing sync infrastructure (SyncOutbox, push/pull endpoints) with new vocabulary table. Same last-write-wins conflict resolution.

### Sync Tables
- `vocabulary` - New table for vocabulary entries
- Uses same sync columns: `lastSyncedAt`, `isPendingSync`, `version`, `deletedAt`

### Pull Endpoint Update
Extend `/sync/pull` to include vocabulary:

```typescript
const { data: vocabulary } = await client
  .from('vocabulary')
  .select('*')
  .eq('user_id', userId)
  .gt('updated_at', since);

return { books, highlights, vocabulary, syncedAt };
```

### Rationale
Existing sync infrastructure handles offline-first requirements. Adding vocabulary as another synced entity minimizes new code.

---

## Summary

| Component | Technology | Rationale |
|-----------|------------|-----------|
| vocab.db Parsing | sql.js (WASM) | Full SQLite in Deno, no native deps |
| File Transfer | Base64 encoding | Safe binary transfer over HTTPS |
| Deduplication | SHA-256 hash | Deterministic, efficient |
| Mobile List | Flutter ListView | Standard pattern, efficient scrolling |
| Sync | Existing SyncOutbox | Reuse infrastructure, offline-first |
