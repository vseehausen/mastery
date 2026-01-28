<script lang="ts">
  import { goto } from '$app/navigation';
  import { signInWithEmail } from '$lib/api/auth';
  import { Button } from '$lib/components/ui/button/index.js';
  import { Input } from '$lib/components/ui/input/index.js';
  import { Label } from '$lib/components/ui/label/index.js';
  import { ArrowLeft, Loader2 } from 'lucide-svelte';

  let email = $state('');
  let password = $state('');
  let isLoading = $state(false);
  let error = $state<string | null>(null);

  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

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

  function handleBack() {
    goto('/auth');
  }

  function handleSignUp() {
    goto('/auth/email-sign-up');
  }
</script>

<div class="flex min-h-screen items-center justify-center bg-background p-8">
  <div class="w-full max-w-md space-y-6 rounded-xl border border-border bg-card p-8 shadow-lg">
    <!-- Back Button -->
    <button
      type="button"
      class="flex items-center gap-2 text-sm text-muted-foreground hover:text-foreground"
      onclick={handleBack}
      disabled={isLoading}
    >
      <ArrowLeft class="h-4 w-4" />
      Other sign in options
    </button>

    <!-- Header -->
    <div class="space-y-2 text-center">
      <div class="mx-auto flex h-12 w-12 items-center justify-center rounded-lg bg-primary">
        <span class="text-lg font-bold text-primary-foreground">K</span>
      </div>
      <h1 class="text-2xl font-semibold text-foreground">Welcome back</h1>
      <p class="text-sm text-muted-foreground">Sign in with your email</p>
    </div>

    <!-- Error Message -->
    {#if error}
      <div class="rounded-lg border border-destructive/50 bg-destructive/10 p-3 text-sm text-destructive">
        {error}
      </div>
    {/if}

    <!-- Form -->
    <form onsubmit={(e) => { e.preventDefault(); handleSignIn(); }} class="space-y-4">
      <div class="space-y-2">
        <Label for="email">Email</Label>
        <Input
          id="email"
          type="email"
          bind:value={email}
          placeholder="your@email.com"
          disabled={isLoading}
          required
        />
      </div>

      <div class="space-y-2">
        <Label for="password">Password</Label>
        <Input
          id="password"
          type="password"
          bind:value={password}
          placeholder="Enter your password"
          disabled={isLoading}
          required
        />
      </div>

      <Button type="submit" class="w-full" disabled={isLoading}>
        {#if isLoading}
          <Loader2 class="h-4 w-4 animate-spin" />
          Signing in...
        {:else}
          Sign In
        {/if}
      </Button>
    </form>

    <!-- Sign Up Link -->
    <div class="text-center text-sm text-muted-foreground">
      Don't have an account?
      <button
        type="button"
        class="font-medium text-primary hover:underline"
        onclick={handleSignUp}
        disabled={isLoading}
      >
        Sign up
      </button>
    </div>
  </div>
</div>
