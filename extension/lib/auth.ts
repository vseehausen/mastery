import { getSupabaseClient } from './api-client';
import type { Session } from '@supabase/supabase-js';

export async function signIn(email: string, password: string): Promise<{ error?: string }> {
  const supabase = getSupabaseClient();
  const { error } = await supabase.auth.signInWithPassword({ email, password });
  if (error) return { error: error.message };
  return {};
}

export async function signOut(): Promise<void> {
  const supabase = getSupabaseClient();
  await supabase.auth.signOut();
}

export async function getSession(): Promise<Session | null> {
  const supabase = getSupabaseClient();
  const { data: { session } } = await supabase.auth.getSession();
  return session;
}

export async function isAuthenticated(): Promise<boolean> {
  const session = await getSession();
  const isAuthed = session !== null;
  console.log('[Mastery] isAuthenticated check:', isAuthed, session ? `user: ${session.user.email}` : 'no session');
  return isAuthed;
}

export function onAuthStateChange(callback: (session: Session | null) => void): () => void {
  const supabase = getSupabaseClient();
  const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
    callback(session);
  });
  return () => subscription.unsubscribe();
}
