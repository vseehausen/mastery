-- Migration: Add enrichment feedback table
-- Stores user feedback (upvote/downvote/flag) on AI-generated meanings

-- =============================================================================
-- Enrichment Feedback Table
-- Captures user feedback on quality of AI-generated meanings and cues.
-- =============================================================================

CREATE TABLE IF NOT EXISTS enrichment_feedback (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    meaning_id UUID NOT NULL REFERENCES meanings(id) ON DELETE CASCADE,
    field_name VARCHAR(50) NOT NULL,
    rating VARCHAR(10) NOT NULL CHECK (rating IN ('up', 'down')),
    flag_category VARCHAR(30),
    comment TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for enrichment_feedback
CREATE INDEX IF NOT EXISTS idx_enrichment_feedback_user ON enrichment_feedback(user_id);
CREATE INDEX IF NOT EXISTS idx_enrichment_feedback_meaning ON enrichment_feedback(meaning_id);

-- RLS for enrichment_feedback
ALTER TABLE enrichment_feedback ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own enrichment feedback"
    ON enrichment_feedback FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own enrichment feedback"
    ON enrichment_feedback FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own enrichment feedback"
    ON enrichment_feedback FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own enrichment feedback"
    ON enrichment_feedback FOR DELETE
    USING (auth.uid() = user_id);
