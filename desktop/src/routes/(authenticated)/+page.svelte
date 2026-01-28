<script lang="ts">
  import { onMount, onDestroy } from 'svelte';
  import { checkKindleStatus, type KindleStatus } from '$lib/api/kindle';
  import { importFromKindle, type ImportResult } from '$lib/api/vocab';
  import { Button } from '$lib/components/ui/button/index.js';
  import KindleStatusCard from '$lib/components/KindleStatusCard.svelte';
  import ImportHistory from '$lib/components/ImportHistory.svelte';
  import { Download, Loader2 } from 'lucide-svelte';

  let status = $state<KindleStatus>({ connected: false, connectionType: null });
  let importing = $state(false);
  let error = $state<string | null>(null);
  let historyComponent = $state<ImportHistory | null>(null);
  let pollInterval: ReturnType<typeof setInterval>;

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

    try {
      await importFromKindle();
      historyComponent?.refresh();
    } catch (e) {
      error = e instanceof Error ? e.message : String(e);
    } finally {
      importing = false;
    }
  }

  onMount(async () => {
    await pollStatus();
    pollInterval = setInterval(pollStatus, 3000);
  });

  onDestroy(() => {
    if (pollInterval) clearInterval(pollInterval);
  });
</script>

<div class="flex h-full flex-col bg-background">
  <!-- Header -->
  <div class="border-b border-border bg-card p-8">
    <div class="mx-auto flex max-w-6xl items-center justify-between">
      <h1 class="text-2xl font-semibold text-foreground">Kindle Import Hub</h1>
      <Button
        disabled={!status.connected || importing}
        onclick={handleImport}
        size="lg"
      >
        {#if importing}
          <Loader2 class="h-4 w-4 animate-spin" />
          Importing...
        {:else}
          <Download class="h-4 w-4" />
          Import Notes
        {/if}
      </Button>
    </div>
  </div>

  <!-- Main Content -->
  <div class="flex-1 overflow-auto">
    <div class="mx-auto max-w-6xl space-y-8 p-8">
      <!-- Error Message -->
      {#if error}
        <div class="rounded-lg border border-destructive/50 bg-destructive/10 p-4 text-sm text-destructive">
          {error}
        </div>
      {/if}

      <!-- Kindle Status Card -->
      <KindleStatusCard {status} />

      <!-- Import History -->
      <ImportHistory bind:this={historyComponent} />
    </div>
  </div>
</div>
