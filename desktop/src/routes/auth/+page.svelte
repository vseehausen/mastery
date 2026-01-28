<script lang="ts">
  import { onMount, onDestroy } from 'svelte';
  import { goto } from '$app/navigation';
  import { signInWithOAuth, listenForOAuthCallback, type OAuthProvider } from '$lib/api/auth';
  import { Button } from '$lib/components/ui/button/index.js';
  import { Apple, Chrome, Mail } from 'lucide-svelte';

  let error = $state<string | null>(null);
  let unlistenOAuth: (() => void) | null = null;

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

  function handleEmailOption() {
    goto('/auth/email-sign-up');
  }
</script>

<div class="flex min-h-screen items-center justify-center bg-background p-8">
  <div class="w-full max-w-md space-y-6 rounded-xl border border-border bg-card p-8 shadow-lg">
    <!-- Header -->
    <div class="space-y-2 text-center">
      <div class="mx-auto flex h-12 w-12 items-center justify-center rounded-lg bg-primary">
        <span class="text-lg font-bold text-primary-foreground">K</span>
      </div>
      <h1 class="text-2xl font-semibold text-foreground">Welcome to Mastery</h1>
      <p class="text-sm text-muted-foreground">Your vocabulary shadow brain</p>
    </div>

    <!-- Error Message -->
    {#if error}
      <div class="rounded-lg border border-destructive/50 bg-destructive/10 p-3 text-sm text-destructive">
        {error}
      </div>
    {/if}

    <!-- OAuth Buttons -->
    <div class="space-y-3">
      <Button
        variant="outline"
        class="w-full"
        onclick={() => handleOAuthSignIn('apple')}
      >
        <Apple class="h-4 w-4" />
        Continue with Apple
      </Button>

      <Button
        variant="outline"
        class="w-full"
        onclick={() => handleOAuthSignIn('google')}
      >
        <Chrome class="h-4 w-4" />
        Continue with Google
      </Button>
    </div>

    <!-- Divider -->
    <div class="relative">
      <div class="absolute inset-0 flex items-center">
        <div class="w-full border-t border-border"></div>
      </div>
      <div class="relative flex justify-center text-xs uppercase">
        <span class="bg-card px-2 text-muted-foreground">or</span>
      </div>
    </div>

    <!-- Email Option -->
    <Button
      variant="outline"
      class="w-full"
      onclick={handleEmailOption}
    >
      <Mail class="h-4 w-4" />
      Continue with Email
    </Button>

    <!-- Terms of Service Note -->
    <p class="text-center text-xs text-muted-foreground">
      By continuing, you agree to our <button type="button" class="text-primary hover:underline">Terms of Service</button>
    </p>
  </div>
</div>
