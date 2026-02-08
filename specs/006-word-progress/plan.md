# Implementation Plan: Word-Level Progress & Motivation

**Branch**: `006-word-progress` | **Date**: 2026-02-08 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/006-word-progress/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Introduce competence-based progress tracking for vocabulary words through five user-driven stages (Captured → Practicing → Stabilizing → Active → Mastered). Display real-time micro-feedback during learning sessions, post-session recaps, and persistent stage indicators in the vocabulary list. Progress is determined exclusively by user-driven learning events (reviews, recalls, non-translation retrievals) using deterministic logic aligned with Self-Determination Theory for intrinsic motivation.

## Technical Context

**Language/Version**: Dart 3.x (Flutter mobile), TypeScript (Supabase Edge Functions)
**Primary Dependencies**: Flutter 3.x, Riverpod (state management), Supabase Flutter SDK, PostgreSQL (Supabase)
**Storage**: Supabase PostgreSQL (existing vocabulary, learning_cards tables; will add progress_stage column and learning_events table)
**Testing**: flutter_test (mobile unit/widget tests), Deno test (Edge Function integration tests)
**Target Platform**: iOS/Android mobile (Flutter), Supabase Edge Functions runtime
**Project Type**: Mobile + Backend (Flutter app + Supabase backend)
**Performance Goals**: Stage calculation < 50ms per word, micro-feedback display < 100ms from recall completion, session recap generation < 200ms
**Constraints**: Must preserve existing timeboxed session flow, no additional network requests during sessions (stage calculations happen client-side from existing data), deterministic stage logic (no ML/randomness)
**Scale/Scope**: ~254 words per user (current avg), 6 progress stages, 5 cue types, affects 3 screens (learn session, session complete, vocabulary list)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### I. Test-First Development ✅

**Status**: PASS - Test plan defined

**Evidence**:
- Mobile widget tests required for micro-feedback display (ProgressMicroFeedback widget)
- Mobile widget tests for session recap (SessionCompleteScreen with progress summary)
- Mobile widget tests for vocabulary list stage badges (StatusBadge widget updates)
- Unit tests for stage calculation logic (ProgressStageService)
- Integration tests for learning event logging (if Edge Function added)

**Test-first approach**: Tests will be written alongside implementation for all new widgets and business logic.

### II. Code Quality Standards ✅

**Status**: PASS - Quality gates defined

**Evidence**:
- All Flutter code will pass `flutter analyze` (strict mode)
- All code will be formatted with `dart format`
- Type-safe Dart code (no dynamic types without justification)
- Edge Functions (if added) will use TypeScript with strict mode

**Local verification**: `flutter analyze && flutter test` before commits

### III. Observability ✅

**Status**: PASS - Logging approach defined

**Evidence**:
- debugPrint for stage transition events during development
- debugPrint for learning event capture
- Future: Structured logging for progress analytics (deferred to post-launch)

**Development logging**: Stage transitions, calculation inputs/outputs, edge cases

### IV. Simplicity (YAGNI) ✅

**Status**: PASS - No premature abstraction

**Evidence**:
- Stage calculation logic lives in single service class (ProgressStageService)
- No abstractions until 3rd use case (only 1 progress tracking system)
- Minimal dependencies (uses existing Riverpod, Supabase stack)
- Reuses existing learning_cards table for SRS data

**Complexity avoided**:
- No complex state machines (simple enum-based stages)
- No separate progress database (uses existing vocabulary table + new column)
- No real-time progress updates across devices (calculated client-side from sync'd data)

### V. Online-Required Architecture ✅

**Status**: PASS - Aligned with architecture

**Evidence**:
- Progress stage calculated from Supabase data via Riverpod providers
- Learning events logged to Supabase (online write)
- No local-only progress state (derives from sync'd data)
- Offline mode not required (consistent with app architecture)

**Data flow**: Supabase (vocabulary + learning_cards) → Riverpod cache → Stage calculation → UI display

---

**Overall Status**: ✅ PASS - All constitution principles satisfied. No violations requiring justification.

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
mobile/
├── lib/
│   ├── domain/
│   │   └── models/
│   │       └── progress_stage.dart          # Enum: Captured, Practicing, Stabilizing, Active, Mastered
│   ├── data/
│   │   ├── models/
│   │   │   └── learning_event.dart          # Learning event data model
│   │   └── services/
│   │       └── progress_stage_service.dart  # Stage calculation logic
│   ├── features/
│   │   ├── learn/
│   │   │   └── widgets/
│   │   │       └── progress_micro_feedback.dart  # "Stabilizing", "Active now" toast
│   │   ├── session/
│   │   │   └── screens/
│   │   │       └── session_complete_screen.dart  # Updated with progress recap
│   │   └── vocabulary/
│   │       └── presentation/
│   │           └── widgets/
│   │               └── word_card.dart        # Updated StatusBadge with progress stage
│   └── providers/
│       └── progress_provider.dart            # Riverpod provider for stage calculation
└── test/
    ├── unit/
    │   └── services/
    │       └── progress_stage_service_test.dart
    └── widgets/
        ├── learn/
        │   └── progress_micro_feedback_test.dart
        └── session/
            └── session_complete_screen_test.dart

supabase/
├── migrations/
│   └── 20260208_add_progress_tracking.sql   # Add progress_stage column, learning_events table
└── functions/
    └── (no new functions - stage calc happens client-side)
```

**Structure Decision**: This is a Mobile + Backend feature following the existing Mastery project structure. The core logic lives in the Flutter mobile app (`mobile/lib/`), with database schema changes in Supabase migrations. No new Edge Functions required—progress stage calculation happens client-side using existing Riverpod/Supabase architecture. Tests follow Flutter conventions (unit tests for services, widget tests for UI components).

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |
