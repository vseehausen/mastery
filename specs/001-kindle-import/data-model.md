# Data Model: Kindle Import

**Feature**: 001-kindle-import
**Date**: 2026-01-24

## Entity Relationship Diagram

```
┌─────────────┐       ┌─────────────┐       ┌─────────────┐
│   Language  │       │    User     │       │    Book     │
├─────────────┤       ├─────────────┤       ├─────────────┤
│ id (PK)     │       │ id (PK)     │       │ id (PK)     │
│ code        │       │ email       │       │ title       │
│ name        │       │ createdAt   │       │ author      │
│ createdAt   │◄──────│ languageId  │       │ asin        │
└─────────────┘       │ autoSync    │       │ userId (FK) │
                      └──────┬──────┘       │ languageId  │
                             │              │ createdAt   │
                             │              │ updatedAt   │
                             │              └──────┬──────┘
                             │                     │
                             │    ┌────────────────┘
                             │    │
                             ▼    ▼
                      ┌─────────────────┐
                      │    Highlight    │
                      ├─────────────────┤
                      │ id (PK)         │
                      │ userId (FK)     │
                      │ bookId (FK)     │
                      │ content         │
                      │ type            │
                      │ location        │
                      │ page            │
                      │ kindleDate      │
                      │ note            │
                      │ context         │
                      │ contentHash     │
                      │ createdAt       │
                      │ updatedAt       │
                      │ deletedAt       │
                      │ lastSyncedAt    │
                      │ isPendingSync   │
                      └────────┬────────┘
                               │
                               │
                      ┌────────▼────────┐
                      │  ImportSession  │
                      ├─────────────────┤
                      │ id (PK)         │
                      │ userId (FK)     │
                      │ source          │
                      │ filename        │
                      │ totalFound      │
                      │ imported        │
                      │ skipped         │
                      │ errors          │
                      │ startedAt       │
                      │ completedAt     │
                      └─────────────────┘
```

---

## Entities

### 1. Language

Supported languages for vocabulary learning. English created at initialization.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | PK | Unique identifier |
| `code` | String(5) | UNIQUE, NOT NULL | ISO 639-1 code (e.g., "en", "es") |
| `name` | String(50) | NOT NULL | Display name (e.g., "English") |
| `createdAt` | DateTime | NOT NULL | When language was added |

**Seed Data**:
```json
{ "id": "uuid", "code": "en", "name": "English", "createdAt": "2026-01-24T00:00:00Z" }
```

---

### 2. User

Account owner with preferences.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | PK | Supabase Auth user ID |
| `email` | String(255) | UNIQUE, NOT NULL | User email |
| `languageId` | UUID | FK → Language | Default learning language |
| `autoSyncEnabled` | Boolean | DEFAULT true | Desktop auto-import preference |
| `createdAt` | DateTime | NOT NULL | Account creation time |
| `updatedAt` | DateTime | NOT NULL | Last profile update |

**Notes**:
- `id` comes from Supabase Auth (not auto-generated)
- Profile stored in `public.users` table, linked to `auth.users`

---

### 3. Book

A source containing highlights.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | PK | Unique identifier |
| `userId` | UUID | FK → User, NOT NULL | Owner |
| `languageId` | UUID | FK → Language | Content language |
| `title` | String(500) | NOT NULL | Book title |
| `author` | String(255) | NULL | Author name(s) |
| `asin` | String(20) | NULL, UNIQUE per user | Amazon ASIN if available |
| `highlightCount` | Integer | DEFAULT 0 | Cached count |
| `createdAt` | DateTime | NOT NULL | First import time |
| `updatedAt` | DateTime | NOT NULL | Last modification |
| `deletedAt` | DateTime | NULL | Soft delete timestamp |
| `lastSyncedAt` | DateTime | NULL | Last cloud sync |
| `isPendingSync` | Boolean | DEFAULT false | Needs sync |

**Indexes**:
- `idx_book_user_title` on (userId, title)
- `idx_book_pending_sync` on (userId, isPendingSync)

**Uniqueness**:
- Unique constraint on (userId, title, author) to prevent duplicates

---

### 4. Highlight

A text passage marked by the user.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | PK | Unique identifier |
| `userId` | UUID | FK → User, NOT NULL | Owner |
| `bookId` | UUID | FK → Book, NOT NULL | Source book |
| `content` | Text | NOT NULL | Highlighted text |
| `type` | Enum | NOT NULL | 'highlight' or 'note' |
| `location` | String(50) | NULL | Kindle location (e.g., "1234-1256") |
| `page` | Integer | NULL | Page number if available |
| `kindleDate` | DateTime | NULL | Original highlight date from Kindle |
| `note` | Text | NULL | User's personal note |
| `context` | Text | NULL | Surrounding sentence (future) |
| `contentHash` | String(64) | NOT NULL | SHA-256 for duplicate detection |
| `createdAt` | DateTime | NOT NULL | Import time |
| `updatedAt` | DateTime | NOT NULL | Last edit time |
| `deletedAt` | DateTime | NULL | Soft delete timestamp |
| `lastSyncedAt` | DateTime | NULL | Last cloud sync |
| `isPendingSync` | Boolean | DEFAULT false | Needs sync |
| `version` | Integer | DEFAULT 1 | For conflict resolution |

**Indexes**:
- `idx_highlight_user_book` on (userId, bookId)
- `idx_highlight_content_hash` on (userId, contentHash)
- `idx_highlight_pending_sync` on (userId, isPendingSync)
- `idx_highlight_fts` - FTS5 index on content

**Constraints**:
- Unique constraint on (userId, contentHash) to prevent duplicates

**Type Enum**:
```sql
CREATE TYPE highlight_type AS ENUM ('highlight', 'note');
```

---

### 5. ImportSession

Record of an import operation.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | PK | Unique identifier |
| `userId` | UUID | FK → User, NOT NULL | Who imported |
| `source` | Enum | NOT NULL | 'file' or 'device' |
| `filename` | String(255) | NULL | Original filename |
| `deviceName` | String(100) | NULL | Kindle device name if device import |
| `totalFound` | Integer | NOT NULL | Total entries in file |
| `imported` | Integer | NOT NULL | New highlights added |
| `skipped` | Integer | NOT NULL | Duplicates skipped |
| `errors` | Integer | DEFAULT 0 | Parse errors |
| `errorDetails` | JSON | NULL | Array of error messages |
| `startedAt` | DateTime | NOT NULL | Import start time |
| `completedAt` | DateTime | NULL | Import completion time |

**Source Enum**:
```sql
CREATE TYPE import_source AS ENUM ('file', 'device');
```

---

### 6. SyncOutbox (Local Only)

Queue for pending sync operations. Exists only in local SQLite.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | Integer | PK, AUTO | Local sequence |
| `tableName` | String(50) | NOT NULL | 'books' or 'highlights' |
| `recordId` | UUID | NOT NULL | Entity ID |
| `operation` | Enum | NOT NULL | 'insert', 'update', 'delete' |
| `payload` | JSON | NOT NULL | Serialized entity data |
| `createdAt` | DateTime | NOT NULL | When queued |
| `retryCount` | Integer | DEFAULT 0 | Failed attempts |
| `lastError` | Text | NULL | Last error message |

---

## State Transitions

### Highlight Lifecycle

```
┌─────────┐     Import      ┌──────────┐
│ (none)  │ ───────────────►│  Active  │
└─────────┘                 └────┬─────┘
                                 │
                    ┌────────────┼────────────┐
                    │            │            │
                    ▼            ▼            ▼
               ┌────────┐  ┌─────────┐  ┌──────────┐
               │  Edit  │  │ Add Note│  │  Delete  │
               └───┬────┘  └────┬────┘  └────┬─────┘
                   │            │            │
                   └────────────┼────────────┘
                                │
                                ▼
                         ┌────────────┐
                         │   Active   │ (updatedAt changed)
                         │   or       │
                         │  Deleted   │ (deletedAt set)
                         └────────────┘
```

### Sync States

```
┌──────────────┐    Local change    ┌─────────────────┐
│   Synced     │ ──────────────────►│ isPendingSync   │
│              │                    │ = true          │
└──────────────┘                    └────────┬────────┘
       ▲                                     │
       │                                     │
       │           Sync success              │
       └─────────────────────────────────────┘
              (isPendingSync = false,
               lastSyncedAt = now)
```

---

## Validation Rules

### Book
- Title: 1-500 characters, required
- Author: 0-255 characters, optional

### Highlight
- Content: 1-10000 characters, required
- Location: Valid format "NNNN" or "NNNN-NNNN"
- Page: Positive integer or null
- ContentHash: SHA-256 hex string (64 chars)

### ImportSession
- TotalFound >= Imported + Skipped + Errors
- CompletedAt >= StartedAt (if set)

---

## Database Migrations

### PostgreSQL (Supabase)

```sql
-- Migration 001: Initial schema
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TYPE highlight_type AS ENUM ('highlight', 'note');
CREATE TYPE import_source AS ENUM ('file', 'device');

CREATE TABLE languages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code VARCHAR(5) UNIQUE NOT NULL,
    name VARCHAR(50) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE users (
    id UUID PRIMARY KEY REFERENCES auth.users(id),
    email VARCHAR(255) UNIQUE NOT NULL,
    language_id UUID REFERENCES languages(id),
    auto_sync_enabled BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE books (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id),
    language_id UUID REFERENCES languages(id),
    title VARCHAR(500) NOT NULL,
    author VARCHAR(255),
    asin VARCHAR(20),
    highlight_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    last_synced_at TIMESTAMPTZ,
    UNIQUE(user_id, title, author)
);

CREATE TABLE highlights (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id),
    book_id UUID NOT NULL REFERENCES books(id),
    content TEXT NOT NULL,
    type highlight_type NOT NULL,
    location VARCHAR(50),
    page INTEGER,
    kindle_date TIMESTAMPTZ,
    note TEXT,
    context TEXT,
    content_hash VARCHAR(64) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    last_synced_at TIMESTAMPTZ,
    version INTEGER DEFAULT 1,
    UNIQUE(user_id, content_hash)
);

CREATE TABLE import_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id),
    source import_source NOT NULL,
    filename VARCHAR(255),
    device_name VARCHAR(100),
    total_found INTEGER NOT NULL,
    imported INTEGER NOT NULL,
    skipped INTEGER NOT NULL,
    errors INTEGER DEFAULT 0,
    error_details JSONB,
    started_at TIMESTAMPTZ NOT NULL,
    completed_at TIMESTAMPTZ
);

-- Indexes
CREATE INDEX idx_books_user_title ON books(user_id, title);
CREATE INDEX idx_highlights_user_book ON highlights(user_id, book_id);
CREATE INDEX idx_highlights_content_hash ON highlights(user_id, content_hash);
CREATE INDEX idx_highlights_fts ON highlights USING gin(to_tsvector('english', content));

-- Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE books ENABLE ROW LEVEL SECURITY;
ALTER TABLE highlights ENABLE ROW LEVEL SECURITY;
ALTER TABLE import_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can only access own data" ON users
    FOR ALL USING (auth.uid() = id);

CREATE POLICY "Users can only access own books" ON books
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can only access own highlights" ON highlights
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can only access own import sessions" ON import_sessions
    FOR ALL USING (auth.uid() = user_id);

-- Seed English language
INSERT INTO languages (code, name) VALUES ('en', 'English');
```

---

## Drift Schema (Flutter/SQLite)

```dart
// lib/data/database/tables.dart

class Languages extends Table {
  TextColumn get id => text()();
  TextColumn get code => text().withLength(max: 5)();
  TextColumn get name => text().withLength(max: 50)();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Books extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get languageId => text().nullable()();
  TextColumn get title => text().withLength(max: 500)();
  TextColumn get author => text().withLength(max: 255).nullable()();
  TextColumn get asin => text().withLength(max: 20).nullable()();
  IntColumn get highlightCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  BoolColumn get isPendingSync => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class Highlights extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get bookId => text()();
  TextColumn get content => text()();
  TextColumn get type => text()(); // 'highlight' or 'note'
  TextColumn get location => text().nullable()();
  IntColumn get page => integer().nullable()();
  DateTimeColumn get kindleDate => dateTime().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get context => text().nullable()();
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

class ImportSessions extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get source => text()(); // 'file' or 'device'
  TextColumn get filename => text().nullable()();
  TextColumn get deviceName => text().nullable()();
  IntColumn get totalFound => integer()();
  IntColumn get imported => integer()();
  IntColumn get skipped => integer()();
  IntColumn get errors => integer().withDefault(const Constant(0))();
  TextColumn get errorDetails => text().nullable()(); // JSON array
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class SyncOutbox extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get tableName => text()();
  TextColumn get recordId => text()();
  TextColumn get operation => text()(); // insert, update, delete
  TextColumn get payload => text()(); // JSON
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
}
```
