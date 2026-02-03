# Tasks: Meaning Graph

**Input**: Design documents from `/specs/005-meaning-graph/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/enrich-vocabulary.md, quickstart.md

**Tests**: Tests are written alongside implementation per constitution principle I (Test-First). Each user story phase includes test tasks.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Database schema, new tables, migration, and edge function scaffolding

- [x] T001 Create PostgreSQL migration for meaning graph tables (meanings, cues, confusable_sets, confusable_set_members, meaning_edits, enrichment_queue) with RLS policies and indexes in `supabase/migrations/20260131000001_add_meaning_graph.sql`
- [x] T002 Add `native_language_code` (VARCHAR(5), default 'de') and `meaning_display_mode` (VARCHAR(10), default 'both') columns to `user_learning_preferences` table in the same migration file
- [x] T003 ~~Add Drift table definitions...~~ **SUPERSEDED**: Drift removed; data accessed via SupabaseDataService
- [x] T004 ~~Register new tables in @DriftDatabase...~~ **SUPERSEDED**: Drift removed
- [x] T005 ~~Add nativeLanguageCode to Drift table...~~ **SUPERSEDED**: Drift removed
- [x] T006 ~~Run build_runner...~~ **SUPERSEDED**: No Drift code generation needed

**Checkpoint**: Database schema ready on both PostgreSQL and SQLite. No runtime changes yet.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core repositories, models, and edge function that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T007 Create `CueType` enum (translation, definition, synonym, contextCloze, disambiguation) and `MaturityStage` enum (newCard, growing, mature) in `mobile/lib/domain/models/cue_type.dart`
- [x] T008 ~~[P] Create MeaningRepository...~~ **SUPERSEDED**: Methods moved to SupabaseDataService (`getMeanings`, `updateMeaning`, etc.)
- [x] T009 ~~[P] Create CueRepository...~~ **SUPERSEDED**: Methods moved to SupabaseDataService (`getCuesForVocabulary`, etc.)
- [x] T010 ~~[P] Create ConfusableSetRepository...~~ **SUPERSEDED**: Methods moved to SupabaseDataService
- [x] T011 ~~[P] Create MeaningEditRepository...~~ **SUPERSEDED**: Methods moved to SupabaseDataService (`createMeaningEdit`)
- [x] T012 Create `EnrichmentService` on mobile that calls the `enrich-vocabulary/request` edge function, parses the response, and stores meanings/cues/confusable sets via repositories in `mobile/lib/domain/services/enrichment_service.dart`
- [x] T013 Scaffold `enrich-vocabulary` edge function with CORS handling, auth, and route dispatching (request + status endpoints) in `supabase/functions/enrich-vocabulary/index.ts`
- [x] T014 Implement the AI enrichment fallback chain in the edge function: (1) OpenAI GPT-4o-mini with structured JSON prompt → (2) DeepL API translation → (3) Google Cloud Translation → (4) encounter context extraction. Use `Deno.env.get()` for API keys. Write results to meanings, cues, confusable_sets, enrichment_queue tables in `supabase/functions/enrich-vocabulary/index.ts`
- [x] T015 Implement the enrichment buffer logic in the edge function: check user's enriched count, pick next un-enriched words (oldest first, batch of 5), process via fallback chain, return results with buffer_status in `supabase/functions/enrich-vocabulary/index.ts`
- [x] T016 Add new tables (meanings, cues, confusable_sets, confusable_set_members, meaning_edits) to sync/pull response in `supabase/functions/sync/index.ts`
- [x] T017 Add new tables to sync/push handling (insert/upsert/update/delete with last-write-wins) in `supabase/functions/sync/index.ts`
- [x] T018 Register Riverpod providers for data access (`meaningsProvider`, `enrichmentServiceProvider`, etc.) in `mobile/lib/providers/supabase_provider.dart` and `mobile/lib/providers/learning_providers.dart`
- [x] T019 ~~Write unit tests for MeaningRepository...~~ **SUPERSEDED**: Repository tests removed with Drift; data access tested via integration tests
- [x] T020 Run `flutter analyze` and `flutter test` to verify all foundational code passes

**Checkpoint**: Foundation ready — repositories, edge function, sync, and providers are operational. User story implementation can now begin.

---

## Phase 3: User Story 1 — Rich Translations with Alternatives (Priority: P1) 🎯 MVP

**Goal**: Display rich meaning data on the vocabulary detail screen — primary translation, alternatives, English definition, per-meaning cards with expand/collapse, edit, and pin.

**Independent Test**: Open any enriched vocabulary word's detail screen and verify primary translation, English definition, and alternatives are displayed. Edit and pin actions persist.

### Tests for User Story 1

- [x] T021 [P] [US1] Write widget test for `MeaningCard` (collapsed/expanded states, shows translation + definition, alternatives behind expand) in `mobile/test/features/vocabulary/presentation/widgets/meaning_card_test.dart`
- [x] T022 [P] [US1] Write widget test for `MeaningEditor` (edit translation, pin alternative, save) in `mobile/test/features/vocabulary/presentation/widgets/meaning_editor_test.dart`

### Implementation for User Story 1

- [x] T023 [P] [US1] Create `MeaningCard` widget: collapsed state shows primary translation + English definition; expanded state shows alternative translations, "Not the same as..." traps, pin/edit buttons in `mobile/lib/features/vocabulary/presentation/widgets/meaning_card.dart`
- [x] T024 [P] [US1] Create `MeaningEditor` widget: inline edit for primary translation and English definition, pin alternative as primary, save via MeaningRepository + create MeaningEdit record in `mobile/lib/features/vocabulary/presentation/widgets/meaning_editor.dart`
- [x] T025 [US1] Update `VocabularyDetailScreen` to load meanings via `MeaningRepository.getForVocabulary()` and display `MeaningCard` widgets below the word header. Show "Generating meanings..." placeholder for un-enriched words in `mobile/lib/features/vocabulary/vocabulary_detail_screen.dart`
- [x] T026 [US1] Trigger enrichment buffer check when user opens vocabulary detail for an un-enriched word — call `EnrichmentService` if buffer is low in `mobile/lib/features/vocabulary/vocabulary_detail_screen.dart`
- [x] T027 [US1] Add enrichment trigger after import: when sync/pull returns new vocabulary, check buffer status and trigger `EnrichmentService.replenishIfNeeded()` in auth_guard.dart and vocabulary_screen.dart
- [x] T028 [US1] Run `flutter analyze` and `flutter test` to verify US1 is complete

**Checkpoint**: User Story 1 is fully functional — users can see rich translations, alternatives, edit/pin meanings on the word detail screen. Enrichment buffer keeps words ready.

---

## Phase 4: User Story 2 — Definition-Based Active Recall (Priority: P2)

**Goal**: Learning sessions present definition cues (C→A) and synonym cues (D→A) for growing/mature words, alongside existing translation cues.

**Independent Test**: Start a learning session with a word at growing/mature stage and verify definition-based or synonym-based prompts appear. Self-grading works normally via FSRS.

### Tests for User Story 2

- [x] T029 [P] [US2] Write unit test for `CueSelector`: verify maturity stage thresholds (new < 1.0, growing 1.0-21.0, mature >= 21.0), cue type weights per stage, redistribution when data is missing in `mobile/test/domain/services/cue_selector_test.dart`
- [x] T030 [P] [US2] Write widget test for `DefinitionCueCard` (shows definition prompt, reveal answer, FSRS grade buttons) in `mobile/test/features/learn/widgets/definition_cue_card_test.dart`
- [x] T031 [P] [US2] Write widget test for `SynonymCueCard` (shows synonym prompt, reveal answer, FSRS grade buttons) in `mobile/test/features/learn/widgets/synonym_cue_card_test.dart`

### Implementation for User Story 2

- [x] T032 [US2] Create `CueSelector` service: `getMaturityStage(card)` using stability thresholds, `selectCueType(card, hasMeaning, hasEncounterContext, hasConfusables)` using weighted random selection per research.md R4 in `mobile/lib/domain/services/cue_selector.dart`
- [x] T033 [US2] Add `cueType` field to `PlannedItem` model in `mobile/lib/domain/models/planned_item.dart`
- [x] T034 [US2] Modify `SessionPlanner.buildSessionPlan()` to: (1) filter out un-enriched cards (no meanings), (2) assign cue type via `CueSelector` to each `PlannedItem` in `mobile/lib/domain/services/session_planner.dart`
- [x] T035 [P] [US2] Create `DefinitionCueCard` widget: shows English definition as prompt, "Which word fits best?" microcopy, reveal target word, FSRS grade buttons (Again/Hard/Good/Easy) in `mobile/lib/features/learn/widgets/definition_cue_card.dart`
- [x] T036 [P] [US2] Create `SynonymCueCard` widget: shows synonym phrase as prompt, "Recall the word." microcopy, reveal target word, FSRS grade buttons in `mobile/lib/features/learn/widgets/synonym_cue_card.dart`
- [x] T037 [US2] Update `SessionScreen._buildItemCard()` to dispatch to the correct card widget based on `PlannedItem.cueType`: translation → existing `RecallCard`, definition → `DefinitionCueCard`, synonym → `SynonymCueCard` in `mobile/lib/features/learn/screens/session_screen.dart`
- [x] T038 [US2] Update `SessionScreen._loadVocabWithContext()` to also load meaning and cue data for the current item, passing prompt_text/answer_text to the cue card widgets in `mobile/lib/features/learn/screens/session_screen.dart`
- [x] T039 [US2] Add `cue_type` field to PostgreSQL `review_logs` table to track which cue type was used for each review (Drift removed)
- [x] T040 [US2] Run `flutter analyze` and `flutter test` to verify US2 is complete

**Checkpoint**: User Story 2 is functional — learning sessions now present definition and synonym cues for growing/mature words. Translation cues still work for new words.

---

## Phase 5: User Story 3 — Confusion/Disambiguation Prompts (Priority: P3)

**Goal**: Mature words with known confusable neighbors get multiple-choice disambiguation prompts in sessions.

**Independent Test**: Start a session with a mature word that has a confusable set. Verify a disambiguation prompt appears with multiple-choice options and a post-answer explanation.

### Tests for User Story 3

- [x] T041 [P] [US3] Write widget test for `DisambiguationCard` (shows cloze sentence, options, correct/incorrect feedback with explanation) in `mobile/test/features/learn/widgets/disambiguation_card_test.dart`

### Implementation for User Story 3

- [x] T042 [US3] Create `DisambiguationCard` widget: shows cloze sentence from cue prompt_text, renders options from cue metadata, handles selection, shows explanation after answer ("Correct — ..." / "Not quite — ...") in `mobile/lib/features/learn/widgets/disambiguation_card.dart`
- [x] T043 [US3] Update `SessionScreen._buildItemCard()` to dispatch `disambiguation` cue type to `DisambiguationCard`, passing options and explanations from cue metadata in `mobile/lib/features/learn/screens/session_screen.dart`
- [x] T044 [US3] Handle disambiguation grading: correct answer → `ReviewRating.good`, incorrect → `ReviewRating.again`, then process through existing `_processReview()` flow in `mobile/lib/features/learn/screens/session_screen.dart`
- [x] T045 [US3] Run `flutter analyze` and `flutter test` to verify US3 is complete

**Checkpoint**: User Story 3 is functional — disambiguation prompts appear for mature words with confusable sets.

---

## Phase 6: User Story 4 — Context Cloze Prompts (Priority: P4)

**Goal**: Fill-in-the-blank exercises using encounter context sentences for growing/mature words.

**Independent Test**: Start a session with a word that has encounter context at growing/mature stage. Verify a cloze prompt appears with the word blanked out, and a meaning-based hint is available.

### Tests for User Story 4

- [x] T046 [P] [US4] Write widget test for `ClozeCueCard` (shows sentence with blank, reveal answer with highlighted word, hint display) in `mobile/test/features/learn/widgets/cloze_cue_card_test.dart`

### Implementation for User Story 4

- [x] T047 [US4] Create `ClozeCueCard` widget: shows sentence with ___ blank from cue prompt_text, "Fill the blank." microcopy, reveal answer with target word highlighted, optional hint from cue hint_text in `mobile/lib/features/learn/widgets/cloze_cue_card.dart`
- [x] T048 [US4] Update `SessionScreen._buildItemCard()` to dispatch `contextCloze` cue type to `ClozeCueCard` in `mobile/lib/features/learn/screens/session_screen.dart`
- [x] T049 [US4] Ensure `CueSelector` only selects `contextCloze` when encounter context exists (checked via hasEncounterContext flag) — verify in existing `CueSelector` logic in `mobile/lib/domain/services/cue_selector.dart`
- [x] T050 [US4] Run `flutter analyze` and `flutter test` to verify US4 is complete

**Checkpoint**: User Story 4 is functional — context cloze prompts appear for words with encounter sentences.

---

## Phase 7: User Story 5 — Meaning Selection for Ambiguous Words (Priority: P5)

**Goal**: Words with 2+ distinct meanings show a "Pick your meaning" screen, letting the user choose which meaning to learn first.

**Independent Test**: Add an ambiguous word (e.g., "bank") and verify the meaning picker appears on first encounter, allows selection, and respects the user's choice in sessions.

### Tests for User Story 5

- [x] T051 [P] [US5] Write widget test for `MeaningPickerScreen` (shows meanings with recommended default, selection updates is_active/is_primary) in `mobile/test/features/vocabulary/widgets/meaning_picker_test.dart`

### Implementation for User Story 5

- [x] T052 [US5] Create `MeaningPickerScreen`: title "Which meaning do you want to learn first?", subtitle "You can learn the others later.", list of meanings with recommended badge on first, "Start with this" button. On selection: set chosen meaning as `is_primary=true` and `is_active=true`, others as `is_active=false` in `mobile/lib/features/vocabulary/presentation/widgets/meaning_picker.dart`
- [x] T053 [US5] Trigger meaning picker: after enrichment returns 2+ distinct meanings for a word, navigate to `MeaningPickerScreen` before the word enters learning sessions. Check meaning count in `EnrichmentService` response handling in `mobile/lib/domain/services/enrichment_service.dart`
- [x] T054 [US5] Allow activating additional meanings later from `VocabularyDetailScreen` — add "Learn this meaning too" button on inactive meaning cards in `mobile/lib/features/vocabulary/vocabulary_detail_screen.dart`
- [x] T055 [US5] Run `flutter analyze` and `flutter test` to verify US5 is complete

**Checkpoint**: User Story 5 is functional — ambiguous words prompt meaning selection.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Native language setting, display toggle, observability, and final integration

- [x] T056 [P] Create native language picker setting: dropdown of supported languages, saves to `UserLearningPreferences.nativeLanguageCode`, passes language code to enrichment requests in `mobile/lib/features/settings/language_setting.dart`
- [x] T057 [P] Create meaning display mode toggle (native / English / both) in settings, saves to `UserLearningPreferences.meaningDisplayMode`, `MeaningCard` reads this preference to show/hide translations or definitions in `mobile/lib/features/settings/language_setting.dart`
- [x] T058 ~~Update UserPreferencesRepository...~~ **SUPERSEDED**: Preferences accessed via `userPreferencesProvider` and `SupabaseDataService.updatePreferences()`
- [x] T059 Add structured logging for observability: (1) enrichment service — log enrichment requests (word count, language), fallback chain usage (which tier was used), buffer status changes, and errors in `mobile/lib/domain/services/enrichment_service.dart` and `supabase/functions/enrich-vocabulary/index.ts`; (2) cue selector — log selected cue type, maturity stage, and available/unavailable cue types per card in `mobile/lib/domain/services/cue_selector.dart`; (3) session planner — log session composition (count of each cue type, number of un-enriched cards filtered out) in `mobile/lib/domain/services/session_planner.dart`
- [x] T060 Add edge case handling: "Not available — add your own" when no translation available, low-confidence indicator (confidence < 0.6), "Show more" for > 3 alternatives in `mobile/lib/features/vocabulary/presentation/widgets/meaning_card.dart`
- [x] T061 Run full test suite: `flutter analyze`, `flutter test`, verify enrichment edge function works end-to-end with test vocabulary
- [x] T062 Verify sync round-trip: push meaning edits/pins from mobile → pull enriched data from server, confirm data integrity
- [x] T063 [US1] Handle native language change edge case: when user changes `nativeLanguageCode` in settings, preserve existing meanings (old language), allow re-enrichment on demand via a "Re-translate" button on meaning cards that re-queues the vocabulary for enrichment in the new language in `mobile/lib/features/vocabulary/presentation/widgets/meaning_card.dart` and `mobile/lib/domain/services/enrichment_service.dart`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 — BLOCKS all user stories
- **User Stories (Phase 3-7)**: All depend on Phase 2 completion
  - US1 (Phase 3): No dependencies on other stories
  - US2 (Phase 4): Depends on US1 (needs meaning data to exist for cue selection)
  - US3 (Phase 5): Depends on US2 (extends cue selector with disambiguation type)
  - US4 (Phase 6): Depends on US2 (extends cue selector with context cloze type)
  - US5 (Phase 7): Depends on US1 (needs meaning display to exist)
- **Polish (Phase 8)**: Depends on US1 at minimum; independent of US3-US5

### User Story Dependencies

```
Phase 1 (Setup) → Phase 2 (Foundational)
                     ↓
                  Phase 3 (US1: Rich Translations) ← MVP
                     ↓              ↓
                  Phase 4 (US2)   Phase 7 (US5)
                     ↓     ↓
                  Phase 5  Phase 6
                  (US3)    (US4)
                     ↓
                  Phase 8 (Polish)
```

### Within Each User Story

- Tests written first (fail before implementation)
- Models/repositories before services
- Services before UI widgets
- Core implementation before integration
- `flutter analyze` + `flutter test` at end of each story

### Parallel Opportunities

- T008, T009, T010, T011 (all repositories) can run in parallel
- T021, T022 (US1 tests) can run in parallel
- T023, T024 (US1 widgets) can run in parallel
- T029, T030, T031 (US2 tests) can run in parallel
- T035, T036 (US2 cue cards) can run in parallel
- T056, T057 (settings widgets) can run in parallel
- US3 and US4 can run in parallel (both extend US2 independently)
- US5 can run in parallel with US2/US3/US4 (only depends on US1)

---

## Parallel Example: User Story 1

```bash
# Launch US1 tests in parallel:
Task: "Widget test for MeaningCard" (T021)
Task: "Widget test for MeaningEditor" (T022)

# Launch US1 widgets in parallel:
Task: "Create MeaningCard widget" (T023)
Task: "Create MeaningEditor widget" (T024)
```

## Parallel Example: User Story 2

```bash
# Launch US2 tests in parallel:
Task: "Unit test for CueSelector" (T029)
Task: "Widget test for DefinitionCueCard" (T030)
Task: "Widget test for SynonymCueCard" (T031)

# Launch US2 cue card widgets in parallel:
Task: "Create DefinitionCueCard" (T035)
Task: "Create SynonymCueCard" (T036)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (schema + migration)
2. Complete Phase 2: Foundational (repositories + edge function + sync)
3. Complete Phase 3: User Story 1 (meaning cards on detail screen)
4. **STOP and VALIDATE**: View enriched words, edit/pin translations
5. Deploy/demo if ready

### Incremental Delivery

1. Setup + Foundational → Foundation ready
2. Add US1 (Rich Translations) → Test → Deploy (MVP!)
3. Add US2 (Active Recall Cues) → Test → Deploy
4. Add US3 (Disambiguation) + US4 (Cloze) in parallel → Test → Deploy
5. Add US5 (Meaning Picker) → Test → Deploy
6. Polish (language settings, logging, edge cases) → Final release

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Verify tests fail before implementing
- Run `flutter analyze` after each phase — zero issues required
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
