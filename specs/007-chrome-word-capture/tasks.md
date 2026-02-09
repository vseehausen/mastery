# Tasks: Chrome Word Capture Extension

**Input**: Design documents from `/specs/007-chrome-word-capture/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/lookup-api.yaml, quickstart.md

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Initialize the WXT extension project and configure build tooling

- [ ] T001 Initialize WXT project with Svelte + TypeScript in `extension/`, configure `extension/wxt.config.ts` for Chrome MV3 target, and create `extension/package.json` with dependencies: wxt, svelte, @supabase/supabase-js
- [ ] T002 Configure Tailwind CSS v4 in `extension/tailwind.config.ts` and `extension/src/assets/app.css` with shared design tokens matching `desktop/` styles
- [ ] T003 [P] Configure ESLint + Prettier in `extension/.eslintrc.js` and `extension/.prettierrc`, add lint/format scripts to `extension/package.json`
- [ ] T004 [P] Configure Vitest in `extension/vitest.config.ts` with TypeScript support and jsdom environment for DOM testing
- [ ] T005 [P] Create extension icon assets (16, 32, 48, 128px) in `extension/src/assets/icons/`
- [ ] T006 Create environment configuration in `extension/.env.example` with `WXT_SUPABASE_URL` and `WXT_SUPABASE_ANON_KEY` variables, and document in `extension/README.md`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**CRITICAL**: No user story work can begin until this phase is complete

- [ ] T007 Implement shared TypeScript types in `extension/src/lib/types.ts`: LookupRequest, LookupResponse, CacheEntry, ExtensionStorage, StatsResponse interfaces (per contracts/lookup-api.yaml and data-model.md)
- [ ] T008 Implement Supabase API client in `extension/src/lib/api-client.ts`: wrapper around @supabase/supabase-js with `lookupWord(request: LookupRequest): Promise<LookupResponse>` and `getStats(url?: string): Promise<StatsResponse>` methods targeting the `lookup-word` edge function
- [ ] T009 Implement auth module in `extension/src/lib/auth.ts`: `signIn(email, password)`, `signOut()`, `getSession()`, `isAuthenticated()`, `onAuthStateChange(callback)` using Supabase Auth with token storage in `chrome.storage.local` under the `auth` key
- [ ] T010 Implement LRU cache manager in `extension/src/lib/cache.ts`: `get(lemma)`, `set(lemma, entry)`, `getPageWords(url)`, `addPageWord(url, lemma)`, `prune()` operating on `chrome.storage.local` under `vocabulary` key with max 5,000 entries and batch eviction of 500 oldest by `lastAccessed`
- [ ] T011 Implement the `lookup-word` Supabase edge function in `supabase/functions/lookup-word/index.ts`: POST handler that accepts `{ raw_word, sentence, url, title }`, calls LLM (OpenAI) for lemmatization + translation + IPA + context sentence translation, upserts vocabulary/source/encounter/meaning/learning_card records, and returns LookupResponse. GET handler for `/batch-status` returning StatsResponse. Reuse `_shared/` utilities for auth, CORS, responses
- [ ] T012 Write edge function tests in `supabase/functions/lookup-word/index_test.ts`: test new word lookup, repeat word lookup (new encounter), multi-word phrase handling, missing auth, invalid request body

**Checkpoint**: Foundation ready — extension project builds, edge function deployed, auth/cache/API layers tested

---

## Phase 3: User Story 1 — Look Up a Word While Reading (Priority: P1) MVP

**Goal**: User double-clicks a word on any webpage → tooltip appears within 300ms with translation, pronunciation, context sentences, and auto-saves to vocabulary

**Independent Test**: Double-click any word on any webpage. Tooltip appears with lemma, IPA, translation, highlighted original sentence, highlighted translated sentence, and "Saved" confirmation. Word appears in Supabase vocabulary table.

### Implementation for User Story 1

- [ ] T013 [US1] Implement word detector in `extension/src/entrypoints/content/word-detector.ts`: attach `dblclick` listener to `document`, extract selected word from `window.getSelection()`, filter out non-word text (numbers, URLs), ignore events inside input/textarea/contenteditable elements, and emit `{ rawWord, position }` to the content script controller
- [ ] T014 [US1] Implement context extractor in `extension/src/entrypoints/content/context-extractor.ts`: given a word and its anchor node, walk up to the nearest block-level container (p, div, li, td, h1-h6), split by sentence boundaries, return the sentence containing the word. Fallback to first 200 characters if no sentence boundary found. Export `extractSentence(word, anchorNode): string`
- [ ] T015 [US1] Implement tooltip renderer in `extension/src/entrypoints/content/tooltip.ts` and `extension/src/entrypoints/content/content.css`: create Shadow DOM host element, render tooltip with sections for lemma + IPA, translation (bold), divider, original context sentence (word wrapped in `<em>`), translated context sentence (word wrapped in `<em>`), and status line ("Saved" for new words, stage badge + "New context saved" for existing). Position below the double-clicked word (flip above if near viewport bottom, never overlap the word). Auto-dismiss on click-outside or scroll. Show sign-in prompt for unauthenticated users.
- [ ] T016 [US1] Implement message bridge in `extension/src/entrypoints/content.ts`: orchestrate the content script by importing word-detector, context-extractor, and tooltip. On double-click: extract word + sentence + page URL/title, send `chrome.runtime.sendMessage({ type: 'lookup', payload })` to service worker, render tooltip with response data. Handle loading state (show nothing until data arrives — 300ms target). Handle error responses with user-friendly message.
- [ ] T017 [US1] Implement service worker in `extension/src/entrypoints/background.ts`: listen for `chrome.runtime.onMessage` with type `'lookup'`, check auth status (if not authenticated, return `{ needsAuth: true }`), check local cache for the word, if cached return immediately, otherwise call `apiClient.lookupWord()`, update cache with response, return LookupResponse to content script. Handle network errors with appropriate error messages.

**Checkpoint**: User Story 1 fully functional — double-click any word → tooltip with full translation data → word saved to backend

---

## Phase 4: User Story 2 — Context Menu Word Lookup (Priority: P2)

**Goal**: User selects text, right-clicks, chooses "Look up in Mastery" → same tooltip behavior as double-click

**Independent Test**: Select a word or phrase, right-click, choose "Look up in Mastery". Tooltip appears with translation and context data. Multi-word phrases are stored as-is.

### Implementation for User Story 2

- [ ] T018 [US2] Register context menu in `extension/src/entrypoints/background.ts`: add `chrome.contextMenus.create({ id: 'mastery-lookup', title: 'Look up in Mastery', contexts: ['selection'] })` on service worker install. Add `chrome.contextMenus.onClicked` listener that sends the selected text + tab URL/title through the same lookup flow as double-click (reuse existing cache check → API call → response pattern)
- [ ] T019 [US2] Handle context menu trigger in `extension/src/entrypoints/content.ts`: listen for messages from service worker with type `'contextMenuLookup'` containing the lookup response, extract the selected text position from the current selection, render the tooltip at the selection position using the same tooltip renderer from T015

**Checkpoint**: User Story 2 functional — right-click selected text → "Look up in Mastery" → tooltip with same behavior as double-click

---

## Phase 5: User Story 3 — Popup with Page Stats (Priority: P3)

**Goal**: User clicks toolbar icon → popup shows total word count, words looked up on current page with stage badges, and settings

**Independent Test**: Look up 2-3 words on a page. Click toolbar icon. Popup shows total count, current page words with stage badges, and settings toggle.

### Implementation for User Story 3

- [ ] T020 [US3] Create popup HTML shell in `extension/src/entrypoints/popup/index.html` with Svelte mount point, and popup entry in `extension/src/entrypoints/popup/main.ts` that initializes the Svelte app with Tailwind styles
- [ ] T021 [US3] Implement popup Svelte component in `extension/src/entrypoints/popup/App.svelte`: show login form (email + password) when unauthenticated, show stats view when authenticated. Stats view displays: total tracked word count (from `getStats()`), list of words looked up on the current tab URL (from `getStats(url)` or local `pageWords` cache) with stage badges (color-coded by progress_stage), and a settings section. Settings section shows user email and sign-out button.
- [ ] T022 [US3] Implement page word tracking in `extension/src/entrypoints/background.ts`: after each successful lookup, store the lemma in the `pageWords` map keyed by tab URL (using cache module's `addPageWord`). When popup requests current page words, return from `pageWords` cache with stage data. Clear page words when tab navigates to a new URL (listen to `chrome.tabs.onUpdated` with `changeInfo.url`).

**Checkpoint**: User Story 3 functional — popup shows total count, per-page word list with stages, login/logout, settings

---

## Phase 6: User Story 4 — Offline Cached Lookups (Priority: P4)

**Goal**: Previously cached words show tooltip offline; new lookups show "Offline — translation unavailable"

**Independent Test**: Look up a word online. Go offline (DevTools Network → Offline). Double-click same word (cached tooltip appears). Double-click new word ("Offline" message appears).

### Implementation for User Story 4

- [ ] T023 [US4] Add offline detection in `extension/src/entrypoints/background.ts`: before making API calls, check `navigator.onLine`. If offline and word is in cache, return cached data. If offline and word is NOT in cache, return `{ offline: true }` error response. Content script tooltip handler renders "Offline — translation unavailable" message for offline errors.

**Checkpoint**: User Story 4 functional — cached words work offline, new lookups show offline message

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Edge cases, error handling, and production readiness

- [ ] T024 [P] Add non-word filtering to `extension/src/entrypoints/content/word-detector.ts`: reject selections that are purely numeric, contain URLs, or are longer than 50 characters (for double-click — context menu allows up to 100 chars for phrases)
- [ ] T025 [P] Add token expiry handling in `extension/src/lib/auth.ts`: detect expired JWT on API 401 responses, clear stored auth, notify content script to show sign-in prompt on next lookup, show "Session expired" in popup
- [ ] T026 [P] Add error tooltip variant in `extension/src/entrypoints/content/tooltip.ts`: render "Couldn't translate — try again" for backend errors (non-offline), with same positioning and auto-dismiss behavior
- [ ] T027 Build production bundle: add `pnpm build` script in `extension/package.json`, verify output in `extension/.output/chrome-mv3/`, validate manifest.json permissions are minimal (activeTab, contextMenus, storage only — no "browsing activity" warnings)
- [ ] T028 Manual end-to-end validation: load packed extension in Chrome, test on 3 sites (news article, SPA, long-form blog), verify all user stories work, check page load performance impact is zero

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion — BLOCKS all user stories
- **User Story 1 (Phase 3)**: Depends on Foundational (Phase 2)
- **User Story 2 (Phase 4)**: Depends on User Story 1 (reuses tooltip, message bridge, service worker lookup flow)
- **User Story 3 (Phase 5)**: Depends on Foundational (Phase 2) — can run in parallel with US1/US2 if needed
- **User Story 4 (Phase 6)**: Depends on User Story 1 (requires cache and lookup flow to exist)
- **Polish (Phase 7)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational — establishes core lookup pipeline
- **User Story 2 (P2)**: Depends on US1 (reuses tooltip renderer, service worker lookup, cache)
- **User Story 3 (P3)**: Can start after Foundational — popup is independent UI, only needs API client and cache
- **User Story 4 (P4)**: Depends on US1 (requires cache and lookup flow to add offline branching)

### Within Each User Story

- Types/contracts before implementation
- Backend (edge function) before frontend (extension)
- Cache/API layer before content script
- Content script before popup

### Parallel Opportunities

- T003, T004, T005 can all run in parallel (linting, testing, icons — different files)
- T007, T008, T009, T010 touch different files in `extension/src/lib/` but T008 depends on T007 (types)
- T013, T014 can run in parallel (word-detector vs context-extractor — different files)
- T024, T025, T026 can all run in parallel (different files, independent concerns)
- US3 (popup) can run in parallel with US1/US2 (content script) since they are separate entrypoints

---

## Parallel Example: User Story 1

```bash
# These US1 tasks can run in parallel (different files):
Task T013: "Implement word detector in extension/src/entrypoints/content/word-detector.ts"
Task T014: "Implement context extractor in extension/src/entrypoints/content/context-extractor.ts"

# Then sequentially:
Task T015: "Implement tooltip renderer" (independent but needed by T016)
Task T016: "Implement content script orchestration" (depends on T013, T014, T015)
Task T017: "Implement service worker lookup flow" (depends on T008, T009, T010)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T006)
2. Complete Phase 2: Foundational (T007-T012)
3. Complete Phase 3: User Story 1 (T013-T017)
4. **STOP and VALIDATE**: Double-click any word → tooltip → word saved
5. Deploy as unpacked extension for internal testing

### Incremental Delivery

1. Setup + Foundational → Extension project builds, edge function deployed
2. User Story 1 → Core lookup works → Test independently → Internal release
3. User Story 2 → Context menu works → Test independently
4. User Story 3 → Popup with stats works → Test independently
5. User Story 4 → Offline graceful degradation → Test independently
6. Polish → Edge cases, error handling, production bundle → Chrome Web Store submission

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- The edge function (T011) is the most complex single task — it handles LLM integration, DB writes, and response formatting
- Content script tooltip (T015) is the most UX-critical task — Shadow DOM isolation, positioning, and styling
