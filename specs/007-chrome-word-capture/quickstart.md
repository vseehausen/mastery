# Quickstart: Chrome Word Capture Extension

**Feature**: 007-chrome-word-capture
**Date**: 2026-02-09

## Prerequisites

- Node.js 20+
- pnpm (or npm)
- Chrome browser
- Supabase CLI (`supabase` command) for edge function development
- Access to Supabase project credentials (URL + anon key)

## Setup

### 1. Initialize the Extension Project

```bash
cd extension/
pnpm install
```

### 2. Configure Environment

Create `extension/.env`:

```env
WXT_SUPABASE_URL=https://<project-ref>.supabase.co
WXT_SUPABASE_ANON_KEY=<anon-key>
```

### 3. Development Mode

```bash
# Start WXT dev server (auto-reloads on changes)
cd extension/
pnpm dev
```

This opens Chrome with the extension loaded. Changes to content script, popup, or background service worker hot-reload automatically.

### 4. Edge Function Development

```bash
# Serve edge functions locally
supabase functions serve lookup-word --env-file supabase/.env.local
```

### 5. Run Tests

```bash
# Unit tests (content script logic, cache, API client)
cd extension/
pnpm test

# Edge function tests
cd supabase/functions/lookup-word/
deno test index_test.ts
```

### 6. Build for Production

```bash
cd extension/
pnpm build
```

Output is in `extension/.output/chrome-mv3/`. Load as unpacked extension or pack as `.crx`.

## Key Development Flows

### Testing Word Lookup

1. Start dev server (`pnpm dev`)
2. Navigate to any article (e.g., economist.com)
3. Log in via the popup (click extension icon → enter email/password)
4. Double-click any word → tooltip should appear
5. Check Supabase dashboard: vocabulary, encounters, sources tables should have new records

### Testing the Popup

1. Look up 2-3 words on a page
2. Click the extension toolbar icon
3. Verify: total word count, page-specific word list with stage badges, settings link

### Testing Offline Behavior

1. Look up a word while online (verify it caches)
2. Disconnect network (Chrome DevTools → Network → Offline)
3. Double-click the same word → should show from cache
4. Double-click a new word → should show "Offline — translation unavailable"

## Architecture Notes

- **Content script** (`src/entrypoints/content.ts`): Runs on every page. Attaches double-click listener. Extracts word + sentence. Sends to service worker. Renders tooltip via Shadow DOM.
- **Service worker** (`src/entrypoints/background.ts`): Handles API calls, local cache (chrome.storage.local), context menu registration. Bridges content script ↔ backend.
- **Popup** (`src/entrypoints/popup/`): Svelte app showing stats. Reads from service worker/cache.
- **Edge function** (`supabase/functions/lookup-word/`): Receives word + sentence, calls LLM for translation/lemmatization, writes to DB, returns enriched data.

## Relevant Existing Code

- `supabase/functions/_shared/` — Reusable auth, CORS, response helpers
- `supabase/functions/enrich-vocabulary/` — Similar LLM enrichment pattern
- `desktop/src/` — Svelte + Tailwind + bits-ui reference for popup UI patterns
