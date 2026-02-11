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
    console.log('[Mastery] OAuth: redirect URL:', redirectUrl);

    const { data, error } = await supabase.auth.signInWithOAuth({
      provider,
      options: {
        redirectTo: redirectUrl,
        skipBrowserRedirect: true,
      },
    });

    if (error) {
      console.error('[Mastery] OAuth: Supabase error:', error.message);
      return { error: error.message };
    }
    if (!data.url) {
      console.error('[Mastery] OAuth: No OAuth URL returned');
      return { error: 'No OAuth URL returned' };
    }

    console.log('[Mastery] OAuth: launching auth flow with URL:', data.url);

    const responseUrl = await browser.identity.launchWebAuthFlow({
      url: data.url,
      interactive: true,
    });

    console.log('[Mastery] OAuth: received response URL:', responseUrl);

    if (!responseUrl) {
      console.error('[Mastery] OAuth: flow cancelled');
      return { error: 'OAuth flow was cancelled' };
    }

    // Extract tokens from the callback URL hash fragment
    const hashParams = new URLSearchParams(new URL(responseUrl).hash.substring(1));
    const accessToken = hashParams.get('access_token');
    const refreshToken = hashParams.get('refresh_token');

    console.log('[Mastery] OAuth: token extraction -', {
      hasAccessToken: !!accessToken,
      hasRefreshToken: !!refreshToken,
    });

    if (!accessToken || !refreshToken) {
      console.error('[Mastery] OAuth: missing tokens in callback URL');
      return { error: 'No tokens found in OAuth callback' };
    }

    const { error: sessionError } = await supabase.auth.setSession({
      access_token: accessToken,
      refresh_token: refreshToken,
    });

    if (sessionError) {
      console.error('[Mastery] OAuth: session error:', sessionError.message);
      return { error: sessionError.message };
    }

    console.log('[Mastery] OAuth: sign-in successful');
    return {};
  } catch (err) {
    const errorMessage = err instanceof Error ? err.message : 'OAuth sign-in failed';
    console.error('[Mastery] OAuth: exception:', errorMessage, err);
    return { error: errorMessage };
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
