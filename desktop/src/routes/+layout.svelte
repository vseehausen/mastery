<script lang="ts">
  import { onMount, onDestroy } from 'svelte';
  import { goto } from '$app/navigation';
  import { supabase } from '$lib/supabase';
  import { listen } from '@tauri-apps/api/event';
  import { handleOAuthCallback } from '$lib/api/auth';
  import type { Snippet } from 'svelte';
  import '../app.css';
  
  interface Props {
    children: Snippet;
  }
  
  let { children }: Props = $props();
  let unlistenOAuth: (() => void) | null = null;

  onMount(async () => {
    // Listen for OAuth deep link callbacks
    unlistenOAuth = await listen<string>('oauth-callback', async (event) => {
      const callbackUrl = event.payload;
      const response = await handleOAuthCallback(callbackUrl);
      
      if (response.success) {
        goto('/');
      } else {
        console.error('OAuth callback error:', response.error);
      }
    });

    // Listen for auth state changes
    const { data: { subscription } } = supabase.auth.onAuthStateChange((event, session) => {
      if (event === 'SIGNED_OUT' || (event === 'TOKEN_REFRESHED' && !session)) {
        goto('/auth');
      }
    });

    onDestroy(() => {
      subscription.unsubscribe();
    });
  });

  onDestroy(() => {
    if (unlistenOAuth) {
      unlistenOAuth();
    }
  });
</script>

{@render children()}
