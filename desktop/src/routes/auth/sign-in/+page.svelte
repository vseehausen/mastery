<script lang="ts">
  import { onMount, onDestroy } from 'svelte';
  import { goto } from '$app/navigation';
  import { signInWithEmail, signInWithOAuth, listenForOAuthCallback, type OAuthProvider } from '$lib/api/auth';

  let email = $state('');
  let password = $state('');
  let isLoading = $state(false);
  let error = $state<string | null>(null);
  let showPassword = $state(false);
  let unlistenOAuth: (() => void) | null = null;

  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

  onMount(async () => {
    // Listen silently for OAuth callback events
    unlistenOAuth = await listenForOAuthCallback((response) => {
      if (response.success && response.session) {
        window.location.href = '/';
      } else if (response.error) {
        error = response.error;
      }
    });
  });

  onDestroy(() => {
    if (unlistenOAuth) unlistenOAuth();
  });

  function validateEmail(value: string): boolean {
    return emailRegex.test(value);
  }

  function validatePassword(value: string): boolean {
    return value.length >= 8;
  }

  async function handleSignIn() {
    error = null;

    if (!validateEmail(email)) {
      error = 'Please enter a valid email address';
      return;
    }

    if (!validatePassword(password)) {
      error = 'Password must be at least 8 characters';
      return;
    }

    isLoading = true;

    try {
      const response = await signInWithEmail(email.trim(), password);
      
      if (response.success && response.session) {
        window.location.href = '/';
      } else {
        error = response.error || 'Sign in failed. Please try again.';
      }
    } catch (e) {
      error = e instanceof Error ? e.message : 'An error occurred. Please try again.';
    } finally {
      isLoading = false;
    }
  }

  async function handleOAuthSignIn(provider: OAuthProvider) {
    error = null;
    try {
      const result = await signInWithOAuth(provider);
      if (result.error) {
        error = result.error;
      }
      // Browser opens, callback listener handles the rest
    } catch (e) {
      error = e instanceof Error ? e.message : 'OAuth sign in failed';
    }
  }

  function handleSignUp() {
    goto('/auth/sign-up');
  }
</script>

<div class="auth-container">
  <div class="auth-card">
    <div class="auth-header">
      <h1>Welcome to Mastery</h1>
      <p>Sign in to continue</p>
    </div>

    {#if error}
      <div class="error-message">
        <span class="error-icon">⚠️</span>
        <span>{error}</span>
      </div>
    {/if}

    <form onsubmit={(e) => { e.preventDefault(); handleSignIn(); }}>
      <div class="form-group">
        <label for="email">Email</label>
        <input
          id="email"
          type="email"
          bind:value={email}
          placeholder="your@email.com"
          disabled={isLoading}
          required
        />
      </div>

      <div class="form-group">
        <label for="password">Password</label>
        <div class="password-input">
          <input
            id="password"
            type={showPassword ? 'text' : 'password'}
            bind:value={password}
            placeholder="Enter your password"
            disabled={isLoading}
            required
          />
          <button
            type="button"
            class="toggle-password"
            onclick={() => showPassword = !showPassword}
            tabindex="-1"
          >
            {showPassword ? '👁️' : '👁️‍🗨️'}
          </button>
        </div>
      </div>

      <button
        type="submit"
        class="submit-button"
        disabled={isLoading}
      >
        {#if isLoading}
          <span class="spinner"></span>
          Signing in...
        {:else}
          Sign In
        {/if}
      </button>
    </form>

    <!-- OAuth divider -->
    <div class="divider">
      <span>Or continue with</span>
    </div>

    <!-- OAuth buttons -->
    <div class="oauth-buttons">
      <button
        type="button"
        class="oauth-button apple"
        onclick={() => handleOAuthSignIn('apple')}
        disabled={isLoading}
      >
        <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
          <path d="M17.05 20.28c-.98.95-2.05.8-3.08.35-1.09-.46-2.09-.48-3.24 0-1.44.62-2.2.44-3.06-.35C2.79 15.25 3.51 7.59 9.05 7.31c1.35.07 2.29.74 3.08.8 1.18-.24 2.31-.93 3.57-.84 1.51.12 2.65.72 3.4 1.8-3.12 1.87-2.38 5.98.48 7.13-.57 1.5-1.31 2.99-2.54 4.09l.01-.01zM12.03 7.25c-.15-2.23 1.66-4.07 3.74-4.25.29 2.58-2.34 4.5-3.74 4.25z"/>
        </svg>
        Apple
      </button>
      <button
        type="button"
        class="oauth-button google"
        onclick={() => handleOAuthSignIn('google')}
        disabled={isLoading}
      >
        <svg width="20" height="20" viewBox="0 0 24 24">
          <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
          <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
          <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
          <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
        </svg>
        Google
      </button>
    </div>

    <div class="auth-footer">
      <p>
        Don't have an account?
        <button type="button" class="link-button" onclick={handleSignUp}>
          Sign Up
        </button>
      </p>
    </div>
  </div>
</div>

<style>
  .auth-container {
    display: flex;
    align-items: center;
    justify-content: center;
    min-height: 100vh;
    padding: 2rem;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  }

  .auth-card {
    background: white;
    border-radius: 12px;
    padding: 2.5rem;
    width: 100%;
    max-width: 400px;
    box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
  }

  .auth-header {
    text-align: center;
    margin-bottom: 2rem;
  }

  .auth-header h1 {
    margin: 0 0 0.5rem;
    font-size: 1.875rem;
    font-weight: 700;
    color: #1f2937;
  }

  .auth-header p {
    margin: 0;
    color: #6b7280;
    font-size: 0.875rem;
  }

  .error-message {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    padding: 0.75rem 1rem;
    background: #fef2f2;
    border: 1px solid #fca5a5;
    border-radius: 6px;
    color: #991b1b;
    font-size: 0.875rem;
    margin-bottom: 1.5rem;
  }

  .error-icon {
    font-size: 1rem;
  }

  .form-group {
    margin-bottom: 1.25rem;
  }

  .form-group label {
    display: block;
    margin-bottom: 0.5rem;
    font-size: 0.875rem;
    font-weight: 500;
    color: #374151;
  }

  .form-group input {
    width: 100%;
    padding: 0.75rem;
    border: 1px solid #d1d5db;
    border-radius: 6px;
    font-size: 1rem;
    transition: border-color 0.2s;
  }

  .form-group input:focus {
    outline: none;
    border-color: #8b5cf6;
    box-shadow: 0 0 0 3px rgba(139, 92, 246, 0.1);
  }

  .form-group input:disabled {
    background: #f3f4f6;
    cursor: not-allowed;
  }

  .password-input {
    position: relative;
  }

  .password-input input {
    padding-right: 3rem;
  }

  .toggle-password {
    position: absolute;
    right: 0.75rem;
    top: 50%;
    transform: translateY(-50%);
    background: none;
    border: none;
    cursor: pointer;
    font-size: 1.25rem;
    padding: 0.25rem;
    color: #6b7280;
  }

  .toggle-password:hover {
    color: #374151;
  }

  .submit-button {
    width: 100%;
    padding: 0.875rem;
    background: #8b5cf6;
    color: white;
    border: none;
    border-radius: 6px;
    font-size: 1rem;
    font-weight: 600;
    cursor: pointer;
    transition: background 0.2s;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 0.5rem;
  }

  .submit-button:hover:not(:disabled) {
    background: #7c3aed;
  }

  .submit-button:disabled {
    background: #a78bfa;
    cursor: not-allowed;
  }

  .spinner {
    width: 18px;
    height: 18px;
    border: 2px solid rgba(255, 255, 255, 0.3);
    border-top-color: white;
    border-radius: 50%;
    animation: spin 0.8s linear infinite;
  }

  @keyframes spin {
    to { transform: rotate(360deg); }
  }

  .auth-footer {
    margin-top: 1.5rem;
    text-align: center;
    font-size: 0.875rem;
    color: #6b7280;
  }

  .link-button {
    background: none;
    border: none;
    color: #8b5cf6;
    cursor: pointer;
    font-weight: 600;
    text-decoration: underline;
    padding: 0;
    margin-left: 0.25rem;
  }

  .link-button:hover {
    color: #7c3aed;
  }

  .divider {
    display: flex;
    align-items: center;
    margin: 1.5rem 0;
    color: #6b7280;
    font-size: 0.875rem;
  }

  .divider::before,
  .divider::after {
    content: '';
    flex: 1;
    border-bottom: 1px solid #e5e7eb;
  }

  .divider span {
    padding: 0 1rem;
  }

  .oauth-buttons {
    display: flex;
    gap: 0.75rem;
  }

  .oauth-button {
    flex: 1;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 0.5rem;
    padding: 0.75rem;
    border-radius: 6px;
    font-size: 0.875rem;
    font-weight: 500;
    cursor: pointer;
    transition: all 0.2s;
  }

  .oauth-button:disabled {
    opacity: 0.6;
    cursor: not-allowed;
  }

  .oauth-button.apple {
    background: #000;
    color: white;
    border: 1px solid #000;
  }

  .oauth-button.apple:hover:not(:disabled) {
    background: #1a1a1a;
  }

  .oauth-button.google {
    background: white;
    color: #374151;
    border: 1px solid #d1d5db;
  }

  .oauth-button.google:hover:not(:disabled) {
    background: #f9fafb;
    border-color: #9ca3af;
  }
</style>
