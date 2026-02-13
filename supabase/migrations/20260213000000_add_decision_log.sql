CREATE TABLE decision_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    event_type TEXT NOT NULL,
    data JSONB NOT NULL DEFAULT '{}',
    app_version TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_decision_log_user_time ON decision_log(user_id, created_at DESC);
CREATE INDEX idx_decision_log_event_type ON decision_log(event_type, created_at DESC);

-- RLS: users can insert and read their own logs
ALTER TABLE decision_log ENABLE ROW LEVEL SECURITY;
CREATE POLICY "insert_own" ON decision_log FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "select_own" ON decision_log FOR SELECT USING (auth.uid() = user_id);
