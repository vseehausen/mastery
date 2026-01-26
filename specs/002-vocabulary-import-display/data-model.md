# Data Model: Vocabulary Import & Display

**Feature**: 002-vocabulary-import-display
**Date**: 2026-01-26

## Entity Relationship Diagram

```
┌─────────────┐       ┌─────────────────┐       ┌─────────────┐
│   users     │       │   vocabulary    │       │    books    │
├─────────────┤       ├─────────────────┤       ├─────────────┤
│ id (PK)     │──┐    │ id (PK)         │    ┌──│ id (PK)     │
│ email       │  │    │ user_id (FK)────│────┘  │ user_id     │
│ ...         │  └────│ book_id (FK)────│───────│ title       │
└─────────────┘       │ word            │       │ author      │
                      │ stem            │       │ asin        │
                      │ context         │       │ ...         │
                      │ lookup_timestamp│       └─────────────┘
                      │ content_hash    │
                      │ created_at      │       ┌─────────────────┐
                      │ updated_at      │       │ import_sessions │
                      │ deleted_at      │       ├─────────────────┤
                      │ last_synced_at  │       │ id (PK)         │
                      │ is_pending_sync │       │ user_id (FK)    │
                      │ version         │       │ source          │
                      └─────────────────┘       │ total_found     │
                                                │ imported        │
                                                │ skipped         │
                                                │ ...             │
                                                └─────────────────┘
```

## New Entity: Vocabulary

### Purpose
Stores vocabulary words looked up on Kindle via Vocabulary Builder. Each entry represents a single lookup event with the word, context sentence, and source book.

### Fields

| Field | Type | Nullable | Description |
|-------|------|----------|-------------|
| id | UUID | No | Primary key |
| user_id | UUID | No | Foreign key to users |
| book_id | UUID | Yes | Foreign key to books (nullable if book unknown) |
| word | VARCHAR(100) | No | The looked-up word |
| stem | VARCHAR(100) | Yes | Word stem/root form |
| context | TEXT | Yes | Context sentence where word was looked up |
| lookup_timestamp | TIMESTAMPTZ | Yes | When word was looked up on Kindle |
| content_hash | VARCHAR(64) | No | SHA-256 hash for deduplication |
| created_at | TIMESTAMPTZ | No | Record creation time |
| updated_at | TIMESTAMPTZ | No | Last modification time |
| deleted_at | TIMESTAMPTZ | Yes | Soft delete timestamp |
| last_synced_at | TIMESTAMPTZ | Yes | Last sync with cloud |
| is_pending_sync | BOOLEAN | No | Awaiting sync (default: false) |
| version | INTEGER | No | Optimistic locking (default: 1) |

### Indexes

```sql
-- Primary queries
CREATE INDEX idx_vocabulary_user_id ON vocabulary(user_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_vocabulary_user_book ON vocabulary(user_id, book_id);

-- Deduplication
CREATE UNIQUE INDEX idx_vocabulary_content_hash ON vocabulary(user_id, content_hash);

-- Sync queries
CREATE INDEX idx_vocabulary_pending_sync ON vocabulary(user_id, is_pending_sync) 
    WHERE is_pending_sync = true;

-- Sort by newest
CREATE INDEX idx_vocabulary_lookup_timestamp ON vocabulary(user_id, lookup_timestamp DESC);
```

### Validation Rules

1. **word**: Required, max 100 characters, trimmed
2. **context**: Optional, max 2000 characters
3. **content_hash**: Required, unique per user, generated from `word|context|book_title`
4. **lookup_timestamp**: Should be in the past

### State Transitions

```
[Created] ──sync──> [Synced] ──edit──> [Pending Sync] ──sync──> [Synced]
    │                   │                    │
    └───────────────────┴────────────────────┴──────delete──> [Deleted]
```

## Updated Entity: Books

### Changes
No schema changes required. Books table already supports vocabulary via the existing structure. Vocabulary entries reference books by `book_id`.

### Book Creation Flow
1. Parse vocab.db → extract book info
2. Check if book exists (by title + author for user)
3. If not, create new book record
4. Link vocabulary entry to book

## Updated Entity: ImportSession

### Changes
Add new source type for vocabulary imports.

| Change | Type | Description |
|--------|------|-------------|
| source | ENUM | Add 'vocab_db' to existing ('file', 'device') |

### Updated Enum

```sql
ALTER TYPE import_source ADD VALUE 'vocab_db';
```

## Mobile Schema (Drift)

### New Table: Vocabulary

```dart
class Vocabulary extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get bookId => text().nullable()();
  TextColumn get word => text().withLength(max: 100)();
  TextColumn get stem => text().withLength(max: 100).nullable()();
  TextColumn get context => text().nullable()();
  DateTimeColumn get lookupTimestamp => dateTime().nullable()();
  TextColumn get contentHash => text().withLength(max: 64)();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  BoolColumn get isPendingSync => boolean().withDefault(const Constant(false))();
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}
```

## Hash Generation

### Algorithm

```typescript
// Server-side (TypeScript)
function generateContentHash(word: string, context: string | null, bookTitle: string | null): string {
  const normalized = [
    word.toLowerCase().trim(),
    (context || '').trim(),
    (bookTitle || '').trim()
  ].join('|');
  
  return crypto.createHash('sha256').update(normalized).digest('hex');
}
```

```dart
// Client-side (Dart)
String generateContentHash(String word, String? context, String? bookTitle) {
  final normalized = [
    word.toLowerCase().trim(),
    (context ?? '').trim(),
    (bookTitle ?? '').trim(),
  ].join('|');
  
  return sha256.convert(utf8.encode(normalized)).toString();
}
```

## Migration Script

```sql
-- Migration: Add vocabulary table for 002-vocabulary-import-display
-- Date: 2026-01-26

-- Update import_source enum
ALTER TYPE import_source ADD VALUE IF NOT EXISTS 'vocab_db';

-- Create vocabulary table
CREATE TABLE vocabulary (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    book_id UUID REFERENCES books(id) ON DELETE SET NULL,
    word VARCHAR(100) NOT NULL,
    stem VARCHAR(100),
    context TEXT,
    lookup_timestamp TIMESTAMPTZ,
    content_hash VARCHAR(64) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    last_synced_at TIMESTAMPTZ,
    is_pending_sync BOOLEAN DEFAULT false,
    version INTEGER DEFAULT 1,
    UNIQUE(user_id, content_hash)
);

-- Indexes
CREATE INDEX idx_vocabulary_user_id ON vocabulary(user_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_vocabulary_user_book ON vocabulary(user_id, book_id);
CREATE INDEX idx_vocabulary_pending_sync ON vocabulary(user_id, is_pending_sync) 
    WHERE is_pending_sync = true;
CREATE INDEX idx_vocabulary_lookup_timestamp ON vocabulary(user_id, lookup_timestamp DESC);

-- Row Level Security
ALTER TABLE vocabulary ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can only access own vocabulary" ON vocabulary
    FOR ALL USING (auth.uid() = user_id);

-- Trigger for updated_at
CREATE TRIGGER update_vocabulary_updated_at
    BEFORE UPDATE ON vocabulary
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
```
