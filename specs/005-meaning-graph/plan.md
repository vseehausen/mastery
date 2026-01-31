# Implementation Plan: Meaning Graph

**Branch**: `005-meaning-graph` | **Date**: 2026-01-31 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/005-meaning-graph/spec.md`

## Summary

Add a "Meaning Graph" to the Mastery vocabulary learning app: each vocabulary word gets structured meaning data (translations, English definitions, confusable sets) generated server-side via an AI/translation fallback chain. Learning sessions evolve from basic translation cues to definition-based active recall and disambiguation prompts as cards mature. A rolling buffer strategy (~10 pre-enriched words) caps AI cost while ensuring zero-latency access. The user's native language is configurable (default: German).

## Technical Context

**Language/Version**: Dart 3.x (Flutter 3.x), TypeScript (Deno Edge Functions), Rust 1.75+ (Tauri)
**Primary Dependencies**: `fsrs: ^2.0.1`, `drift` (SQLite ORM), `flutter_riverpod`, `supabase_flutter`, `shadcn_ui`
**Storage**: SQLite via Drift (mobile local cache), PostgreSQL via Supabase (cloud)
**Testing**: `flutter_test`, Deno test
**Target Platform**: iOS, Android (Flutter), Supabase Edge Functions (backend)
**Project Type**: Mobile + API
**Performance Goals**: Meaning data available instantly from local cache; enrichment latency hidden by buffer strategy; session flow unchanged (<10% duration increase)
**Constraints**: Online-required; AI cost capped via rolling buffer (~10 words); existing FSRS scheduling reused as-is
**Scale/Scope**: Hundreds of vocabulary words per user; ~10 enriched at a time; 5 cue types; 3-tier fallback chain

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Test-First | PASS | Tests required for: enrichment service, cue selector, meaning repository, session planner changes, new edge function |
| II. Code Quality | PASS | All new Dart code through `flutter analyze`; new TS through ESLint; strict typing |
| III. Observability | PASS | Structured logging for enrichment pipeline (success/fallback/failure), cue selection decisions, buffer replenishment events |
| IV. Simplicity (YAGNI) | PASS | No abstraction beyond what's needed; cue selector is a simple function, not a plugin system; meaning data is flat tables, not a graph DB |
| V. Online-Required | PASS | Feature is inherently online (AI/translation services). Constitution updated from Offline-First to Online-Required. |

## Project Structure

### Documentation (this feature)

```text
specs/005-meaning-graph/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0: research decisions
├── data-model.md        # Phase 1: entity design
├── quickstart.md        # Phase 1: dev setup guide
├── contracts/           # Phase 1: API contracts
│   └── enrich-vocabulary.md
└── checklists/
    └── requirements.md  # Spec quality checklist
```

### Source Code (repository root)

```text
mobile/lib/
├── data/
│   ├── database/
│   │   ├── tables.dart              # + Meanings, Cues, ConfusableSets, MeaningEdits, EnrichmentQueue
│   │   └── database.dart            # Schema version 5 → 6
│   └── repositories/
│       ├── meaning_repository.dart  # NEW: CRUD for meanings + cues
│       └── enrichment_repository.dart # NEW: buffer queue management
├── domain/
│   ├── services/
│   │   ├── cue_selector.dart        # NEW: select cue type by card maturity
│   │   └── session_planner.dart     # MODIFIED: filter un-enriched cards, add cue type
│   └── models/
│       ├── cue_type.dart            # NEW: enum + metadata
│       └── planned_item.dart        # MODIFIED: add cueType field
└── features/
    ├── learn/
    │   ├── screens/
    │   │   └── session_screen.dart   # MODIFIED: dispatch to cue-specific card widgets
    │   └── widgets/
    │       ├── definition_cue_card.dart    # NEW
    │       ├── synonym_cue_card.dart       # NEW
    │       ├── cloze_cue_card.dart         # NEW
    │       ├── disambiguation_card.dart    # NEW
    │       └── recall_card.dart            # EXISTING (translation cue)
    ├── vocabulary/
    │   ├── vocabulary_detail_screen.dart   # MODIFIED: add meaning cards
    │   └── presentation/widgets/
    │       ├── meaning_card.dart           # NEW: collapsed/expanded meaning display
    │       └── meaning_editor.dart         # NEW: edit/pin translation
    └── settings/
        └── language_setting.dart           # NEW: native language picker

supabase/
├── functions/
│   ├── enrich-vocabulary/
│   │   └── index.ts                 # NEW: enrichment edge function
│   └── sync/
│       └── index.ts                 # MODIFIED: add meanings, cues, confusable_sets tables to pull
└── migrations/
    └── 20260131000001_add_meaning_graph.sql  # NEW: meanings, cues, confusable_sets, meaning_edits, enrichment_queue
```

**Structure Decision**: Extends existing mobile + API structure. New tables added to existing Drift database. New edge function `enrich-vocabulary` handles the AI/translation fallback chain. Sync function extended to include new tables. No new projects or fundamental architecture changes.

## Complexity Tracking

No constitution violations to justify. The feature adds new tables and a new edge function but follows existing patterns (Drift tables, Riverpod providers, Supabase edge functions, sync outbox).
