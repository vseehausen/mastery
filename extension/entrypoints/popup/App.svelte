<script lang="ts">
  import { onMount } from 'svelte';
  import { signIn, signOut } from '@/lib/auth';
  import { getSupabaseClient } from '@/lib/api-client';
  import { getPageWords } from '@/lib/cache';
  import type { Session } from '@supabase/supabase-js';
  import type { PageWord, StatsResponse } from '@/lib/types';

  let session: Session | null = $state(null);
  let loading = $state(true);
  let email = $state('');
  let password = $state('');
  let loginError = $state('');
  let loggingIn = $state(false);

  let totalWords = $state(0);
  let pageWords: PageWord[] = $state([]);

  const STAGE_COLORS: Record<string, string> = {
    new: '#3b82f6',
    practicing: '#f59e0b',
    stabilizing: '#f97316',
    known: '#10b981',
    mastered: '#8b5cf6',
  };

  onMount(async () => {
    const supabase = getSupabaseClient();
    const { data: { session: s } } = await supabase.auth.getSession();
    session = s;
    loading = false;

    if (session) {
      await loadStats();
    }

    supabase.auth.onAuthStateChange((_event, s) => {
      session = s;
      if (s) loadStats();
    });
  });

  async function loadStats() {
    try {
      // Get current tab URL
      const [tab] = await browser.tabs.query({ active: true, currentWindow: true });
      const tabUrl = tab?.url ?? '';

      // Load stats from edge function
      const supabase = getSupabaseClient();
      const params = tabUrl ? `?url=${encodeURIComponent(tabUrl)}` : '';
      const { data } = await supabase.functions.invoke(`lookup-word/batch-status${params}`, {
        method: 'GET',
      });

      if (data) {
        const stats = data as StatsResponse;
        totalWords = stats.total_words;
        pageWords = stats.page_words;
      }
    } catch (err) {
      console.error('[Mastery] Failed to load stats:', err);
    }
  }

  async function handleLogin() {
    loginError = '';
    loggingIn = true;
    const result = await signIn(email, password);
    loggingIn = false;
    if (result.error) {
      loginError = result.error;
    } else {
      password = '';
    }
  }

  async function handleLogout() {
    await signOut();
    session = null;
    totalWords = 0;
    pageWords = [];
  }
</script>

<main class="w-80 min-h-[200px]">
  {#if loading}
    <div class="flex items-center justify-center p-8">
      <span class="text-sm text-gray-400">Loading...</span>
    </div>
  {:else if !session}
    <!-- Login Form -->
    <div class="p-4 space-y-3">
      <h1 class="text-lg font-semibold text-gray-900">Mastery</h1>
      <p class="text-xs text-gray-500">Sign in to capture vocabulary</p>

      <form onsubmit={(e) => { e.preventDefault(); handleLogin(); }} class="space-y-2">
        <input
          type="email"
          bind:value={email}
          placeholder="Email"
          class="w-full px-3 py-2 text-sm border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
          required
        />
        <input
          type="password"
          bind:value={password}
          placeholder="Password"
          class="w-full px-3 py-2 text-sm border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
          required
        />
        {#if loginError}
          <p class="text-xs text-red-500">{loginError}</p>
        {/if}
        <button
          type="submit"
          disabled={loggingIn}
          class="w-full px-3 py-2 text-sm font-medium text-white bg-gray-900 rounded-lg hover:bg-gray-800 disabled:opacity-50"
        >
          {loggingIn ? 'Signing in...' : 'Sign in'}
        </button>
      </form>
    </div>
  {:else}
    <!-- Stats View -->
    <div class="p-4 space-y-4">
      <div class="flex items-center justify-between">
        <h1 class="text-lg font-semibold text-gray-900">Mastery</h1>
        <span class="text-xs font-medium text-gray-500 bg-gray-100 px-2 py-1 rounded-full">
          {totalWords} words
        </span>
      </div>

      {#if pageWords.length > 0}
        <div class="space-y-1">
          <h2 class="text-xs font-medium text-gray-400 uppercase tracking-wide">This page</h2>
          <ul class="space-y-1">
            {#each pageWords as word}
              <li class="flex items-center justify-between py-1 px-2 rounded-md hover:bg-gray-50">
                <div>
                  <span class="text-sm font-medium text-gray-900">{word.lemma}</span>
                  <span class="text-xs text-gray-400 ml-1">{word.translation}</span>
                </div>
                <span
                  class="text-[10px] font-medium px-1.5 py-0.5 rounded-full text-white capitalize"
                  style:background={STAGE_COLORS[word.stage] ?? '#718096'}
                >
                  {word.stage}
                </span>
              </li>
            {/each}
          </ul>
        </div>
      {:else}
        <p class="text-xs text-gray-400 text-center py-4">
          Double-click any word to look it up
        </p>
      {/if}

      <!-- Settings -->
      <div class="border-t border-gray-100 pt-3">
        <div class="flex items-center justify-between">
          <span class="text-xs text-gray-500 truncate">{session.user.email}</span>
          <button
            onclick={handleLogout}
            class="text-xs text-gray-400 hover:text-gray-600"
          >
            Sign out
          </button>
        </div>
      </div>
    </div>
  {/if}
</main>
