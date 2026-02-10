# Edge Functions Architecture

## Data Flows

### Lookup (browser extension)

1. `lookup-word` receives word + sentence + URL from extension
2. Normalizes word (trim + lowercase), checks user's `vocabulary` by `word`
3. If existing: record encounter, return enrichment data from `global_dictionary`
4. If new: check `word_variants` → `global_dictionary` for shared enrichment data
5. If variant found: create vocabulary (linked), learning card, encounter
6. If unknown: translate (DeepL/Google), create vocabulary (unlinked), learning card, encounter, trigger `enrich-vocabulary`

### Add (Kindle import)

1. `parse-vocab` receives base64-encoded `vocab.db` SQLite file
2. Parses LOOKUPS + WORDS + BOOK_INFO from the Kindle database
3. Deduplicates against existing vocabulary by normalized `word`
4. Batch-inserts new vocabulary + learning cards, creates encounters
5. Triggers enrichment for all newly imported words

### Enrichment

1. `enrich-vocabulary` picks words where `global_dictionary_id IS NULL`
2. Checks `word_variants` → `global_dictionary` — if found, links and returns
3. If not found: translates, calls OpenAI for linguistic data (definition, IPA, synonyms, confusables, examples, CEFR) + **lemma resolution**
4. Upserts `global_dictionary` by `(language_code, lemma)` (UNIQUE handles races via 23505 + fetch)
5. Creates `word_variants` mappings (surface form → global_dictionary, lemma → global_dictionary)
6. Links `vocabulary.global_dictionary_id` to the entry
7. Merges duplicates: if linking causes two vocab entries for the same user to point to the same global_dictionary (e.g., "running" and "ran" both → "run"), moves encounters to the older entry and soft-deletes the duplicate

## Domain Invariants

- Full enrichment data lives in `global_dictionary`. Vocabulary links via `global_dictionary_id`.
- `global_dictionary_id IS NULL` = unresolved (needs enrichment).
- All add paths (lookup, Kindle import) must trigger enrichment for unresolved words.
- `normalize(word) = word.trim().toLowerCase()` — no stemming. Lemma resolution is deferred to AI during enrichment.
- `word_variants` maps surface forms to `global_dictionary` entries. Populated by enrichment only.
- Races on `global_dictionary` resolved by UNIQUE constraint on `(language_code, lemma)` + fetch on 23505.
- Each DB write is idempotent: inserts use ON CONFLICT, so retries are safe.
- `language_code` defaults to `'en'` (words are English).

## Tables

- **global_dictionary**: shared enrichment data, unique on `(language_code, lemma)`. Not user-scoped. `lemma` = AI-resolved base form.
- **word_variants**: surface form → global_dictionary mapping, unique on `(language_code, variant)`. Shared across users. Populated by enrichment.
- **vocabulary**: per-user word identity, unique on `(user_id, word) WHERE deleted_at IS NULL`. FK `global_dictionary_id` (nullable).
- **learning_cards**: FSRS spaced-repetition state, unique on `(user_id, vocabulary_id)`.
- **encounters**: word seen in context. FK to `vocabulary` and `source`.
- **sources**: where words come from — type `website` (extension) or `book` (Kindle). Per-user.
