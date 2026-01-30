-- Migration: Add learning feature tables (004-calm-srs-learning)
-- Schema version: 3 → 4

-- =============================================================================
-- Learning Cards Table
-- One row per vocabulary item that enters the learning system
-- =============================================================================

CREATE TABLE IF NOT EXISTS learning_cards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    vocabulary_id UUID NOT NULL,
    state INTEGER NOT NULL DEFAULT 0, -- 0=new, 1=learning, 2=review, 3=relearning
    due TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    stability DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    difficulty DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    reps INTEGER NOT NULL DEFAULT 0,
    lapses INTEGER NOT NULL DEFAULT 0,
    last_review TIMESTAMPTZ,
    is_leech BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    last_synced_at TIMESTAMPTZ,
    is_pending_sync BOOLEAN NOT NULL DEFAULT FALSE,
    version INTEGER NOT NULL DEFAULT 1
);

-- Indexes for learning_cards
CREATE INDEX IF NOT EXISTS idx_learning_cards_user_due ON learning_cards(user_id, due);
CREATE INDEX IF NOT EXISTS idx_learning_cards_user_state ON learning_cards(user_id, state);
CREATE INDEX IF NOT EXISTS idx_learning_cards_user_leech ON learning_cards(user_id, is_leech);

-- RLS for learning_cards
ALTER TABLE learning_cards ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own learning cards"
    ON learning_cards FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own learning cards"
    ON learning_cards FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own learning cards"
    ON learning_cards FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own learning cards"
    ON learning_cards FOR DELETE
    USING (auth.uid() = user_id);

-- =============================================================================
-- Review Logs Table
-- Append-only log of every review interaction
-- =============================================================================

CREATE TABLE IF NOT EXISTS review_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    learning_card_id UUID NOT NULL REFERENCES learning_cards(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL, -- 1=again, 2=hard, 3=good, 4=easy
    interaction_mode INTEGER NOT NULL, -- 0=recognition, 1=recall
    state_before INTEGER NOT NULL,
    state_after INTEGER NOT NULL,
    stability_before DOUBLE PRECISION NOT NULL,
    stability_after DOUBLE PRECISION NOT NULL,
    difficulty_before DOUBLE PRECISION NOT NULL,
    difficulty_after DOUBLE PRECISION NOT NULL,
    response_time_ms INTEGER NOT NULL,
    retrievability_at_review DOUBLE PRECISION NOT NULL,
    reviewed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    session_id UUID,
    is_pending_sync BOOLEAN NOT NULL DEFAULT FALSE
);

-- Indexes for review_logs
CREATE INDEX IF NOT EXISTS idx_review_logs_card ON review_logs(learning_card_id);
CREATE INDEX IF NOT EXISTS idx_review_logs_user_reviewed ON review_logs(user_id, reviewed_at);
CREATE INDEX IF NOT EXISTS idx_review_logs_session ON review_logs(session_id);

-- RLS for review_logs
ALTER TABLE review_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own review logs"
    ON review_logs FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own review logs"
    ON review_logs FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- No update/delete policies - review logs are append-only

-- =============================================================================
-- Learning Sessions Table
-- Tracks each time-boxed practice session
-- =============================================================================

CREATE TABLE IF NOT EXISTS learning_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL,
    planned_minutes INTEGER NOT NULL,
    elapsed_seconds INTEGER NOT NULL DEFAULT 0,
    bonus_seconds INTEGER NOT NULL DEFAULT 0,
    items_presented INTEGER NOT NULL DEFAULT 0,
    items_completed INTEGER NOT NULL DEFAULT 0,
    new_words_presented INTEGER NOT NULL DEFAULT 0,
    reviews_presented INTEGER NOT NULL DEFAULT 0,
    accuracy_rate DOUBLE PRECISION,
    avg_response_time_ms INTEGER,
    outcome INTEGER NOT NULL DEFAULT 0, -- 0=in_progress, 1=complete, 2=partial, 3=expired
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_pending_sync BOOLEAN NOT NULL DEFAULT FALSE
);

-- Indexes for learning_sessions
CREATE INDEX IF NOT EXISTS idx_learning_sessions_user_started ON learning_sessions(user_id, started_at);
CREATE INDEX IF NOT EXISTS idx_learning_sessions_user_outcome ON learning_sessions(user_id, outcome);

-- RLS for learning_sessions
ALTER TABLE learning_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own learning sessions"
    ON learning_sessions FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own learning sessions"
    ON learning_sessions FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own learning sessions"
    ON learning_sessions FOR UPDATE
    USING (auth.uid() = user_id);

-- =============================================================================
-- User Learning Preferences Table
-- One row per user with learning settings
-- =============================================================================

CREATE TABLE IF NOT EXISTS user_learning_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    daily_time_target_minutes INTEGER NOT NULL DEFAULT 10,
    target_retention DOUBLE PRECISION NOT NULL DEFAULT 0.90,
    intensity INTEGER NOT NULL DEFAULT 1, -- 0=light, 1=normal, 2=intense
    new_word_suppression_active BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_synced_at TIMESTAMPTZ,
    is_pending_sync BOOLEAN NOT NULL DEFAULT FALSE
);

-- RLS for user_learning_preferences
ALTER TABLE user_learning_preferences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own preferences"
    ON user_learning_preferences FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own preferences"
    ON user_learning_preferences FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own preferences"
    ON user_learning_preferences FOR UPDATE
    USING (auth.uid() = user_id);

-- =============================================================================
-- Streaks Table
-- Tracks current and longest streak per user
-- =============================================================================

CREATE TABLE IF NOT EXISTS streaks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    current_count INTEGER NOT NULL DEFAULT 0,
    longest_count INTEGER NOT NULL DEFAULT 0,
    last_completed_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_synced_at TIMESTAMPTZ,
    is_pending_sync BOOLEAN NOT NULL DEFAULT FALSE
);

-- RLS for streaks
ALTER TABLE streaks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own streak"
    ON streaks FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own streak"
    ON streaks FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own streak"
    ON streaks FOR UPDATE
    USING (auth.uid() = user_id);

-- =============================================================================
-- Add foreign key constraint for session_id in review_logs
-- =============================================================================

ALTER TABLE review_logs
    ADD CONSTRAINT fk_review_logs_session
    FOREIGN KEY (session_id)
    REFERENCES learning_sessions(id)
    ON DELETE SET NULL;
