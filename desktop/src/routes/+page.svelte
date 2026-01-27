<script lang="ts">
  import { onMount, onDestroy } from 'svelte';
  import { goto } from '$app/navigation';
  import { checkKindleStatus, type KindleStatus } from '$lib/api/kindle';
  import { importFromKindle, type ImportResult } from '$lib/api/vocab';
  import { signOut, getCurrentUser, getSession } from '$lib/api/auth';
  import ImportHistory from '$lib/components/ImportHistory.svelte';

  let status = $state<KindleStatus>({ connected: false, connectionType: null });
  let importing = $state(false);
  let lastResult = $state<ImportResult | null>(null);
  let error = $state<string | null>(null);
  let historyComponent = $state<ImportHistory | null>(null);
  let pollInterval: ReturnType<typeof setInterval>;
  let currentUser = $state<{ id: string; email?: string } | null>(null);
  let isLoading = $state(true);
  let isAuthenticated = $state(false);

  async function checkAuthAndLoadUser() {
    const session = await getSession();
    const user = await getCurrentUser();
    
    if (session && user) {
      isAuthenticated = true;
      currentUser = user;
    } else {
      isAuthenticated = false;
      currentUser = null;
      goto('/auth/sign-in');
    }
    isLoading = false;
  }

  async function handleSignOut() {
    try {
      await signOut();
      goto('/auth/sign-in');
    } catch (e) {
      console.error('Sign out error:', e);
    }
  }

  async function pollStatus() {
    try {
      status = await checkKindleStatus();
    } catch (e) {
      console.error('Failed to check Kindle status:', e);
    }
  }

  async function handleImport() {
    importing = true;
    error = null;
    lastResult = null;
    
    try {
      lastResult = await importFromKindle();
      historyComponent?.refresh();
    } catch (e) {
      error = e instanceof Error ? e.message : String(e);
    } finally {
      importing = false;
    }
  }

  onMount(async () => {
    await checkAuthAndLoadUser();
    if (isAuthenticated) {
      pollStatus();
      pollInterval = setInterval(pollStatus, 3000);
    }
  });

  onDestroy(() => {
    if (pollInterval) clearInterval(pollInterval);
  });
</script>

{#if isLoading}
  <div class="loading-container">
    <div class="spinner-large"></div>
    <p>Loading...</p>
  </div>
{:else if isAuthenticated}
<main class="container">
  <div class="header-row">
    <div>
      <h1>Mastery</h1>
      <p class="subtitle">Import vocabulary from your Kindle</p>
    </div>
    {#if currentUser}
      <div class="user-info">
        <span class="user-email">{currentUser.email || 'User'}</span>
        <button class="sign-out-button" onclick={handleSignOut}>Sign Out</button>
      </div>
    {/if}
  </div>

  <div class="status-card">
    <div class="connection-row">
      <div class="status-indicator" class:connected={status.connected}></div>
      <div class="status-text">
        {#if status.connected}
          <span class="connected-text">Kindle Connected</span>
          <span class="connection-type">via {status.connectionType === 'mounted' ? 'USB' : 'MTP'}</span>
        {:else}
          <span class="disconnected-text">Kindle Not Connected</span>
          <span class="hint">Connect your Kindle via USB</span>
        {/if}
      </div>
    </div>

    {#if status.connected}
      <button 
        class="import-button" 
        onclick={handleImport} 
        disabled={importing}
      >
        {#if importing}
          <span class="spinner"></span>
          Importing...
        {:else}
          Import Vocabulary
        {/if}
      </button>
    {/if}

    {#if lastResult}
      <div class="result-card success">
        <div class="result-header">Import Complete</div>
        <div class="result-stats">
          <div class="stat">
            <span class="stat-value">{lastResult.imported}</span>
            <span class="stat-label">imported</span>
          </div>
          <div class="stat">
            <span class="stat-value">{lastResult.skipped}</span>
            <span class="stat-label">skipped</span>
          </div>
          <div class="stat">
            <span class="stat-value">{lastResult.books}</span>
            <span class="stat-label">books</span>
          </div>
        </div>
        {#if lastResult.error}
          <p class="result-warning">{lastResult.error}</p>
        {/if}
      </div>
    {/if}

    {#if error}
      <div class="result-card error">
        <div class="result-header">Import Failed</div>
        <p class="error-text">{error}</p>
      </div>
    {/if}
  </div>

  <ImportHistory bind:this={historyComponent} />
</main>
{/if}

<style>
  .loading-container {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    min-height: 100vh;
    color: #6b7280;
  }

  .spinner-large {
    width: 40px;
    height: 40px;
    border: 4px solid #e5e7eb;
    border-top-color: #8b5cf6;
    border-radius: 50%;
    animation: spin 1s linear infinite;
    margin-bottom: 1rem;
  }

  .container {
    padding: 2rem;
    max-width: 500px;
    margin: 0 auto;
  }

  .header-row {
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    margin-bottom: 1rem;
  }

  .user-info {
    display: flex;
    flex-direction: column;
    align-items: flex-end;
    gap: 0.5rem;
  }

  .user-email {
    font-size: 0.875rem;
    color: #6b7280;
  }

  .sign-out-button {
    padding: 0.5rem 1rem;
    background: #ef4444;
    color: white;
    border: none;
    border-radius: 6px;
    font-size: 0.875rem;
    cursor: pointer;
    transition: background 0.2s;
  }

  .sign-out-button:hover {
    background: #dc2626;
  }

  h1 {
    margin: 0;
    font-size: 2rem;
    text-align: center;
  }

  .subtitle {
    text-align: center;
    color: #666;
    margin: 0.5rem 0 2rem;
  }

  .status-card {
    background: #f8f9fa;
    border-radius: 12px;
    padding: 1.5rem;
    display: flex;
    flex-direction: column;
    gap: 1rem;
  }

  .connection-row {
    display: flex;
    align-items: center;
    gap: 1rem;
  }

  .status-indicator {
    width: 16px;
    height: 16px;
    border-radius: 50%;
    background: #dc2626;
    flex-shrink: 0;
    box-shadow: 0 0 8px rgba(220, 38, 38, 0.4);
    transition: all 0.3s ease;
  }

  .status-indicator.connected {
    background: #22c55e;
    box-shadow: 0 0 8px rgba(34, 197, 94, 0.4);
  }

  .status-text {
    display: flex;
    flex-direction: column;
    gap: 0.125rem;
  }

  .connected-text {
    font-weight: 600;
    color: #22c55e;
  }

  .disconnected-text {
    font-weight: 600;
    color: #666;
  }

  .connection-type, .hint {
    font-size: 0.85rem;
    color: #888;
  }

  .import-button {
    background: #8b5cf6;
    color: white;
    border: none;
    border-radius: 8px;
    padding: 1rem 1.5rem;
    font-size: 1rem;
    font-weight: 600;
    cursor: pointer;
    transition: background 0.2s ease;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 0.5rem;
  }

  .import-button:hover:not(:disabled) {
    background: #7c3aed;
  }

  .import-button:disabled {
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

  .result-card {
    border-radius: 8px;
    padding: 1rem;
  }

  .result-card.success {
    background: #f0fdf4;
    border: 1px solid #86efac;
  }

  .result-card.error {
    background: #fef2f2;
    border: 1px solid #fca5a5;
  }

  .result-header {
    font-weight: 600;
    margin-bottom: 0.75rem;
  }

  .result-card.success .result-header {
    color: #166534;
  }

  .result-card.error .result-header {
    color: #991b1b;
  }

  .result-stats {
    display: flex;
    gap: 1.5rem;
  }

  .stat {
    display: flex;
    flex-direction: column;
    align-items: center;
  }

  .stat-value {
    font-size: 1.25rem;
    font-weight: 700;
    color: #166534;
  }

  .stat-label {
    font-size: 0.8rem;
    color: #666;
  }

  .result-warning {
    margin: 0.75rem 0 0;
    font-size: 0.85rem;
    color: #b45309;
  }

  .error-text {
    margin: 0;
    color: #991b1b;
    font-size: 0.9rem;
  }
</style>
