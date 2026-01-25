<script lang="ts">
  import { getKindleStatus, syncKindleVocab, getVocabDbPath } from '$lib/api/kindle';

  let kindleConnected = $state<boolean | null>(null);
  let checking = $state(false);
  let syncing = $state(false);
  let vocabPath = $state<string | null>(null);
  let syncStatus = $state<string | null>(null);
  let error = $state<string | null>(null);
  let logs = $state<string[]>([]);

  function addLog(msg: string) {
    const timestamp = new Date().toLocaleTimeString();
    logs = [...logs, `[${timestamp}] ${msg}`];
    console.log(msg);
  }

  function clearLogs() {
    logs = [];
  }

  async function checkKindleStatus() {
    checking = true;
    error = null;
    addLog('Checking Kindle status...');
    try {
      kindleConnected = await getKindleStatus();
      addLog(`Kindle connected: ${kindleConnected}`);
      // Also check if we have a synced vocab.db
      try {
        vocabPath = await getVocabDbPath();
        addLog(`Existing vocab.db found at: ${vocabPath}`);
      } catch {
        vocabPath = null;
        addLog('No existing vocab.db found');
      }
    } catch (err) {
      console.error('Failed to check Kindle status:', err);
      kindleConnected = false;
      const errMsg = err instanceof Error ? err.message : String(err);
      error = errMsg;
      addLog(`Error: ${errMsg}`);
    } finally {
      checking = false;
    }
  }

  async function handleSyncVocab() {
    syncing = true;
    error = null;
    syncStatus = null;
    clearLogs();
    addLog('Starting vocab.db sync...');
    addLog('This may prompt for your password (required for MTP access)');
    
    try {
      const result = await syncKindleVocab();
      syncStatus = result;
      addLog(`Success: ${result}`);
      // Refresh vocab path
      try {
        vocabPath = await getVocabDbPath();
        addLog(`Vocab.db saved to: ${vocabPath}`);
      } catch {
        vocabPath = null;
      }
    } catch (err) {
      const errMsg = err instanceof Error ? err.message : String(err);
      error = errMsg;
      addLog(`Error: ${errMsg}`);
    } finally {
      syncing = false;
      addLog('Sync operation complete');
    }
  }

  // Check status on mount
  checkKindleStatus();
</script>

<main class="container">
  <h1>Mastery Desktop</h1>

  <div class="kindle-section">
    <h2>Kindle Vocabulary Sync</h2>
    
    <button onclick={checkKindleStatus} disabled={checking}>
      {checking ? 'Checking...' : 'Check Kindle Status'}
    </button>
    
    {#if kindleConnected !== null}
      <p class="status-message">
        Kindle Connected: <strong class={kindleConnected ? 'connected' : 'disconnected'}>
          {kindleConnected ? 'Yes' : 'No'}
        </strong>
      </p>
    {/if}

    {#if kindleConnected}
      <div class="sync-section">
        <button onclick={handleSyncVocab} disabled={syncing} class="sync-button">
          {syncing ? 'Syncing...' : 'Sync Vocabulary Database'}
        </button>
        <p class="hint">
          Syncs vocab.db from your Kindle. You may be prompted for your password.
        </p>
      </div>
    {/if}

    {#if syncStatus}
      <p class="success-message">{syncStatus}</p>
    {/if}

    {#if error}
      <p class="error-message">{error}</p>
    {/if}

    {#if vocabPath}
      <div class="vocab-info">
        <h3>Synced Vocabulary Database</h3>
        <p class="file-path">{vocabPath}</p>
      </div>
    {/if}

    {#if !kindleConnected && kindleConnected !== null}
      <div class="instructions">
        <h3>How to connect your Kindle</h3>
        <ol>
          <li>Connect your Kindle via USB cable</li>
          <li>On older Kindles: Enable USB drive mode</li>
          <li>On newer Kindles (2024+): The app will access it directly via MTP</li>
          <li>Click "Check Kindle Status" to detect your device</li>
        </ol>
      </div>
    {/if}

    {#if logs.length > 0}
      <div class="log-section">
        <div class="log-header">
          <h3>Activity Log</h3>
          <button onclick={clearLogs} class="clear-btn">Clear</button>
        </div>
        <div class="log-content">
          {#each logs as log}
            <div class="log-line">{log}</div>
          {/each}
        </div>
      </div>
    {/if}
  </div>
</main>

<style>
  .container {
    margin: 0;
    padding: 2rem;
    display: flex;
    flex-direction: column;
    align-items: center;
    min-height: 100vh;
  }

  h1 {
    margin-bottom: 2rem;
  }

  .kindle-section {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 1rem;
    padding: 2rem;
    background: #f5f5f5;
    border-radius: 8px;
    min-width: 400px;
    max-width: 600px;
  }

  button {
    border-radius: 8px;
    border: 1px solid transparent;
    padding: 0.6em 1.2em;
    font-size: 1em;
    font-weight: 500;
    font-family: inherit;
    background-color: #646cff;
    color: white;
    cursor: pointer;
    transition: background-color 0.25s;
  }

  button:hover:not(:disabled) {
    background-color: #535bf2;
  }

  button:disabled {
    background-color: #999;
    cursor: not-allowed;
  }

  .sync-button {
    background-color: #22c55e;
  }

  .sync-button:hover:not(:disabled) {
    background-color: #16a34a;
  }

  .status-message {
    margin-top: 1rem;
    font-size: 1.1em;
  }

  .connected {
    color: #22c55e;
  }

  .disconnected {
    color: #ef4444;
  }

  .sync-section {
    margin-top: 1rem;
    text-align: center;
  }

  .hint {
    font-size: 0.85em;
    color: #666;
    margin-top: 0.5rem;
  }

  .success-message {
    color: #22c55e;
    background: #f0fdf4;
    padding: 0.75rem 1rem;
    border-radius: 4px;
    margin-top: 1rem;
  }

  .error-message {
    color: #dc2626;
    background: #fef2f2;
    padding: 0.75rem 1rem;
    border-radius: 4px;
    margin-top: 1rem;
  }

  .vocab-info {
    margin-top: 1.5rem;
    padding: 1rem;
    background: white;
    border-radius: 4px;
    width: 100%;
  }

  .vocab-info h3 {
    margin: 0 0 0.5rem 0;
    font-size: 1em;
  }

  .file-path {
    font-family: monospace;
    font-size: 0.85em;
    color: #666;
    word-break: break-all;
    margin: 0;
  }

  .instructions {
    margin-top: 1.5rem;
    padding: 1rem;
    background: #fef3c7;
    border-radius: 4px;
    width: 100%;
  }

  .instructions h3 {
    margin: 0 0 0.75rem 0;
    font-size: 1em;
  }

  .instructions ol {
    margin: 0;
    padding-left: 1.5rem;
  }

  .instructions li {
    margin-bottom: 0.5rem;
    font-size: 0.9em;
  }

  .log-section {
    margin-top: 1.5rem;
    width: 100%;
    background: #1a1a2e;
    border-radius: 4px;
    overflow: hidden;
  }

  .log-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 0.5rem 1rem;
    background: #16213e;
  }

  .log-header h3 {
    margin: 0;
    font-size: 0.9em;
    color: #a0a0a0;
  }

  .clear-btn {
    padding: 0.25rem 0.5rem;
    font-size: 0.75em;
    background: #333;
    color: #888;
  }

  .clear-btn:hover:not(:disabled) {
    background: #444;
  }

  .log-content {
    padding: 0.75rem 1rem;
    max-height: 200px;
    overflow-y: auto;
    font-family: monospace;
    font-size: 0.8em;
  }

  .log-line {
    color: #4ade80;
    padding: 0.15rem 0;
    word-break: break-all;
  }

  .log-line:nth-child(even) {
    color: #86efac;
  }
</style>
