# FSRS Research for Mastery Vocabulary Learning

**Research Date**: 2026-01-30
**Purpose**: Evaluate FSRS algorithm for Flutter/Dart mobile vocabulary SRS implementation

---

## 1. FSRS vs SM-2: Algorithm Comparison

### Performance & Accuracy

**FSRS significantly outperforms SM-2:**
- **99.6% superiority** over Anki SM-2 (lower log loss for 99.6% of users)
- **20-30% fewer reviews** to achieve same knowledge retention
- Medical students report 20-30% fewer daily reviews while maintaining same retention rates
- Also outperforms SM-17: **83.3% superiority** in estimating recall probability

### Key Differences

| Feature | SM-2 | FSRS |
|---------|------|------|
| Formula | Same formula for everyone | Learns personal memory patterns |
| Training | Hand-tuned constants | Machine learning on 700M+ reviews from 20K users |
| Parameters | Fixed | 21 optimizable parameters (FSRS-6) |
| Forgetting Curve | Exponential | Power function (better data fit) |
| Overdue Handling | Linear interval increase | Converges to upper limit (prevents skew) |
| Development | 1987 (legacy) | 2023 (modern, actively maintained) |
| Flexibility | Rigid review timing | Supports early reviews and delays |

### Recommendation

**Use FSRS** for modern SRS app. It's backed by academic research, provides 20-30% efficiency gains, and is actively maintained by the Open Spaced Repetition community with implementations in multiple languages including Dart.

**Sources:**
- [FSRS vs SM-2 Complete Guide - MemoForge](https://memoforge.app/blog/fsrs-vs-sm2-anki-algorithm-guide-2025/)
- [Expertium's Benchmark](https://expertium.github.io/Benchmark.html)
- [SuperMemo dethroned by FSRS](https://supermemopedia.com/wiki/SuperMemo_dethroned_by_FSRS)

---

## 2. FSRS Implementation in Dart/Flutter

### Official Dart Package Available

✅ **Package**: `fsrs` on pub.dev
✅ **Version**: 2.0.1 (latest as of 2026-01)
✅ **License**: MIT
✅ **Maintainer**: open-spaced-repetition organization

### Installation

```yaml
dependencies:
  fsrs: ^2.0.1
```

### Core API Usage

```dart
// Initialize scheduler with default parameters
var scheduler = Scheduler();

// Create a new card
final card = Card(cardId: 1);
// or auto-generate ID
final card = await Card.create();

// Review a card
final rating = Rating.good;
final (:card, :reviewLog) = scheduler.reviewCard(card, rating);

// Get retrievability (probability of recall)
final probability = scheduler.getCardRetrievability(card);
```

### Card States

The package defines three states:
- `State.Learning` - New cards being studied initially
- `State.Review` - Cards graduated from Learning state
- `State.Relearning` - Cards that lapsed from Review state

### Rating System

Four ratings map to numbers 1-4:
- `Rating.Again` (1) - Forgot the card
- `Rating.Hard` (2) - Remembered with serious difficulty
- `Rating.Good` (3) - Remembered after hesitation
- `Rating.Easy` (4) - Remembered easily

### Configuration Parameters

```dart
Scheduler(
  parameters: List<double>, // 21 model weights (default provided)
  desiredRetention: 0.9,    // Target retention rate (70-97% reasonable)
  learningSteps: [1, 10],   // Minutes for new cards (default: 1min, 10min)
  relearningSteps: [10],    // Minutes for lapsed cards
  maximumInterval: 36500,   // Max days (default: ~100 years)
  enableFuzzing: true,      // Randomize intervals slightly
);
```

### Important Implementation Notes

1. **Timezone**: Package uses UTC exclusively. All datetimes must be UTC.
2. **Serialization**: Card, Scheduler, and ReviewLog support JSON via `toMap()` and `fromMap()`.
3. **Dependencies**: Only requires `meta` package (^1.15.0) - very lightweight.

### Algorithm Core Logic

**Memory State Variables:**
- **Stability (S)**: Time (days) for retrievability to decay from 100% to 90%
- **Difficulty (D)**: Range [1, 10], represents material complexity
- **Retrievability (R)**: Probability [0, 1] of successful recall (computed dynamically)

**Forgetting Curve (FSRS-6):**
```
R(t, S) = (1 + factor × t/S)^(-w₂₀)
```
Where factor calibrates to maintain R(S, S) = 90%

**Interval Calculation:**
For desired retention `r`, next interval:
```
I(r, S) = (S/FACTOR) × (r^(1/DECAY) - 1)
```
When r = 0.9, interval equals stability

**Stability Update on Success:**
```
S' = S × α
```
Where α depends on difficulty, saturation effects, and recall ease

**Stability Update on Failure:**
```
S' = min(S_f, S)
```
Asymmetric memory consolidation - forgetting causes steeper stability loss

**Difficulty Update:**
Initial: `D₀(G) = w₄ - e^(w₅(G-1)) + 1`
Subsequent: Blends toward baseline to prevent "ease hell"

### Feasibility Assessment

✅ **Highly Feasible** - Official Dart package exists, well-maintained, MIT licensed
✅ **Easy Integration** - Simple API, JSON serialization built-in
✅ **No Native Dependencies** - Pure Dart implementation
✅ **Production Ready** - Used in multiple apps, backed by OSR community

### Alternative: Rust FFI Binding

For performance-critical scenarios, `fsrs-rs-dart` provides Flutter/Dart bindings to Rust implementation using `flutter_rust_bridge`. This includes optimizer capabilities (the pure Dart version only has scheduler).

**Sources:**
- [fsrs Dart package on pub.dev](https://pub.dev/packages/fsrs)
- [GitHub - dart-fsrs](https://github.com/open-spaced-repetition/dart-fsrs)
- [GitHub - fsrs-rs-dart](https://github.com/open-spaced-repetition/fsrs-rs-dart)
- [Implementing FSRS in 100 Lines](https://borretti.me/article/implementing-fsrs-in-100-lines)
- [FSRS Algorithm Wiki](https://github.com/open-spaced-repetition/fsrs4anki/wiki/The-Algorithm)

---

## 3. Priority Scoring for Session Planning

### Standard Approach: Overdue + Retrievability

**Priority Formula (Recommended):**
```dart
priority = overdueAmount × (1 - retrievability) × lapseWeight
```

Components:
1. **Overdue Amount**: `max(0, currentDate - dueDate)` in days
2. **Retrievability**: FSRS provides `getCardRetrievability()` - lower = higher urgency
3. **Lapse Weight**: Multiply by `1 + (lapses / maxLapses)` to prioritize problematic cards

### Anki's Approach

Anki prioritizes overdue cards using: **overdue_ratio = overdue_days / interval_length**

Example: A card with 5-day interval overdue by 2 days displays before a card with 10-day interval overdue by 3 days.

### FSRS Overdue Handling

When cards are overdue:
- Retrievability (R) decreases as delay increases
- If review is successful, subsequent stability (S) increases
- However, stability **converges to upper limit** (doesn't increase linearly like SM-2)
- This prevents parameter skew from long breaks

### Session Planning Strategy

1. **Fetch due cards**: `WHERE due <= CURRENT_DATE`
2. **Calculate priority**: Use formula above
3. **Sort by priority**: Descending (highest urgency first)
4. **Apply time box**: See section 4
5. **Apply new word cap**: See section 5

**Sources:**
- [Anki Deck Options Manual](https://docs.ankiweb.net/deck-options.html)
- [FSRS Algorithm Wiki - The Algorithm](https://github.com/open-spaced-repetition/fsrs4anki/wiki/The-Algorithm)
- [Technical Principles of FSRS](https://www.oreateai.com/blog/technical-principles-and-application-prospects-of-the-free-spaced-repetition-scheduler-fsrs/36ee752bd462235d0d5b903059bc8684)

---

## 4. Time-Per-Item Estimation

### Empirical Data

**Language Flashcards:**
- **3 minutes for 30 cards** = ~6 seconds per card average
- **10 flashcards per minute** = 6 seconds per card
- **20 minutes daily** can handle 10 new words + ~30-40 reviews = ~0.4 seconds per item average

### Review Load Multiplier

**Steady-state review load** = 3-4× daily new cards (short-term)
**Long-term review load** = 5-6× daily new cards

Example:
- Add 10 new words/day → Expect 30-40 reviews/day initially
- After several months → 50-60 reviews/day

### Time-Boxing Implementation

```dart
// Conservative estimate
const avgSecondsPerCard = 8; // Includes thinking + typing

int estimateSessionTime(int cardCount) {
  return cardCount * avgSecondsPerCard;
}

List<Card> buildTimeBoxedSession({
  required List<Card> dueCards,
  required int maxSeconds,
}) {
  final maxCards = maxSeconds ~/ avgSecondsPerCard;
  return dueCards.take(maxCards).toList();
}
```

### Best Practices

1. **Track actual review times**: Store `time_taken_ms` in review logs
2. **Calculate rolling average**: Per-user, per-card-type averages
3. **Adaptive estimation**: Adjust based on historical data
4. **Buffer time**: Add 20% buffer for UI transitions, breaks
5. **Per-rating timing**: "Again" takes longer than "Easy"

**Sources:**
- [The Most Effective Spaced Repetition Methods](http://www.flashcardlearner.com/articles/the-most-effective-spaced-repetition-flashcard-learning-methods/)
- [RemNote Understanding Spaced Repetition](https://help.remnote.com/en/articles/9337171-understanding-spaced-repetition)

---

## 5. New-Word Daily Cap

### Recommended Limits

**Conservative approach (recommended for beginners):**
- Start with **5-10 new cards/day**
- Gradually increase if comfortable
- Monitor review load (should be 3-4× new card count)

**Moderate approach (experienced learners):**
- **10-20 new cards/day** for sustainable long-term learning
- Example: 10 new words/day = 3,650 words/year with only 20 min/day

**Aggressive approach (exam prep):**
- **30-50 new cards/day** maximum (e.g., MCAT prep)
- Risk of burnout and overwhelming review load
- Not sustainable long-term

### Safety Mechanism

**If reviews exceed 80 and user feels tense**: Cut new cards in half for next week

### Implementation

```dart
class SessionConfig {
  int maxNewCardsPerDay;
  int maxReviewsPerDay;

  // Adaptive adjustment
  void adjustIfOverloaded(int todayReviews, bool userReportedStress) {
    if (todayReviews > 80 || userReportedStress) {
      maxNewCardsPerDay = (maxNewCardsPerDay / 2).round();
    }
  }
}

// Query new cards with limit
Future<List<Card>> getNewCards(int limit) async {
  return (db.select(db.cards)
    ..where((c) => c.state.equals(State.Learning.index))
    ..where((c) => c.reps.equals(0))
    ..limit(limit))
    .get();
}
```

### Drift Schema Addition

```dart
class Cards extends Table {
  // ... existing fields
  IntColumn get dailyNewCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastNewCardDate => dateTime().nullable()();
}

// Reset counter daily
Future<void> resetDailyCountIfNeeded() async {
  final today = DateTime.now().toUtc();
  final cards = await (db.select(db.cards)
    ..where((c) => c.lastNewCardDate.isSmallerThan(Variable(today))))
    .get();

  for (final card in cards) {
    await (db.update(db.cards)..where((c) => c.id.equals(card.id)))
      .write(CardsCompanion(
        dailyNewCount: const Value(0),
        lastNewCardDate: Value(today),
      ));
  }
}
```

**Key Principle**: **Sustainability trumps ambition** - consistent moderate pace beats aggressive starts that lead to burnout.

**Sources:**
- [How to Use Spaced Repetition Without Burning Out](https://languavibe.com/spaced-repetition-language-learning-without-burnout/)
- [The Most Effective Spaced Repetition Methods](http://www.flashcardlearner.com/articles/the-most-effective-spaced-repetition-flashcard-learning-methods/)
- [Noji Daily New Cards Help](https://help.noji.io/en/articles/9640354-daily-new-cards)

---

## 6. Leech Detection

### Standard Thresholds

**Anki (industry standard):**
- Default: **8 lapses** triggers leech warning
- Subsequent warnings: Every **4 lapses** (half of initial threshold)
- Example: Warnings at 8, 12, 16, 20... lapses

**RemNote:**
- Default: **4 lapses** (more aggressive)
- Customizable threshold

**SuperMemo:**
- **5+ lapses** combined with interval ≤ 60 days

### Lapse Definition

A **lapse** occurs when:
- User fails a card in **Review** state (not Learning/Relearning)
- Card transitions from Review → Relearning state
- Rating is "Again" (1)

**Not counted as lapses:**
- Failing a new card during initial learning
- Failing during relearning phase
- Multiple fails in same learning session (counts as one lapse)

### Implementation

```dart
class Cards extends Table {
  // ... existing fields
  IntColumn get lapses => integer().withDefault(const Constant(0))();
  BoolColumn get isLeech => boolean().withDefault(const Constant(false))();
  DateTimeColumn get leechMarkedAt => dateTime().nullable()();
}

// Check and mark leeches after review
Future<void> checkLeechStatus(int cardId, Rating rating, State oldState, State newState) async {
  if (rating == Rating.again && oldState == State.review) {
    final card = await (db.select(db.cards)..where((c) => c.id.equals(cardId))).getSingle();
    final newLapseCount = card.lapses + 1;

    const leechThreshold = 8; // Configurable
    final wasLeech = card.isLeech;
    final isLeechNow = newLapseCount >= leechThreshold;

    // Warn on: 8, 12, 16, 20... (initial + multiples of half-threshold)
    final shouldWarn = !wasLeech && isLeechNow ||
                       (isLeechNow && newLapseCount % (leechThreshold ~/ 2) == 0);

    await (db.update(db.cards)..where((c) => c.id.equals(cardId)))
      .write(CardsCompanion(
        lapses: Value(newLapseCount),
        isLeech: Value(isLeechNow),
        leechMarkedAt: Value(isLeechNow && !wasLeech ? DateTime.now().toUtc() : card.leechMarkedAt),
      ));

    if (shouldWarn) {
      // Show leech warning to user
      // Suggest: simplify card, split into multiple cards, or suspend
    }
  }
}
```

### Leech Handling Options

1. **Suspend card**: Remove from review rotation (manual intervention needed)
2. **Flag for editing**: Mark for user to simplify/rewrite
3. **Split card**: Break complex concept into multiple cards
4. **Delete card**: Remove if not worth the time investment

### UI Recommendations

- Show leech badge in card list
- Filter/sort by leech status
- Analytics: Track leech rate per deck/tag
- Notification when card becomes leech

**Sources:**
- [Anki Leeches Manual](https://docs.ankiweb.net/leeches.html)
- [Dealing with Leeches - Control-Alt-Backspace](https://controlaltbackspace.org/leech/)
- [RemNote Dealing with Leech Cards](https://help.remnote.com/en/articles/7183408-dealing-with-leech-cards)
- [Hacking Chinese - Killing Leeches](https://www.hackingchinese.com/killing-leeches/)

---

## 7. Drift (SQLite) Schema Patterns

### Complete Card Schema for FSRS

```dart
@DataClassName('VocabCard')
class VocabCards extends Table {
  // Primary key
  IntColumn get id => integer().autoIncrement()();

  // Foreign keys
  IntColumn get highlightId => integer().references(Highlights, #id)();
  IntColumn get userId => integer().references(Users, #id)();

  // FSRS Memory State (core algorithm fields)
  RealColumn get stability => real().withDefault(const Constant(0.0))();      // S: time (days) for R to decay from 1.0 to 0.9
  RealColumn get difficulty => real().withDefault(const Constant(0.0))();     // D: range [1, 10]
  RealColumn get retrievability => real().withDefault(const Constant(1.0))(); // R: cached value, recomputed on access

  // FSRS State Machine
  IntColumn get state => intEnum<CardState>()();  // Learning, Review, Relearning
  DateTimeColumn get due => dateTime()();         // Next review date (UTC)
  DateTimeColumn get lastReview => dateTime().nullable()(); // Last review timestamp (UTC)

  // Review Statistics
  IntColumn get reps => integer().withDefault(const Constant(0))();       // Total successful reviews
  IntColumn get lapses => integer().withDefault(const Constant(0))();     // Failed reviews (Review → Relearning transitions)
  IntColumn get elapsedDays => integer().withDefault(const Constant(0))(); // Days since card creation

  // Leech Detection
  BoolColumn get isLeech => boolean().withDefault(const Constant(false))();
  DateTimeColumn get leechMarkedAt => dateTime().nullable()();

  // Session Management
  IntColumn get dailyNewCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastNewCardDate => dateTime().nullable()();

  // Priority Scoring (computed/indexed)
  IntColumn get priority => integer().nullable()(); // Cached priority score for sorting

  // Metadata
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  // Sync
  BoolColumn get needsSync => boolean().withDefault(const Constant(true))();
}

// Review logs for analytics and parameter optimization
@DataClassName('ReviewLog')
class ReviewLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get cardId => integer().references(VocabCards, #id, onDelete: KeyAction.cascade)();

  // Review details
  IntColumn get rating => intEnum<Rating>()();        // 1=Again, 2=Hard, 3=Good, 4=Easy
  IntColumn get stateBefore => intEnum<CardState>()();
  IntColumn get stateAfter => intEnum<CardState>()();

  // FSRS state before review
  RealColumn get stabilityBefore => real()();
  RealColumn get difficultyBefore => real()();
  RealColumn get retrievabilityBefore => real()();

  // FSRS state after review
  RealColumn get stabilityAfter => real()();
  RealColumn get difficultyAfter => real()();

  // Timing
  DateTimeColumn get reviewedAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get timeTakenMs => integer()();           // For time estimation
  IntColumn get scheduledDays => integer()();         // Interval length
  IntColumn get elapsedDays => integer()();           // Actual days since last review

  // Sync
  BoolColumn get needsSync => boolean().withDefault(const Constant(true))();
}

// Enums
enum CardState { learning, review, relearning }
enum Rating { again, hard, good, easy }
```

### Key Schema Decisions

**FSRS Core Fields (Required):**
- `stability`, `difficulty`, `retrievability` - DSR memory state
- `state` - Learning/Review/Relearning
- `due` - Next review date (indexed for queries)
- `lastReview` - For computing overdue amount

**Performance Optimization:**
- Index on `due` for "cards due today" queries
- Index on `state` for filtering new/review cards
- Index on `priority` for session building
- Cached `retrievability` (recompute periodically, not every query)

**Analytics & Optimization:**
- `ReviewLogs` table stores complete history
- Enables parameter optimization (if using Rust optimizer binding)
- Track `timeTakenMs` for time estimation improvements
- Store before/after states for debugging/analysis

**Sync Considerations:**
- `needsSync` flags for outbox pattern
- All timestamps UTC (FSRS package requirement)
- `updatedAt` for last-write-wins conflict resolution

### Indexes

```dart
@TableIndex(name: 'idx_cards_due', columns: {#due})
@TableIndex(name: 'idx_cards_state_due', columns: {#state, #due})
@TableIndex(name: 'idx_cards_user_state', columns: {#userId, #state})
@TableIndex(name: 'idx_cards_priority', columns: {#priority})
@TableIndex(name: 'idx_review_logs_card', columns: {#cardId})
class VocabCards extends Table { /* ... */ }
```

### Example Queries

```dart
// Get due cards for today's session (priority-sorted)
Future<List<VocabCard>> getDueCards(DateTime now, int limit) async {
  return (db.select(db.vocabCards)
    ..where((c) => c.due.isSmallerOrEqualValue(now))
    ..where((c) => c.state.equals(CardState.review.index))
    ..orderBy([
      (c) => OrderingTerm(expression: c.priority, mode: OrderingMode.desc),
      (c) => OrderingTerm(expression: c.due, mode: OrderingMode.asc),
    ])
    ..limit(limit))
    .get();
}

// Get new cards (respecting daily cap)
Future<List<VocabCard>> getNewCards(int userId, int dailyLimit) async {
  final today = DateTime.now().toUtc().copyWith(hour: 0, minute: 0, second: 0);

  return (db.select(db.vocabCards)
    ..where((c) => c.userId.equals(userId))
    ..where((c) => c.state.equals(CardState.learning.index))
    ..where((c) => c.reps.equals(0))
    ..where((c) =>
      c.lastNewCardDate.isSmallerThan(Variable(today)) |
      c.lastNewCardDate.isNull() |
      c.dailyNewCount.isSmallerThan(Variable(dailyLimit))
    )
    ..limit(dailyLimit))
    .get();
}

// Get leeches for review
Future<List<VocabCard>> getLeeches(int userId) async {
  return (db.select(db.vocabCards)
    ..where((c) => c.userId.equals(userId))
    ..where((c) => c.isLeech.equals(true))
    ..orderBy([
      (c) => OrderingTerm(expression: c.lapses, mode: OrderingMode.desc)
    ]))
    .get();
}

// Update card after review (FSRS integration)
Future<void> reviewCard(VocabCard card, Rating rating, Scheduler scheduler) async {
  final oldState = CardState.values[card.state];

  // Create FSRS card from our schema
  final fsrsCard = FsrsCard(
    stability: card.stability,
    difficulty: card.difficulty,
    elapsedDays: card.elapsedDays,
    scheduledDays: card.due.difference(card.lastReview ?? card.createdAt).inDays,
    reps: card.reps,
    lapses: card.lapses,
    state: _toFsrsState(oldState),
    lastReview: card.lastReview,
  );

  // Get updated card from FSRS
  final (:card: updatedFsrsCard, :reviewLog: fsrsLog) =
    scheduler.reviewCard(fsrsCard, rating);

  // Calculate new priority
  final overdue = DateTime.now().toUtc().difference(card.due).inDays;
  final priority = _calculatePriority(
    overdueDays: overdue,
    retrievability: updatedFsrsCard.retrievability,
    lapses: updatedFsrsCard.lapses,
  );

  // Update database
  await (db.update(db.vocabCards)..where((c) => c.id.equals(card.id)))
    .write(VocabCardsCompanion(
      stability: Value(updatedFsrsCard.stability),
      difficulty: Value(updatedFsrsCard.difficulty),
      retrievability: Value(updatedFsrsCard.retrievability),
      state: Value(_toCardState(updatedFsrsCard.state).index),
      due: Value(updatedFsrsCard.due),
      lastReview: Value(DateTime.now().toUtc()),
      reps: Value(updatedFsrsCard.reps),
      lapses: Value(updatedFsrsCard.lapses),
      elapsedDays: Value(updatedFsrsCard.elapsedDays),
      priority: Value(priority),
      updatedAt: Value(DateTime.now().toUtc()),
      needsSync: const Value(true),
    ));

  // Insert review log
  await db.into(db.reviewLogs).insert(ReviewLogsCompanion.insert(
    cardId: card.id,
    rating: rating,
    stateBefore: oldState,
    stateAfter: _toCardState(updatedFsrsCard.state),
    stabilityBefore: card.stability,
    difficultyBefore: card.difficulty,
    retrievabilityBefore: card.retrievability,
    stabilityAfter: updatedFsrsCard.stability,
    difficultyAfter: updatedFsrsCard.difficulty,
    reviewedAt: DateTime.now().toUtc(),
    timeTakenMs: fsrsLog.elapsed_days * 86400000, // placeholder
    scheduledDays: fsrsLog.scheduled_days,
    elapsedDays: fsrsLog.elapsed_days,
  ));

  // Check leech status
  await checkLeechStatus(card.id, rating, oldState, _toCardState(updatedFsrsCard.state));
}

int _calculatePriority({
  required int overdueDays,
  required double retrievability,
  required int lapses,
}) {
  const maxLapses = 20;
  final overdueWeight = overdueDays.clamp(0, 365);
  final forgettingRisk = (1.0 - retrievability) * 100;
  final lapseWeight = 1 + (lapses / maxLapses);

  return (overdueWeight * forgettingRisk * lapseWeight).round();
}
```

**Sources:**
- [FSRS Dart Package API Docs](https://pub.dev/documentation/fsrs/latest/)
- [Implementing FSRS in 100 Lines](https://borretti.me/article/implementing-fsrs-in-100-lines)
- [FSRS4Anki Tutorial](https://github.com/open-spaced-repetition/fsrs4anki/blob/main/docs/tutorial.md)

---

## 8. Additional Recommendations

### Parameter Optimization

The default 21 parameters work well, but for best results:
- Use `fsrs-rs-dart` Rust binding (includes optimizer)
- Collect ~1000+ review logs before optimizing
- Re-optimize every 3-6 months as user data grows

### Load Balancing

Avoid "review spikes" by spreading due dates:
- Enable `enableFuzzing: true` in Scheduler (randomizes intervals ±2.5%)
- FSRS Helper addon has "Load Balance" feature for even distribution
- Consider "Easy Days" feature (reduce reviews on specific days)

### Retrievability Computation

```dart
// Recompute retrievability periodically (not every query)
Future<void> updateRetrievability(VocabCard card, Scheduler scheduler) async {
  final fsrsCard = _toFsrsCard(card);
  final r = scheduler.getCardRetrievability(fsrsCard);

  await (db.update(db.vocabCards)..where((c) => c.id.equals(card.id)))
    .write(VocabCardsCompanion(retrievability: Value(r)));
}
```

### Timezone Handling

```dart
// CRITICAL: FSRS requires UTC
DateTime get now => DateTime.now().toUtc();

DateTime get todayMidnight => DateTime.now().toUtc().copyWith(
  hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0,
);
```

### Testing Strategy

1. **Unit tests**: FSRS formulas with known inputs/outputs
2. **Integration tests**: Card state transitions, leech detection
3. **Simulation tests**: Run 1000 reviews, check distribution
4. **Performance tests**: Query speed for 10K+ cards

---

## 9. Summary & Action Items

### Key Decisions

✅ **Use FSRS** over SM-2 (20-30% efficiency gain, modern algorithm)
✅ **Use `fsrs` Dart package** from pub.dev (official, MIT, well-maintained)
✅ **Leech threshold: 8 lapses** (Anki standard, adjustable)
✅ **New card limit: 10/day default** (conservative, user-adjustable)
✅ **Time estimate: 6-8 seconds/card** (adjust based on actual data)
✅ **Priority formula**: `overdue × (1 - retrievability) × lapseWeight`

### Implementation Checklist

- [ ] Add `fsrs: ^2.0.1` to mobile/pubspec.yaml
- [ ] Create Drift schema with FSRS fields (stability, difficulty, retrievability, state, due, lapses)
- [ ] Add indexes on `due`, `state`, `priority`
- [ ] Create `ReviewLogs` table for analytics
- [ ] Implement `reviewCard()` integration with FSRS package
- [ ] Implement priority calculation and session building
- [ ] Add leech detection logic (8 lapse threshold)
- [ ] Add new card daily cap with reset logic
- [ ] Implement time-per-card tracking in review logs
- [ ] Add retrievability recomputation (daily background task)
- [ ] Create unit tests for FSRS integration
- [ ] Create UI for leech management

### Open Questions

1. **Parameter optimization**: Start with defaults or pre-optimize using sample data?
2. **FSRS version**: Use pure Dart or Rust binding (FFI)?
3. **Sync strategy**: How to handle FSRS state conflicts (last-write-wins on stability/difficulty)?
4. **Learning steps**: Use default [1, 10] minutes or customize for vocabulary?
5. **Maximum interval**: Cap at 365 days or use default 36,500 days?

---

## References

### Primary Sources

- [FSRS GitHub - open-spaced-repetition](https://github.com/open-spaced-repetition)
- [FSRS Dart Package](https://pub.dev/packages/fsrs)
- [FSRS Algorithm Wiki](https://github.com/open-spaced-repetition/fsrs4anki/wiki/The-Algorithm)
- [FSRS Technical Explanation](https://expertium.github.io/Algorithm.html)

### Additional Reading

- [Implementing FSRS in 100 Lines](https://borretti.me/article/implementing-fsrs-in-100-lines)
- [Spaced Repetition Systems Have Gotten Way Better](https://domenic.me/fsrs/)
- [FSRS vs SM-2 Guide](https://memoforge.app/blog/fsrs-vs-sm2-anki-algorithm-guide-2025/)
- [Anki Leeches Manual](https://docs.ankiweb.net/leeches.html)
- [Dealing with Leeches](https://controlaltbackspace.org/leech/)
- [How to Use SRS Without Burning Out](https://languavibe.com/spaced-repetition-language-learning-without-burnout/)

### Tools & Implementations

- [Awesome FSRS List](https://github.com/open-spaced-repetition/awesome-fsrs)
- [FSRS4Anki](https://github.com/open-spaced-repetition/fsrs4anki)
- [FSRS Rust Implementation](https://github.com/open-spaced-repetition/fsrs-rs)
- [FSRS Python Package](https://github.com/open-spaced-repetition/py-fsrs)

---

**Research completed**: 2026-01-30
**Next step**: Review research with team and finalize implementation plan
