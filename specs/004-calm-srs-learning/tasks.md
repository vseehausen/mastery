# Tasks: Calm, Time-Boxed SRS Learning

**Input**: Design documents from `/specs/004-calm-srs-learning/`
**Prerequisites**: plan.md, spec.md, data-model.md, research.md, contracts/, quickstart.md

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Mobile**: `mobile/lib/` (Flutter app)
- **Tests**: `mobile/test/`
- **Backend**: `supabase/migrations/`

---

## Phase 1: Setup

**Purpose**: Add FSRS dependency and prepare project structure

- [x] T001 Add `fsrs: ^2.0.1` dependency to `mobile/pubspec.yaml`
- [x] T002 [P] Create feature directory structure at `mobile/lib/features/learn/` with subdirectories: screens/, widgets/, providers/
- [x] T003 [P] Create domain directory structure at `mobile/lib/domain/services/` and `mobile/lib/domain/models/`

---

## Phase 2: Foundational (Database & Core Services)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**CRITICAL**: No user story work can begin until this phase is complete

### Database Schema (Drift)

- [x] T004 Define `LearningCards` table in `mobile/lib/data/database/tables.dart` with FSRS fields (state, due, stability, difficulty, reps, lapses, isLeech) and sync fields
- [x] T005 [P] Define `ReviewLogs` table in `mobile/lib/data/database/tables.dart` with before/after snapshots, responseTimeMs, retrievabilityAtReview, sessionId
- [x] T006 [P] Define `LearningSessions` table in `mobile/lib/data/database/tables.dart` with timer fields, outcome enum, accuracyRate, avgResponseTimeMs
- [x] T007 [P] Define `UserLearningPreferences` table in `mobile/lib/data/database/tables.dart` with dailyTimeTargetMinutes, targetRetention, intensity
- [x] T008 [P] Define `Streaks` table in `mobile/lib/data/database/tables.dart` with currentCount, longestCount, lastCompletedDate
- [x] T009 Update `mobile/lib/data/database/database.dart`: add 5 new tables to @DriftDatabase annotation, bump schemaVersion to 4, add migration from v3 to v4
- [x] T010 Run `dart run build_runner build --delete-conflicting-outputs` to generate Drift code

### Repositories

- [x] T011 [P] Implement `LearningCardRepository` in `mobile/lib/data/repositories/learning_card_repository.dart` with CRUD, getDueCards(userId, limit), getNewCards(userId, limit), getLeeches(userId), updateAfterReview()
- [x] T012 [P] Implement `ReviewLogRepository` in `mobile/lib/data/repositories/review_log_repository.dart` with insert(), getBySession(sessionId), getAverageResponseTime(userId)
- [x] T013 [P] Implement `SessionRepository` in `mobile/lib/data/repositories/session_repository.dart` with create(), updateProgress(), getActiveSession(userId), endSession(), computeSessionAggregates()
- [x] T014 [P] Implement `StreakRepository` in `mobile/lib/data/repositories/streak_repository.dart` with get(userId), increment(userId), reset(userId), updateLongest()
- [x] T015 [P] Implement `UserPreferencesRepository` in `mobile/lib/data/repositories/user_preferences_repository.dart` with get(userId), upsert(), getOrCreateWithDefaults(userId)

### Core Domain Services

- [x] T016 Implement `SrsScheduler` in `mobile/lib/domain/services/srs_scheduler.dart` per contracts/srs-scheduler.md: reviewCard(), getRetrievability(), createScheduler(), initializeCard(), LEECH_THRESHOLD=8
- [x] T017 Implement `TelemetryService` in `mobile/lib/domain/services/telemetry_service.dart` with getEstimatedSecondsPerItem(userId) using rolling average from ReviewLogs, default 15s for new users
- [x] T018 Implement `SessionPlanner` in `mobile/lib/domain/services/session_planner.dart` per contracts/session-planner.md: buildSessionPlan(), computePriorityScore(), shouldSuppressNewWords() with hysteresis logic
- [x] T019 [P] Create `SessionPlan` value object in `mobile/lib/domain/models/session_plan.dart` with items, estimatedDurationSeconds, newWordCount, reviewCount, leechCount
- [x] T020 [P] Create `PriorityScore` value object in `mobile/lib/domain/models/priority_score.dart` with score calculation helpers
- [x] T021 [P] Create `PlannedItem` model in `mobile/lib/domain/models/planned_item.dart` with learningCard, interactionMode (recognition/recall), priority
- [x] T022 [P] Create enums file in `mobile/lib/domain/models/learning_enums.dart`: CardState, ReviewRating, InteractionMode, Intensity, SessionOutcome

### Providers

- [x] T023 Create `learning_providers.dart` in `mobile/lib/providers/` wiring SrsScheduler, SessionPlanner, TelemetryService as Riverpod providers

### Supabase Migration

- [x] T024 Create Supabase migration `supabase/migrations/2026MMDD000001_add_learning_tables.sql` with all 5 tables, RLS policies (auth.uid() = user_id), indexes matching Drift schema, ON DELETE CASCADE for ReviewLogs

**Checkpoint**: Foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - Start and Complete a Daily Session (Priority: P1) MVP

**Goal**: Learner taps "Start Session (X min)", reviews items for configured duration, sees "You're done for today" message

**Independent Test**: Start a session with vocabulary items, answer items, verify session ends at time limit with completion message and streak increments

### Implementation for User Story 1

- [x] T025 [US1] Implement `SessionHomeScreen` in `mobile/lib/features/learn/screens/session_home_screen.dart` showing "Start Session (X min)" CTA, progress bar for today, streak indicator, "Nothing to practice" state
- [x] T026 [US1] Implement `SessionTimer` widget in `mobile/lib/features/learn/widgets/session_timer.dart` with countdown display, elapsed time tracking, pause/resume support
- [x] T027 [US1] Implement `SessionProgressBar` widget in `mobile/lib/features/learn/widgets/session_progress_bar.dart` showing items completed vs total
- [x] T028 [US1] Implement `RecognitionCard` widget in `mobile/lib/features/learn/widgets/recognition_card.dart` with MCQ layout (4 options), tap handling, correct/incorrect feedback
- [x] T029 [US1] Implement `RecallCard` widget in `mobile/lib/features/learn/widgets/recall_card.dart` with show/hide answer toggle, Again/Hard/Good/Easy buttons
- [x] T030 [US1] Implement `DistractorService` in `mobile/lib/domain/services/distractor_service.dart` to select 3 wrong answers for MCQ from vocabulary pool
- [x] T031 [US1] Implement `SessionScreen` in `mobile/lib/features/learn/screens/session_screen.dart` with item presentation loop, timer integration, save-after-every-item persistence, mode selection (recognition for new/weak, recall for mature)
- [x] T032 [US1] Implement `SessionCompleteScreen` in `mobile/lib/features/learn/screens/session_complete_screen.dart` with "You're done for today" message, streak display, return to home button
- [x] T033 [US1] Implement `session_providers.dart` in `mobile/lib/features/learn/providers/` with activeSessionProvider, sessionPlanProvider, currentItemProvider, sessionTimerProvider
- [x] T034 [US1] Implement `StreakIndicator` widget in `mobile/lib/features/learn/widgets/streak_indicator.dart` showing current streak count
- [x] T035 [US1] Implement `streak_providers.dart` in `mobile/lib/features/learn/providers/` with currentStreakProvider, updateStreak mutation
- [x] T036 [US1] Wire session completion to streak increment: on SessionOutcome.complete, call StreakRepository.increment() if not already completed today
- [x] T037 [US1] Add navigation routes for learn feature: /learn (home), /learn/session, /learn/complete
- [x] T038 [US1] Replace "Coming soon" placeholder in existing navigation with SessionHomeScreen

**Checkpoint**: User Story 1 complete - learner can start session, practice vocabulary, session ends at time limit, streak increments

---

## Phase 4: User Story 2 - Session Fills Using Priority Score (Priority: P1)

**Goal**: System builds session plan using priority scoring (overdue amount, retrievability, lapses) and selects correct interaction mode per item

**Independent Test**: Create user with mix of due reviews, leeches, new words; start session; verify items appear in priority-score order with correct interaction mode

### Implementation for User Story 2

- [x] T039 [US2] Implement priority score query in `LearningCardRepository.getDueCardsSorted()` in `mobile/lib/data/repositories/learning_card_repository.dart` returning cards ordered by computed priority
- [x] T040 [US2] Implement `selectInteractionMode()` in `SessionPlanner` in `mobile/lib/domain/services/session_planner.dart`: Recognition for state=new/learning/relearning or stability < 7 days; Recall for state=review with stability >= 7 days
- [x] T041 [US2] Update `buildSessionPlan()` in `SessionPlanner` to fill session: due reviews first (sorted by priority) -> leeches -> new words (up to intensity cap) -> stop at capacity
- [x] T042 [US2] Implement intensity-based new-word caps in `SessionPlanner`: Light=2/10min, Normal=5/10min, Intense=8/10min per data-model.md
- [x] T043 [US2] Update `SessionScreen` to use planned item order and assigned interaction mode from SessionPlan

**Checkpoint**: User Story 2 complete - session fills with priority-scored items, correct interaction mode per item

---

## Phase 5: User Story 3 - Invisible Backlog Handling After Missed Days (Priority: P1)

**Goal**: After missed days, learner sees same calm UX with no backlog numbers; new words suppressed when overdue exceeds 1 session capacity

**Independent Test**: Simulate user missing 5 days with 100 overdue items; verify home screen shows only "Start Session (X min)", session contains only reviews, new words suppressed

### Implementation for User Story 3

- [x] T044 [US3] Implement `shouldSuppressNewWords()` with hysteresis in `SessionPlanner` in `mobile/lib/domain/services/session_planner.dart`: entry at 1x capacity, exit at 2x capacity
- [x] T045 [US3] Add `newWordSuppressionActive` state tracking in `UserLearningPreferences` or session-level state to implement hysteresis correctly across sessions
- [x] T046 [US3] Update `buildSessionPlan()` to set newWordCap=0 when suppression active, silently filling entire session with overdue reviews
- [x] T047 [US3] Verify SessionHomeScreen shows NO backlog count, NO overdue indicator, NO special messaging regardless of overdue amount
- [x] T048 [US3] Implement load-balancing: when overdue exceeds session capacity, distribute across future sessions by capping items per session at capacity

**Checkpoint**: User Story 3 complete - missed days result in same calm UX, new words auto-suppressed during recovery

---

## Phase 6: User Story 4 - Configure Daily Time and Learning Intensity (Priority: P2)

**Goal**: Learner configures daily time target (1-60 min), intensity (Light/Normal/Intense), target retention (85-95%)

**Independent Test**: Change each setting, start new session, verify session duration and item mix reflect updated preferences

### Implementation for User Story 4

- [x] T049 [US4] Implement `LearningSettingsScreen` in `mobile/lib/features/learn/screens/learning_settings_screen.dart` with time target picker (5/10/15 presets + custom 1-60), intensity selector, retention slider
- [x] T050 [US4] Implement `learning_preferences_providers.dart` in `mobile/lib/features/learn/providers/` with userPreferencesProvider, updatePreferences mutation
- [x] T051 [US4] Update `SessionHomeScreen` CTA to reflect current dailyTimeTargetMinutes from UserLearningPreferences
- [x] T052 [US4] Pass user's targetRetention to SrsScheduler.createScheduler() when building session
- [x] T053 [US4] Add settings navigation from SessionHomeScreen (gear icon)

**Checkpoint**: User Story 4 complete - learner can configure learning preferences

---

## Phase 7: User Story 5 - Streak Tracking Based on Time Commitment (Priority: P2)

**Goal**: Streak increments only when full time commitment completed; resets after missed day; visible on home screen

**Independent Test**: Complete sessions on consecutive days, verify streak increments; miss a day, verify streak resets to 0

### Implementation for User Story 5

- [x] T054 [US5] Implement streak increment logic: only increment when SessionOutcome=complete AND plannedMinutes fully elapsed
- [x] T055 [US5] Implement streak reset logic: on session start, if lastCompletedDate is not yesterday and not today, reset currentCount to 0
- [x] T056 [US5] Implement "already completed today" state: after completing session, show "You're done for today" on SessionHomeScreen, disable start button
- [x] T057 [US5] Implement partial session tracking: if user quits early, show progress bar at X% complete, do NOT increment streak
- [x] T058 [US5] Update longestCount when currentCount exceeds it in StreakRepository

**Checkpoint**: User Story 5 complete - streak tracking works correctly

---

## Phase 8: User Story 6 - Optional Bonus Time Extension (Priority: P3)

**Goal**: After session ends, offer "+2 min bonus" button; user can extend multiple times

**Independent Test**: Complete session, tap bonus button, verify 2 more minutes of practice, completion screen reappears after bonus

### Implementation for User Story 6

- [x] T059 [US6] Add "+2 min bonus" button to `SessionCompleteScreen` in `mobile/lib/features/learn/screens/session_complete_screen.dart`
- [x] T060 [US6] Implement bonus extension flow: on tap, add 120 seconds to session, fetch more items from planner, resume SessionScreen
- [x] T061 [US6] Track bonusSeconds in LearningSessions table, update after each bonus
- [x] T062 [US6] Allow multiple consecutive bonus extensions (button reappears after each bonus completes)
- [x] T063 [US6] Handle edge case: if all items exhausted during bonus, end early with "You've reviewed everything available"

**Checkpoint**: User Story 6 complete - bonus extension fully functional

---

## Phase 9: Session Resume & Edge Cases

**Purpose**: Crash recovery and edge case handling per spec.md

- [x] T064 Implement session resume on app restart: check for active session where now < expiresAt, resume with remaining time
- [x] T065 Implement session expiry: if now > expiresAt on restart, discard session (set outcome=expired), generate fresh session
- [x] T066 Handle "no items available" state: show "Nothing to practice right now. Check back later." when no due items and no new words
- [x] T067 Handle "all items exhausted early" state: end session early with "You've reviewed everything available", still count as complete for streak
- [x] T068 Implement elapsed-time timer (not wall clock) for session duration to handle timezone changes gracefully
- [x] T069 Implement save-after-every-item: persist LearningCard updates and ReviewLog immediately after each grade

---

## Phase 10: Sync Integration

**Purpose**: Extend existing sync infrastructure for learning data

- [x] T070 [P] Add LearningCards to SyncOutbox pattern in `mobile/lib/data/services/sync_service.dart`
- [x] T071 [P] Add LearningSessions to SyncOutbox pattern
- [x] T072 [P] Add Streaks to SyncOutbox pattern
- [x] T073 [P] Add UserLearningPreferences to SyncOutbox pattern
- [x] T074 Add ReviewLogs to sync (push-only, append-only - never pulled)
- [x] T075 Trigger sync on session complete

---

## Phase 11: Polish & Cross-Cutting Concerns

**Purpose**: Code quality, tests, and documentation

**Test-First Deviation Note**: Tests are grouped here for MVP pragmatism rather than pure test-first. Acceptable if: tests are completed within the same PR as implementation or in the immediately following PR, before the feature is marked "done". This maintains the constitution's intent (tests document behavior, prevent regressions) while allowing faster iteration.

- [x] T076 [P] Run `flutter analyze` and fix all errors/warnings
- [x] T077 [P] Run `dart format .` on all new files
- [x] T078 Implement unit tests for SrsScheduler in `mobile/test/unit/services/srs_scheduler_test.dart`
- [x] T079 [P] Implement unit tests for SessionPlanner in `mobile/test/unit/services/session_planner_test.dart`
- [x] T080 [P] Implement unit tests for TelemetryService in `mobile/test/unit/services/telemetry_service_test.dart`
- [ ] T081 [P] Implement repository tests for LearningCardRepository in `mobile/test/unit/repositories/learning_card_repository_test.dart`
- [ ] T082 [P] Implement repository tests for SessionRepository in `mobile/test/unit/repositories/session_repository_test.dart`
- [ ] T083 [P] Implement repository tests for StreakRepository in `mobile/test/unit/repositories/streak_repository_test.dart`
- [ ] T084 [P] Implement widget tests for RecognitionCard in `mobile/test/widgets/recognition_card_test.dart`
- [ ] T085 [P] Implement widget tests for RecallCard in `mobile/test/widgets/recall_card_test.dart`
- [ ] T086 Implement widget tests for SessionScreen in `mobile/test/widgets/session_screen_test.dart`
- [ ] T087 Validate quickstart.md steps work end-to-end
- [ ] T088 Final review: verify no backlog counts, due numbers, or pressure indicators visible in any UI

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup - BLOCKS all user stories
- **User Stories (Phase 3-8)**: All depend on Foundational phase completion
  - US1, US2, US3 are all P1 and have interdependencies - implement sequentially
  - US4, US5 (P2) can start after US1-3 complete
  - US6 (P3) can start after US5 complete
- **Session Resume (Phase 9)**: Depends on US1 (Phase 3)
- **Sync (Phase 10)**: Depends on Foundational (Phase 2)
- **Polish (Phase 11)**: Depends on all user stories being complete

### User Story Dependencies

- **US1 (P1)**: Core session loop - no story dependencies, but requires foundational phase
- **US2 (P1)**: Priority scoring - builds on US1 session infrastructure
- **US3 (P1)**: Backlog handling - builds on US2 session planner
- **US4 (P2)**: Settings - independent of US2/US3, only needs US1
- **US5 (P2)**: Streaks - builds on US1 session completion
- **US6 (P3)**: Bonus time - builds on US5 streak logic

### Within Each Phase

- Database tables before repositories
- Repositories before services
- Services before providers
- Providers before screens
- Widgets can be parallel with screens

### Parallel Opportunities

**Phase 2 (Foundational)**:
- T004-T008: All 5 tables can be defined in parallel
- T011-T015: All repositories can be implemented in parallel
- T019-T022: All models/enums can be created in parallel

**Phase 10 (Sync)**:
- T070-T073: All sync integrations can run in parallel

**Phase 11 (Polish)**:
- T078-T085: All unit/widget tests can run in parallel

---

## Parallel Example: Foundational Phase

```bash
# Launch all table definitions together:
Task: "Define LearningCards table in mobile/lib/data/database/tables.dart"
Task: "Define ReviewLogs table in mobile/lib/data/database/tables.dart"
Task: "Define LearningSessions table in mobile/lib/data/database/tables.dart"
Task: "Define UserLearningPreferences table in mobile/lib/data/database/tables.dart"
Task: "Define Streaks table in mobile/lib/data/database/tables.dart"

# Then sequentially:
Task: "Update database.dart with new tables and migration"
Task: "Run build_runner"

# Then launch all repositories together:
Task: "Implement LearningCardRepository"
Task: "Implement ReviewLogRepository"
Task: "Implement SessionRepository"
Task: "Implement StreakRepository"
Task: "Implement UserPreferencesRepository"
```

---

## Implementation Strategy

### MVP First (User Stories 1-3)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1 (core session loop)
4. Complete Phase 4: User Story 2 (priority scoring)
5. Complete Phase 5: User Story 3 (backlog handling)
6. **STOP and VALIDATE**: Test full session flow independently
7. Deploy/demo if ready - this is the MVP

### Incremental Delivery

1. MVP (US1-3) → Core calm learning experience works
2. Add US4 (Settings) → User personalization
3. Add US5 (Streaks) → Habit formation
4. Add US6 (Bonus) → Engagement enhancement
5. Each story adds value without breaking previous stories

---

## Summary

| Phase | Task Count | Parallel Tasks |
|-------|------------|----------------|
| Setup | 3 | 2 |
| Foundational | 21 | 14 |
| US1 - Session | 14 | 0 |
| US2 - Priority | 5 | 0 |
| US3 - Backlog | 5 | 0 |
| US4 - Settings | 5 | 0 |
| US5 - Streaks | 5 | 0 |
| US6 - Bonus | 5 | 0 |
| Resume/Edge | 6 | 0 |
| Sync | 6 | 4 |
| Polish | 13 | 10 |
| **Total** | **88** | **30** |

**MVP Scope**: Phases 1-5 (48 tasks) delivers complete calm learning experience
**Suggested MVP Order**: Setup → Foundational → US1 → US2 → US3 → Phase 9 (resume) → basic tests
