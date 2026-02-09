# Research: Chrome Word Capture Extension

**Feature**: 007-chrome-word-capture
**Date**: 2026-02-09

## Decision 1: Extension Framework — WXT

**Decision**: Use WXT (wxt.dev) as the extension framework.

**Rationale**: WXT provides Manifest V3 boilerplate, hot reload during development, Vite-based build system (Svelte + Tailwind integrate naturally), and cross-browser output from a single codebase. The project already uses Vite-based tooling in the desktop app. WXT's entrypoint conventions (`src/entrypoints/content.ts`, `src/entrypoints/background.ts`, `src/entrypoints/popup/`) map cleanly to the extension's architecture.

**Alternatives considered**:
- **Plasmo**: Similar capabilities but less mature, opinionated about React. Our stack is Svelte.
- **Raw Manifest V3**: No framework overhead but requires manual hot reload, build config, and cross-browser polyfills. Not worth the maintenance cost.
- **CRXJS**: Vite plugin for Chrome extensions. Good but WXT is more comprehensive and better maintained.

## Decision 2: Content Script Tooltip — Shadow DOM with Vanilla JS

**Decision**: Render the tooltip as a Shadow DOM element using vanilla JS/TS. No framework in the content script.

**Rationale**: The content script runs on every page and must be <30KB gzipped. Svelte adds ~15KB minimum even compiled. The tooltip is a single, static UI element — no reactivity needed. Shadow DOM isolates styles completely from the host page (FR-015). Vanilla JS keeps the content script minimal and fast.

**Alternatives considered**:
- **Svelte in content script**: Would add framework overhead to every page load. Tooltip doesn't need reactivity.
- **iframe isolation**: Heavier than Shadow DOM, harder to position relative to the word, cross-origin restrictions.
- **Direct DOM injection**: No style isolation — host page CSS would break tooltip layout.

## Decision 3: Popup UI — Svelte 5 + Tailwind + shadcn-svelte

**Decision**: Use Svelte 5 with Tailwind CSS v4 and bits-ui (shadcn-svelte successor) for the popup.

**Rationale**: Matches the desktop app's (Tauri) tech stack exactly. Shared design tokens, component patterns, and developer mental model. The popup is a self-contained UI surface where framework overhead is acceptable (~80KB budget). Svelte compiles to minimal JS.

**Alternatives considered**:
- **Vanilla HTML/CSS/JS**: Would work but loses shared component consistency with the desktop app.
- **React**: Not used elsewhere in the project. Would add unnecessary cognitive switching.

## Decision 4: Lemmatization — Backend-Side via LLM

**Decision**: Perform lemmatization on the backend as part of the lookup edge function. The LLM call that translates the word and context sentence also returns the lemma.

**Rationale**: Keeps the content script small (no lemmatizer library shipped to every page). The backend already calls an LLM for translation — adding lemmatization to the same prompt is free. Backend-side lemmatization is already the pattern used by the enrichment pipeline (`stem` column on vocabulary table). For English, LLM-based lemmatization is more accurate than dictionary-based approaches for edge cases.

**Alternatives considered**:
- **Client-side lemmatizer (wink-lemmatizer)**: ~50KB added to content script. Reduces latency for the lemma step but increases bundle size beyond the 30KB target.
- **Separate lemmatization service**: Over-engineered. The LLM already handles this.
- **Dictionary lookup table**: Smaller but less accurate for irregular forms. Not needed when the LLM is already in the loop.

## Decision 5: Translation & Context — Single LLM Call

**Decision**: Use a single LLM API call (OpenAI GPT-4o-mini or similar) to perform word translation, context sentence translation, word-in-context alignment, pronunciation lookup, and lemmatization in one request.

**Rationale**: The spec requires word translation + context sentence translation + word highlighting in both languages + IPA + lemma. Splitting these into separate API calls would exceed the 300ms tooltip target. A single structured prompt returns all fields. The existing enrichment pipeline already uses OpenAI for definitions/synonyms, so the API key and patterns are established.

**Alternatives considered**:
- **DeepL for translation + separate lemmatizer + IPA dictionary**: Multiple round-trips, harder to align highlighted words across languages. Could be faster for raw translation but slower overall.
- **Google Translate API**: Good for word translation but doesn't provide lemmatization or IPA in one call.
- **Two-phase (fast translation first, enrichment later)**: Could show a partial tooltip immediately with just the translation, then fill in context. Adds complexity. The 300ms budget should be achievable with a single fast LLM call + aggressive caching.

## Decision 6: Auth Flow — Email/Password Login in Popup

**Decision**: Users log in via email/password form in the extension popup. Supabase Auth handles authentication and returns a JWT stored in `chrome.storage.local`.

**Rationale**: The mobile app already supports email/password auth via Supabase. The popup provides a natural login surface without redirecting to external pages. The JWT is stored locally and included in API requests as a Bearer token — matching the existing edge function auth pattern. Token refresh is handled by the Supabase client library.

**Alternatives considered**:
- **OAuth redirect to web page**: Opens a new tab for login, requires redirect URI handling. More complex for a simple email/password flow.
- **QR code pairing with mobile app**: Novel UX but high implementation cost. Deferred.
- **OAuth with Google/Apple**: The mobile app supports these, but the extension popup is too small for OAuth buttons in V1. Can be added later.

## Decision 7: Database Schema — No Changes Needed

**Decision**: Use the existing database tables as-is. No new migrations required.

**Rationale**: The existing schema already supports the Chrome extension's data model:
- `vocabulary` table: stores words with `stem` (lemma) and `word` (raw form)
- `encounters` table: stores context sentences with `context`, `source_id`, `occurred_at`
- `sources` table: has `type: 'website'` with `url` and `domain` columns
- `meanings` table: stores translations, definitions, pronunciation, synonyms
- `learning_cards` table: stores FSRS state and `progress_stage`

The extension's word lookup creates records in these existing tables, identical to how Kindle import (Tauri) creates records via the `parse-vocab` edge function.

**Alternatives considered**:
- **New `extension_lookups` table**: Unnecessary duplication. Encounters table already captures everything needed.
- **Adding `translated_context` column to encounters**: Could store the translated sentence, but this is better kept as part of the meaning/enrichment data or cached locally. The translated context is a presentation concern, not a core domain entity.

## Decision 8: Local Cache Strategy — chrome.storage.local with LRU

**Decision**: Use `chrome.storage.local` for caching vocabulary data (translation, pronunciation, stage, lookup count). LRU eviction at ~5,000 entries.

**Rationale**: `chrome.storage.local` persists across browser restarts, has 10MB quota (more than enough for 5,000 word entries), and is the standard storage API for Manifest V3 extensions. LRU eviction prevents unbounded growth. The cache stores only what's needed for instant tooltip rendering — not full encounter history.

**Alternatives considered**:
- **IndexedDB**: More powerful but overkill for a flat key-value cache. Adds complexity.
- **In-memory only**: Lost on service worker restart (MV3 service workers are ephemeral). Not persistent enough.
- **chrome.storage.session**: New in MV3 but clears on browser restart. Not suitable for persistent cache.
