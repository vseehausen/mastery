-- Migration: Initial schema for Mastery
-- Date: 2026-01-24

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA extensions;

-- Create custom types
CREATE TYPE source_type AS ENUM ('book', 'website', 'document', 'manual');
CREATE TYPE import_source AS ENUM ('file', 'device');

-- Languages table
CREATE TABLE languages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(5) UNIQUE NOT NULL,
    name VARCHAR(50) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Seed English language
INSERT INTO languages (code, name) VALUES ('en', 'English');

-- Users profile table (extends auth.users)
CREATE TABLE users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email VARCHAR(255) UNIQUE NOT NULL,
    language_id UUID REFERENCES languages(id),
    auto_sync_enabled BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Sources table - origin container (book, website, document, manual)
CREATE TABLE sources (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type source_type NOT NULL,
    title VARCHAR(500) NOT NULL,
    author VARCHAR(255),
    asin VARCHAR(20),
    url TEXT,
    domain VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    last_synced_at TIMESTAMPTZ,
    is_pending_sync BOOLEAN DEFAULT false,
    version INTEGER DEFAULT 1,
    UNIQUE(user_id, type, title, author)
);

-- Import sessions table
CREATE TABLE import_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
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
CREATE INDEX idx_sources_user_id ON sources(user_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_sources_user_type_title ON sources(user_id, type, title);
CREATE INDEX idx_sources_pending_sync ON sources(user_id, is_pending_sync) WHERE is_pending_sync = true;
CREATE INDEX idx_import_sessions_user_id ON import_sessions(user_id);

-- Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE sources ENABLE ROW LEVEL SECURITY;
ALTER TABLE import_sessions ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can only access own profile" ON users
    FOR ALL USING (auth.uid() = id);

CREATE POLICY "Users can only access own sources" ON sources
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can only access own import sessions" ON import_sessions
    FOR ALL USING (auth.uid() = user_id);

-- Function to auto-create user profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users (id, email)
    VALUES (NEW.id, NEW.email);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create profile on auth.users insert
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER update_sources_updated_at
    BEFORE UPDATE ON sources
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
