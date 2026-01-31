<script lang="ts">
  import { getImportHistory, formatTimestamp, type ImportSession } from '$lib/api/vocab';
  import { Card, CardHeader, CardTitle, CardContent } from './ui/card/index.js';
  import { Badge } from './ui/badge/index.js';
  import EmptyState from './EmptyState.svelte';
  import { FileText, CheckCircle, XCircle } from 'lucide-svelte';
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

<Card>
  <CardHeader>
    <div class="flex items-center justify-between">
      <CardTitle class="text-lg">Import History</CardTitle>
      {#if !loading && sessions.length > 0}
        <span class="text-sm text-muted-foreground">
          {sessions.length} {sessions.length === 1 ? 'import' : 'imports'}
        </span>
      {/if}
    </div>
  </CardHeader>
  <CardContent>
    {#if loading}
      <p class="text-center py-8 text-muted-foreground">Loading history...</p>
    {:else if error}
      <div class="rounded-lg border border-destructive/50 bg-destructive/10 p-3 text-sm text-destructive">
        {error}
      </div>
    {:else if sessions.length === 0}
      <div class="py-8">
        <EmptyState
          title="No imports yet"
          description="Connect your Kindle to import your highlights"
        >
          {#snippet icon()}
            <FileText class="h-6 w-6 text-muted-foreground" />
          {/snippet}
        </EmptyState>
      </div>
    {:else}
      <div class="space-y-2 max-h-96 overflow-y-auto">
        {#each sessions as session}
          <div class="rounded-lg border border-border bg-secondary/30 p-4">
            <!-- Header: Timestamp + Status -->
            <div class="mb-3 flex items-center justify-between">
              <span class="text-sm text-muted-foreground">{formatTimestamp(session.timestamp)}</span>
              {#if session.status === 'success'}
                <div class="flex items-center gap-2">
                  <CheckCircle class="h-4 w-4 text-emerald-600" />
                  <Badge variant="secondary">Completed</Badge>
                </div>
              {:else}
                <div class="flex items-center gap-2">
                  <XCircle class="h-4 w-4 text-red-600" />
                  <Badge variant="destructive">Failed</Badge>
                </div>
              {/if}
            </div>

            <!-- Stats -->
            <div class="flex gap-4 text-sm">
              <div>
                <span class="font-semibold text-foreground">{session.imported}</span>
                <span class="text-muted-foreground"> imported</span>
              </div>
              <div>
                <span class="font-semibold text-foreground">{session.skipped}</span>
                <span class="text-muted-foreground"> skipped</span>
              </div>
            </div>

            <!-- Error Message -->
            {#if session.error}
              <p class="mt-2 text-xs text-destructive">{session.error}</p>
            {/if}
          </div>
        {/each}
      </div>
    {/if}
  </CardContent>
</Card>
