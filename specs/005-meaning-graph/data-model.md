# Data Model: Meaning Graph

**Feature**: 005-meaning-graph | **Date**: 2026-01-31

## Entity Relationship Overview

```
Vocabulary (existing)
  ├── 1:N → Meaning
  │         ├── primary_translation, alternatives[], english_definition
  │         ├── language_code, confidence, is_active, sort_order
  │         └── 1:N → Cue
  │                   └── cue_type, content, hint
  ├── N:M → ConfusableSet (via confusable_set_members)
  │         ├── words[], explanations[], example_sentences[]
  │         └── language_code
  ├── 1:N → MeaningEdit
  │         └── meaning_id, field, original_value, user_value
  └── 1:1 → EnrichmentQueue (optional, when pending)
              └── status, priority, attempts, last_error

UserLearningPreferences (existing, extended)
  └── + native_language_code (default: 'de')
  └── + meaning_display_mode ('native', 'english', 'both')
```

## New Tables

### meanings

Stores distinct senses for a vocabulary word. One vocabulary can have multiple meanings.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PK, default gen_random_uuid() | |
| user_id | UUID | NOT NULL, FK → auth.users | Row-level security |
| vocabulary_id | UUID | NOT NULL, FK → vocabulary | Parent word |
| language_code | VARCHAR(5) | NOT NULL | ISO 639-1 code of translation language |
| primary_translation | TEXT | NOT NULL | Best translation in native language |
| alternative_translations | JSONB | NOT NULL, default '[]' | Array of up to 5 alternative translations |
| english_definition | TEXT | NOT NULL | One-line English definition |
| extended_definition | TEXT | | Optional longer explanation |
| part_of_speech | VARCHAR(20) | | noun, verb, adjective, adverb, other |
| synonyms | JSONB | NOT NULL, default '[]' | Array of English synonyms (up to 3) |
| confidence | DOUBLE PRECISION | NOT NULL, default 1.0 | AI confidence score (0.0-1.0) |
| is_primary | BOOLEAN | NOT NULL, default false | Whether this is the user's primary meaning |
| is_active | BOOLEAN | NOT NULL, default true | Whether included in learning |
| sort_order | INTEGER | NOT NULL, default 0 | Display ordering |
| source | VARCHAR(20) | NOT NULL, default 'ai' | 'ai', 'deepl', 'google', 'context', 'user' |
| created_at | TIMESTAMPTZ | NOT NULL, default NOW() | |
| updated_at | TIMESTAMPTZ | NOT NULL, default NOW() | |
| deleted_at | TIMESTAMPTZ | | Soft delete |
| last_synced_at | TIMESTAMPTZ | | |
| is_pending_sync | BOOLEAN | NOT NULL, default false | |
| version | INTEGER | NOT NULL, default 1 | Conflict resolution |

**Indexes**:
- `(user_id, vocabulary_id)` — fetch meanings for a word
- `(user_id, is_active)` — filter active meanings

**Constraints**:
- At most one meaning per vocabulary_id can have `is_primary = true` (enforced via partial unique index or application logic)

### cues

Pre-generated prompt triggers for learning sessions. Each cue belongs to one meaning.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PK, default gen_random_uuid() | |
| user_id | UUID | NOT NULL, FK → auth.users | |
| meaning_id | UUID | NOT NULL, FK → meanings | Parent meaning |
| cue_type | VARCHAR(20) | NOT NULL | 'translation', 'definition', 'synonym', 'context_cloze', 'disambiguation' |
| prompt_text | TEXT | NOT NULL | The text shown to the user as the prompt |
| answer_text | TEXT | NOT NULL | The correct answer |
| hint_text | TEXT | | Optional hint shown on failure |
| metadata | JSONB | default '{}' | Type-specific data (e.g., distractors for disambiguation) |
| created_at | TIMESTAMPTZ | NOT NULL, default NOW() | |
| updated_at | TIMESTAMPTZ | NOT NULL, default NOW() | |
| deleted_at | TIMESTAMPTZ | | |
| last_synced_at | TIMESTAMPTZ | | |
| is_pending_sync | BOOLEAN | NOT NULL, default false | |
| version | INTEGER | NOT NULL, default 1 | |

**Indexes**:
- `(meaning_id, cue_type)` — fetch cues by type for a meaning
- `(user_id)` — RLS

**Cue type details**:

| cue_type | prompt_text | answer_text | metadata |
|----------|-------------|-------------|----------|
| translation | Primary translation (e.g., "effizient") | English word | {} |
| definition | English definition sentence | English word | {} |
| synonym | Synonym phrase/description | English word | {} |
| context_cloze | Sentence with ___ blank | English word | `{"full_sentence": "..."}` |
| disambiguation | Cloze sentence for MCQ | English word | `{"options": ["effective","efficient","fast"], "explanations": {"efficient": "minimal waste", ...}}` |

### confusable_sets

Groups of commonly confused words.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PK, default gen_random_uuid() | |
| user_id | UUID | NOT NULL, FK → auth.users | |
| language_code | VARCHAR(5) | NOT NULL | Native language for explanations |
| words | JSONB | NOT NULL | Array of English words in the set |
| explanations | JSONB | NOT NULL | Map: word → one-line distinction |
| example_sentences | JSONB | default '{}' | Map: word → example sentence |
| created_at | TIMESTAMPTZ | NOT NULL, default NOW() | |
| updated_at | TIMESTAMPTZ | NOT NULL, default NOW() | |
| deleted_at | TIMESTAMPTZ | | |
| last_synced_at | TIMESTAMPTZ | | |
| is_pending_sync | BOOLEAN | NOT NULL, default false | |
| version | INTEGER | NOT NULL, default 1 | |

**Indexes**:
- `(user_id)` — RLS

### confusable_set_members

Join table linking vocabulary to confusable sets.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PK, default gen_random_uuid() | |
| confusable_set_id | UUID | NOT NULL, FK → confusable_sets | |
| vocabulary_id | UUID | NOT NULL, FK → vocabulary | |
| created_at | TIMESTAMPTZ | NOT NULL, default NOW() | |

**Indexes**:
- UNIQUE `(confusable_set_id, vocabulary_id)`
- `(vocabulary_id)` — find confusable sets for a word

### meaning_edits

Tracks user overrides of auto-generated data.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PK, default gen_random_uuid() | |
| user_id | UUID | NOT NULL, FK → auth.users | |
| meaning_id | UUID | NOT NULL, FK → meanings | |
| field_name | VARCHAR(50) | NOT NULL | e.g., 'primary_translation', 'english_definition' |
| original_value | TEXT | NOT NULL | Auto-generated value |
| user_value | TEXT | NOT NULL | User's override |
| created_at | TIMESTAMPTZ | NOT NULL, default NOW() | |

**Indexes**:
- `(meaning_id, field_name)` — lookup edit for a specific field

### enrichment_queue

Tracks which vocabulary words need enrichment. Server-side only (not synced to mobile).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PK, default gen_random_uuid() | |
| user_id | UUID | NOT NULL, FK → auth.users | |
| vocabulary_id | UUID | NOT NULL, FK → vocabulary | |
| status | VARCHAR(20) | NOT NULL, default 'pending' | 'pending', 'processing', 'completed', 'failed' |
| priority | INTEGER | NOT NULL, default 0 | Higher = process first |
| attempts | INTEGER | NOT NULL, default 0 | Retry count |
| last_error | TEXT | | Error message from last attempt |
| last_attempted_at | TIMESTAMPTZ | | |
| completed_at | TIMESTAMPTZ | | |
| created_at | TIMESTAMPTZ | NOT NULL, default NOW() | |

**Indexes**:
- UNIQUE `(user_id, vocabulary_id)` — one queue entry per word per user
- `(user_id, status, priority DESC)` — fetch next batch to process

## Modified Tables

### user_learning_preferences (existing)

Add two columns:

| Column | Type | Default | Description |
|--------|------|---------|-------------|
| native_language_code | VARCHAR(5) | 'de' | User's native language (ISO 639-1) |
| meaning_display_mode | VARCHAR(10) | 'both' | 'native', 'english', 'both' |

## Drift Table Definitions (Mobile SQLite)

New tables to add to `mobile/lib/data/database/tables.dart`:

- `Meanings` — mirrors PostgreSQL `meanings` table (all columns except `enrichment_queue` which is server-only)
- `Cues` — mirrors PostgreSQL `cues` table
- `ConfusableSets` — mirrors PostgreSQL `confusable_sets` table
- `ConfusableSetMembers` — mirrors PostgreSQL join table
- `MeaningEdits` — mirrors PostgreSQL `meaning_edits` table

The `enrichment_queue` table is **server-only** and NOT synced to mobile. Mobile triggers enrichment via API calls and receives results through the sync pull.

## State Transitions

### Enrichment Queue Lifecycle

```
pending → processing → completed
                    ↘ failed → pending (retry, max 3 attempts)
```

### Meaning Lifecycle

```
[created by AI] → [active, is_primary=true for first meaning]
                → [user edits] → MeaningEdit record created, meaning.primary_translation updated
                → [user pins alternative] → swap is_primary flags
                → [user deactivates] → is_active=false, excluded from learning
                → [user deletes] → soft delete (deleted_at set)
```

### Learning Card + Cue Integration

```
LearningCard.state/stability → CueSelector determines maturity stage
                             → Weighted random selects cue_type
                             → Cue record provides prompt_text/answer_text
                             → Card widget renders cue-type-specific UI
                             → User response → SRS scheduler (existing flow unchanged)
```
