-- Migration: Add vocabulary and encounters tables
-- Date: 2026-01-26

-- Update import_source enum
ALTER TYPE import_source ADD VALUE IF NOT EXISTS 'vocab_db';

-- Create vocabulary table (word identity only)
CREATE TABLE vocabulary (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    word VARCHAR(100) NOT NULL,
    stem VARCHAR(100),
    content_hash VARCHAR(64) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    last_synced_at TIMESTAMPTZ,
    is_pending_sync BOOLEAN DEFAULT false,
    version INTEGER DEFAULT 1,
    UNIQUE(user_id, content_hash)
);

-- Encounters table - a vocabulary word seen in a source, with context
CREATE TABLE encounters (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    vocabulary_id UUID NOT NULL REFERENCES vocabulary(id) ON DELETE CASCADE,
    source_id UUID REFERENCES sources(id) ON DELETE SET NULL,
    context TEXT,
    locator_json TEXT,
    occurred_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    last_synced_at TIMESTAMPTZ,
    is_pending_sync BOOLEAN DEFAULT false,
    version INTEGER DEFAULT 1
);

-- Vocabulary indexes
CREATE INDEX idx_vocabulary_user_id ON vocabulary(user_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_vocabulary_pending_sync ON vocabulary(user_id, is_pending_sync)
    WHERE is_pending_sync = true;

-- Encounters indexes
CREATE INDEX idx_encounters_user_vocab ON encounters(user_id, vocabulary_id);
CREATE INDEX idx_encounters_user_source ON encounters(user_id, source_id);
CREATE INDEX idx_encounters_user_occurred ON encounters(user_id, occurred_at DESC);
CREATE INDEX idx_encounters_pending_sync ON encounters(user_id, is_pending_sync)
    WHERE is_pending_sync = true;

-- Row Level Security
ALTER TABLE vocabulary ENABLE ROW LEVEL SECURITY;
ALTER TABLE encounters ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can only access own vocabulary" ON vocabulary
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can only access own encounters" ON encounters
    FOR ALL USING (auth.uid() = user_id);

-- Triggers for updated_at
CREATE TRIGGER update_vocabulary_updated_at
    BEFORE UPDATE ON vocabulary
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER update_encounters_updated_at
    BEFORE UPDATE ON encounters
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
