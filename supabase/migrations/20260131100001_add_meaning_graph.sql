-- Migration: Add meaning graph tables (005-meaning-graph)
-- Schema version: 5 → 6

-- =============================================================================
-- Meanings Table
-- Stores distinct senses for a vocabulary word. One vocabulary can have multiple meanings.
-- =============================================================================

CREATE TABLE IF NOT EXISTS meanings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    vocabulary_id UUID NOT NULL REFERENCES vocabulary(id) ON DELETE CASCADE,
    language_code VARCHAR(5) NOT NULL,
    primary_translation TEXT NOT NULL,
    alternative_translations JSONB NOT NULL DEFAULT '[]',
    english_definition TEXT NOT NULL,
    extended_definition TEXT,
    part_of_speech VARCHAR(20),
    synonyms JSONB NOT NULL DEFAULT '[]',
    confidence DOUBLE PRECISION NOT NULL DEFAULT 1.0,
    is_primary BOOLEAN NOT NULL DEFAULT FALSE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    sort_order INTEGER NOT NULL DEFAULT 0,
    source VARCHAR(20) NOT NULL DEFAULT 'ai',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    last_synced_at TIMESTAMPTZ,
    is_pending_sync BOOLEAN NOT NULL DEFAULT FALSE,
    version INTEGER NOT NULL DEFAULT 1
);

-- Indexes for meanings
CREATE INDEX IF NOT EXISTS idx_meanings_user_vocab ON meanings(user_id, vocabulary_id);
CREATE INDEX IF NOT EXISTS idx_meanings_user_active ON meanings(user_id, is_active);

-- RLS for meanings
ALTER TABLE meanings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own meanings"
    ON meanings FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own meanings"
    ON meanings FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own meanings"
    ON meanings FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own meanings"
    ON meanings FOR DELETE
    USING (auth.uid() = user_id);

-- =============================================================================
-- Cues Table
-- Pre-generated prompt triggers for learning sessions. Each cue belongs to one meaning.
-- =============================================================================

CREATE TABLE IF NOT EXISTS cues (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    meaning_id UUID NOT NULL REFERENCES meanings(id) ON DELETE CASCADE,
    cue_type VARCHAR(20) NOT NULL, -- 'translation', 'definition', 'synonym', 'context_cloze', 'disambiguation'
    prompt_text TEXT NOT NULL,
    answer_text TEXT NOT NULL,
    hint_text TEXT,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    last_synced_at TIMESTAMPTZ,
    is_pending_sync BOOLEAN NOT NULL DEFAULT FALSE,
    version INTEGER NOT NULL DEFAULT 1
);

-- Indexes for cues
CREATE INDEX IF NOT EXISTS idx_cues_meaning_type ON cues(meaning_id, cue_type);
CREATE INDEX IF NOT EXISTS idx_cues_user ON cues(user_id);

-- RLS for cues
ALTER TABLE cues ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own cues"
    ON cues FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own cues"
    ON cues FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own cues"
    ON cues FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own cues"
    ON cues FOR DELETE
    USING (auth.uid() = user_id);

-- =============================================================================
-- Confusable Sets Table
-- Groups of commonly confused words.
-- =============================================================================

CREATE TABLE IF NOT EXISTS confusable_sets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    language_code VARCHAR(5) NOT NULL,
    words JSONB NOT NULL,
    explanations JSONB NOT NULL,
    example_sentences JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    last_synced_at TIMESTAMPTZ,
    is_pending_sync BOOLEAN NOT NULL DEFAULT FALSE,
    version INTEGER NOT NULL DEFAULT 1
);

-- Indexes for confusable_sets
CREATE INDEX IF NOT EXISTS idx_confusable_sets_user ON confusable_sets(user_id);

-- RLS for confusable_sets
ALTER TABLE confusable_sets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own confusable sets"
    ON confusable_sets FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own confusable sets"
    ON confusable_sets FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own confusable sets"
    ON confusable_sets FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own confusable sets"
    ON confusable_sets FOR DELETE
    USING (auth.uid() = user_id);

-- =============================================================================
-- Confusable Set Members Table
-- Join table linking vocabulary to confusable sets.
-- =============================================================================

CREATE TABLE IF NOT EXISTS confusable_set_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    confusable_set_id UUID NOT NULL REFERENCES confusable_sets(id) ON DELETE CASCADE,
    vocabulary_id UUID NOT NULL REFERENCES vocabulary(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for confusable_set_members
CREATE UNIQUE INDEX IF NOT EXISTS idx_confusable_set_members_unique
    ON confusable_set_members(confusable_set_id, vocabulary_id);
CREATE INDEX IF NOT EXISTS idx_confusable_set_members_vocab
    ON confusable_set_members(vocabulary_id);

-- =============================================================================
-- Meaning Edits Table
-- Tracks user overrides of auto-generated data.
-- =============================================================================

CREATE TABLE IF NOT EXISTS meaning_edits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    meaning_id UUID NOT NULL REFERENCES meanings(id) ON DELETE CASCADE,
    field_name VARCHAR(50) NOT NULL,
    original_value TEXT NOT NULL,
    user_value TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for meaning_edits
CREATE INDEX IF NOT EXISTS idx_meaning_edits_meaning_field
    ON meaning_edits(meaning_id, field_name);

-- RLS for meaning_edits
ALTER TABLE meaning_edits ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own meaning edits"
    ON meaning_edits FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own meaning edits"
    ON meaning_edits FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- =============================================================================
-- Enrichment Queue Table (server-side only, not synced to mobile)
-- Tracks which vocabulary words need enrichment.
-- =============================================================================

CREATE TABLE IF NOT EXISTS enrichment_queue (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    vocabulary_id UUID NOT NULL REFERENCES vocabulary(id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL DEFAULT 'pending', -- 'pending', 'processing', 'completed', 'failed'
    priority INTEGER NOT NULL DEFAULT 0,
    attempts INTEGER NOT NULL DEFAULT 0,
    last_error TEXT,
    last_attempted_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for enrichment_queue
CREATE UNIQUE INDEX IF NOT EXISTS idx_enrichment_queue_user_vocab
    ON enrichment_queue(user_id, vocabulary_id);
CREATE INDEX IF NOT EXISTS idx_enrichment_queue_user_status_priority
    ON enrichment_queue(user_id, status, priority DESC);

-- RLS for enrichment_queue
ALTER TABLE enrichment_queue ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own enrichment queue"
    ON enrichment_queue FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own enrichment queue"
    ON enrichment_queue FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own enrichment queue"
    ON enrichment_queue FOR UPDATE
    USING (auth.uid() = user_id);

-- =============================================================================
-- Modify user_learning_preferences: add native_language_code and meaning_display_mode
-- =============================================================================

ALTER TABLE user_learning_preferences
    ADD COLUMN IF NOT EXISTS native_language_code VARCHAR(5) NOT NULL DEFAULT 'de';

ALTER TABLE user_learning_preferences
    ADD COLUMN IF NOT EXISTS meaning_display_mode VARCHAR(10) NOT NULL DEFAULT 'both';

-- =============================================================================
-- Add cue_type to review_logs for tracking which cue was used per review
-- =============================================================================

ALTER TABLE review_logs
    ADD COLUMN IF NOT EXISTS cue_type VARCHAR(20);
