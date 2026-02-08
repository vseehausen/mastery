# Implementation Tasks: Word-Level Progress & Motivation

**Feature**: 006-word-progress
**Branch**: `006-word-progress`
**Generated**: 2026-02-08
**Template Version**: 1.0

## Task Organization

Tasks are organized into phases aligned with user stories from spec.md:
- **Phase 0: Setup** - Database migrations and foundational models
- **Phase 1: Foundational** - Core services and business logic
- **Phase 2: US1 (P1)** - Real-time progress micro-feedback during sessions
- **Phase 3: US2 (P2)** - Session progress summary/recap
- **Phase 4: US3 (P3)** - Vocabulary list stage indicators
- **Phase 5: Polish** - Performance optimization and accessibility

**Priority Legend**: P0 (blocking), P1 (high), P2 (medium), P3 (low)

---

## Phase 0: Setup

### Database Migration

- [X] [TASK-001] [P0] Create Supabase migration file `supabase/migrations/20260208_add_progress_tracking.sql`
  - Add `progress_stage` column to `learning_cards` table (VARCHAR(20), DEFAULT 'captured')
  - Create index `idx_learning_cards_user_stage` on (user_id, progress_stage) WHERE deleted_at IS NULL
  - Add column comment explaining computed nature of stage
  - **Acceptance**: Migration applies cleanly with `supabase db push`, no errors
  - **Test**: Run migration on local Supabase instance, verify column exists with correct default

### Domain Models

- [X] [TASK-002] [P0] Create ProgressStage enum at `mobile/lib/domain/models/progress_stage.dart`
  - Define 5 stages: captured, practicing, stabilizing, active, mastered
  - Implement `displayName` getter returning capitalized stage names
  - Implement `getColor(MasteryColorScheme)` method mapping stages to colors (captured→mutedForeground, practicing/stabilizing→accent, active/mastered→success)
  - Add `fromString()` factory method for database deserialization
  - **Acceptance**: Enum compiles, all getters return correct values
  - **Test**: Unit test `progress_stage_test.dart` verifying displayName, color mapping, fromString

- [X] [TASK-003] [P0] Create StageTransition model at `mobile/lib/domain/models/stage_transition.dart`
  - Fields: vocabularyId (String), wordText (String), fromStage (ProgressStage?), toStage (ProgressStage), timestamp (DateTime)
  - Add `isRareAchievement` getter (true if toStage == active || toStage == mastered)
  - Implement JSON serialization methods
  - **Acceptance**: Model compiles, serialization round-trips correctly
  - **Test**: Unit test verifying JSON serialization, isRareAchievement logic

- [X] [TASK-004] [P0] Create SessionProgressSummary model at `mobile/lib/domain/models/session_progress_summary.dart`
  - Field: transitions (List<StageTransition>)
  - Computed getters: stabilizingCount, activeCount, masteredCount, hasTransitions, hasRareAchievements
  - Method: `toDisplayString()` returning formatted summary (e.g., "2 words → Stabilizing • 1 word → Active")
  - **Acceptance**: Model compiles, computed properties calculate correctly
  - **Test**: Unit test with various transition lists verifying count logic, display formatting

---

## Phase 1: Foundational

### Business Logic

- [X] [TASK-005] [P0] Create ProgressStageService at `mobile/lib/data/services/progress_stage_service.dart`
  - Implement `calculateStage(LearningCard?, int nonTranslationSuccessCount)` method
  - Stage logic:
    - No card → Captured
    - reps >= 1 → Practicing
    - stability >= 1.0 && reps >= 3 && lapses <= 2 && state == 2 → Stabilizing
    - Stabilizing criteria + nonTranslationSuccessCount >= 1 → Active
    - stability >= 90 && reps >= 12 && lapses <= 1 && state == 2 → Mastered
  - Add debug logging for stage calculations
  - **Acceptance**: Service compiles, calculateStage returns correct stages for all cases
  - **Test**: Unit test `test/unit/services/progress_stage_service_test.dart` with 10+ test cases covering all stages, edge cases, regression paths
  - **Performance**: Stage calculation completes in <50ms per word (measured with Stopwatch)

- [X] [TASK-006] [P1] Extend LearningCard model to include `progressStage` field at `mobile/lib/data/models/learning_card.dart`
  - Add `progressStage` field (ProgressStage?, nullable for backwards compatibility)
  - Update JSON deserialization to parse progress_stage column
  - Update JSON serialization to write progress_stage column
  - **Acceptance**: LearningCard model compiles, JSON round-trips correctly with new field
  - **Test**: Unit test verifying serialization with and without progressStage field

### Data Queries

- [X] [TASK-007] [P1] Add getNonTranslationSuccessCount method to SupabaseDataService at `mobile/lib/data/services/supabase_data_service.dart`
  - Query review_logs WHERE learning_card_id = ? AND rating >= 3 AND cue_type IN ('definition', 'synonym', 'context_cloze', 'disambiguation')
  - Return count as int
  - Handle null/empty results (return 0)
  - **Acceptance**: Method compiles, returns correct counts for test data
  - **Test**: Integration test with seeded review_logs data verifying count accuracy
  - **Performance**: Query completes in <100ms (use EXPLAIN ANALYZE to verify index usage)

---

## Phase 2: US1 (P1) - Real-Time Progress Micro-Feedback

### Session State Management

- [X] [TASK-008] [P1] [US1] Extend SessionProvider to track stage transitions at `mobile/lib/features/learn/providers/session_provider.dart`
  - Add `transitions` field (List<StageTransition>)
  - Add `recordReview()` method:
    - Calculate stage BEFORE review (using current card state)
    - Submit grade to FSRS (existing logic)
    - Calculate stage AFTER review (using updated card state)
    - If stage changed: create StageTransition, add to transitions list, trigger micro-feedback
  - Add `clearTransitions()` method for session reset
  - **Acceptance**: SessionProvider compiles, recordReview detects transitions correctly
  - **Test**: Widget test verifying transitions list updates when card state changes

### Micro-Feedback Widget

- [X] [TASK-009] [P1] [US1] Create ProgressMicroFeedback widget at `mobile/lib/features/learn/widgets/progress_micro_feedback.dart`
  - StatefulWidget accepting ProgressStage parameter
  - AnimatedOpacity for fade in/out (300ms in, 2000ms hold, 400ms out)
  - Material 3 Badge with stage displayName and color
  - Auto-dismiss after 2.5 seconds total
  - SemanticsService announcement: "Word progressing to {stage}"
  - **Acceptance**: Widget builds without errors, animation timing correct, screen reader announces
  - **Test**: Widget test `test/widgets/learn/progress_micro_feedback_test.dart`:
    - Badge appears on init
    - Badge disappears after 2.5s
    - Correct color for each stage
    - Screen reader announcement fires

- [X] [TASK-010] [P1] [US1] Integrate ProgressMicroFeedback into learn session screens
  - Update `mobile/lib/features/learn/widgets/definition_cue_card.dart`
  - Update `mobile/lib/features/learn/widgets/synonym_cue_card.dart`
  - Update `mobile/lib/features/learn/widgets/cloze_cue_card.dart`
  - Update `mobile/lib/features/learn/widgets/recall_card.dart`
  - Update `mobile/lib/features/learn/widgets/disambiguation_card.dart`
  - Add Stack overlay with ProgressMicroFeedback widget (top-right position)
  - Show only when stage transition detected in SessionProvider
  - **Acceptance**: Micro-feedback appears during session when stage changes, no errors
  - **Test**: Manual test on simulator completing session with words at different stages

### Testing & Verification

- [X] [TASK-011] [P1] [US1] Verify US1 acceptance scenarios
  - AS1: Review word with multiple successful recalls → see "Stabilizing" feedback
  - AS2: First correct non-translation review → see "Active now" feedback
  - AS3: Review word not meeting criteria → no feedback shown
  - AS4: Answer incorrectly → no progress feedback
  - **Acceptance**: All 4 acceptance scenarios pass manual testing
  - **Test**: Manual test checklist on simulator with pre-seeded test data

---

## Phase 3: US2 (P2) - Session Progress Summary

### Session Recap UI

- [X] [TASK-012] [P2] [US2] Extend SessionCompleteScreen at `mobile/lib/features/session/screens/session_complete_screen.dart`
  - Add conditional "Progress Made" card (only show if transitions exist)
  - Card layout: Title + icon/count/label rows for each transition type
  - Order: Mastered → Active → Stabilizing (by significance)
  - Use MasteryTextStyles.h4 for title, MasteryTextStyles.body for counts
  - Color coding: Stabilizing (amber/accent), Active (green/success), Mastered (emerald/success with emphasis)
  - Add subtle pulse animation for rare achievements (active/mastered)
  - Semantics: "2 words progressed to Stabilizing, 1 word became Active" (liveRegion: true)
  - **Acceptance**: Card displays correctly with proper styling, only shows when transitions exist
  - **Test**: Widget test `test/widgets/session/session_complete_screen_test.dart`:
    - Card not shown when no transitions
    - Card shows correct counts for each transition type
    - Rare achievements highlighted
    - Screen reader announces summary

- [X] [TASK-013] [P2] [US2] Connect SessionProvider transitions to SessionCompleteScreen
  - Pass SessionProgressSummary from SessionProvider to SessionCompleteScreen
  - Update navigation to SessionCompleteScreen to include summary data
  - Clear transitions when session restarts
  - **Acceptance**: Session recap displays accurate data from completed session
  - **Test**: Integration test completing session, verifying recap data matches recorded transitions

### Testing & Verification

- [X] [TASK-014] [P2] [US2] Verify US2 acceptance scenarios
  - AS1: Session with 2 stabilized + 1 active → see "2 words stabilized • 1 word became Active"
  - AS2: Session with no transitions → see standard "Done ✅" without recap
  - AS3: Session with mastered word → recap highlights rare achievement
  - AS4: Multiple transition types → summarized in order (Mastered → Active → Stabilizing)
  - **Acceptance**: All 4 acceptance scenarios pass manual testing
  - **Test**: Manual test checklist on simulator with various session outcomes

---

## Phase 4: US3 (P3) - Vocabulary List Stage Indicators

### Vocabulary List UI

- [X] [TASK-015] [P3] [US3] Update VocabularyProvider to calculate stages at `mobile/lib/providers/vocabulary_provider.dart`
  - Extend loadVocabulary() to fetch learning_cards with vocabulary
  - For each word: calculate stage using ProgressStageService
  - Cache stage in VocabularyWithStage wrapper model (create if needed)
  - **Acceptance**: Provider loads vocabulary with computed stages, no errors
  - **Test**: Unit test verifying stage calculation for vocabulary list items

- [X] [TASK-016] [P3] [US3] Update StatusBadge widget at `mobile/lib/features/vocabulary/presentation/widgets/status_badge.dart`
  - Add progress stage display mode
  - Map ProgressStage enum to badge text and color
  - Reuse existing badge styling (small pill shape)
  - **Acceptance**: Badge displays progress stage with correct color
  - **Test**: Widget test verifying badge appearance for each stage

- [X] [TASK-017] [P3] [US3] Update VocabularyListItem to display progress stage badge
  - Update `mobile/lib/features/vocabulary/presentation/widgets/word_card.dart`
  - Replace or augment existing StatusBadge with progress stage
  - Position in metadata row (below word text)
  - **Acceptance**: Vocabulary list items show progress stage badges
  - **Test**: Widget test verifying badge appears for each list item

- [X] [TASK-018] [P3] [US3] Add filtering/sorting by progress stage to vocabulary list
  - Update VocabularyScreen at `mobile/lib/features/vocabulary/presentation/screens/vocabulary_screen.dart`
  - Add filter dropdown for stage (All, Captured, Practicing, Stabilizing, Active, Mastered)
  - Add sort option by stage (in addition to existing sorts)
  - **Acceptance**: Filtering and sorting work correctly, vocabulary list updates
  - **Test**: Widget test verifying filter/sort controls update displayed words

### Testing & Verification

- [X] [TASK-019] [P3] [US3] Verify US3 acceptance scenarios
  - AS1: Word captured but not reviewed → shows "Captured"
  - AS2: Word being practiced → shows correct stage (Practicing/Stabilizing/Active/Mastered)
  - AS3: Filter/sort by stage → easily identify words at specific stages
  - **Acceptance**: All 3 acceptance scenarios pass manual testing
  - **Test**: Manual test checklist on simulator with diverse vocabulary

---

## Phase 5: Polish

### Performance Optimization

- [X] [TASK-020] [P2] Add performance instrumentation to ProgressStageService
  - Wrap calculateStage() with Stopwatch timing
  - Add debugPrint for calculations >50ms (warning threshold)
  - Test with 100-word vocabulary list load
  - **Acceptance**: Stage calculation averages <50ms per word
  - **Test**: Performance benchmark test measuring calculation time

- [X] [TASK-021] [P2] Optimize vocabulary list query for stage display
  - Verify index usage with EXPLAIN ANALYZE on learning_cards query
  - Add batch stage calculation (calculate all stages in single pass)
  - Consider caching stage in learning_cards.progress_stage column (write-behind pattern)
  - **Acceptance**: Vocabulary list with 100 words loads in <500ms
  - **Test**: Performance benchmark measuring list load time

### Accessibility

- [X] [TASK-022] [P2] Verify color contrast for all progress stage colors
  - Test Captured (mutedForeground) on Stone background
  - Test Practicing/Stabilizing (accent/amber) on Stone background
  - Test Active/Mastered (success/green) on Stone background
  - Use WebAIM Contrast Checker, ensure WCAG AA compliance
  - **Acceptance**: All stage colors meet WCAG AA contrast ratio (4.5:1 for text)
  - **Test**: Automated contrast checker or manual verification

- [X] [TASK-023] [P2] Verify screen reader experience
  - Test micro-feedback announcements during session
  - Test session recap announcement on SessionCompleteScreen
  - Test vocabulary list stage badge semantics
  - Verify announcements are concise (5-10 words max)
  - **Acceptance**: All progress indicators are accessible via screen reader
  - **Test**: Manual test with iOS VoiceOver, verify announcements clear and timely

### Code Quality

- [X] [TASK-024] [P1] Run full test suite and verify coverage
  - Execute `flutter test` for all new tests
  - Verify unit test coverage for ProgressStageService (100%)
  - Verify widget test coverage for micro-feedback, session recap
  - **Acceptance**: All tests pass, no test failures
  - **Test**: CI pipeline or local `flutter test` command

- [X] [TASK-025] [P1] Run flutter analyze and fix any issues
  - Execute `flutter analyze` in strict mode
  - Fix all errors, warnings, and hints
  - Ensure type-safe code (no dynamic types without justification)
  - **Acceptance**: `flutter analyze` returns 0 issues
  - **Test**: CI pipeline or local `flutter analyze` command

- [X] [TASK-026] [P1] Format all Dart code
  - Execute `dart format mobile/lib mobile/test`
  - Verify consistent code style across all new files
  - **Acceptance**: All files formatted per Dart style guide
  - **Test**: `dart format --set-exit-if-changed` returns 0

---

## Dependency Graph

```
TASK-001 (migration) ────┐
                         ├──> TASK-005 (service) ──┐
TASK-002 (ProgressStage) ┤                         ├──> TASK-008 (session tracking) ──> TASK-009 (micro-feedback) ──> TASK-010 (integration) ──> TASK-011 (US1 verify)
                         ├──> TASK-006 (LearningCard)
TASK-003 (StageTransition)                         │
                                                    ├──> TASK-012 (recap UI) ──> TASK-013 (recap integration) ──> TASK-014 (US2 verify)
TASK-004 (Summary) ─────────────────────────────────┤
                                                    └──> TASK-015 (vocab provider) ──> TASK-016 (badge) ──> TASK-017 (list item) ──> TASK-018 (filter/sort) ──> TASK-019 (US3 verify)

TASK-007 (data query) ──> TASK-005 (service)

TASK-020, TASK-021, TASK-022, TASK-023 (polish) can run after respective feature complete

TASK-024, TASK-025, TASK-026 (quality) run after all implementation complete
```

---

## Parallel Execution Examples

### Batch 1: Foundation (can run in parallel after migration)
```bash
# After TASK-001 complete
TASK-002, TASK-003, TASK-004 (domain models)
```

### Batch 2: Services (can run in parallel after foundation)
```bash
# After domain models complete
TASK-005 (ProgressStageService)
TASK-006 (LearningCard extension)
TASK-007 (data query)
```

### Batch 3: Features (can run in parallel after services)
```bash
# After services complete, split into 3 parallel work streams:
- US1 stream: TASK-008 → TASK-009 → TASK-010 → TASK-011
- US2 stream: TASK-012 → TASK-013 → TASK-014
- US3 stream: TASK-015 → TASK-016 → TASK-017 → TASK-018 → TASK-019
```

### Batch 4: Polish (can run in parallel after features)
```bash
# After US1/US2/US3 complete
TASK-020 (perf instrumentation)
TASK-021 (query optimization)
TASK-022 (contrast check)
TASK-023 (screen reader)
```

### Batch 5: Quality (sequential, runs last)
```bash
# After all implementation + polish complete
TASK-024 (tests) → TASK-025 (analyze) → TASK-026 (format)
```

---

## Completion Checklist

### Per-Task Verification
- [ ] Code compiles without errors
- [ ] Tests pass (unit, widget, integration as specified)
- [ ] Manual testing complete (if specified)
- [ ] Performance targets met (if specified)
- [ ] Accessibility verified (if specified)

### Phase-Level Verification
- [ ] Phase 0: Migration applied, models compile
- [ ] Phase 1: Services functional, tests pass
- [ ] Phase 2: US1 acceptance scenarios verified
- [ ] Phase 3: US2 acceptance scenarios verified
- [ ] Phase 4: US3 acceptance scenarios verified
- [ ] Phase 5: All quality gates pass

### Final Verification
- [ ] All 26 tasks completed and checked off
- [ ] `flutter analyze` returns 0 issues
- [ ] `flutter test` all tests pass
- [ ] Manual testing on iOS simulator complete
- [ ] Performance targets met (stage calc <50ms, list load <500ms, micro-feedback <100ms)
- [ ] Accessibility verified (VoiceOver, contrast)
- [ ] Constitution principles satisfied (test-first, quality, observability, simplicity, online-required)

---

## Notes

**Test-First Development**: Write tests alongside implementation for TASK-002 through TASK-019. Tests are specified in acceptance criteria for each task.

**Performance Measurement**: Use Stopwatch class for timing measurements in TASK-020, TASK-021. Target: stage calculation <50ms, vocabulary list load <500ms, micro-feedback display <100ms.

**Accessibility**: Screen reader announcements required for TASK-009 (micro-feedback), TASK-012 (session recap). Verify with iOS VoiceOver in TASK-023.

**User-Driven Progression**: All stage transitions triggered by user actions (reviews) only. Background enrichment does NOT change stages (per design principle).

**Independent Testing**: Each user story can be tested independently:
- US1: Complete learning session, verify micro-feedback appears
- US2: Complete session, verify recap shows correct counts
- US3: Browse vocabulary list, verify stage badges display
