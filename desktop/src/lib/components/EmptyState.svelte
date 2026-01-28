<script lang="ts">
  import type { Snippet } from 'svelte';

  interface Props {
    icon?: Snippet;
    title: string;
    description: string;
  }

  let { icon, title, description }: Props = $props();
</script>

<div class="flex flex-col items-center justify-center py-12 text-center">
  {#if icon}
    <div class="mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-secondary">
      {@render icon()}
    </div>
  {/if}
  <h3 class="font-medium text-foreground">{title}</h3>
  <p class="mt-1 text-sm text-muted-foreground">{description}</p>
</div>
