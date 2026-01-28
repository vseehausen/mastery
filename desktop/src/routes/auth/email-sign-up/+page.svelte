<script lang="ts">
  import { goto } from '$app/navigation';
  import { signUpWithEmail } from '$lib/api/auth';
  import { Button } from '$lib/components/ui/button/index.js';
  import { Input } from '$lib/components/ui/input/index.js';
  import { Label } from '$lib/components/ui/label/index.js';
  import { ArrowLeft, Loader2, CheckCircle } from 'lucide-svelte';

  let fullName = $state('');
  let email = $state('');
  let password = $state('');
  let isLoading = $state(false);
  let error = $state<string | null>(null);
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

    if (!fullName.trim()) {
      error = 'Please enter your full name';
      return false;
    }

    if (!validateEmail(email)) {
      error = 'Please enter a valid email address';
      return false;
    }

    if (!validatePassword(password)) {
      error = 'Password must be at least 8 characters';
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
      const response = await signUpWithEmail(email.trim(), password, fullName.trim());

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

  function handleBack() {
    goto('/auth');
  }

  function handleSignIn() {
    goto('/auth/email-sign-in');
  }
</script>

<div class="flex min-h-screen items-center justify-center bg-background p-8">
  <div class="w-full max-w-md space-y-6 rounded-xl border border-border bg-card p-8 shadow-lg">
    {#if signupComplete}
      <!-- Success State -->
      <div class="space-y-6 text-center">
        <div class="flex justify-center">
          <div class="rounded-full bg-accent p-4">
            <CheckCircle class="h-8 w-8 text-accent-foreground" />
          </div>
        </div>
        <div class="space-y-2">
          <h1 class="text-2xl font-semibold text-foreground">Check Your Email</h1>
          <p class="text-sm text-muted-foreground">
            We sent a verification link to<br />
            <span class="font-medium text-foreground">{email}</span>
          </p>
          <p class="text-xs text-muted-foreground">
            Click the link to verify your account and get started.
          </p>
        </div>
      </div>
    {:else}
      <!-- Sign Up Form -->
      <div>
        <!-- Back Button -->
        <button
          type="button"
          class="flex items-center gap-2 text-sm text-muted-foreground hover:text-foreground"
          onclick={handleBack}
          disabled={isLoading}
        >
          <ArrowLeft class="h-4 w-4" />
          Other sign up options
        </button>
      </div>

      <!-- Header -->
      <div class="space-y-2 text-center">
        <div class="mx-auto flex h-12 w-12 items-center justify-center rounded-lg bg-primary">
          <span class="text-lg font-bold text-primary-foreground">K</span>
        </div>
        <h1 class="text-2xl font-semibold text-foreground">Create Account</h1>
        <p class="text-sm text-muted-foreground">Sign up with your email</p>
      </div>

      <!-- Error Message -->
      {#if error}
        <div class="rounded-lg border border-destructive/50 bg-destructive/10 p-3 text-sm text-destructive">
          {error}
        </div>
      {/if}

      <!-- Form -->
      <form onsubmit={(e) => { e.preventDefault(); handleSignUp(); }} class="space-y-4">
        <div class="space-y-2">
          <Label for="fullName">Full Name</Label>
          <Input
            id="fullName"
            type="text"
            bind:value={fullName}
            placeholder="John Doe"
            disabled={isLoading}
            required
          />
        </div>

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
            placeholder="At least 8 characters"
            disabled={isLoading}
            required
          />
        </div>

        <Button type="submit" class="w-full" disabled={isLoading}>
          {#if isLoading}
            <Loader2 class="h-4 w-4 animate-spin" />
            Creating account...
          {:else}
            Create Account
          {/if}
        </Button>
      </form>

      <!-- Sign In Link -->
      <div class="text-center text-sm text-muted-foreground">
        Already have an account?
        <button
          type="button"
          class="font-medium text-primary hover:underline"
          onclick={handleSignIn}
          disabled={isLoading}
        >
          Sign in
        </button>
      </div>
    {/if}
  </div>
</div>
