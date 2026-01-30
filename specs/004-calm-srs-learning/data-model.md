# Data Model: Calm, Time-Boxed SRS Learning

**Feature**: 004-calm-srs-learning
**Date**: 2026-01-29
**Schema Version**: 3 → 4

## Overview

Five new Drift tables extend the existing schema. All tables follow the project's sync patterns (`isPendingSync`, `lastSyncedAt`, `version`) and use text UUIDs as primary keys to match the existing convention.

## New Tables

### LearningCards

One row per vocabulary item that enters the learning system. References `Vocabularys.id`.

| Column | Type | Default | Notes |
|--------|------|---------|-------|
| id | text (PK) | UUID | |
| userId | text | required | Owner |
| vocabularyId | text (FK) | required | References Vocabularys.id |
| state | integer | 0 | Enum: 0=new, 1=learning, 2=review, 3=relearning |
| due | dateTime | now (UTC) | Next review date |
| stability | real | 0.0 | FSRS: days for R to decay from 1.0 to 0.9 |
| difficulty | real | 0.0 | FSRS: range [1, 10] |
| reps | integer | 0 | Total successful reviews |
| lapses | integer | 0 | Failed reviews (Review → Relearning) |
| lastReview | dateTime? | null | Last review timestamp (UTC) |
| isLeech | boolean | false | True when lapses >= 8 |
| createdAt | dateTime | now | |
| updatedAt | dateTime | now | |
| deletedAt | dateTime? | null | Soft delete |
| lastSyncedAt | dateTime? | null | |
| isPendingSync | boolean | false | |
| version | integer | 1 | Conflict resolution |

**Indexes**: `(userId, due)`, `(userId, state)`, `(userId, isLeech)`

### ReviewLogs

Append-only log of every review interaction. Used for telemetry, FSRS parameter optimization, and analytics.

| Column | Type | Default | Notes |
|--------|------|---------|-------|
| id | text (PK) | UUID | |
| userId | text | required | |
| learningCardId | text (FK) | required | References LearningCards.id |
| rating | integer | required | Enum: 1=again, 2=hard, 3=good, 4=easy |
| interactionMode | integer | required | Enum: 0=recognition, 1=recall |
| stateBefore | integer | required | Card state before review |
| stateAfter | integer | required | Card state after review |
| stabilityBefore | real | required | |
| stabilityAfter | real | required | |
| difficultyBefore | real | required | |
| difficultyAfter | real | required | |
| responseTimeMs | integer | required | Actual time user took |
| retrievabilityAtReview | real | required | FSRS retrievability (0-1) at review time, for model validation |
| reviewedAt | dateTime | now (UTC) | |
| sessionId | text (FK)? | null | References LearningSessions.id |
| isPendingSync | boolean | false | |

**Indexes**: `(learningCardId)`, `(userId, reviewedAt)`, `(sessionId)`

### LearningSessions

Tracks each time-boxed practice session. Supports resume via `expiresAt`.

| Column | Type | Default | Notes |
|--------|------|---------|-------|
| id | text (PK) | UUID | |
| userId | text | required | |
| startedAt | dateTime | now (UTC) | |
| expiresAt | dateTime | required | Default: end of local day |
| plannedMinutes | integer | required | User's daily target |
| elapsedSeconds | integer | 0 | Updated after each item |
| bonusSeconds | integer | 0 | Accumulated bonus time |
| itemsPresented | integer | 0 | |
| itemsCompleted | integer | 0 | |
| newWordsPresented | integer | 0 | |
| reviewsPresented | integer | 0 | |
| accuracyRate | real? | null | Fraction of reviews rated Good/Easy (computed at session end) |
| avgResponseTimeMs | integer? | null | Mean response time across all reviews (computed at session end) |
| outcome | integer | 0 | Enum: 0=in_progress, 1=complete, 2=partial, 3=expired |
| createdAt | dateTime | now | |
| updatedAt | dateTime | now | |
| isPendingSync | boolean | false | |

**Indexes**: `(userId, startedAt)`, `(userId, outcome)`

### UserLearningPreferences

One row per user. Created with defaults on first session start.

| Column | Type | Default | Notes |
|--------|------|---------|-------|
| id | text (PK) | UUID | |
| userId | text (unique) | required | |
| dailyTimeTargetMinutes | integer | 10 | 1-60 |
| targetRetention | real | 0.90 | 0.85-0.95 |
| intensity | integer | 1 | Enum: 0=light, 1=normal, 2=intense |
| createdAt | dateTime | now | |
| updatedAt | dateTime | now | |
| lastSyncedAt | dateTime? | null | |
| isPendingSync | boolean | false | |

### Streaks

One row per user. Tracks current and longest streak.

| Column | Type | Default | Notes |
|--------|------|---------|-------|
| id | text (PK) | UUID | |
| userId | text (unique) | required | |
| currentCount | integer | 0 | |
| longestCount | integer | 0 | |
| lastCompletedDate | dateTime? | null | Calendar date of last completed session |
| createdAt | dateTime | now | |
| updatedAt | dateTime | now | |
| lastSyncedAt | dateTime? | null | |
| isPendingSync | boolean | false | |

## Entity Relationships

```text
Vocabularys 1──1 LearningCards    (vocabularyId FK)
LearningCards 1──* ReviewLogs     (learningCardId FK)
LearningSessions 1──* ReviewLogs  (sessionId FK, nullable)
Users 1──1 UserLearningPreferences (userId unique)
Users 1──1 Streaks                 (userId unique)
Users 1──* LearningCards           (userId)
Users 1──* LearningSessions        (userId)
```

## State Transitions

### LearningCard.state

```text
new (0) ──[first review]──→ learning (1)
learning (1) ──[graduate]──→ review (2)
review (2) ──[lapse/Again]──→ relearning (3)
relearning (3) ──[regraduate]──→ review (2)
```

FSRS manages these transitions via `Scheduler.reviewCard()`.

### LearningSession.outcome

```text
in_progress (0) ──[timer ends]──→ complete (1)
in_progress (0) ──[user quits early]──→ partial (2)
in_progress (0) ──[past expiresAt]──→ expired (3)
```

## Intensity New-Word Caps

Per-session new-word limits derived from intensity and time budget:

| Intensity | New words per 10 min | Formula |
|-----------|---------------------|---------|
| Light (0) | 2 | `floor(timeMinutes / 10) * 2` |
| Normal (1) | 5 | `floor(timeMinutes / 10) * 5` |
| Intense (2) | 8 | `floor(timeMinutes / 10) * 8` |

These caps are suppressed to zero when overdue items exceed 1 session's capacity.

## Supabase Migration

The Supabase migration mirrors all five tables with:
- UUID primary keys
- TIMESTAMPTZ for all datetime columns
- RLS policies: `auth.uid() = user_id` for all tables
- Foreign keys with `ON DELETE CASCADE` for ReviewLogs → LearningCards
- Indexes matching the Drift schema

## Sync Strategy

Learning data syncs using the existing SyncOutbox pattern:
- **Push**: LearningCards, LearningSessions, Streaks, UserLearningPreferences changes queue to outbox
- **Pull**: Fetch records updated since `lastSyncedAt`
- **ReviewLogs**: Append-only, push only (never pulled; server is the archive)
- **Conflict resolution**: Last-write-wins via `version` field (same as existing vocabulary sync)
- **Frequency**: Sync triggers on session complete + periodic background sync
