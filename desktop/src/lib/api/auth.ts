import { supabase } from '$lib/supabase';
import { listen, type UnlistenFn } from '@tauri-apps/api/event';
import type { User as SupabaseUser } from '@supabase/supabase-js';

export interface AuthSession {
  accessToken: string;
  refreshToken: string;
  expiresAt: number;
  userId: string;
  email?: string;
}

export interface AuthResponse {
  success: boolean;
  session?: AuthSession;
  error?: string;
}

export interface User {
  id: string;
  email?: string;
  emailConfirmedAt?: string;
  createdAt: string;
  lastSignInAt?: string;
}

export type OAuthProvider = 'apple' | 'google';

function convertSupabaseUser(user: SupabaseUser): User {
  return {
    id: user.id,
    email: user.email,
    emailConfirmedAt: user.email_confirmed_at || undefined,
    createdAt: user.created_at,
    lastSignInAt: user.last_sign_in_at || undefined,
  };
}

function convertSupabaseSession(session: any): AuthSession | null {
  if (!session) return null;
  return {
    accessToken: session.access_token,
    refreshToken: session.refresh_token,
    expiresAt: session.expires_at || Math.floor(Date.now() / 1000) + 3600,
    userId: session.user?.id || '',
    email: session.user?.email,
  };
}

export async function signUpWithEmail(email: string, password: string): Promise<AuthResponse> {
  try {
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
    });

    if (error) {
      return { success: false, error: error.message };
    }

    if (!data.session) {
      return { success: false, error: 'Email confirmation required' };
    }

    return {
      success: true,
      session: convertSupabaseSession(data.session),
    };
  } catch (error) {
    return { success: false, error: String(error) };
  }
}

export async function signInWithEmail(email: string, password: string): Promise<AuthResponse> {
  try {
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });

    if (error) {
      return { success: false, error: error.message };
    }

    return {
      success: true,
      session: convertSupabaseSession(data.session),
    };
  } catch (error) {
    return { success: false, error: String(error) };
  }
}

export async function signOut(): Promise<void> {
  await supabase.auth.signOut();
}

export async function getSession(): Promise<AuthSession | null> {
  try {
    const { data } = await supabase.auth.getSession();
    return convertSupabaseSession(data.session);
  } catch {
    return null;
  }
}

export async function getCurrentUser(): Promise<User | null> {
  try {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return null;
    return convertSupabaseUser(user);
  } catch {
    return null;
  }
}

export async function signInWithOAuth(provider: OAuthProvider): Promise<{ error?: string }> {
  try {
    const { data, error } = await supabase.auth.signInWithOAuth({
      provider,
      options: {
        redirectTo: 'mastery://auth/callback',
        skipBrowserRedirect: true,
      },
    });

    if (error) {
      return { error: error.message };
    }

    if (data.url) {
      const { openUrl } = await import('@tauri-apps/plugin-opener');
      await openUrl(data.url);
    }

    return {};
  } catch (error) {
    return { error: String(error) };
  }
}

function extractTokensFromUrl(url: string): { accessToken?: string; refreshToken?: string; expiresAt?: number } {
  try {
    const parsed = new URL(url);
    const fragment = parsed.hash.substring(1);
    const params = new URLSearchParams(fragment);

    const accessToken = params.get('access_token') || undefined;
    const refreshToken = params.get('refresh_token') || undefined;
    const expiresAtStr = params.get('expires_at');
    const expiresAt = expiresAtStr ? parseInt(expiresAtStr, 10) : undefined;

    return { accessToken, refreshToken, expiresAt };
  } catch {
    return {};
  }
}

export async function handleOAuthCallback(callbackUrl: string): Promise<AuthResponse> {
  try {
    const tokens = extractTokensFromUrl(callbackUrl);

    if (!tokens.accessToken || !tokens.refreshToken) {
      return { success: false, error: 'No tokens found in callback URL' };
    }

    const { data, error } = await supabase.auth.setSession({
      access_token: tokens.accessToken,
      refresh_token: tokens.refreshToken,
    });

    if (error) {
      return { success: false, error: error.message };
    }

    return {
      success: true,
      session: convertSupabaseSession(data.session),
    };
  } catch (error) {
    return { success: false, error: String(error) };
  }
}

export async function listenForOAuthCallback(
  callback: (response: AuthResponse) => void
): Promise<UnlistenFn> {
  return listen<string>('oauth-callback', async (event) => {
    const response = await handleOAuthCallback(event.payload);
    callback(response);
  });
}

export function onAuthStateChange(callback: (session: AuthSession | null) => void): UnlistenFn {
  const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
    callback(convertSupabaseSession(session));
  });

  return () => {
    subscription.unsubscribe();
  };
}
