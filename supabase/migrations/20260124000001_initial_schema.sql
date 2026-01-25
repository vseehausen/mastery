-- Migration: Initial schema for Kindle Import feature
-- Date: 2026-01-24

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA extensions;

-- Create custom types
CREATE TYPE highlight_type AS ENUM ('highlight', 'note');
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

-- Books table
CREATE TABLE books (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
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

-- Highlights table
CREATE TABLE highlights (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    book_id UUID NOT NULL REFERENCES books(id) ON DELETE CASCADE,
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
CREATE INDEX idx_books_user_title ON books(user_id, title);
CREATE INDEX idx_books_user_id ON books(user_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_highlights_user_book ON highlights(user_id, book_id);
CREATE INDEX idx_highlights_content_hash ON highlights(user_id, content_hash);
CREATE INDEX idx_highlights_user_id ON highlights(user_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_import_sessions_user_id ON import_sessions(user_id);

-- Full-text search index
CREATE INDEX idx_highlights_fts ON highlights USING gin(to_tsvector('english', content));

-- Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE books ENABLE ROW LEVEL SECURITY;
ALTER TABLE highlights ENABLE ROW LEVEL SECURITY;
ALTER TABLE import_sessions ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can only access own profile" ON users
    FOR ALL USING (auth.uid() = id);

CREATE POLICY "Users can only access own books" ON books
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can only access own highlights" ON highlights
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

-- Function to update highlight count on books
CREATE OR REPLACE FUNCTION public.update_book_highlight_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE books SET highlight_count = highlight_count + 1, updated_at = NOW()
        WHERE id = NEW.book_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE books SET highlight_count = highlight_count - 1, updated_at = NOW()
        WHERE id = OLD.book_id;
    ELSIF TG_OP = 'UPDATE' AND OLD.deleted_at IS NULL AND NEW.deleted_at IS NOT NULL THEN
        -- Soft delete
        UPDATE books SET highlight_count = highlight_count - 1, updated_at = NOW()
        WHERE id = NEW.book_id;
    ELSIF TG_OP = 'UPDATE' AND OLD.deleted_at IS NOT NULL AND NEW.deleted_at IS NULL THEN
        -- Restore
        UPDATE books SET highlight_count = highlight_count + 1, updated_at = NOW()
        WHERE id = NEW.book_id;
    END IF;
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for highlight count
CREATE TRIGGER on_highlight_change
    AFTER INSERT OR UPDATE OR DELETE ON highlights
    FOR EACH ROW EXECUTE FUNCTION public.update_book_highlight_count();

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

CREATE TRIGGER update_books_updated_at
    BEFORE UPDATE ON books
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER update_highlights_updated_at
    BEFORE UPDATE ON highlights
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
