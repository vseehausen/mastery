<script lang="ts">
  import { goto } from '$app/navigation';
  import { signUpWithEmail } from '$lib/api/auth';

  let email = $state('');
  let password = $state('');
  let confirmPassword = $state('');
  let isLoading = $state(false);
  let error = $state<string | null>(null);
  let showPassword = $state(false);
  let showConfirmPassword = $state(false);
  let signupComplete = $state(false);

  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

  function validateEmail(value: string): boolean {
    return emailRegex.test(value);
  }

  function validatePassword(value: string): boolean {
    return value.length >= 8;
  }

  function validateForm(): boolean {
    error = null;

    if (!validateEmail(email)) {
      error = 'Please enter a valid email address';
      return false;
    }

    if (!validatePassword(password)) {
      error = 'Password must be at least 8 characters';
      return false;
    }

    if (password !== confirmPassword) {
      error = 'Passwords do not match';
      return false;
    }

    return true;
  }

  async function handleSignUp() {
    if (!validateForm()) {
      return;
    }

    isLoading = true;

    try {
      const response = await signUpWithEmail(email.trim(), password);
      
      if (response.success) {
        signupComplete = true;
      } else {
        error = response.error || 'Sign up failed. Please try again.';
      }
    } catch (e) {
      error = e instanceof Error ? e.message : 'An error occurred. Please try again.';
    } finally {
      isLoading = false;
    }
  }

  function handleSignIn() {
    goto('/auth/sign-in');
  }
</script>

{#if signupComplete}
  <div class="auth-container">
    <div class="auth-card">
      <div class="success-content">
        <div class="success-icon">✓</div>
        <h1>Check Your Email</h1>
        <p>
          We sent a verification email to:<br />
          <strong>{email}</strong>
        </p>
        <p class="hint">
          Please click the link in the email to verify your account.
        </p>
        <button class="submit-button" onclick={handleSignIn}>
          Back to Sign In
        </button>
      </div>
    </div>
  </div>
{:else}
  <div class="auth-container">
    <div class="auth-card">
      <div class="auth-header">
        <h1>Join Mastery</h1>
        <p>Create an account to sync your highlights</p>
      </div>

      {#if error}
        <div class="error-message">
          <span class="error-icon">⚠️</span>
          <span>{error}</span>
        </div>
      {/if}

      <form onsubmit={(e) => { e.preventDefault(); handleSignUp(); }}>
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
              placeholder="At least 8 characters"
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

        <div class="form-group">
          <label for="confirmPassword">Confirm Password</label>
          <div class="password-input">
            <input
              id="confirmPassword"
              type={showConfirmPassword ? 'text' : 'password'}
              bind:value={confirmPassword}
              placeholder="Confirm your password"
              disabled={isLoading}
              required
            />
            <button
              type="button"
              class="toggle-password"
              onclick={() => showConfirmPassword = !showConfirmPassword}
              tabindex="-1"
            >
              {showConfirmPassword ? '👁️' : '👁️‍🗨️'}
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
            Creating account...
          {:else}
            Create Account
          {/if}
        </button>
      </form>

      <div class="auth-footer">
        <p>
          Already have an account?
          <button type="button" class="link-button" onclick={handleSignIn}>
            Sign In
          </button>
        </p>
      </div>
    </div>
  </div>
{/if}

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

  .success-content {
    text-align: center;
  }

  .success-icon {
    width: 64px;
    height: 64px;
    margin: 0 auto 1.5rem;
    background: #10b981;
    color: white;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 2rem;
    font-weight: bold;
  }

  .success-content h1 {
    margin: 0 0 1rem;
    font-size: 1.875rem;
    font-weight: 700;
    color: #1f2937;
  }

  .success-content p {
    margin: 0.5rem 0;
    color: #6b7280;
    font-size: 0.875rem;
  }

  .success-content .hint {
    font-size: 0.8125rem;
    color: #9ca3af;
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
    margin-top: 1.5rem;
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
</style>
