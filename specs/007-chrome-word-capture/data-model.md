# Data Model: Chrome Word Capture Extension

**Feature**: 007-chrome-word-capture
**Date**: 2026-02-09

## Overview

The Chrome extension uses the **existing Mastery database schema** with no new tables or migrations. All entities below map directly to existing tables. This document clarifies how the extension creates and reads records in those tables.

## Entities

### Vocabulary (existing table: `vocabulary`)

The canonical word record. Created on first lookup of a word.

| Field | Type | Extension Usage |
|-------|------|-----------------|
| id | UUID | Auto-generated on insert |
| user_id | UUID | From authenticated user's JWT |
| word | VARCHAR(100) | Raw word as encountered (e.g., "ameliorating") |
| stem | VARCHAR(100) | Lemma returned by LLM (e.g., "ameliorate") |
| content_hash | VARCHAR(64) | Hash of lemma for dedup — extension uses `hash(stem)` |
| created_at | TIMESTAMPTZ | Auto |
| updated_at | TIMESTAMPTZ | Auto |

**Extension behavior**:
- On first lookup: INSERT with `word` = raw form, `stem` = lemma from LLM
- On repeat lookup (same lemma): No new vocabulary record — just add encounter
- Uniqueness: `(user_id, content_hash)` prevents duplicates

### Encounter (existing table: `encounters`)

Each word lookup creates an encounter — the context sentence where the word was found.

| Field | Type | Extension Usage |
|-------|------|-----------------|
| id | UUID | Auto-generated |
| user_id | UUID | From JWT |
| vocabulary_id | UUID | Links to the vocabulary record (by lemma) |
| source_id | UUID | Links to the source (webpage) |
| context | TEXT | Original context sentence with the word |
| locator_json | TEXT | Not used by extension (Kindle-specific) |
| occurred_at | TIMESTAMPTZ | Timestamp of the double-click |
| created_at | TIMESTAMPTZ | Auto |

**Extension behavior**:
- Every lookup creates a new encounter (even for previously tracked words)
- Context contains the original sentence extracted from the DOM

### Source (existing table: `sources`)

The webpage where a word was encountered.

| Field | Type | Extension Usage |
|-------|------|-----------------|
| id | UUID | Auto-generated |
| user_id | UUID | From JWT |
| type | source_type ENUM | Always `'website'` for extension lookups |
| title | VARCHAR(500) | Page title from `document.title` |
| author | VARCHAR(255) | Not used by extension |
| asin | VARCHAR(50) | Not used by extension (Kindle-specific) |
| url | TEXT | Full page URL |
| domain | VARCHAR(255) | Extracted from URL (e.g., "economist.com") |
| created_at | TIMESTAMPTZ | Auto |

**Extension behavior**:
- Upsert on lookup: find existing source by `(user_id, type='website', title, author=null)` or create new
- Domain extracted from URL before insert

### Meaning (existing table: `meanings`)

Translation and definition data for a vocabulary word.

| Field | Type | Extension Usage |
|-------|------|-----------------|
| id | UUID | Auto-generated |
| user_id | UUID | From JWT |
| vocabulary_id | UUID | Links to vocabulary |
| language_code | VARCHAR(5) | User's native language (e.g., "de") |
| primary_translation | TEXT | Word translation (e.g., "allgegenwärtig") |
| english_definition | TEXT | English definition from LLM |
| part_of_speech | VARCHAR(20) | From LLM (e.g., "adjective") |
| synonyms | JSONB | From LLM |
| is_primary | BOOLEAN | TRUE for extension-created meanings |
| source | VARCHAR(20) | `'ai'` for LLM-generated |
| created_at | TIMESTAMPTZ | Auto |

**Extension behavior**:
- Created on first lookup of a new word
- On repeat lookup: existing meaning reused, not duplicated

### Learning Card (existing table: `learning_cards`)

FSRS spaced repetition state. Created alongside vocabulary on first lookup.

| Field | Type | Extension Usage |
|-------|------|-----------------|
| id | UUID | Auto-generated |
| user_id | UUID | From JWT |
| vocabulary_id | UUID | Links to vocabulary |
| state | INTEGER | Default 0 (new) |
| progress_stage | VARCHAR(20) | Default `'new'` — displayed as stage badge in tooltip/popup |
| due | TIMESTAMPTZ | Default NOW() |
| stability | DOUBLE PRECISION | Default 0.0 |
| difficulty | DOUBLE PRECISION | Default 0.0 |

**Extension behavior**:
- Created on first word lookup (state=new, stage=new)
- Read by extension for tooltip stage badge display
- Updated only by the mobile app during practice sessions (never by extension)

## Local Cache Schema (chrome.storage.local)

The extension maintains a local cache for fast tooltip rendering on repeat lookups.

```typescript
interface CacheEntry {
  lemma: string;              // Canonical word form
  translation: string;        // Native language translation
  pronunciation: string;      // IPA pronunciation
  stage: string;              // Learning stage from learning_cards.progress_stage
  lookupCount: number;        // How many times looked up
  lastAccessed: number;       // Unix timestamp for LRU eviction
}

interface ExtensionStorage {
  vocabulary: Record<string, CacheEntry>;  // Keyed by lemma, max ~5,000 entries
  settings: {
    nativeLanguage: string;     // e.g., "de" — pulled from account on login
  };
  auth: {
    accessToken: string;
    refreshToken: string;
    userId: string;
    expiresAt: number;
  };
  pageWords: Record<string, string[]>;  // Keyed by tab URL, value is array of lemmas looked up
}
```

**LRU eviction**: When cache exceeds 5,000 entries, remove the 500 entries with the oldest `lastAccessed` timestamp (batch eviction to avoid per-lookup overhead).

## Data Flow

### First Lookup (new word)

```
1. Content script → Service worker: { rawWord, sentence, url, title }
2. Service worker → check cache: miss
3. Service worker → POST /lookup-word: { raw_word, sentence, url, title }
4. Edge function:
   a. Call LLM: get lemma, translation, pronunciation, IPA, context translation, definition
   b. Hash lemma → content_hash
   c. Check vocabulary: does (user_id, content_hash) exist?
   d. No → INSERT vocabulary, meaning, learning_card, source (upsert), encounter
   e. Return: { lemma, translation, pronunciation, contextOriginal, contextTranslated, stage: "new", isNew: true }
5. Service worker → cache entry + respond to content script
6. Content script → render tooltip with "Saved"
```

### Repeat Lookup (existing word)

```
1. Content script → Service worker: { rawWord, sentence, url, title }
2. Service worker → check cache: HIT
3. Service worker → render tooltip from cache immediately (<50ms)
4. Service worker → POST /lookup-word in background (add new encounter + get fresh stage)
5. Edge function:
   a. Call LLM: get context translation for new sentence
   b. Find vocabulary by (user_id, content_hash of lemma)
   c. INSERT encounter with new context + source
   d. Return: { lemma, translation, pronunciation, contextOriginal, contextTranslated, stage, isNew: false }
6. Service worker → update cache with fresh stage
```

## State Transitions

The extension only creates records — it never updates learning state. State transitions are owned by the mobile app:

```
Extension creates:   vocabulary (word=raw, stem=lemma)
                     → meaning (translation, definition)
                     → learning_card (state=new, stage=new)
                     → encounter (context sentence)
                     → source (webpage URL)

Mobile app updates:  learning_card.state (FSRS algorithm)
                     learning_card.progress_stage (new → practicing → stabilizing → known → mastered)

Extension reads:     learning_card.progress_stage (for tooltip/popup badges)
```
