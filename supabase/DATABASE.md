# Database

Vocabulary learning app. English words, spaced repetition, multi-device sync.

## Tables

### User-scoped

| Table | Purpose | Key columns | Dedup |
|-------|---------|-------------|-------|
| **vocabulary** | Per-user word identity | `word` (normalized), `global_dictionary_id` (nullable = unenriched) | `UNIQUE (user_id, word) WHERE deleted_at IS NULL` |
| **learning_cards** | FSRS spaced-repetition state | `state` (0=new,1=learning,2=review,3=relearning), `stability`, `difficulty`, `due` | `UNIQUE (user_id, vocabulary_id) WHERE deleted_at IS NULL` |
| **encounters** | Word seen in context | `vocabulary_id`, `source_id`, `context` (sentence), `occurred_at` | — |
| **sources** | Origin (book, website) | `type`, `title`, `url`, `domain`, `author`, `asin` | `UNIQUE (user_id, type, title, author)` |
| **review_logs** | Append-only review history | `rating` (1-4), `interaction_mode`, stability/difficulty before+after | — |
| **learning_sessions** | Time-boxed practice sessions | `planned_minutes`, `outcome` (0=active,1=complete,2=partial,3=expired) | — |
| **enrichment_feedback** | User up/down votes on AI data | `global_dictionary_id`, `field_name`, `rating` (up/down) | — |
| **import_sessions** | Kindle import tracking | `total_found`, `imported`, `skipped`, `errors` | — |
| **user_learning_preferences** | Settings | `daily_time_target_minutes`, `target_retention`, `new_words_per_session`, `native_language_code` | `UNIQUE (user_id)` |
| **streaks** | Current/longest streak | `current_count`, `longest_count`, `last_completed_date` | `UNIQUE (user_id)` |

### Shared (not user-scoped)

| Table | Purpose | Key columns | Dedup |
|-------|---------|-------------|-------|
| **global_dictionary** | AI-enriched word data | `lemma`, `translations` (JSONB by lang), `part_of_speech`, `english_definition`, `pronunciation_ipa`, `confusables`, `example_sentences`, `cefr_level` | `UNIQUE (language_code, lemma)` |
| **word_variants** | Surface form → dictionary lookup | `variant` (normalized), `global_dictionary_id`, `method` | `UNIQUE (language_code, variant)` |

### Conventions

- **Soft delete**: `deleted_at` on vocabulary, learning_cards, encounters, sources. Reactivate by clearing it.
- **Sync columns**: `is_pending_sync`, `version`, `last_synced_at` on all synced tables.
- **RLS**: Every user-scoped table enforces `auth.uid() = user_id`. `word_variants` is read-only for authenticated, write for service_role.

## Relationships

```
word_variants ──→ global_dictionary ←── vocabulary ──→ user
                                            ↑
                                       encounters ──→ sources
                                            ↑
                                       learning_cards
                                            ↑
                                       review_logs ──→ learning_sessions
```

`vocabulary.global_dictionary_id` is the bridge between per-user state and shared enrichment. `NULL` means the word hasn't been enriched yet.

## Flows

### Lookup (browser extension → `lookup-word`)

```
raw_word → normalize (trim+lowercase)
  → check vocabulary(user_id, word)
    → existing: record encounter, return enrichment
    → new: check word_variants(variant) → global_dictionary
      → variant found: create vocab (linked), card, encounter
      → unknown: translate (DeepL), create vocab (unlinked), card, encounter
         → fire-and-forget: trigger enrichment
```

### Import (Kindle → `parse-vocab`)

```
vocab.db (base64 SQLite) → parse LOOKUPS+WORDS+BOOK_INFO
  → classify each entry:
    → active: encounter only
    → soft-deleted: reactivate vocab+card, add encounter
    → new: insert vocab+card, add encounter
  → trigger enrichment for new+reactivated words
```

### Enrichment (`enrich-vocabulary`)

```
vocabulary_id → fetch word
  → check word_variants → global_dictionary
    → found: link vocabulary, merge duplicates, done
  → translate (DeepL/Google)
  → AI enhance (OpenAI gpt-4o-mini): lemma, definition, synonyms, confusables, examples...
  → upsert global_dictionary by (language_code, lemma)
  → upsert word_variants: surface_form → dict, lemma → dict
  → link vocabulary.global_dictionary_id
  → merge: if another vocab for same user points to same dict entry,
    keep oldest, move encounters, soft-delete duplicate+card
```

### Sync (mobile ↔ `sync`)

- **Push**: `{ table, operation, id, data, version }` — optimistic locking via `version` column. Conflicts returned if server version > client version.
- **Pull**: `{ lastSyncedAt }` → returns all rows with `updated_at > lastSyncedAt` across all synced tables.

## Edge Function APIs

### `POST /lookup-word`

Look up a word from the browser extension. Creates vocab + card + encounter if new.

**Request**: `{ raw_word, sentence, url, title, native_lang? }` (JWT)
**Response**: `{ lemma, raw_word, translation, pronunciation, part_of_speech, english_definition, context_original, context_translated, stage, is_new, vocabulary_id }`

### `GET /lookup-word/batch-status`

Page-level vocabulary statistics for the extension badge.

**Query**: `?url=...&native_lang=de` (JWT)
**Response**: `{ total_words, page_words: [{ lemma, translation, stage }] }`

### `POST /enrich-vocabulary/request`

Enrich vocabulary with AI-generated data. Called by user (JWT) or server (service role).

**Request (JWT)**: `{ vocabulary_ids?, native_language_code, batch_size?, force_re_enrich? }`
**Request (service role)**: `{ vocabulary_ids, native_language_code?, batch_size? }`
**Response**: `{ enriched: [{ vocabulary_id, word, global_dictionary_id }], failed: [{ vocabulary_id, error }], skipped: [...], buffer_status? }`

### `GET /enrich-vocabulary/status`

Check how many words are enriched vs pending.

**Response (JWT)**: `{ enriched_count, un_enriched_count, buffer_target, pending_in_queue, needs_replenishment }`

### `POST /parse-vocab`

Import Kindle Vocabulary Builder database.

**Request**: `{ file (base64), native_language_code? }` (JWT or X-Dev-Secret)
**Response**: `{ totalParsed, imported, encounters, skipped, errors? }`

### `POST /sync/push`

Push client changes with optimistic locking.

**Request**: `{ changes: [{ table, operation, id, data, version? }] }` (JWT)
**Response**: `{ applied, syncedAt }` or `409 { applied, conflicts: [{ id, table, serverVersion, serverUpdatedAt }], syncedAt }`

Allowed tables: sources, encounters, vocabulary, learning_cards, learning_sessions, streaks, user_learning_preferences, confusable_sets, confusable_set_members.

### `POST /sync/pull`

Pull all changes since last sync.

**Request**: `{ lastSyncedAt? }` (JWT)
**Response**: `{ sources, encounters, vocabulary, learning_cards, learning_sessions, streaks, user_learning_preferences, confusable_sets, confusable_set_members, syncedAt }`

### `POST /process-learning-cards`

Create missing learning cards for vocabulary without one.

**Request**: `{ userId? }` (JWT or X-Dev-Secret)
**Response**: `{ processed, skipped?, totalVocabulary?, errors?, message? }`

### RPC: `get_session_cards(p_user_id, p_limit)`

Single query for all data needed in a practice session. Returns cards with vocabulary, enrichment, latest encounter context, confusable flag, and non-translation success count. Only returns enriched vocabulary (`global_dictionary_id IS NOT NULL`). Sorted: new cards last, leeches first, then by due date.

### RPC: `get_vocabulary_stage_counts(p_user_id)`

Returns `(stage, count)` rows for dashboard stats. Stages: captured, practicing, stabilizing, active, mastered.

## Rationale

**Why `word_variants` instead of stemming?** Porter stemming truncates words into non-words ("running" → "run" works, but "better" → "better" ≠ "good"). AI resolves the true lemma during enrichment and populates variant mappings. The fast path stays dumb: `trim().toLowerCase()`.

**Why `global_dictionary_id` nullable?** Words enter as unlinked stubs (immediate response to user). Enrichment runs async and links them later. This decouples lookup latency from AI processing time.

**Why merge after enrichment?** Two surface forms ("ran", "running") may resolve to the same lemma ("run"). After linking, if a user has both, merge into one vocabulary entry to avoid duplicate reviews.

**Why soft delete?** Re-encountering a deleted word reactivates it instead of creating a new row. Preserves encounter history and learning progress.

**Why partial unique index on vocabulary?** `UNIQUE (user_id, word) WHERE deleted_at IS NULL` allows soft-deleted rows to coexist with an active row for the same word. Trade-off: `ON CONFLICT` doesn't work with partial indexes — app-level dedup required.
