-- Migration: Add usage_examples JSONB column to global_dictionary
-- Date: 2026-02-13
--
-- Required by get_session_cards RPC (20260214000000) which selects gd.usage_examples

ALTER TABLE global_dictionary
  ADD COLUMN IF NOT EXISTS usage_examples JSONB DEFAULT '[]'::jsonb;
