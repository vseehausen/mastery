# Quickstart: 004-calm-srs-learning

## Prerequisites

- Flutter 3.x / Dart 3.x installed
- Existing `mobile/` app builds and runs
- Supabase CLI installed (`supabase db push` works)

## Setup

```bash
# 1. Switch to feature branch
git checkout 004-calm-srs-learning

# 2. Add FSRS dependency
cd mobile
flutter pub add fsrs

# 3. Regenerate Drift code after schema changes
dart run build_runner build --delete-conflicting-outputs

# 4. Run the app (triggers schema migration 3 → 4)
flutter run

# 5. Apply Supabase migration
cd ../supabase
supabase db push
```

## Key Files to Implement (in order)

1. **Database schema** — `mobile/lib/data/database/tables.dart`
   - Add 5 new table classes (LearningCards, ReviewLogs, LearningSessions, UserLearningPreferences, Streaks)
   - Update `database.dart`: add tables to `@DriftDatabase`, bump schemaVersion to 4, add migration

2. **Repositories** — `mobile/lib/data/repositories/`
   - `learning_card_repository.dart` — CRUD, due queries, leech queries, new-word queries
   - `review_log_repository.dart` — insert, query by card/session, time-per-item aggregation
   - `session_repository.dart` — create, update progress, resume logic
   - `streak_repository.dart` — increment, reset, get current
   - `user_preferences_repository.dart` — get/upsert preferences

3. **Domain services** — `mobile/lib/domain/services/`
   - `srs_scheduler.dart` — FSRS wrapper (see `contracts/srs-scheduler.md`)
   - `session_planner.dart` — Priority scoring + time-boxing (see `contracts/session-planner.md`)
   - `telemetry_service.dart` — Rolling average of responseTimeMs from ReviewLogs

4. **Providers** — `mobile/lib/features/learn/providers/`
   - Wire repositories and services into Riverpod providers

5. **UI screens** — `mobile/lib/features/learn/screens/`
   - `session_home_screen.dart` — Replace "Coming soon" placeholder
   - `session_screen.dart` — Timer + card presentation loop
   - `session_complete_screen.dart` — "You're done" + bonus button
   - `learning_settings_screen.dart` — Time target, retention, intensity

6. **Interaction widgets** — `mobile/lib/features/learn/widgets/`
   - `recognition_card.dart` — MCQ with 4 options
   - `recall_card.dart` — Show/hide answer + self-grade buttons

7. **Supabase migration** — `supabase/migrations/`
   - Mirror all 5 tables with RLS policies

## Running Tests

```bash
cd mobile
flutter test                    # All tests
flutter test test/unit/         # Unit tests only
flutter analyze                 # Lint check
```

## Architecture Notes

- **All SRS logic is local** — the FSRS scheduler, session planner, and priority scorer run entirely in Dart on the device
- **Save after every item** — each completed review persists immediately to SQLite (crash safety)
- **Session resume** — check `LearningSessions.expiresAt` on app start; resume if still valid
- **No "recovery mode" UX** — the planner silently suppresses new words when backlog is large (hysteresis rule)
- **Existing patterns** — follow the same repository/provider/screen architecture as `vocabulary/` feature
