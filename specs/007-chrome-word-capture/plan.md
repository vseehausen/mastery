# Implementation Plan: Chrome Word Capture Extension

**Branch**: `007-chrome-word-capture` | **Date**: 2026-02-09 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/007-chrome-word-capture/spec.md`

## Summary

Build a Chrome extension (Manifest V3) that lets users double-click any word while reading web articles to see a contextual translation tooltip. Every lookup automatically captures the word to their Mastery vocabulary for spaced repetition practice in the mobile app. The extension uses WXT framework (cross-browser ready), Svelte + Tailwind for the popup UI, vanilla JS for the lightweight content script, and a new Supabase edge function for word lookup/enrichment. The existing database schema (vocabulary, encounters, sources, meanings) supports the extension with no schema changes needed.

## Technical Context

**Language/Version**: TypeScript 5.x (extension), Deno (edge function)
**Primary Dependencies**: WXT (extension framework), Svelte 5 (popup UI), Tailwind CSS v4 (styling), @supabase/supabase-js (API client)
**Storage**: chrome.storage.local (client-side cache), Supabase PostgreSQL (backend — existing schema)
**Testing**: Vitest (unit tests), Playwright (integration tests with Chrome extension loading)
**Target Platform**: Chrome (Manifest V3), Chromium-based browsers
**Project Type**: Extension + backend edge function
**Performance Goals**: Tooltip in <300ms (new lookups), <50ms (cached), zero page load impact, content script <30KB gzipped
**Constraints**: Minimal permissions (activeTab, contextMenus, storage only), Shadow DOM tooltip isolation, no DOM scanning on load
**Scale/Scope**: ~5,000 word local cache (LRU), single user per extension instance, English-only reading language for V1

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Test-First Development | PASS | Vitest for content script logic (word extraction, context parsing, cache management). Playwright for extension integration tests. Edge function tests follow existing `index_test.ts` pattern. |
| II. Code Quality Standards | PASS | ESLint + Prettier for TypeScript. WXT handles build/bundle. Type-safe throughout. |
| III. Observability | PASS | console.log/debugPrint in development. Edge function logging follows existing pattern (console.error with context prefix). |
| IV. Simplicity (YAGNI) | PASS | V1 scope is minimal — tooltip + popup + backend lookup. No highlighting, no side panel, no offline queue, no phrase detection. Language-agnostic architecture but English-only surface. |
| V. Online-Required Architecture | PASS | Extension requires connectivity for new lookups. Cached words served locally for repeat lookups. No offline capture queue. Explicit "Offline — translation unavailable" message for new lookups without connectivity. |

No violations. No complexity tracking entries needed.

## Project Structure

### Documentation (this feature)

```text
specs/007-chrome-word-capture/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── lookup-api.yaml  # OpenAPI spec for word lookup edge function
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
extension/                          # Chrome extension (WXT project)
├── src/
│   ├── entrypoints/
│   │   ├── content.ts              # Content script — double-click detection, context extraction
│   │   ├── content/
│   │   │   ├── word-detector.ts    # Double-click handler, word extraction from Selection
│   │   │   ├── context-extractor.ts # Sentence extraction from DOM
│   │   │   ├── tooltip.ts          # Shadow DOM tooltip rendering + positioning
│   │   │   └── content.css         # Tooltip styles (injected into Shadow DOM)
│   │   ├── background.ts          # Service worker — API calls, cache, context menu
│   │   └── popup/
│   │       ├── App.svelte          # Popup UI root
│   │       ├── main.ts             # Popup entry
│   │       └── index.html          # Popup HTML shell
│   ├── lib/
│   │   ├── api-client.ts           # Supabase API wrapper for lookup edge function
│   │   ├── cache.ts                # LRU cache manager (chrome.storage.local)
│   │   ├── auth.ts                 # Auth token management (store, check, refresh)
│   │   └── types.ts                # Shared TypeScript types
│   └── assets/
│       └── icons/                  # Extension icons (16, 32, 48, 128)
├── tests/
│   ├── unit/
│   │   ├── word-detector.test.ts
│   │   ├── context-extractor.test.ts
│   │   ├── cache.test.ts
│   │   └── api-client.test.ts
│   └── integration/
│       └── lookup-flow.test.ts     # Playwright test with loaded extension
├── wxt.config.ts                   # WXT configuration
├── tailwind.config.ts              # Tailwind config (shared tokens)
├── tsconfig.json
├── vitest.config.ts
└── package.json

supabase/functions/
├── lookup-word/                    # NEW edge function
│   ├── index.ts                    # Word lookup + enrichment + context translation
│   └── index_test.ts               # Edge function tests
└── _shared/                        # Existing shared utilities (reused)
    ├── supabase.ts
    ├── response.ts
    └── cors.ts
```

**Structure Decision**: The extension lives in a new `extension/` directory at the repo root, following the same pattern as `desktop/` (Tauri) and `mobile/` (Flutter). The backend addition is a single new edge function `lookup-word/` alongside existing functions, reusing the shared utilities. No new database migrations needed — existing `vocabulary`, `encounters`, `sources`, and `meanings` tables support the extension's data model.

## Complexity Tracking

> No violations detected. No entries needed.
