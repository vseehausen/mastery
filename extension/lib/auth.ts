import { getSupabaseClient } from './api-client';
import type { Session } from '@supabase/supabase-js';

export type OAuthProvider = 'google' | 'apple';

export async function signIn(email: string, password: string): Promise<{ error?: string }> {
  const supabase = getSupabaseClient();
  const { error } = await supabase.auth.signInWithPassword({ email, password });
  if (error) return { error: error.message };
  return {};
}

export async function signUp(email: string, password: string): Promise<{ error?: string }> {
  const supabase = getSupabaseClient();
  const { error } = await supabase.auth.signUp({ email, password });
  if (error) return { error: error.message };
  return {};
}

export async function signInWithOAuth(provider: OAuthProvider): Promise<{ error?: string }> {
  try {
    const supabase = getSupabaseClient();
    const redirectUrl = browser.identity.getRedirectURL();

    const { data, error } = await supabase.auth.signInWithOAuth({
      provider,
      options: {
        redirectTo: redirectUrl,
        skipBrowserRedirect: true,
      },
    });

    if (error) return { error: error.message };
    if (!data.url) return { error: 'No OAuth URL returned' };

    const responseUrl = await browser.identity.launchWebAuthFlow({
      url: data.url,
      interactive: true,
    });

    if (!responseUrl) return { error: 'OAuth flow was cancelled' };

    // Extract tokens from the callback URL hash fragment
    const hashParams = new URLSearchParams(new URL(responseUrl).hash.substring(1));
    const accessToken = hashParams.get('access_token');
    const refreshToken = hashParams.get('refresh_token');

    if (!accessToken || !refreshToken) {
      return { error: 'No tokens found in OAuth callback' };
    }

    const { error: sessionError } = await supabase.auth.setSession({
      access_token: accessToken,
      refresh_token: refreshToken,
    });

    if (sessionError) return { error: sessionError.message };
    return {};
  } catch (err) {
    return { error: err instanceof Error ? err.message : 'OAuth sign-in failed' };
  }
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
