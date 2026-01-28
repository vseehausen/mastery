<script lang="ts">
  import { Button } from './ui/button/index.js';
  import { Avatar, AvatarImage, AvatarFallback } from './ui/avatar/index.js';
  import { BookOpen, LogOut, Sparkles } from 'lucide-svelte';

  interface Props {
    user: { email?: string; fullName?: string; id: string } | null;
    onSignOut: () => void;
  }

  let { user, onSignOut }: Props = $props();

  function getInitials(email?: string, name?: string): string {
    if (name) {
      return name
        .split(' ')
        .map((n) => n[0])
        .join('')
        .toUpperCase()
        .slice(0, 2);
    }
    if (!email) return 'U';
    const parts = email.split('@')[0].split('.');
    return parts.map((p) => p[0]).join('').toUpperCase().slice(0, 2);
  }
</script>

<div class="flex h-screen w-64 flex-col border-r border-sidebar-border bg-sidebar">
  <!-- Header -->
  <div class="flex items-center gap-3 p-6">
    <div class="relative flex h-8 w-8 items-center justify-center rounded-md bg-primary">
      <BookOpen class="h-5 w-5 text-primary-foreground" />
      <Sparkles class="absolute -right-1 -top-1 h-3 w-3 text-mastery-accent" />
    </div>
    <div class="flex flex-col">
      <span class="font-semibold text-sidebar-foreground">Mastery</span>
    </div>
  </div>

  <!-- Spacer -->
  <div class="flex-1"></div>

  <!-- Footer -->
  <div class="border-t border-sidebar-border p-4">
    <div class="flex items-center gap-3">
      <Avatar class="h-8 w-8 shrink-0">
        <AvatarImage alt={user?.fullName || user?.email || 'User'} />
        <AvatarFallback>{getInitials(user?.email, user?.fullName)}</AvatarFallback>
      </Avatar>
      <div class="min-w-0 flex-1">
        <p class="truncate text-sm font-medium text-sidebar-foreground">
          {user?.fullName || 'User'}
        </p>
        <p class="truncate text-xs text-muted-foreground">
          {user?.email || ''}
        </p>
      </div>
      <Button
        variant="ghost"
        size="icon"
        class="h-8 w-8 shrink-0 text-muted-foreground hover:text-sidebar-foreground"
        onclick={onSignOut}
        title="Sign out"
      >
        <LogOut class="h-4 w-4" />
      </Button>
    </div>
  </div>
</div>
