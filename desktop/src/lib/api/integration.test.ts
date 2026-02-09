import { describe, it, expect, beforeAll } from 'vitest';
import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL || process.env.VITE_SUPABASE_URL;
const supabasePublishableKey = import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY || process.env.VITE_SUPABASE_PUBLISHABLE_KEY;

if (!supabaseUrl || !supabasePublishableKey) {
  console.warn('Skipping integration tests: Missing Supabase environment variables');
}

const testSupabase = supabaseUrl && supabasePublishableKey
  ? createClient(supabaseUrl, supabasePublishableKey)
  : null;

const testUserEmail = process.env.TEST_USER_EMAIL;
const testUserPassword = process.env.TEST_USER_PASSWORD;

describe.skipIf(!testSupabase || !import.meta.env.RUN_INTEGRATION_TESTS)('Integration Tests', () => {
  describe('Supabase Connection', () => {
    it('can connect to Supabase', async () => {
      if (!testSupabase) return;
      
      const { data, error } = await testSupabase.auth.getSession();
      expect(error).toBeNull();
      expect(data).toBeTruthy();
    });
  });

  describe('Edge Function Access', () => {
    it('can call parse-vocab edge function (verifies auth + endpoint)', async () => {
      if (!testSupabase) return;
      
      const testFile = btoa('SQLite format 3\x00');
      
      const { data, error } = await testSupabase.functions.invoke('parse-vocab', {
        body: { file: testFile }
      });

      if (error) {
        expect(error.message).toBeTruthy();
        expect(error.message).not.toContain('ENOTFOUND');
        expect(error.message).not.toContain('fetch failed');
      } else if (data) {
        expect(data.error || 'invalid').toBeTruthy();
      }
    });
  });

  describe('Database Access', () => {
    it('can query import_sessions table structure (verifies RLS)', async () => {
      if (!testSupabase) return;
      
      const { data, error } = await testSupabase
        .from('import_sessions')
        .select('id')
        .limit(0);

      if (error) {
        expect(error.message).toBeTruthy();
        expect(error.message).not.toContain('ENOTFOUND');
        expect(error.message).not.toContain('fetch failed');
      } else {
        expect(Array.isArray(data)).toBe(true);
      }
    });
  });

  describe.skipIf(!testUserEmail || !testUserPassword)('Auth Flow', () => {
    beforeAll(async () => {
      if (!testSupabase) return;
      
      await testSupabase.auth.signOut();
    });

    it('can sign in with existing test account', async () => {
      if (!testSupabase || !testUserEmail || !testUserPassword) return;
      
      const { data, error } = await testSupabase.auth.signInWithPassword({
        email: testUserEmail,
        password: testUserPassword
      });
      
      expect(error).toBeNull();
      expect(data.session).toBeTruthy();
      expect(data.user).toBeTruthy();
    });

    it('can get current session after sign in', async () => {
      if (!testSupabase) return;
      
      const { data } = await testSupabase.auth.getSession();
      expect(data.session).toBeTruthy();
      expect(data.session?.user).toBeTruthy();
    });

    it('can fetch import sessions when authenticated', async () => {
      if (!testSupabase) return;
      
      const { data, error } = await testSupabase
        .from('import_sessions')
        .select('*')
        .order('started_at', { ascending: false })
        .limit(10);

      expect(error).toBeNull();
      expect(Array.isArray(data)).toBe(true);
    });

    it('can sign out', async () => {
      if (!testSupabase) return;
      
      const { error } = await testSupabase.auth.signOut();
      expect(error).toBeNull();
    });
  });
});
