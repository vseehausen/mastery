/**
 * Authentication API for desktop app
 * Uses Tauri commands to interact with Rust backend
 */

import { invoke } from '@tauri-apps/api/core';
import { listen, type UnlistenFn } from '@tauri-apps/api/event';
import { openUrl } from '@tauri-apps/plugin-opener';

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

interface OAuthUrlResponse {
  url?: string;
  error?: string;
}

export type OAuthProvider = 'apple' | 'google';

export async function signUpWithEmail(email: string, password: string): Promise<AuthResponse> {
  try {
    return await invoke<AuthResponse>('auth_sign_up_with_email', { email, password });
  } catch (error) {
    return { success: false, error: String(error) };
  }
}

export async function signInWithEmail(email: string, password: string): Promise<AuthResponse> {
  try {
    return await invoke<AuthResponse>('auth_sign_in_with_email', { email, password });
  } catch (error) {
    return { success: false, error: String(error) };
  }
}

export async function signOut(): Promise<void> {
  await invoke('auth_sign_out');
}

export async function getSession(): Promise<AuthSession | null> {
  try {
    return await invoke<AuthSession | null>('auth_get_session');
  } catch {
    return null;
  }
}

export async function getCurrentUser(): Promise<User | null> {
  try {
    return await invoke<User | null>('auth_get_current_user');
  } catch {
    return null;
  }
}

export async function signInWithOAuth(provider: OAuthProvider): Promise<{ error?: string }> {
  try {
    const response = await invoke<OAuthUrlResponse>('auth_get_oauth_url', { provider });
    
    if (response.error || !response.url) {
      return { error: response.error || 'Failed to get OAuth URL' };
    }
    
    await openUrl(response.url);
    return {};
  } catch (error) {
    return { error: String(error) };
  }
}

export async function handleOAuthCallback(callbackUrl: string): Promise<AuthResponse> {
  try {
    return await invoke<AuthResponse>('auth_handle_oauth_callback', { callbackUrl });
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
