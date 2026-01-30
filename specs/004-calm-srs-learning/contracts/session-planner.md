# Contract: Session Planner

**Service**: `SessionPlanner`
**Location**: `mobile/lib/domain/services/session_planner.dart`

## Purpose

Builds a time-boxed session plan by selecting and ordering items from the learning card pool. Enforces priority scoring, new-word suppression (backlog hysteresis), and time-budget constraints.

## Interface

### `buildSessionPlan`

Generates a session plan for the current user.

**Input**:
```
userId: String
timeTargetMinutes: int (1-60)
intensity: Intensity (light | normal | intense)
targetRetention: double (0.85-0.95)
estimatedSecondsPerItem: double (from TelemetryService)
```

**Output**:
```
SessionPlan:
  items: List<PlannedItem>      # Ordered list of items to present
  estimatedDurationSeconds: int # Total estimated session time
  newWordCount: int             # Number of new words included
  reviewCount: int              # Number of reviews included
  leechCount: int               # Number of leeches included
```

**Algorithm**:
1. Query all due LearningCards where `due <= now` for the user, ordered by priority score descending
2. Query all leech LearningCards where `isLeech = true AND due <= now`
3. Compute session capacity: `maxItems = floor(timeTargetMinutes * 60 / estimatedSecondsPerItem)`
4. Compute overdue count: total cards where `due <= now`
5. Compute backlog threshold: `1 session capacity` (entry) / `2 session capacity` (exit)
6. If overdue > 1 session capacity → `newWordCap = 0`; else compute from intensity table
7. Fill plan: due reviews first → leeches → new words (up to cap) → stop at capacity

### `computePriorityScore`

Scores a single learning card for session ordering.

**Input**:
```
card: LearningCard
now: DateTime (UTC)
```

**Output**:
```
double (higher = more urgent)
```

**Formula**:
```
overdueDays = max(0, now.difference(card.due).inDays)
retrievability = fsrs.getCardRetrievability(card)
lapseWeight = 1 + (card.lapses / 20)
priority = overdueDays * (1 - retrievability) * lapseWeight
```

### `shouldSuppressNewWords`

Determines if new-word introduction should be suppressed.

**Input**:
```
overdueCount: int
sessionCapacity: int
previouslySupressed: bool
```

**Output**:
```
bool (true = suppress new words)
```

**Logic** (hysteresis):
```
if previouslySuppressed:
  return overdueCount > 2 * sessionCapacity   # exit threshold
else:
  return overdueCount > sessionCapacity        # entry threshold
```

## Error Handling

- If no items are available at all → return empty plan (caller shows "Nothing to practice" UX)
- If fewer items than capacity → return partial plan (session ends early, still counts as complete)

## Dependencies

- `LearningCardRepository` (data layer)
- `SrsScheduler` (FSRS retrievability computation)
- `TelemetryService` (time-per-item estimates)
