<script lang="ts">
  import { getKindleStatus, getClippingsInfo, readClippings, countClippings, formatFileSize } from '$lib/api/kindle';

  let kindleConnected = $state<boolean | null>(null);
  let checking = $state(false);
  let filePath = $state<string | null>(null);
  let fileSize = $state<number | null>(null);
  let loadingInfo = $state(false);
  let fileContent = $state<string | null>(null);
  let loadingContent = $state(false);
  let highlightCount = $state<number | null>(null);
  let error = $state<string | null>(null);

  async function checkKindleStatus() {
    checking = true;
    error = null;
    try {
      kindleConnected = await getKindleStatus();
      if (kindleConnected) {
        await loadFileInfo();
      } else {
        filePath = null;
        fileSize = null;
        fileContent = null;
      }
    } catch (err) {
      console.error('Failed to check Kindle status:', err);
      kindleConnected = false;
      error = err instanceof Error ? err.message : 'Failed to check status';
    } finally {
      checking = false;
    }
  }

  async function loadFileInfo() {
    if (!kindleConnected) return;
    
    loadingInfo = true;
    error = null;
    try {
      const [path, size] = await getClippingsInfo();
      filePath = path;
      fileSize = size;
    } catch (err) {
      console.error('Failed to load file info:', err);
      filePath = null;
      fileSize = null;
      error = err instanceof Error ? err.message : 'Failed to load file info';
    } finally {
      loadingInfo = false;
    }
  }

  async function loadClippings() {
    if (!kindleConnected) return;
    
    loadingContent = true;
    error = null;
    try {
      const content = await readClippings();
      fileContent = content;
      // Count highlights
      const count = await countClippings(content);
      highlightCount = count;
    } catch (err) {
      console.error('Failed to read clippings:', err);
      fileContent = null;
      highlightCount = null;
      error = err instanceof Error ? err.message : 'Failed to read file';
    } finally {
      loadingContent = false;
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
        
        <button onclick={loadClippings} disabled={loadingContent} class="load-button">
          {loadingContent ? 'Loading...' : 'Load Clippings'}
        </button>
      </div>
    {/if}

    {#if error}
      <p class="error-message">Error: {error}</p>
    {/if}

    {#if fileContent !== null}
      <div class="content-preview">
        {#if highlightCount !== null}
          <h3>Found {highlightCount} highlights</h3>
        {/if}
        <h3>File Content Preview (first 500 characters):</h3>
        <pre class="content-text">{fileContent.substring(0, 500)}...</pre>
        <p class="content-info">Total size: {fileContent.length} characters</p>
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

  .load-button {
    margin-top: 1rem;
  }

  .error-message {
    color: #dc2626;
    margin-top: 1rem;
    padding: 0.5rem;
    background: #fef2f2;
    border-radius: 4px;
  }

  .content-preview {
    margin-top: 2rem;
    padding: 1rem;
    background: white;
    border-radius: 4px;
    min-width: 100%;
  }

  .content-text {
    background: #f5f5f5;
    padding: 1rem;
    border-radius: 4px;
    overflow-x: auto;
    font-size: 0.9em;
    white-space: pre-wrap;
    word-wrap: break-word;
    max-height: 300px;
    overflow-y: auto;
  }

  .content-info {
    margin-top: 0.5rem;
    font-size: 0.9em;
    color: #666;
  }
</style>
