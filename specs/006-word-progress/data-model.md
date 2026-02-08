# Data Model: Word-Level Progress & Motivation

**Feature**: 006-word-progress
**Date**: 2026-02-08
**Status**: Draft

## Overview

This document defines the data entities, relationships, and state transitions for word-level progress tracking. The feature extends existing tables (`learning_cards`) and uses existing data sources (`review_logs`, `meanings`) to compute progress stages.

---

## Core Entities

### 1. ProgressStage (Enum)

**Purpose**: Represents a vocabulary word's current competence level.

**Values**:
- `captured` - Word captured from reading, not yet reviewed
- `practicing` - Active in SRS rotation, early learning (first review completed)
- `stabilizing` - Successful recalls across time, emerging consolidation
- `active` - Retrieved from non-translation cues (production recall)
- `mastered` - High stability, rare reviews, low lapse rate

**Properties**:
- Deterministic (computed from learning data, not stored as independent state)
- One-way progression with regression rules (e.g., Active → Stabilizing if lapses increase)
- Mapped to UI labels, colors, and semantic meanings

**Dart Implementation**:
```dart
enum ProgressStage {
  captured,
  practicing,
  stabilizing,
  active,
  mastered;

  String get displayName {
    switch (this) {
      case captured: return 'Captured';
      case practicing: return 'Practicing';
      case stabilizing: return 'Stabilizing';
      case active: return 'Active';
      case mastered: return 'Mastered';
    }
  }

  Color getColor(MasteryColorScheme colors) {
    switch (this) {
      case captured: return colors.mutedForeground;
      case practicing: return colors.warning; // Amber
      case stabilizing: return colors.accent; // Amber
      case active: return colors.success; // Green
      case mastered: return colors.success.withValues(alpha: 0.8); // Emerald
    }
  }
}
```

---

### 2. StageTransition (Value Object)

**Purpose**: Represents a change from one progress stage to another during a learning session.

**Attributes**:
- `vocabularyId` (UUID): Word that transitioned
- `wordText` (String): Word display text (for UI)
- `fromStage` (ProgressStage?): Previous stage (null if first transition)
- `toStage` (ProgressStage): New stage
- `timestamp` (DateTime): When transition occurred

**Lifecycle**:
- Created during learning session when stage changes after review
- Collected in memory during session (not persisted to database)
- Aggregated for session recap display

**Dart Implementation**:
```dart
class StageTransition {
  final String vocabularyId;
  final String wordText;
  final ProgressStage? fromStage;
  final ProgressStage toStage;
  final DateTime timestamp;

  StageTransition({
    required this.vocabularyId,
    required this.wordText,
    this.fromStage,
    required this.toStage,
    required this.timestamp,
  });

  bool get isRareAchievement => toStage == ProgressStage.active || toStage == ProgressStage.mastered;
}
```

---

### 3. SessionProgressSummary (Aggregate)

**Purpose**: Summary of all stage transitions that occurred during a completed learning session.

**Attributes**:
- `transitions` (List<StageTransition>): All transitions during session
- `stabilizingCount` (int): Count of words that reached Stabilizing
- `activeCount` (int): Count of words that reached Active
- `masteredCount` (int): Count of words that reached Mastered
- `hasTransitions` (bool): True if any transitions occurred

**Computed Properties**:
- Counts are derived from `transitions` list
- Empty if no transitions occurred (don't show recap)

**Dart Implementation**:
```dart
class SessionProgressSummary {
  final List<StageTransition> transitions;

  SessionProgressSummary(this.transitions);

  int get stabilizingCount => transitions.where((t) => t.toStage == ProgressStage.stabilizing).length;
  int get activeCount => transitions.where((t) => t.toStage == ProgressStage.active).length;
  int get masteredCount => transitions.where((t) => t.toStage == ProgressStage.mastered).length;

  bool get hasTransitions => transitions.isNotEmpty;
  bool get hasRareAchievements => transitions.any((t) => t.isRareAchievement);

  String toDisplayString() {
    final parts = <String>[];
    if (stabilizingCount > 0) parts.add('$stabilizingCount word${stabilizingCount > 1 ? 's' : ''} → Stabilizing');
    if (activeCount > 0) parts.add('$activeCount word${activeCount > 1 ? 's' : ''} → Active');
    if (masteredCount > 0) parts.add('$masteredCount word${masteredCount > 1 ? 's' : ''} → Mastered');
    return parts.join(' • ');
  }
}
```

---

## Extended Entities (Database)

### 4. LearningCard (Extended)

**Purpose**: Existing table, extended with `progress_stage` column for caching.

**New Field**:
- `progress_stage` (VARCHAR(20)): Cached current stage value
  - Default: `'captured'`
  - Updated when stage calculation detects transition
  - Indexed for fast vocabulary list filtering

**Existing Fields Used**:
- `stability` (REAL): Memory duration in days (FSRS metric)
- `difficulty` (REAL): Learning difficulty (FSRS metric)
- `state` (INTEGER): Card state (0=new, 1=learning, 2=review, 3=relearning)
- `reps` (INTEGER): Count of successful reviews
- `lapses` (INTEGER): Count of review failures
- `last_review` (TIMESTAMPTZ): Most recent review timestamp

**Relationships**:
- One-to-One with `vocabulary` (via `vocabulary_id`)
- One-to-Many with `review_logs` (learning_card_id)

**SQL Schema Addition**:
```sql
ALTER TABLE learning_cards
  ADD COLUMN IF NOT EXISTS progress_stage VARCHAR(20) NOT NULL DEFAULT 'captured';

CREATE INDEX IF NOT EXISTS idx_learning_cards_user_stage
  ON learning_cards(user_id, progress_stage)
  WHERE deleted_at IS NULL;
```

---

### 5. ReviewLog (Existing, No Changes)

**Purpose**: Existing table that logs every review interaction. Used to detect non-translation retrievals.

**Key Fields Used**:
- `learning_card_id` (UUID): Link to learning card
- `cue_type` (VARCHAR(20)): How word was presented (translation, definition, synonym, context_cloze, disambiguation)
- `rating` (INTEGER): Grade given (1=Again, 2=Hard, 3=Good, 4=Easy)
- `reviewed_at` (TIMESTAMPTZ): When review occurred

**Query for Active Status**:
```sql
-- Detect if word has achieved non-translation success
SELECT COUNT(*) > 0 AS has_non_translation_success
FROM review_logs
WHERE learning_card_id = ?
  AND rating >= 3
  AND cue_type IN ('definition', 'synonym', 'context_cloze', 'disambiguation')
```

**Relationships**:
- Many-to-One with `learning_cards` (via learning_card_id)

---

### 6. Meaning (Existing, No Changes)

**Purpose**: Existing table storing word senses/translations. Background enrichment adds meanings automatically.

**Key Fields**:
- `vocabulary_id` (UUID): Link to vocabulary word
- `translation` (TEXT): Primary meaning text
- `deleted_at` (TIMESTAMPTZ): Soft delete timestamp (NULL = active)

**Note**: Meaning enrichment is a background system task. It does NOT affect progress stage (stages only change via user actions).

**Relationships**:
- Many-to-One with `vocabulary` (via vocabulary_id)

---

## Data Flow

### Stage Calculation Pipeline

```
┌─────────────────────────────────────────────────────────────┐
│ Input: vocabulary_id, user_id                               │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ 1. Fetch learning_card row (if exists)                      │
│    → Extract: stability, state, reps, lapses                │
│    → If no card: stage = Captured                           │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. Query review_logs (if card exists)                       │
│    → Count non-translation successes                        │
│    → (rating >= 3, cue_type IN [...])                       │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. Apply stage transition rules                             │
│    → ProgressStageService.calculateStage(...)               │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ Output: ProgressStage enum                                  │
│         (captured, practicing, ..., mastered)               │
└─────────────────────────────────────────────────────────────┘
```

### Session Review Flow

```
User completes review
         │
         ▼
Calculate stage BEFORE review
         │
         ▼
Submit grade to FSRS
         │
         ▼
Update learning_card (stability, reps, lapses, state)
         │
         ▼
Calculate stage AFTER review
         │
         ▼
Stage changed? ────NO──── Continue to next card
         │
        YES
         │
         ▼
Create StageTransition
         │
         ▼
Display micro-feedback (2.5s badge)
         │
         ▼
Add to session transitions list
         │
         ▼
Continue to next card
         │
        ...
         │
         ▼
Session ends
         │
         ▼
Generate SessionProgressSummary
         │
         ▼
Display recap on SessionCompleteScreen
```

---

## State Transitions

### Stage Progression Diagram

```
[Captured] ──first review (user action)──> [Practicing]
                                                │
                                                │ stability >= 1.0
                                                │ reps >= 3
                                                │ lapses <= 2
                                                │ (user reviews)
                                                ▼
                                           [Stabilizing]
                                                │
                                                │ non-translation
                                                │ success
                                                │ (user reviews with
                                                │  definition/synonym cues)
                                                ▼
                                             [Active]
                                                │
                                                │ stability >= 90
                                                │ reps >= 12
                                                │ lapses <= 1
                                                │ (continued user reviews)
                                                ▼
                                            [Mastered]
```

**Note**: All transitions are driven by user actions (reviews). Background enrichment does NOT change stage.

### Regression Paths

```
[Mastered] ──lapses > 1 OR stability < 60──> [Active]
                                                │
                                                │ lapses > 2
                                                │ OR stability < 7
                                                ▼
                                          [Stabilizing]
                                                │
                                                │ stability < 1.0
                                                │ OR state IN (0,1,3)
                                                ▼
                                           [Practicing]
                                         (no further regression)
```

---

## Validation Rules

### Stage Calculation Invariants

1. **Captured → Practicing**:
   - One-way gate: First review creates learning_card, never deleted
   - `reps >= 1` OR `review_logs.count > 0`
   - User-driven: Requires user to complete first review

2. **Practicing ↔ Stabilizing**:
   - Stabilizing requires: `state = 2` AND `stability >= 1.0` AND `reps >= 3` AND `lapses <= 2`
   - Regression if any criterion fails
   - User-driven: Requires multiple successful reviews

3. **Stabilizing → Active**:
   - One-way gate: Once achieved, never regress below Active (even if only translation reviews afterward)
   - Requires: All Stabilizing criteria + `non_translation_success_count >= 1`
   - User-driven: Requires user to successfully complete non-translation cue

4. **Active ↔ Mastered**:
   - Mastered requires: `stability >= 90` AND `reps >= 12` AND `lapses <= 1` AND `state = 2`
   - Regression if any criterion fails

### Data Consistency Rules

1. **Cached Stage Sync**:
   - `learning_cards.progress_stage` MUST match computed stage from rules
   - Update after every review that changes FSRS metrics
   - Client-side calculation ensures consistency (no race conditions)

2. **Transition Logging** (future):
   - If `learning_stage_transitions` table added later:
     - One row per transition event
     - `stage_to` of latest row MUST match `learning_cards.progress_stage`
     - Ordered by `created_at` ASC

3. **Review Log Integrity**:
   - `cue_type` field MUST be populated for all reviews (required for Active detection)
   - Valid values: 'translation', 'definition', 'synonym', 'context_cloze', 'disambiguation'

---

## Performance Considerations

### Query Optimization

1. **Vocabulary List Query**:
   ```sql
   SELECT v.*, lc.progress_stage
   FROM vocabulary v
   LEFT JOIN learning_cards lc ON lc.vocabulary_id = v.id
   WHERE v.user_id = ?
   ORDER BY lc.progress_stage DESC, v.word ASC
   ```
   - Uses index: `idx_learning_cards_user_stage`
   - Fast filter: `WHERE lc.progress_stage = 'active'`

2. **Stage Calculation Query**:
   ```sql
   -- Single query to fetch all data needed
   SELECT
     lc.*,
     (SELECT COUNT(*) FROM meanings WHERE vocabulary_id = ? AND deleted_at IS NULL) AS meaning_count,
     (SELECT COUNT(*) FROM review_logs WHERE learning_card_id = lc.id AND rating >= 3 AND cue_type IN (...)) AS non_trans_count
   FROM learning_cards lc
   WHERE lc.vocabulary_id = ?
   ```
   - Runs once per review, cached during session
   - Target: <50ms per word

3. **Session Recap**:
   - No additional queries (uses in-memory transitions list)
   - Counts computed from List<StageTransition>
   - O(n) where n = cards reviewed in session (~10-20)

### Caching Strategy

1. **Client-Side Cache**:
   - Riverpod `FutureProvider.autoDispose` caches stage per word
   - Invalidate after review completion
   - Cache duration: Until next review or vocabulary list refresh

2. **Database Cache**:
   - `learning_cards.progress_stage` stores last computed value
   - Updated asynchronously after review (write-behind pattern)
   - Vocabulary list reads cached value directly (no computation)

---

## Migration Strategy

### Phase 1: Add Column (Zero Downtime)

```sql
-- Add column with default value (instant, no table lock)
ALTER TABLE learning_cards
  ADD COLUMN IF NOT EXISTS progress_stage VARCHAR(20) NOT NULL DEFAULT 'captured';
```

### Phase 2: Backfill (Background Job)

```sql
-- Backfill 'clarified' for cards with meanings
UPDATE learning_cards lc
SET progress_stage = 'clarified'
FROM vocabulary v
WHERE lc.vocabulary_id = v.id
  AND EXISTS (SELECT 1 FROM meanings m WHERE m.vocabulary_id = v.id AND m.deleted_at IS NULL)
  AND lc.reps = 0;

-- Backfill 'practicing' for cards with reviews but low stability
UPDATE learning_cards
SET progress_stage = 'practicing'
WHERE reps > 0 AND stability < 7.0;

-- Backfill 'stabilizing' for cards with moderate stability
UPDATE learning_cards
SET progress_stage = 'stabilizing'
WHERE stability >= 7.0 AND stability < 21.0;

-- 'active' and 'mastered' computed on-demand (requires review_logs analysis)
```

### Phase 3: Index Creation (Low Impact)

```sql
-- Create index concurrently (PostgreSQL 9.1+)
CREATE INDEX CONCURRENTLY idx_learning_cards_user_stage
  ON learning_cards(user_id, progress_stage)
  WHERE deleted_at IS NULL;
```

---

## Summary

**Entities**:
- `ProgressStage` (enum): 6 stages representing competence levels
- `StageTransition` (value object): Captures stage changes during sessions
- `SessionProgressSummary` (aggregate): Summary of all transitions in a session
- `LearningCard` (extended): Add `progress_stage` column for caching
- `ReviewLog` (existing): Use `cue_type` field for non-translation detection
- `Meaning` (existing): Use to detect enrichment status

**Data Flow**:
1. Calculate stage from meanings + learning_cards + review_logs
2. Detect transitions before/after each review
3. Display micro-feedback on transitions
4. Aggregate transitions for session recap

**Performance**:
- Stage calculation: <50ms per word
- Vocabulary list: Fast (indexed progress_stage column)
- Session recap: O(n) in-memory aggregation

**Migration**:
- Add column with default (zero downtime)
- Backfill in background
- Create index concurrently
