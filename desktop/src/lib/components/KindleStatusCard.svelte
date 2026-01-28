<script lang="ts">
  import { Card, CardContent } from './ui/card/index.js';
  import { Badge } from './ui/badge/index.js';
  import { Tablet } from 'lucide-svelte';
  import type { KindleStatus } from '$lib/api/kindle';

  interface Props {
    status: KindleStatus;
  }

  let { status }: Props = $props();
</script>

<Card>
  <CardContent class="p-6">
    <div class="flex items-stretch gap-6">
      <!-- Icon -->
      <div class="flex items-center">
        <div class="flex h-12 w-12 items-center justify-center rounded-lg bg-muted">
          <Tablet class="h-6 w-6 text-muted-foreground" />
        </div>
      </div>

      <!-- Content -->
      <div class="flex flex-1 flex-col justify-center">
        <h3 class="text-lg font-semibold text-foreground">Kindle Detected</h3>
        <p class="mt-1 text-sm text-muted-foreground">
          {status.connected
            ? `Connected via ${status.connectionType || 'USB'}`
            : 'Connect a Kindle device to import highlights'}
        </p>
      </div>

      <!-- Status Badge -->
      {#if status.connected}
        <div class="flex items-center">
          <Badge variant="success">Connected</Badge>
        </div>
      {/if}
    </div>
  </CardContent>
</Card>
