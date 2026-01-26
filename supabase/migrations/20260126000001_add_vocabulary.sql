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
