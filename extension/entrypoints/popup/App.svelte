<script lang="ts">
  import { onMount } from 'svelte';
  import { signIn, signUp, signOut, signInWithOAuth, type OAuthProvider } from '@/lib/auth';
  import { getSupabaseClient } from '@/lib/api-client';
  import { getSettings, updateSettings, type TooltipDetail, type Settings } from '@/lib/settings';
  import { Button } from '@/lib/components/ui/button';
  import { Input } from '@/lib/components/ui/input';
  import { Separator } from '@/lib/components/ui/separator';
  import { Switch } from '@/lib/components/ui/switch';
  import type { Session } from '@supabase/supabase-js';
  import type { StatsResponse, ProgressStage, StageCounts } from '@/lib/types';

  // ---- State ----
  type Screen = 'loading' | 'auth' | 'empty' | 'dashboard' | 'settings';
  let screen: Screen = $state('loading');
  let session: Session | null = $state(null);

  // Auth
  let email = $state('');
  let password = $state('');
  let authError = $state('');
  let authLoading = $state(false);
  let authMode: 'signin' | 'signup' = $state('signin');
  let authMethod: 'initial' | 'email' = $state('initial');

  // Stats
  let stats: StatsResponse | null = $state(null);
  let pageWordCount = $state(0);
  let isOnline = $state(true);

  // Settings
  let settings: Settings = $state({
    nativeLanguage: 'de',
    tooltipDetail: 'standard',
    autoCapture: true,
    pausedSites: [],
  });
  let currentDomain = $state('');

  // ---- Stage display ----
  const STAGE_COLORS: Record<ProgressStage, string> = {
    new: 'var(--stage-new)',
    practicing: 'var(--stage-practicing)',
    stabilizing: 'var(--stage-stabilizing)',
    known: 'var(--stage-known)',
    mastered: 'var(--stage-mastered)',
  };

  const STAGE_LABELS: Record<ProgressStage, string> = {
    new: 'New',
    practicing: 'Practicing',
    stabilizing: 'Stabilizing',
    known: 'Known',
    mastered: 'Mastered',
  };

  const STAGES: ProgressStage[] = ['new', 'practicing', 'stabilizing', 'known', 'mastered'];

  // ---- Lifecycle ----
  onMount(async () => {
    try {
      const supabase = getSupabaseClient();
      const { data: { session: s } } = await supabase.auth.getSession();
      session = s;
      settings = await getSettings();

      // Get current tab domain
      try {
        const [tab] = await browser.tabs.query({ active: true, currentWindow: true });
        if (tab?.url) {
          currentDomain = new URL(tab.url).hostname;
        }
      } catch { /* ignore */ }

      isOnline = navigator.onLine;

      if (session) {
        await loadStats();
      } else {
        screen = 'auth';
      }

      supabase.auth.onAuthStateChange(async (_event, s) => {
        session = s;
        if (s) {
          await loadStats();
        } else {
          screen = 'auth';
          stats = null;
        }
      });
    } catch (err) {
      console.error('[Mastery] Popup init failed:', err);
      screen = 'auth';
    }
  });

  async function loadStats() {
    try {
      const [tab] = await browser.tabs.query({ active: true, currentWindow: true });
      const tabUrl = tab?.url ?? '';

      const supabase = getSupabaseClient();
      const params = tabUrl ? `?url=${encodeURIComponent(tabUrl)}` : '';
      const { data } = await supabase.functions.invoke(`lookup-word/batch-status${params}`, {
        method: 'GET',
      });

      if (data) {
        stats = data as StatsResponse;
        pageWordCount = stats.page_words.length;
        screen = stats.total_words > 0 ? 'dashboard' : 'empty';
      } else {
        screen = 'empty';
      }
    } catch (err) {
      console.error('[Mastery] Failed to load stats:', err);
      screen = 'empty';
    }
  }

  // ---- Auth handlers ----
  async function handleEmailAuth() {
    authError = '';
    authLoading = true;
    const result = authMode === 'signin'
      ? await signIn(email, password)
      : await signUp(email, password);
    authLoading = false;
    if (result.error) {
      authError = result.error;
    } else {
      password = '';
    }
  }

  async function handleOAuth(provider: OAuthProvider) {
    authError = '';
    authLoading = true;
    const result = await signInWithOAuth(provider);
    authLoading = false;
    if (result.error) {
      authError = result.error;
    }
  }

  async function handleLogout() {
    await signOut();
    session = null;
    stats = null;
    screen = 'auth';
  }

  // ---- Settings handlers ----
  async function setTooltipDetail(detail: TooltipDetail) {
    settings = await updateSettings({ tooltipDetail: detail });
  }

  async function toggleAutoCapture() {
    settings = await updateSettings({ autoCapture: !settings.autoCapture });
  }

  async function togglePauseSite() {
    if (!currentDomain) return;
    const paused = settings.pausedSites.includes(currentDomain);
    const pausedSites = paused
      ? settings.pausedSites.filter(d => d !== currentDomain)
      : [...settings.pausedSites, currentDomain];
    settings = await updateSettings({ pausedSites });
  }

  // ---- Helpers ----
  function timeAgo(isoDate: string): string {
    const diff = Date.now() - new Date(isoDate).getTime();
    const mins = Math.floor(diff / 60000);
    if (mins < 1) return 'just now';
    if (mins < 60) return `${mins}m ago`;
    const hours = Math.floor(mins / 60);
    if (hours < 24) return `${hours}h ago`;
    const days = Math.floor(hours / 24);
    return `${days}d ago`;
  }

  function stageBarWidths(counts: StageCounts): Record<ProgressStage, number> {
    const total = STAGES.reduce((sum, s) => sum + (counts[s] || 0), 0);
    if (total === 0) return { new: 0, practicing: 0, stabilizing: 0, known: 0, mastered: 0 };
    const widths = {} as Record<ProgressStage, number>;
    for (const s of STAGES) {
      widths[s] = ((counts[s] || 0) / total) * 100;
    }
    return widths;
  }

  const isSitePaused = $derived(currentDomain ? settings.pausedSites.includes(currentDomain) : false);
</script>

<main class="w-80 min-h-[200px] bg-background text-foreground">
  <!-- ===== LOADING ===== -->
  {#if screen === 'loading'}
    <div class="flex items-center justify-center p-8">
      <span class="text-sm text-muted-foreground">Loading...</span>
    </div>

  <!-- ===== AUTH ===== -->
  {:else if screen === 'auth'}
    {#if authMethod === 'initial'}
      <!-- Initial auth options -->
      <div class="p-6 flex flex-col items-center space-y-4">
        <!-- Logo -->
        <div class="flex items-center gap-2">
          <div class="flex gap-0.5">
            <div class="w-1 h-4 rounded-full bg-stage-new"></div>
            <div class="w-1 h-4 rounded-full bg-stage-practicing"></div>
            <div class="w-1 h-4 rounded-full bg-stage-stabilizing"></div>
            <div class="w-1 h-4 rounded-full bg-stage-known"></div>
            <div class="w-1 h-4 rounded-full bg-stage-mastered"></div>
          </div>
          <span class="text-base font-bold tracking-tight">Mastery</span>
        </div>

        <div class="text-center">
          <h1 class="text-lg font-semibold">Welcome back</h1>
          <p class="text-xs text-muted-foreground mt-1">Sign in to capture vocabulary</p>
        </div>

        <!-- Auth buttons -->
        <div class="w-full space-y-2">
          <Button
            variant="outline"
            class="w-full"
            disabled={authLoading}
            onclick={() => handleOAuth('google')}
          >
            <svg class="w-4 h-4 mr-2" viewBox="0 0 24 24">
              <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92a5.06 5.06 0 0 1-2.2 3.32v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.1z"/>
              <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
              <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
              <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
            </svg>
            Continue with Google
          </Button>
          <Button
            variant="outline"
            class="w-full"
            disabled={authLoading}
            onclick={() => handleOAuth('apple')}
          >
            <svg class="w-4 h-4 mr-2" viewBox="0 0 24 24" fill="currentColor">
              <path d="M17.05 20.28c-.98.95-2.05.88-3.08.4-1.09-.5-2.08-.48-3.24 0-1.44.62-2.2.44-3.06-.4C2.79 15.25 3.51 7.59 9.05 7.31c1.35.07 2.29.74 3.08.8 1.18-.24 2.31-.93 3.57-.84 1.51.12 2.65.72 3.4 1.8-3.12 1.87-2.38 5.98.48 7.13-.57 1.5-1.31 2.99-2.54 4.09zM12.03 7.25c-.15-2.23 1.66-4.07 3.74-4.25.29 2.58-2.34 4.5-3.74 4.25z"/>
            </svg>
            Continue with Apple
          </Button>
          <Button
            variant="outline"
            class="w-full"
            disabled={authLoading}
            onclick={() => { authMethod = 'email'; }}
          >
            <svg class="w-4 h-4 mr-2" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <rect width="20" height="16" x="2" y="4" rx="2"/>
              <path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7"/>
            </svg>
            Sign in with email
          </Button>
        </div>
      </div>

    {:else if authMethod === 'email'}
      <!-- Email auth screen -->
      <div class="p-6 flex flex-col space-y-4">
        <!-- Header with back button -->
        <div class="flex items-center gap-2">
          <button
            class="text-muted-foreground hover:text-foreground transition-colors"
            onclick={() => { authMethod = 'initial'; authError = ''; }}
            aria-label="Back"
          >
            <svg class="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <path d="m15 18-6-6 6-6"/>
            </svg>
          </button>
          <h1 class="text-sm font-semibold">
            {authMode === 'signin' ? 'Sign in with email' : 'Create account'}
          </h1>
        </div>

        <!-- Email form -->
        <form onsubmit={(e) => { e.preventDefault(); handleEmailAuth(); }} class="w-full space-y-3">
          <Input
            type="email"
            value={email}
            oninput={(e) => { email = (e.target as HTMLInputElement).value; }}
            placeholder="Email"
            required
            disabled={authLoading}
          />
          <Input
            type="password"
            value={password}
            oninput={(e) => { password = (e.target as HTMLInputElement).value; }}
            placeholder="Password"
            required
            disabled={authLoading}
          />
          {#if authError}
            <p class="text-xs text-destructive">{authError}</p>
          {/if}
          <Button
            type="submit"
            class="w-full"
            disabled={authLoading}
          >
            {authLoading ? 'Signing in...' : authMode === 'signin' ? 'Sign in' : 'Create account'}
          </Button>
        </form>

        <!-- Toggle auth mode -->
        <p class="text-xs text-center text-muted-foreground">
          {#if authMode === 'signin'}
            Don't have an account?
            <button class="text-foreground font-medium hover:underline" onclick={() => { authMode = 'signup'; authError = ''; }}>
              Sign up
            </button>
          {:else}
            Already have an account?
            <button class="text-foreground font-medium hover:underline" onclick={() => { authMode = 'signin'; authError = ''; }}>
              Sign in
            </button>
          {/if}
        </p>
      </div>
    {/if}

  <!-- ===== EMPTY STATE ===== -->
  {:else if screen === 'empty'}
    <div class="p-4">
      <!-- Header -->
      <div class="flex items-center justify-between mb-8">
        <div class="flex items-center gap-2">
          <div class="flex gap-0.5">
            <div class="w-1 h-3 rounded-full bg-stage-new"></div>
            <div class="w-1 h-3 rounded-full bg-stage-practicing"></div>
            <div class="w-1 h-3 rounded-full bg-stage-stabilizing"></div>
            <div class="w-1 h-3 rounded-full bg-stage-known"></div>
            <div class="w-1 h-3 rounded-full bg-stage-mastered"></div>
          </div>
          <span class="text-sm font-bold tracking-tight">Mastery</span>
        </div>
        <div class="flex items-center gap-1.5">
          <span class="w-2 h-2 rounded-full {isOnline ? 'bg-success' : 'bg-warning'}"></span>
          <span class="text-xs text-muted-foreground">{isOnline ? 'Synced' : 'Offline'}</span>
        </div>
      </div>

      <!-- Empty illustration -->
      <div class="flex flex-col items-center text-center py-6 space-y-3">
        <div class="w-12 h-12 rounded-lg bg-muted flex items-center justify-center">
          <svg class="w-6 h-6 text-muted-foreground" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <circle cx="11" cy="11" r="8"/>
            <path d="m21 21-4.3-4.3"/>
          </svg>
        </div>
        <div>
          <p class="text-sm font-medium">No words yet</p>
          <p class="text-xs text-muted-foreground mt-1">Double-click any word on a webpage to look it up</p>
        </div>
      </div>
    </div>

  <!-- ===== DASHBOARD ===== -->
  {:else if screen === 'dashboard'}
    <div class="p-4 space-y-4">
      <!-- Header -->
      <div class="flex items-center justify-between">
        <div class="flex items-center gap-2">
          <div class="flex gap-0.5">
            <div class="w-1 h-3 rounded-full bg-stage-new"></div>
            <div class="w-1 h-3 rounded-full bg-stage-practicing"></div>
            <div class="w-1 h-3 rounded-full bg-stage-stabilizing"></div>
            <div class="w-1 h-3 rounded-full bg-stage-known"></div>
            <div class="w-1 h-3 rounded-full bg-stage-mastered"></div>
          </div>
          <span class="text-sm font-bold tracking-tight">Mastery</span>
        </div>
        <div class="flex items-center gap-3">
          <div class="flex items-center gap-1.5">
            <span class="w-2 h-2 rounded-full {isOnline ? 'bg-success' : 'bg-warning'}"></span>
            <span class="text-xs text-muted-foreground">{isOnline ? 'Synced' : 'Offline'}</span>
          </div>
          <button
            class="text-muted-foreground hover:text-foreground transition-colors"
            onclick={() => { screen = 'settings'; }}
            aria-label="Settings"
          >
            <svg class="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <path d="M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z"/>
              <circle cx="12" cy="12" r="3"/>
            </svg>
          </button>
        </div>
      </div>

      <!-- Page context -->
      {#if pageWordCount > 0}
        <div class="flex items-center gap-2 text-xs text-muted-foreground">
          <svg class="w-3.5 h-3.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7Z"/>
            <path d="M14 2v4a2 2 0 0 0 2 2h4"/>
          </svg>
          <span>{pageWordCount} word{pageWordCount !== 1 ? 's' : ''} captured on this page</span>
        </div>
      {/if}

      <!-- Stats row -->
      {#if stats}
        <div class="grid grid-cols-3 gap-2">
          <div class="text-center py-2 px-1 bg-muted/50 rounded-lg">
            <div class="text-lg font-bold leading-none">{stats.total_words}</div>
            <div class="text-[10px] text-muted-foreground mt-1">Total</div>
          </div>
          <div class="text-center py-2 px-1 bg-muted/50 rounded-lg">
            <div class="text-lg font-bold leading-none">{stats.words_this_week}</div>
            <div class="text-[10px] text-muted-foreground mt-1">This week</div>
          </div>
          <div class="text-center py-2 px-1 bg-muted/50 rounded-lg">
            <div class="text-lg font-bold leading-none">{stats.streak_days}</div>
            <div class="text-[10px] text-muted-foreground mt-1">Day streak</div>
          </div>
        </div>

        <!-- Stage bar -->
        {@const widths = stageBarWidths(stats.stage_counts)}
        {@const totalStaged = STAGES.reduce((sum, s) => sum + (stats!.stage_counts[s] || 0), 0)}
        {#if totalStaged > 0}
          <div class="space-y-2">
            <div class="flex h-2 rounded-full overflow-hidden">
              {#each STAGES as stage}
                {#if widths[stage] > 0}
                  <div
                    class="h-full transition-all"
                    style:width="{widths[stage]}%"
                    style:background={STAGE_COLORS[stage]}
                  ></div>
                {/if}
              {/each}
            </div>
            <div class="flex flex-wrap gap-x-3 gap-y-1">
              {#each STAGES as stage}
                {#if stats.stage_counts[stage] > 0}
                  <div class="flex items-center gap-1">
                    <span class="w-2 h-2 rounded-full" style:background={STAGE_COLORS[stage]}></span>
                    <span class="text-[10px] text-muted-foreground">
                      {STAGE_LABELS[stage]} {stats.stage_counts[stage]}
                    </span>
                  </div>
                {/if}
              {/each}
            </div>
          </div>
        {/if}

        <!-- Recent captures -->
        {#if stats.recent_words.length > 0}
          <div class="space-y-1">
            <h2 class="text-xs font-medium text-muted-foreground uppercase tracking-wide">Recent</h2>
            <ul class="space-y-0.5">
              {#each stats.recent_words as word}
                <li class="flex items-center justify-between py-1.5 px-2 rounded-md hover:bg-muted/50">
                  <div class="flex items-baseline gap-1.5 min-w-0">
                    <span class="text-sm font-medium font-serif truncate">{word.lemma}</span>
                    <span class="text-xs text-muted-foreground truncate">{word.translation}</span>
                  </div>
                  <div class="flex items-center gap-2 shrink-0 ml-2">
                    <span class="text-[10px] text-muted-foreground">{timeAgo(word.captured_at)}</span>
                    <span
                      class="w-2 h-2 rounded-full"
                      style:background={STAGE_COLORS[word.stage]}
                    ></span>
                  </div>
                </li>
              {/each}
            </ul>
          </div>
        {/if}
      {/if}

      <!-- Footer -->
      <p class="text-[10px] text-center text-muted-foreground/60 pt-1">
        Select any word to look it up
      </p>
    </div>

  <!-- ===== SETTINGS ===== -->
  {:else if screen === 'settings'}
    <div class="p-4 space-y-4">
      <!-- Header -->
      <div class="flex items-center gap-2">
        <button
          class="text-muted-foreground hover:text-foreground transition-colors"
          onclick={() => { screen = 'dashboard'; }}
          aria-label="Back"
        >
          <svg class="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="m15 18-6-6 6-6"/>
          </svg>
        </button>
        <h1 class="text-sm font-semibold">Settings</h1>
      </div>

      <!-- Native language -->
      <div class="space-y-1.5">
        <label for="native-lang" class="text-xs font-medium">Native language</label>
        <select
          id="native-lang"
          class="w-full h-9 rounded-md border border-input bg-background px-3 text-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
          value={settings.nativeLanguage}
          onchange={async (e) => {
            settings = await updateSettings({ nativeLanguage: (e.target as HTMLSelectElement).value });
          }}
        >
          <option value="de">German</option>
          <option value="es">Spanish</option>
          <option value="fr">French</option>
          <option value="it">Italian</option>
          <option value="pt">Portuguese</option>
          <option value="nl">Dutch</option>
          <option value="pl">Polish</option>
          <option value="ru">Russian</option>
          <option value="ja">Japanese</option>
          <option value="zh">Chinese</option>
          <option value="ko">Korean</option>
        </select>
      </div>

      <!-- Tooltip detail -->
      <div class="space-y-2">
        <span class="text-xs font-medium">Tooltip detail</span>
        <div class="flex gap-1">
          {#each (['compact', 'standard', 'full'] as const) as level}
            <button
              class="flex-1 py-1.5 text-xs font-medium rounded-md transition-colors {settings.tooltipDetail === level ? 'bg-primary text-primary-foreground' : 'bg-muted text-muted-foreground hover:text-foreground'}"
              onclick={() => setTooltipDetail(level)}
            >
              {level.charAt(0).toUpperCase() + level.slice(1)}
            </button>
          {/each}
        </div>
      </div>

      <!-- Auto-capture toggle -->
      <div class="flex items-center justify-between">
        <label for="auto-capture" class="text-xs font-medium">Auto-capture words</label>
        <Switch
          id="auto-capture"
          checked={settings.autoCapture}
          onchange={toggleAutoCapture}
        />
      </div>

      <!-- Pause on this site -->
      {#if currentDomain}
        <div class="flex items-center justify-between">
          <div>
            <label for="pause-site" class="text-xs font-medium block">Pause on this site</label>
            <span class="text-[10px] text-muted-foreground">{currentDomain}</span>
          </div>
          <Switch
            id="pause-site"
            checked={isSitePaused}
            onchange={togglePauseSite}
          />
        </div>
      {/if}

      <Separator />

      <!-- Sign out -->
      <button
        class="text-xs text-muted-foreground hover:text-destructive transition-colors"
        onclick={handleLogout}
      >
        Sign out
      </button>
    </div>
  {/if}
</main>
