# Tasks: Vocabulary Import & Display

**Input**: Design documents from `/specs/002-vocabulary-import-display/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/api.yaml

**Organization**: Tasks grouped by user story for independent implementation and testing.

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story (US1, US2, US3)
- Paths are relative to repository root

---

## Phase 1: Setup (Database & Schema)

**Purpose**: Database schema and shared infrastructure

- [x] T001 Create vocabulary table migration in `supabase/migrations/20260126000001_add_vocabulary.sql`
- [x] T002 [P] Add Vocabulary table definition to `mobile/lib/data/database/tables.dart`
- [x] T003 Run Drift code generation: `cd mobile && dart run build_runner build --delete-conflicting-outputs`

---

## Phase 2: Foundational (Sync Infrastructure)

**Purpose**: Sync infrastructure that enables both desktop upload and mobile display

**⚠️ CRITICAL**: US1 and US2 both depend on sync working for vocabulary

- [x] T004 Update sync/pull endpoint to include vocabulary in `supabase/functions/sync/index.ts`
- [x] T005 [P] Update sync/push endpoint to handle vocabulary table in `supabase/functions/sync/index.ts`
- [x] T006 [P] Create VocabularyRepository for local CRUD in `mobile/lib/data/repositories/vocabulary_repository.dart`
- [x] T007 Update SyncService to sync vocabulary in `mobile/lib/data/services/sync_service.dart`

**Checkpoint**: Vocabulary can be synced between server and mobile

---

## Phase 3: User Story 1 - Import Vocabulary from Kindle (Priority: P1) 🎯 MVP

**Goal**: Desktop app reads vocab.db from Kindle, uploads to server for parsing, stores results locally and syncs to cloud

**Independent Test**: Connect Kindle device, trigger import, verify vocabulary appears in Supabase database with correct word, context, and book

**Current State**: Desktop already syncs vocab.db from Kindle locally. Need to add server parsing and cloud sync.

### Refactoring (Remove Clippings Support)

- [x] T008 [US1] Remove clippings-related code from desktop - focus on vocab.db only
- [x] T009 [US1] Clean up test files referencing removed clippings functions in `desktop/src/lib/api/kindle.test.ts`

### Server Implementation

- [x] T010 [US1] Create parse-vocab Edge Function directory structure: `supabase/functions/parse-vocab/index.ts`
- [x] T011 [US1] Implement SQLite parsing with sql.js in `supabase/functions/parse-vocab/index.ts`
- [x] T012 [US1] Add hash generation and book extraction to parse-vocab function
- [x] T013 [US1] Deploy and test parse-vocab function: `cd supabase && supabase functions deploy parse-vocab`

### Desktop Implementation

- [x] T014 [P] [US1] Create vocab types and API client in `desktop/src/lib/api/vocab.ts`
- [x] T015 [P] [US1] Create Rust vocab module structure in `desktop/src-tauri/src/vocab/mod.rs`
- [x] T016 [US1] Implement vocab.db upload to server in `desktop/src-tauri/src/vocab/mod.rs`
- [x] T017 [US1] Add Tauri command to trigger vocabulary import in `desktop/src-tauri/src/main.rs`
- [x] T018 [US1] Server stores vocabulary directly in database (simplified from local cache approach)
- [x] T019 [US1] Server handles cloud storage directly (combined with T018 for MVP simplicity)
- [x] T020 [US1] Add import button and status to desktop UI in `desktop/src/routes/+page.svelte`
- [x] T021 [US1] Server handles deduplication - skip existing vocabulary entries based on content_hash

**Checkpoint**: User Story 1 complete - vocabulary can be imported from Kindle and synced to cloud

---

## Phase 4: User Story 2 - View Vocabulary List on Mobile (Priority: P2)

**Goal**: Mobile app displays vocabulary list with word + truncated context, tap for details, works offline

**Independent Test**: Open mobile app with synced data, verify list shows words sorted newest first, tap shows full details, works offline

### Mobile Implementation

- [x] T022 [P] [US2] Create vocabulary provider in `mobile/lib/features/vocabulary/vocabulary_provider.dart`
- [x] T023 [P] [US2] Create vocabulary list screen in `mobile/lib/features/vocabulary/vocabulary_screen.dart`
- [x] T024 [US2] Create vocabulary detail screen in `mobile/lib/features/vocabulary/vocabulary_detail_screen.dart`
- [x] T025 [US2] Add vocabulary navigation to app router/navigation in `mobile/lib/main.dart`
- [x] T026 [US2] Implement pull-to-refresh and loading states in vocabulary_screen.dart
- [x] T027 [US2] Add empty state when no vocabulary exists in vocabulary_screen.dart

**Checkpoint**: User Story 2 complete - vocabulary viewable on mobile with offline support

---

## Phase 5: User Story 3 - View Import History (Priority: P3)

**Goal**: Desktop app shows history of vocabulary imports with timestamps and word counts

**Independent Test**: Perform multiple imports, verify history shows each import with date and entry count

### Desktop Implementation

- [x] T028 [P] [US3] Create ImportSession storage in desktop local DB in `desktop/src-tauri/src/vocab/mod.rs`
- [x] T029 [US3] Record import session on each vocabulary import in `desktop/src-tauri/src/vocab/mod.rs`
- [x] T030 [US3] Create import history UI component in `desktop/src/lib/components/ImportHistory.svelte`
- [x] T031 [US3] Add import progress feedback (loading, success, error) to desktop UI
- [x] T032 [US3] Display import history with timestamps and counts in desktop UI

**Checkpoint**: User Story 3 complete - import history viewable on desktop

---

## Phase 6: Polish & Error Handling

**Purpose**: Edge cases, error handling, and cross-cutting improvements

- [x] T033 [P] Handle empty/missing vocab.db gracefully in parse-vocab function
- [x] T034 [P] Handle corrupted vocab.db entries with partial parsing in parse-vocab function
- [x] T035 [P] Add error state UI for failed imports in desktop app
- [x] T036 Handle large vocab.db files (>1000 entries) with progress feedback
- [x] T037 [P] Handle offline sync gracefully in mobile vocabulary screen
- [x] T038 Add structured logging for vocabulary import operations
- [x] T039 Run quickstart.md validation - test full flow from Kindle to mobile display

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 (migration must exist)
- **US1 (Phase 3)**: Depends on Phase 2 (sync must work)
- **US2 (Phase 4)**: Depends on Phase 2 (sync must work) - can run parallel to US1
- **US3 (Phase 5)**: Depends on US1 (imports must work)
- **Polish (Phase 6)**: Depends on US1, US2 complete

### User Story Dependencies

```
Phase 1 (Setup)
    │
    ▼
Phase 2 (Foundational) ◄── BLOCKS all user stories
    │
    ├──────────────────┐
    ▼                  ▼
Phase 3 (US1)    Phase 4 (US2)  ◄── Can run in parallel!
    │
    ▼
Phase 5 (US3)
    │
    ▼
Phase 6 (Polish)
```

### Parallel Opportunities

**Within Phase 1:**
- T002 can run parallel to T001 (different files)

**Within Phase 2:**
- T004, T005, T006 can all run in parallel (different files)

**Within Phase 3 (US1):**
- T014, T015 can run in parallel (TypeScript vs Rust)
- Server tasks (T010-T013) can run parallel to Desktop tasks (T014-T021)

**Within Phase 4 (US2):**
- T022, T023 can run in parallel (different files)

**US1 and US2 can run in parallel** after Phase 2 completes

---

## Parallel Execution Examples

### Server + Desktop in Parallel (US1)

```
# After Phase 2 completes, launch these in parallel:

# Terminal 1 - Server tasks (remaining)
Task T013: Deploy parse-vocab function

# Terminal 2 - Desktop tasks (remaining)
Task T018: Store parsed vocabulary locally
Task T019: Push vocabulary to cloud
Task T021: Handle deduplication
```

### Mobile Feature Development (US2)

```
# Launch model/provider tasks in parallel:
Task T022: Create vocabulary_provider.dart
Task T023: Create vocabulary_screen.dart

# Then sequential:
Task T024: Create vocabulary_detail_screen.dart
Task T025: Add navigation
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T003)
2. Complete Phase 2: Foundational (T004-T007)
3. Complete Phase 3: US1 - Import Vocabulary (T008-T019)
4. **STOP and VALIDATE**: Import from real Kindle, verify in Supabase
5. Deploy/demo MVP

### Incremental Delivery

1. **MVP**: Setup + Foundational + US1 → Can import vocabulary
2. **+Mobile**: Add US2 → Can view on mobile
3. **+History**: Add US3 → Can track imports
4. **+Polish**: Error handling, edge cases

### Estimated Task Counts

| Phase | Tasks | Parallelizable | Done |
|-------|-------|----------------|------|
| Setup | 3 | 2 | 3 |
| Foundational | 4 | 3 | 4 |
| US1 (P1) | 14 | 4 | 14 |
| US2 (P2) | 6 | 2 | 6 |
| US3 (P3) | 5 | 1 | 5 |
| Polish | 7 | 4 | 7 |
| **Total** | **39** | **16** | **39** |

---

## Notes

- **IMPORTANT**: Clippings support removed - desktop now uses vocab.db only
- Desktop already syncs vocab.db from Kindle locally (implemented)
- Need to wire up: server parsing → local storage → cloud sync
- Tests not explicitly requested - tasks focus on implementation
- US1 and US2 can proceed in parallel after foundational phase
- Mobile already has sync infrastructure - vocabulary extends it
- Server parses vocab.db using sql.js (WASM) - no native dependencies
- Deduplication via SHA-256 hash of word|context|book_title
