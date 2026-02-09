# Research: Word-Level Progress & Motivation

**Feature**: 006-word-progress
**Date**: 2026-02-08
**Status**: Complete

## Overview

This document consolidates research findings for implementing word-level progress tracking in the Mastery vocabulary app. Research covered three areas: stage transition criteria, data schema design, and UI feedback patterns.

**Important Design Principle**: All stage transitions are driven by user actions (reviews, recalls), NOT by system background tasks (enrichment). This ensures users feel ownership over their progress.

---

## 1. Stage Transition Criteria

### Decision: Use FSRS Metrics for Deterministic Stage Calculation

**Rationale**: The app already uses FSRS (Free Spaced Repetition Scheduler) to track memory state via `learning_cards` table. FSRS provides stability (memory duration), difficulty, and state tracking—ideal for determining competence stages.

### Stage Definitions (5 Stages - User-Driven Only)

| Stage | Min Stability | Min Reps | Max Lapses | State Required | Non-Translation Required |
|-------|---------------|----------|------------|----------------|--------------------------|
| New | N/A | N/A | N/A | No card yet | No |
| Practicing | Any | 1+ | Any | Any | No |
| Stabilizing | 1.0+ days | 3+ | ≤2 | 2 (review) | No |
| Known | 1.0+ days | 3+ | ≤2 | 2 (review) | Yes (≥1 success) |
| Mastered | 90.0+ days | 12+ | ≤1 | 2 (review) | Yes (≥1 success) |

**Note**: "Clarified" stage removed. Background enrichment is a system task, not a user achievement. Stage progression now only reflects user-initiated learning actions.

### Transition Rules

**New → Practicing**
- Trigger: User completes first review interaction
- Check: `learning_cards.reps >= 1` OR exists in `review_logs`
- User action: First review completed

**Practicing → Stabilizing**
- Trigger: Multiple successful recalls showing memory consolidation
- Criteria:
  - `learning_cards.state = 2` (review state—graduated from initial learning)
  - `learning_cards.stability >= 1.0` (memory lasts at least 1 day at 90% retention)
  - `learning_cards.reps >= 3` (at least 3 successful reviews)
  - `learning_cards.lapses <= 2` (low lapse count)

**Stabilizing → Known**
- Trigger: First successful non-translation retrieval (production recall, not recognition)
- Criteria:
  - All Stabilizing criteria still met
  - AND at least one review where:
    - `review_logs.rating >= 3` (Good or Easy)
    - `review_logs.cue_type IN ('definition', 'synonym', 'context_cloze', 'disambiguation')`
- Rationale: Translation cues test recognition; non-translation cues test production/active recall

**Known → Mastered**
- Trigger: Exceptional stability and minimal forgetting
- Criteria (ALL must be true):
  - `learning_cards.stability >= 90.0` (memory lasts 90+ days at 90% retention)
  - `learning_cards.reps >= 12` (minimum 12 successful reviews)
  - `learning_cards.lapses <= 1` (0-1 lapses only—very reliable memory)
  - `learning_cards.state = 2` (in review state, not relearning)
  - At least one successful non-translation review
- Why rare: Requires 3-6 months of consistent practice to reach 90-day stability

### Regression Rules

**Known/Mastered → Stabilizing**
- Trigger: `learning_cards.lapses > 2` OR (`state = 3` AND `stability < 7.0`)
- Rationale: High lapse count or low stability after failure indicates memory breakdown

**Stabilizing → Practicing**
- Trigger: `learning_cards.state IN (0, 1, 3)` OR `stability < 1.0`
- Rationale: Lost graduated status or memory no longer consolidated

**No regression below Practicing**
- Once a word reaches Practicing (first review completed), it never regresses to New
- Learning history remains even if memory weakens
- Rationale: Practicing is the first user-driven action; this milestone is never lost

### Implementation Notes

- Stage calculation is **deterministic** and **computed on-demand** from current `learning_cards` state + `review_logs` history
- No randomness or ML—purely rule-based
- Client-side service (`ProgressStageService`) computes stage from FSRS metrics + review history
- Re-compute after every review to check for transitions (target: <50ms per word)

---

## 2. Data Schema Design

### Decision: Hybrid Approach (Cached Stage Column + Existing Review Logs)

**Approach**: Add `progress_stage` column to `learning_cards` table for fast reads. Compute stage from existing `review_logs.cue_type` + `meanings` data. Defer event logging to post-launch if analytics needed.

**Rationale**:
- **Performance**: Vocabulary list queries need fast stage filtering/sorting
- **Simplicity**: Leverages existing `review_logs` table (already captures cue type, rating, timestamp)
- **YAGNI**: Don't add separate event logging table until proven needed for analytics

### Schema Changes

```sql
-- Add cached stage column
ALTER TABLE learning_cards
  ADD COLUMN IF NOT EXISTS progress_stage VARCHAR(20) NOT NULL DEFAULT 'captured';

-- Index for vocabulary list filtering
CREATE INDEX IF NOT EXISTS idx_learning_cards_user_stage
  ON learning_cards(user_id, progress_stage)
  WHERE deleted_at IS NULL;

COMMENT ON COLUMN learning_cards.progress_stage IS
  'Current progress stage: captured, practicing, stabilizing, active, mastered.
   Computed from review_logs data. Updated after each user-driven stage transition.';
```

### Data Sources for Stage Calculation

1. **New**: No learning_card exists yet (word exists in vocabulary table only)
2. **Practicing/Stabilizing/Mastered**: Use `learning_cards` fields (stability, reps, lapses, state)
3. **Known**: Query `review_logs` for successful non-translation retrievals:
   ```sql
   SELECT COUNT(*) FROM review_logs
   WHERE learning_card_id = ?
     AND rating >= 3
     AND cue_type IN ('definition', 'synonym', 'context_cloze', 'disambiguation')
   ```

### Performance Considerations

- Stage calculation: <50ms per word (single DB query per card, client-side logic)
- Vocabulary list query: Fast (stage is indexed column on learning_cards)
- Session recap: Compute stage before/after each review, diff at session end (no extra DB queries)
- Write overhead: Only UPDATE `learning_cards.progress_stage` when stage changes (not on every review)

### Alternatives Considered

**Option 1: Extend learning_cards only** (Chosen)
- ✅ Minimal schema changes
- ✅ Fast vocabulary list queries
- ✅ Simple 1:1 relationship
- ❌ No historical stage tracking (acceptable for MVP)

**Option 2: New learning_events table** (Rejected for MVP)
- ✅ Historical tracking of all stage transitions
- ✅ Event sourcing pattern for analytics
- ❌ Additional table increases complexity
- ❌ Slower current-stage queries (requires MAX aggregation)
- ❌ Write amplification (every review → 2 table writes)
- **Decision**: Defer until post-launch analytics prove need (YAGNI)

---

## 3. UI Feedback Patterns

### Decision: Inline Badge for Micro-Feedback + Dedicated Recap Card

**Approach**:
1. **During session**: Show inline badge overlay near word card for 2.5-3 seconds on stage transitions
2. **Post-session**: Display dedicated "Progress Made" card on SessionCompleteScreen with transition counts

**Rationale**:
- Respects design principle: "minimal cognitive noise" (no instructional hints, no pressure)
- Non-intrusive: Doesn't interrupt session flow
- Contextual: Feedback appears near relevant content
- Proven patterns: Based on Duolingo micro-animations and Material Design guidelines

### Micro-Feedback (During Session)

**Visual Design**:
- Widget: Material 3 `Badge` with custom styling
- Position: Top-right corner of card content (overlay)
- Style: Small pill-shaped badge (60-80px width, single-line text)
- Colors:
  - "Stabilizing": `colors.accent` (Amber)
  - "Known now": Success green (needs token addition)

**Timing**:
- Display duration: **2.5-3 seconds**
- Animation:
  - Fade in: 300ms
  - Hold: 2000ms
  - Fade out: 400ms
- Trigger: Immediately after grade button tap, on actual stage transition only

**Implementation**:
```dart
Stack(
  children: [
    CardContent(),
    Positioned(
      top: 8,
      right: 8,
      child: AnimatedOpacity(
        duration: Duration(milliseconds: 300),
        opacity: showBadge ? 1.0 : 0.0,
        child: Badge(
          label: Text('Stabilizing'),
          backgroundColor: colors.accent,
        ),
      ),
    ),
  ],
)
```

**Why Not Toast/SnackBar**:
- SnackBars appear at screen bottom (too far from context)
- Toasts can feel intrusive during rapid card flow
- Inline badges respect "minimal cognitive noise" principle

### Session Recap

**Layout**:
- Position: On SessionCompleteScreen, below primary stats (cards reviewed, time spent, streak)
- Component: shadcn Card with icon + count + label rows
- Title: "Progress Made"
- Conditional display: Only show if transitions occurred (no empty state message)

**Visual Structure**:
```
┌─────────────────────────────────┐
│ Progress Made                   │
│                                 │
│ 🎯 2 words → Stabilizing        │ <- Amber icon/color
│ ⭐ 1 word → Known               │ <- Emerald/success color
└─────────────────────────────────┘
```

**Emphasis for Rare Achievements**:
- When word reaches "Known": Add subtle pulse animation (300ms, one-time)
- When word reaches "Mastered": More prominent visual treatment
- Optional: Brief haptic feedback when screen appears

### Accessibility

**Screen Reader Announcements**:

1. **During Session**:
   ```dart
   SemanticsService.announce(
     'Word progressing to Stabilizing',
     TextDirection.ltr,
   );
   ```
   - Keep concise: "Word progressing to {status}" (5 words max)
   - Only announce actual transitions, not every grade

2. **Session Recap**:
   ```dart
   Semantics(
     label: '2 words progressed to Stabilizing, 1 word became Known',
     liveRegion: true,
     child: ProgressSummaryCard(),
   );
   ```
   - Announce summary when SessionCompleteScreen appears
   - Use correct plural/singular: "1 word" vs "2 words"

**Color Contrast**:
- Amber accent: Already meets WCAG AA for Stone background
- Success green: Ensure Green 600+ (light mode) or Green 400+ (dark mode) on Stone backgrounds
- Test with WebAIM Contrast Checker

### Flutter Widgets

**Recommended**:
- `Badge` (Material 3): Native support in Flutter 3.7+
- `AnimatedOpacity`: For fade in/out
- `AnimatedContainer`: For size/color transitions
- `SemanticsService.announce()`: For dynamic status announcements
- `Semantics(liveRegion: true)`: For auto-announcing content changes

**State Management**:
```dart
class SessionState {
  Map<String, TransitionEvent> transitions = {};

  void recordTransition(String wordId, ProgressStage from, ProgressStage to) {
    transitions[wordId] = TransitionEvent(
      from: from,
      to: to,
      timestamp: DateTime.now(),
    );
  }

  SessionSummary getSummary() {
    final stabilizingCount = transitions.values
      .where((t) => t.to == ProgressStage.stabilizing).length;
    final knownCount = transitions.values
      .where((t) => t.to == ProgressStage.active).length;

    return SessionSummary(
      stabilizingCount: stabilizingCount,
      knownCount: knownCount,
    );
  }
}
```

### Alternatives Considered

**Toast Messages** (Rejected)
- ❌ Appear at screen bottom, too far from context
- ❌ Can feel intrusive during rapid card flow

**Full-Screen Confetti** (Rejected)
- ❌ Too celebratory, creates pressure
- ❌ Violates "minimal cognitive noise" principle

**Status Bar Ticker** (Rejected)
- ❌ Competes with session progress indicator
- ❌ Less contextual than inline badge

---

## Summary of Decisions

| Area | Decision | Rationale |
|------|----------|-----------|
| **Stage Calculation** | FSRS metrics (stability, reps, lapses, state) | Leverages existing infrastructure, deterministic, no ML/randomness |
| **Data Schema** | Add `progress_stage` column to `learning_cards` | Fast queries, minimal complexity, defer event logging (YAGNI) |
| **Non-Translation Detection** | Use existing `review_logs.cue_type` field | Already captures needed data, no new logging required |
| **Micro-Feedback UI** | Inline badge overlay (2.5-3s duration) | Non-intrusive, contextual, respects design principles |
| **Session Recap UI** | Dedicated card on SessionCompleteScreen | Clear summary, emphasizes rare achievements, accessible |
| **Accessibility** | Screen reader announcements + color contrast | Ensures inclusive experience for all users |

## Next Steps

**Phase 1: Design & Contracts**
1. Create `data-model.md` documenting entities and relationships
2. Define API contracts (if needed—likely client-side only)
3. Create `quickstart.md` for developer onboarding
4. Update agent context with new technology decisions

**Phase 2: Tasks**
- Generate actionable tasks.md from design artifacts
- Prioritize P1 (micro-feedback) > P2 (session recap) > P3 (vocabulary list badges)
