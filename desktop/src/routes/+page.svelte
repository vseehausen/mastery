<script lang="ts">
  import { getKindleStatus, getClippingsInfo, formatFileSize } from '$lib/api/kindle';

  let kindleConnected = $state<boolean | null>(null);
  let checking = $state(false);
  let filePath = $state<string | null>(null);
  let fileSize = $state<number | null>(null);
  let loadingInfo = $state(false);

  async function checkKindleStatus() {
    checking = true;
    try {
      kindleConnected = await getKindleStatus();
      if (kindleConnected) {
        await loadFileInfo();
      } else {
        filePath = null;
        fileSize = null;
      }
    } catch (error) {
      console.error('Failed to check Kindle status:', error);
      kindleConnected = false;
    } finally {
      checking = false;
    }
  }

  async function loadFileInfo() {
    if (!kindleConnected) return;
    
    loadingInfo = true;
    try {
      const [path, size] = await getClippingsInfo();
      filePath = path;
      fileSize = size;
    } catch (error) {
      console.error('Failed to load file info:', error);
      filePath = null;
      fileSize = null;
    } finally {
      loadingInfo = false;
    }
  }
</script>

<main class="container">
  <h1>Mastery Desktop</h1>

  <div class="kindle-section">
    <h2>Kindle Status</h2>
    <button onclick={checkKindleStatus} disabled={checking}>
      {checking ? 'Checking...' : 'Check Kindle Status'}
    </button>
    
    {#if kindleConnected !== null}
      <p class="status-message">
        Kindle Connected: <strong>{kindleConnected ? 'Yes' : 'No'}</strong>
      </p>
    {/if}

    {#if kindleConnected && loadingInfo}
      <p>Loading file info...</p>
    {/if}

    {#if kindleConnected && filePath && fileSize !== null}
      <div class="file-info">
        <p><strong>File Path:</strong></p>
        <p class="file-path">{filePath}</p>
        <p><strong>File Size:</strong> {formatFileSize(fileSize)}</p>
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
    min-width: 300px;
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

  .status-message {
    margin-top: 1rem;
    font-size: 1.1em;
  }

  .status-message strong {
    color: #646cff;
  }

  .file-info {
    margin-top: 1rem;
    padding: 1rem;
    background: white;
    border-radius: 4px;
    text-align: left;
    min-width: 100%;
  }

  .file-path {
    font-family: monospace;
    font-size: 0.9em;
    color: #666;
    word-break: break-all;
    margin: 0.5rem 0;
  }
</style>
