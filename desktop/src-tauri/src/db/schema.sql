-- Desktop agent database schema
-- Matches the mobile Drift schema for consistency

-- Books table
CREATE TABLE IF NOT EXISTS books (
    id TEXT PRIMARY KEY NOT NULL,
    user_id TEXT NOT NULL,
    title TEXT NOT NULL,
    author TEXT,
    asin TEXT,
    language_id TEXT DEFAULT 'en',
    source TEXT DEFAULT 'kindle',
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now')),
    deleted_at TEXT,
    version INTEGER NOT NULL DEFAULT 1,
    is_pending_sync INTEGER NOT NULL DEFAULT 1,
    last_synced_at TEXT
);

CREATE INDEX IF NOT EXISTS idx_books_user_id ON books(user_id);
CREATE INDEX IF NOT EXISTS idx_books_title ON books(title);
CREATE UNIQUE INDEX IF NOT EXISTS idx_books_user_title_author ON books(user_id, title, author) WHERE deleted_at IS NULL;

-- Highlights table
CREATE TABLE IF NOT EXISTS highlights (
    id TEXT PRIMARY KEY NOT NULL,
    user_id TEXT NOT NULL,
    book_id TEXT NOT NULL REFERENCES books(id),
    content TEXT NOT NULL,
    type TEXT NOT NULL DEFAULT 'highlight',
    location TEXT,
    page INTEGER,
    kindle_date TEXT,
    note TEXT,
    content_hash TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now')),
    deleted_at TEXT,
    version INTEGER NOT NULL DEFAULT 1,
    is_pending_sync INTEGER NOT NULL DEFAULT 1,
    last_synced_at TEXT
);

CREATE INDEX IF NOT EXISTS idx_highlights_user_id ON highlights(user_id);
CREATE INDEX IF NOT EXISTS idx_highlights_book_id ON highlights(book_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_highlights_content_hash ON highlights(user_id, content_hash) WHERE deleted_at IS NULL;

-- Import sessions table
CREATE TABLE IF NOT EXISTS import_sessions (
    id TEXT PRIMARY KEY NOT NULL,
    user_id TEXT NOT NULL,
    source TEXT NOT NULL,
    filename TEXT,
    device_name TEXT,
    total_found INTEGER NOT NULL DEFAULT 0,
    imported INTEGER NOT NULL DEFAULT 0,
    skipped INTEGER NOT NULL DEFAULT 0,
    errors INTEGER NOT NULL DEFAULT 0,
    error_details TEXT,
    started_at TEXT NOT NULL DEFAULT (datetime('now')),
    completed_at TEXT
);

CREATE INDEX IF NOT EXISTS idx_import_sessions_user_id ON import_sessions(user_id);

-- Sync outbox for pending operations
CREATE TABLE IF NOT EXISTS sync_outbox (
    id TEXT PRIMARY KEY NOT NULL,
    entity_table TEXT NOT NULL,
    record_id TEXT NOT NULL,
    operation TEXT NOT NULL,
    payload TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    retry_count INTEGER NOT NULL DEFAULT 0,
    last_error TEXT
);

CREATE INDEX IF NOT EXISTS idx_sync_outbox_created_at ON sync_outbox(created_at);

-- User preferences
CREATE TABLE IF NOT EXISTS preferences (
    key TEXT PRIMARY KEY NOT NULL,
    value TEXT NOT NULL,
    updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- Sync state tracking
CREATE TABLE IF NOT EXISTS sync_state (
    id INTEGER PRIMARY KEY CHECK (id = 1),
    last_synced_at TEXT,
    last_sync_token TEXT
);

-- Initialize sync state with a single row
INSERT OR IGNORE INTO sync_state (id) VALUES (1);
