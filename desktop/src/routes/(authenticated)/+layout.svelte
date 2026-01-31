<script lang="ts">
  import { onMount, onDestroy } from 'svelte';
  import { goto } from '$app/navigation';
  import { onAuthStateChange } from '$lib/api/auth';
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
    const { error } = await supabase.auth.signOut({ scope: 'local' });
    if (error) {
      console.error('Sign out error:', error);
    }
    // Always redirect - local session is cleared even if server call fails
    goto('/auth');
  }

  async function validateSession(): Promise<{ id: string; email?: string; fullName?: string } | null> {
    // Step 1: Check if we have a local session
    const { data: { session } } = await supabase.auth.getSession();
    if (!session) {
      console.log('No local session found');
      return null;
    }

    // Step 2: Validate with server by getting user (this makes a network call)
    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError || !user) {
      console.error('User validation failed:', userError?.message || 'No user returned');
      return null;
    }

    return {
      id: user.id,
      email: user.email,
      fullName: (user.user_metadata?.full_name as string | undefined) || undefined,
    };
  }

  onMount(async () => {
    try {
      const user = await validateSession();
      
      if (!user) {
        console.log('Session invalid, signing out');
        await supabase.auth.signOut({ scope: 'local' });
        goto('/auth');
        return;
      }

      currentUser = user;

      // Subscribe to auth state changes
      unlistenAuth = onAuthStateChange(async (session) => {
        if (session) {
          const validatedUser = await validateSession();
          if (validatedUser) {
            currentUser = validatedUser;
          } else {
            console.log('Session became invalid, signing out');
            await supabase.auth.signOut({ scope: 'local' });
            goto('/auth');
          }
        } else {
          currentUser = null;
          goto('/auth');
        }
      });
    } catch (error) {
      console.error('Auth check failed:', error);
      await supabase.auth.signOut({ scope: 'local' });
      goto('/auth');
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
