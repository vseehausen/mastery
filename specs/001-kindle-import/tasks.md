# Tasks: Kindle Import

**Input**: Design documents from `/specs/001-kindle-import/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/

**Tests**: Tests are written alongside implementation per Constitution Principle I (Test-First Development).

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Mobile**: `mobile/lib/`, `mobile/test/`
- **Desktop**: `desktop/src-tauri/src/`, `desktop/src/`
- **Backend**: `supabase/functions/`, `supabase/migrations/`

---

## Phase 1: Setup (Project Initialization)

**Purpose**: Create monorepo structure and configure tooling

- [ ] T001 Create monorepo directory structure: mobile/, desktop/, supabase/, specs/
- [ ] T002 [P] Initialize Flutter project in mobile/ with flutter create
- [ ] T003 [P] Initialize Tauri project in desktop/ with npm create tauri-app
- [ ] T004 [P] Initialize Supabase project in supabase/ with supabase init
- [ ] T005 [P] Configure Dart analyzer in mobile/analysis_options.yaml (strict mode)
- [ ] T006 [P] Configure ESLint in desktop/eslint.config.js (strict TypeScript)
- [ ] T007 [P] Configure Rust clippy in desktop/src-tauri/clippy.toml (pedantic)
- [ ] T008 Add root .gitignore for all three projects
- [ ] T009 [P] Add mobile dependencies to mobile/pubspec.yaml: drift, drift_flutter, supabase_flutter, file_picker, crypto
- [ ] T010 [P] Add desktop Rust dependencies to desktop/src-tauri/Cargo.toml: nusb, mountpoints, tokio, rusqlite, serde, uuid

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**CRITICAL**: No user story work can begin until this phase is complete

### Backend Foundation

- [ ] T011 Create Supabase migration 001_initial_schema.sql in supabase/migrations/ with all tables, enums, indexes, RLS policies from data-model.md
- [ ] T012 Create seed file supabase/seed.sql with English language entry
- [ ] T013 Deploy migration to Supabase: supabase db push
- [ ] T014 [P] Create Edge Function scaffold supabase/functions/sync/index.ts with Deno boilerplate
- [ ] T015 [P] Create Edge Function scaffold supabase/functions/highlights/index.ts with Deno boilerplate
- [ ] T016 [P] Create Edge Function scaffold supabase/functions/books/index.ts with Deno boilerplate

### Mobile Foundation

- [ ] T017 Create Drift database definition in mobile/lib/data/database/database.dart with all tables from data-model.md
- [ ] T018 Create Drift tables file mobile/lib/data/database/tables.dart (Languages, Books, Highlights, ImportSessions, SyncOutbox)
- [ ] T019 Create FTS5 virtual table in mobile/lib/data/database/fts.drift for highlight search
- [ ] T020 Run build_runner to generate Drift code: dart run build_runner build
- [ ] T021 Create Supabase client setup in mobile/lib/core/supabase_client.dart
- [ ] T022 Create auth repository interface in mobile/lib/domain/repositories/auth_repository.dart
- [ ] T023 Create auth repository implementation in mobile/lib/data/repositories/auth_repository_impl.dart
- [ ] T024 Create auth feature screens: mobile/lib/features/auth/screens/login_screen.dart, signup_screen.dart
- [ ] T025 Create auth state management in mobile/lib/features/auth/auth_cubit.dart
- [ ] T026 Create app entry point with auth gate in mobile/lib/main.dart

### Desktop Foundation

- [ ] T027 Create Rust database module in desktop/src-tauri/src/db/mod.rs with SQLite setup (rusqlite)
- [ ] T028 Create Rust database tables in desktop/src-tauri/src/db/schema.rs matching mobile Drift schema
- [ ] T029 Create Supabase auth helper in desktop/src-tauri/src/sync/auth.rs for JWT handling

**Checkpoint**: Foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - Manual File Import (Priority: P1) MVP

**Goal**: Users can import highlights by selecting a "My Clippings.txt" file from their Kindle

**Independent Test**: Upload a clippings file and verify highlights appear grouped by book

### Implementation for User Story 1

- [ ] T030 [US1] Create clippings parser module in mobile/lib/features/import/parser/clippings_parser.dart
- [ ] T031 [US1] Create parsed entry model in mobile/lib/features/import/parser/parsed_entry.dart (title, author, type, location, page, date, content)
- [ ] T032 [US1] Implement regex patterns for metadata extraction in clippings_parser.dart (handle US/UK date formats, location variations)
- [ ] T033 [US1] Implement content hash generation (SHA-256) in mobile/lib/core/utils/hash_utils.dart
- [ ] T034 [US1] Create test file mobile/test/unit/parser/clippings_parser_test.dart with sample clippings data
- [ ] T035 [US1] Create import service in mobile/lib/features/import/services/import_service.dart (orchestrates parse → dedupe → store)
- [ ] T036 [US1] Create book repository interface in mobile/lib/domain/repositories/book_repository.dart
- [ ] T037 [US1] Create book repository implementation in mobile/lib/data/repositories/book_repository_impl.dart
- [ ] T038 [US1] Create highlight repository interface in mobile/lib/domain/repositories/highlight_repository.dart
- [ ] T039 [US1] Create highlight repository implementation in mobile/lib/data/repositories/highlight_repository_impl.dart
- [ ] T040 [US1] Implement duplicate detection in highlight_repository_impl.dart using contentHash lookup
- [ ] T041 [US1] Create import session repository in mobile/lib/data/repositories/import_session_repository.dart
- [ ] T042 [US1] Create import screen in mobile/lib/features/import/screens/import_screen.dart with file picker
- [ ] T043 [US1] Create import progress widget in mobile/lib/features/import/widgets/import_progress.dart
- [ ] T044 [US1] Create import result widget in mobile/lib/features/import/widgets/import_result.dart (shows imported/skipped/errors)
- [ ] T045 [US1] Create import cubit in mobile/lib/features/import/import_cubit.dart for state management
- [ ] T046 [US1] Implement sync outbox entry creation in import_service.dart (queue for cloud sync)
- [ ] T047 [US1] Create sync service in mobile/lib/data/services/sync_service.dart (push pending changes)
- [ ] T048 [US1] Implement sync/push Edge Function in supabase/functions/sync/push.ts
- [ ] T049 [US1] Implement sync/pull Edge Function in supabase/functions/sync/pull.ts
- [ ] T050 [US1] Create import_sessions Edge Function in supabase/functions/import-sessions/index.ts
- [ ] T051 [US1] Create test mobile/test/unit/services/import_service_test.dart
- [ ] T052 [US1] Create integration test mobile/test/integration/import_flow_test.dart

**Checkpoint**: User Story 1 complete - users can import files and sync to cloud

---

## Phase 4: User Story 2 - Automatic Desktop Import (Priority: P2)

**Goal**: Highlights automatically sync when Kindle device is connected via USB

**Independent Test**: Connect Kindle with desktop agent running, verify new highlights appear automatically

### Implementation for User Story 2

- [ ] T053 [US2] Create Kindle detector module in desktop/src-tauri/src/kindle/mod.rs
- [ ] T054 [US2] Implement USB device detection in desktop/src-tauri/src/kindle/detector.rs using nusb (vendor ID 0x1949)
- [ ] T055 [US2] Implement mount point finder in desktop/src-tauri/src/kindle/mount.rs using mountpoints crate
- [ ] T056 [US2] Create Kindle device watcher in desktop/src-tauri/src/kindle/watcher.rs with polling loop (2s interval)
- [ ] T057 [US2] Create clippings parser in Rust desktop/src-tauri/src/parser/mod.rs (port from Dart)
- [ ] T058 [US2] Create parsed entry struct in desktop/src-tauri/src/parser/entry.rs
- [ ] T059 [US2] Implement regex patterns in desktop/src-tauri/src/parser/patterns.rs
- [ ] T060 [US2] Create test desktop/src-tauri/src/parser/tests.rs with sample data
- [ ] T061 [US2] Create local storage module in desktop/src-tauri/src/db/highlights.rs
- [ ] T062 [US2] Implement duplicate detection in desktop/src-tauri/src/db/highlights.rs using content hash
- [ ] T063 [US2] Create sync module in desktop/src-tauri/src/sync/mod.rs
- [ ] T064 [US2] Implement sync push in desktop/src-tauri/src/sync/push.rs (call Supabase Edge Function)
- [ ] T065 [US2] Create Tauri commands in desktop/src-tauri/src/main.rs: get_kindle_status, start_monitoring, stop_monitoring, trigger_import
- [ ] T066 [US2] Create TypeScript API wrapper in desktop/src/api/kindle.ts for Tauri invoke calls
- [ ] T067 [US2] Create React status component in desktop/src/components/KindleStatus.tsx
- [ ] T068 [US2] Create React settings component in desktop/src/components/Settings.tsx (auto-sync toggle)
- [ ] T069 [US2] Create main app layout in desktop/src/App.tsx with status display
- [ ] T070 [US2] Implement user preferences storage in desktop/src-tauri/src/db/preferences.rs
- [ ] T071 [US2] Create test desktop/src-tauri/src/kindle/tests.rs for detector/mount functions

**Checkpoint**: User Story 2 complete - desktop auto-import works independently

---

## Phase 5: User Story 3 - View and Organize Highlights (Priority: P3)

**Goal**: Users can browse highlights by book and search across all highlights

**Independent Test**: With pre-loaded data, browse books, view highlights, search for specific text

### Implementation for User Story 3

- [ ] T072 [US3] Implement books Edge Function GET /books in supabase/functions/books/index.ts
- [ ] T073 [US3] Implement books Edge Function GET /books/:id in supabase/functions/books/index.ts
- [ ] T074 [US3] Implement highlights Edge Function GET /highlights in supabase/functions/highlights/index.ts (with search param)
- [ ] T075 [US3] Implement highlights Edge Function GET /highlights/:id in supabase/functions/highlights/index.ts
- [ ] T076 [US3] Implement highlights Edge Function PATCH /highlights/:id in supabase/functions/highlights/index.ts
- [ ] T077 [US3] Implement highlights Edge Function DELETE /highlights/:id in supabase/functions/highlights/index.ts
- [ ] T078 [US3] Create library screen in mobile/lib/features/library/screens/library_screen.dart
- [ ] T079 [US3] Create book list widget in mobile/lib/features/library/widgets/book_list.dart
- [ ] T080 [US3] Create book card widget in mobile/lib/features/library/widgets/book_card.dart (title, author, highlight count)
- [ ] T081 [US3] Create book detail screen in mobile/lib/features/library/screens/book_detail_screen.dart
- [ ] T082 [US3] Create highlight list widget in mobile/lib/features/library/widgets/highlight_list.dart
- [ ] T083 [US3] Create highlight card widget in mobile/lib/features/library/widgets/highlight_card.dart
- [ ] T084 [US3] Create highlight detail screen in mobile/lib/features/library/screens/highlight_detail_screen.dart
- [ ] T085 [US3] Create highlight edit screen in mobile/lib/features/library/screens/highlight_edit_screen.dart
- [ ] T086 [US3] Create library cubit in mobile/lib/features/library/library_cubit.dart
- [ ] T087 [US3] Create search screen in mobile/lib/features/search/screens/search_screen.dart
- [ ] T088 [US3] Create search result widget in mobile/lib/features/search/widgets/search_result.dart (highlighted matches)
- [ ] T089 [US3] Create search service in mobile/lib/features/search/services/search_service.dart (uses FTS5)
- [ ] T090 [US3] Create search cubit in mobile/lib/features/search/search_cubit.dart
- [ ] T091 [US3] Implement offline FTS search in search_service.dart using Drift FTS5 queries
- [ ] T092 [US3] Create test mobile/test/unit/services/search_service_test.dart

**Checkpoint**: User Story 3 complete - users can browse and search highlights

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [ ] T093 [P] Add structured logging to mobile in mobile/lib/core/logging/logger.dart
- [ ] T094 [P] Add file-based logging to desktop in desktop/src-tauri/src/logging.rs
- [ ] T095 [P] Configure Crashlytics in mobile/lib/main.dart
- [ ] T096 [P] Add error boundaries to desktop UI in desktop/src/components/ErrorBoundary.tsx
- [ ] T097 Implement background sync worker in mobile/lib/data/services/background_sync.dart
- [ ] T098 Add network connectivity listener in mobile/lib/core/network/connectivity.dart
- [ ] T099 Create onboarding flow in mobile/lib/features/onboarding/ (first-time user guidance)
- [ ] T100 [P] Add loading states to all screens (skeleton loaders)
- [ ] T101 [P] Add empty states to library and search screens
- [ ] T102 [P] Add error states with retry buttons to all screens
- [ ] T103 Run quickstart.md validation: verify all setup steps work
- [ ] T104 Performance test: import 1000 highlights in <30 seconds
- [ ] T105 Performance test: search returns results in <3 seconds

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Story 1 (Phase 3)**: Depends on Foundational (Phase 2)
- **User Story 2 (Phase 4)**: Depends on Foundational (Phase 2) - can run parallel to US1
- **User Story 3 (Phase 5)**: Depends on Foundational (Phase 2) - can run parallel to US1/US2
- **Polish (Phase 6)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: No dependencies on other stories - **MVP**
- **User Story 2 (P2)**: No dependencies on other stories - can run in parallel with US1
- **User Story 3 (P3)**: No hard dependency, but more valuable with imported data from US1/US2

### Within Each User Story

- Models/entities before services
- Services before screens/UI
- Core implementation before integration
- Edge Functions can be developed in parallel with mobile

### Parallel Opportunities

**Phase 1 (Setup)**:
- T002, T003, T004 can run in parallel (different projects)
- T005, T006, T007 can run in parallel (different config files)
- T009, T010 can run in parallel (different dependency files)

**Phase 2 (Foundational)**:
- T014, T015, T016 can run in parallel (different Edge Functions)
- T017-T019 are sequential (Drift schema)
- T022-T025 can run in parallel (different auth files)
- T027-T029 can run in parallel (different Rust modules)

**Phase 3 (US1)**:
- T036-T041 (repositories) can run in parallel
- T048-T050 (Edge Functions) can run in parallel

**Phase 4 (US2)**:
- T053-T056 (Kindle detection) are sequential
- T057-T060 (parser) can run parallel to Kindle detection
- T063-T064 (sync) can run parallel to storage

**Phase 5 (US3)**:
- T072-T077 (Edge Functions) can run in parallel
- T078-T086 (mobile UI) are partially sequential (screens depend on widgets)
- T087-T091 (search) can run parallel to library UI

---

## Parallel Example: User Story 1 Setup

```bash
# After Phase 2 complete, launch these in parallel:

# Thread 1: Parser implementation
Task: T030 Create clippings parser module
Task: T031 Create parsed entry model
Task: T032 Implement regex patterns
Task: T033 Implement content hash generation
Task: T034 Create parser tests

# Thread 2: Repositories
Task: T036 Create book repository interface
Task: T037 Create book repository implementation
Task: T038 Create highlight repository interface
Task: T039 Create highlight repository implementation

# Thread 3: Edge Functions
Task: T048 Implement sync/push Edge Function
Task: T049 Implement sync/pull Edge Function
Task: T050 Create import_sessions Edge Function
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1 (Manual File Import)
4. **STOP and VALIDATE**: Test import with real Kindle clippings file
5. Deploy MVP - users can import and view highlights

### Incremental Delivery

1. Setup + Foundational → Foundation ready
2. Add User Story 1 → Manual import works → **Deploy MVP**
3. Add User Story 3 → Browse/search works → Deploy
4. Add User Story 2 → Desktop auto-import works → Deploy
5. Add Polish → Production-ready → Deploy

### Recommended Priority

Given the dependencies and value delivery:
1. **MVP**: US1 (Manual Import) - core value, works on mobile
2. **v1.1**: US3 (Browse/Search) - makes imported data useful
3. **v1.2**: US2 (Desktop Auto-Import) - power user feature

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Tests are written alongside implementation (Constitution Principle I)
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Avoid: vague tasks, same file conflicts, cross-story dependencies that break independence

---

## Task Summary

| Phase | Tasks | Parallel Opportunities |
|-------|-------|----------------------|
| Phase 1: Setup | 10 | 8 |
| Phase 2: Foundational | 19 | 12 |
| Phase 3: User Story 1 | 23 | 14 |
| Phase 4: User Story 2 | 19 | 10 |
| Phase 5: User Story 3 | 21 | 15 |
| Phase 6: Polish | 13 | 8 |
| **Total** | **105** | **67** |
