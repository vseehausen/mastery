# Contract: SRS Scheduler

**Service**: `SrsScheduler`
**Location**: `mobile/lib/domain/services/srs_scheduler.dart`

## Purpose

Thin wrapper around the `fsrs` Dart package. Provides a stable internal API for reviewing cards, computing retrievability, and managing FSRS state — isolating the rest of the codebase from the FSRS library's API surface.

## Interface

### `reviewCard`

Process a user's review of a learning card and return the updated card state.

**Input**:
```
card: LearningCard (from Drift)
rating: ReviewRating (again | hard | good | easy)
now: DateTime (UTC)
```

**Output**:
```
ReviewResult:
  updatedCard: LearningCard    # New FSRS state (stability, difficulty, due, state, reps, lapses)
  reviewLog: ReviewLogData     # Snapshot for the ReviewLogs table
  isLeech: bool                # True if lapses >= 8 after this review
```

**Behavior**:
1. Convert `LearningCard` → FSRS `Card` object
2. Call `scheduler.reviewCard(fsrsCard, rating)`
3. Check leech: if `rating == again` and old state was `review`, increment lapses; flag if >= 8
4. Convert result back to `LearningCard` fields
5. Build `ReviewLogData` with before/after snapshots

### `getRetrievability`

Compute current probability of recall for a card.

**Input**:
```
card: LearningCard
now: DateTime (UTC)
```

**Output**:
```
double (0.0 to 1.0)
```

### `createScheduler`

Factory that creates an FSRS scheduler with the user's target retention.

**Input**:
```
targetRetention: double (0.85-0.95)
```

**Output**:
```
Scheduler (from fsrs package)
```

**Configuration**:
```
Scheduler(
  desiredRetention: targetRetention,
  learningSteps: [1, 10],       # 1 min, 10 min steps for new cards
  relearningSteps: [10],         # 10 min step for lapsed cards
  maximumInterval: 365,          # Cap at 1 year for MVP
  enableFuzzing: true,           # Prevent review clustering
)
```

### `initializeCard`

Create a new LearningCard from a vocabulary item.

**Input**:
```
vocabularyId: String
userId: String
```

**Output**:
```
LearningCard (state=new, due=now, stability=0, difficulty=0, reps=0, lapses=0)
```

## Constants

```
LEECH_THRESHOLD = 8          # Lapses before marking as leech
MAX_INTERVAL_DAYS = 365      # Maximum review interval
DEFAULT_LEARNING_STEPS = [1, 10]   # Minutes
DEFAULT_RELEARNING_STEPS = [10]    # Minutes
```

## Dependencies

- `fsrs: ^2.0.1` (external package)
- No repository dependencies (pure domain logic)
