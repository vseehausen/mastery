<script lang="ts">
  import { getImportHistory, formatTimestamp, type ImportSession } from '$lib/api/vocab';
  import { onMount } from 'svelte';

  let sessions = $state<ImportSession[]>([]);
  let loading = $state(true);
  let error = $state<string | null>(null);

  export async function refresh() {
    loading = true;
    error = null;
    try {
      sessions = await getImportHistory();
    } catch (e) {
      error = e instanceof Error ? e.message : String(e);
    } finally {
      loading = false;
    }
  }

  onMount(() => {
    refresh();
  });
</script>

<div class="import-history">
  <h3>Import History</h3>
  
  {#if loading}
    <p class="loading">Loading history...</p>
  {:else if error}
    <p class="error">{error}</p>
  {:else if sessions.length === 0}
    <p class="empty">No imports yet</p>
  {:else}
    <div class="sessions">
      {#each sessions as session}
        <div class="session" class:error={session.status === 'error'}>
          <div class="session-header">
            <span class="timestamp">{formatTimestamp(session.timestamp)}</span>
            <span class="status" class:success={session.status === 'success'} class:failed={session.status === 'error'}>
              {session.status === 'success' ? '✓' : '✗'}
            </span>
          </div>
          <div class="session-stats">
            <span><strong>{session.imported}</strong> imported</span>
            <span><strong>{session.skipped}</strong> skipped</span>
            <span><strong>{session.books}</strong> books</span>
          </div>
          {#if session.error}
            <p class="session-error">{session.error}</p>
          {/if}
        </div>
      {/each}
    </div>
  {/if}
</div>

<style>
  .import-history {
    margin-top: 1.5rem;
    width: 100%;
    background: white;
    border-radius: 4px;
    padding: 1rem;
  }

  h3 {
    margin: 0 0 1rem 0;
    font-size: 1em;
    color: #333;
  }

  .loading, .empty {
    color: #666;
    font-size: 0.9em;
    text-align: center;
    padding: 1rem 0;
  }

  .error {
    color: #dc2626;
    font-size: 0.9em;
  }

  .sessions {
    display: flex;
    flex-direction: column;
    gap: 0.75rem;
    max-height: 300px;
    overflow-y: auto;
  }

  .session {
    padding: 0.75rem;
    background: #f9fafb;
    border-radius: 4px;
    border-left: 3px solid #22c55e;
  }

  .session.error {
    border-left-color: #ef4444;
  }

  .session-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 0.5rem;
  }

  .timestamp {
    font-size: 0.85em;
    color: #666;
  }

  .status {
    font-size: 0.9em;
    font-weight: bold;
  }

  .status.success {
    color: #22c55e;
  }

  .status.failed {
    color: #ef4444;
  }

  .session-stats {
    display: flex;
    gap: 1rem;
    font-size: 0.85em;
    color: #555;
  }

  .session-stats strong {
    color: #333;
  }

  .session-error {
    margin: 0.5rem 0 0 0;
    font-size: 0.8em;
    color: #dc2626;
  }
</style>
