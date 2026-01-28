<script lang="ts">
  import { onMount, onDestroy } from 'svelte';
  import { goto } from '$app/navigation';
  import { getCurrentUser, onAuthStateChange } from '$lib/api/auth';
  import { supabase } from '$lib/supabase';
  import Sidebar from '$lib/components/Sidebar.svelte';
  import { Loader2 } from 'lucide-svelte';
  import type { Snippet } from 'svelte';

  interface Props {
    children: Snippet;
  }

  let { children }: Props = $props();
  let currentUser = $state<{ id: string; email?: string; fullName?: string } | null>(null);
  let isLoading = $state(true);
  let unlistenAuth: (() => void) | null = null;

  async function handleSignOut() {
    const { error } = await supabase.auth.signOut();
    if (error) {
      console.error('Sign out error:', error);
    } else {
      goto('/auth/sign-in');
    }
  }

  onMount(async () => {
    try {
      const { data: { session } } = await supabase.auth.getSession();
      const user = await getCurrentUser();

      if (!session || !user) {
        goto('/auth/sign-in');
        return;
      }

      currentUser = user;

      // Subscribe to auth state changes
      unlistenAuth = onAuthStateChange((session) => {
        if (session) {
          getCurrentUser().then(user => {
            currentUser = user;
          });
        } else {
          currentUser = null;
          goto('/auth/sign-in');
        }
      });
    } finally {
      isLoading = false;
    }
  });

  onDestroy(() => {
    if (unlistenAuth) {
      unlistenAuth();
    }
  });
</script>

{#if isLoading}
  <div class="flex h-screen items-center justify-center">
    <Loader2 class="h-8 w-8 animate-spin text-primary" />
  </div>
{:else}
  <div class="flex h-screen">
    <Sidebar user={currentUser} onSignOut={handleSignOut} />
    <main class="flex-1 overflow-auto">
      {@render children()}
    </main>
  </div>
{/if}
