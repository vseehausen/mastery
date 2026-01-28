import { describe, it, expect, vi, beforeEach } from 'vitest';
import { signInWithEmail, signUpWithEmail, signOut, getSession, getCurrentUser } from './auth';

vi.mock('$lib/supabase', () => ({
  supabase: {
    auth: {
      signInWithPassword: vi.fn(),
      signUp: vi.fn(),
      signOut: vi.fn(),
      getSession: vi.fn(),
      getUser: vi.fn(),
      onAuthStateChange: vi.fn(() => ({
        data: { subscription: { unsubscribe: vi.fn() } }
      })),
    }
  }
}));

describe('auth API', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('signInWithEmail calls supabase.auth.signInWithPassword', async () => {
    const { supabase } = await import('$lib/supabase');
    vi.mocked(supabase.auth.signInWithPassword).mockResolvedValue({
      data: {
        user: { id: '123', email: 'test@example.com' },
        session: {
          access_token: 'token',
          refresh_token: 'refresh',
          expires_at: 1234567890,
          user: { id: '123', email: 'test@example.com' }
        }
      },
      error: null
    });

    const result = await signInWithEmail('test@example.com', 'password');
    expect(supabase.auth.signInWithPassword).toHaveBeenCalledWith({
      email: 'test@example.com',
      password: 'password'
    });
    expect(result.success).toBe(true);
    expect(result.error).toBeUndefined();
  });

  it('signInWithEmail returns error on invalid credentials', async () => {
    const { supabase } = await import('$lib/supabase');
    vi.mocked(supabase.auth.signInWithPassword).mockResolvedValue({
      data: { user: null, session: null },
      error: { message: 'Invalid credentials', status: 400 }
    });

    const result = await signInWithEmail('test@example.com', 'wrong');
    expect(result.success).toBe(false);
    expect(result.error).toBeTruthy();
  });

  it('signUpWithEmail calls supabase.auth.signUp', async () => {
    const { supabase } = await import('$lib/supabase');
    vi.mocked(supabase.auth.signUp).mockResolvedValue({
      data: {
        user: { id: '123', email: 'test@example.com' },
        session: {
          access_token: 'token',
          refresh_token: 'refresh',
          expires_at: 1234567890,
          user: { id: '123', email: 'test@example.com' }
        }
      },
      error: null
    });

    const result = await signUpWithEmail('test@example.com', 'password');
    expect(supabase.auth.signUp).toHaveBeenCalledWith({
      email: 'test@example.com',
      password: 'password'
    });
    expect(result.success).toBe(true);
  });

  it('signOut clears session', async () => {
    const { supabase } = await import('$lib/supabase');
    vi.mocked(supabase.auth.signOut).mockResolvedValue({ error: null });

    await signOut();
    expect(supabase.auth.signOut).toHaveBeenCalled();
  });

  it('getSession returns session when available', async () => {
    const { supabase } = await import('$lib/supabase');
    vi.mocked(supabase.auth.getSession).mockResolvedValue({
      data: {
        session: {
          access_token: 'token',
          refresh_token: 'refresh',
          expires_at: 1234567890,
          user: { id: '123', email: 'test@example.com' }
        }
      },
      error: null
    });

    const session = await getSession();
    expect(session).toBeTruthy();
    expect(session?.accessToken).toBe('token');
  });

  it('getCurrentUser returns user when available', async () => {
    const { supabase } = await import('$lib/supabase');
    vi.mocked(supabase.auth.getUser).mockResolvedValue({
      data: {
        user: {
          id: '123',
          email: 'test@example.com',
          created_at: '2024-01-01',
        }
      },
      error: null
    });

    const user = await getCurrentUser();
    expect(user).toBeTruthy();
    expect(user?.id).toBe('123');
    expect(user?.email).toBe('test@example.com');
  });
});
