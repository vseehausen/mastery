# Implementation Plan: Vocabulary Import & Display

**Branch**: `002-vocabulary-import-display` | **Date**: 2026-01-26 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/002-vocabulary-import-display/spec.md`

## Summary

Import vocabulary from Kindle's Vocabulary Builder (vocab.db) via desktop app, parse on server (Supabase Edge Function), and display vocabulary list on Flutter mobile app with offline support. Desktop reads vocab.db from Kindle device, uploads to server for SQLite parsing, stores results locally and syncs to cloud. Mobile displays vocabulary list (word + truncated context) sorted newest first.

## Technical Context

**Language/Version**: Rust 1.75+ (Tauri), Dart 3.x (Flutter), TypeScript (Deno Edge Functions)
**Primary Dependencies**: Tauri 2.x, Flutter 3.x, Supabase, sql.js (SQLite in WASM for Deno)
**Storage**: PostgreSQL (Supabase), SQLite (mobile via Drift, desktop local cache)
**Testing**: cargo test, flutter_test, Deno test
**Target Platform**: macOS desktop (Tauri), iOS/Android (Flutter)
**Project Type**: Multi-platform (desktop agent + mobile app + backend)
**Performance Goals**: Import 1000 vocabulary entries in <30 seconds, mobile sync in <5 seconds
**Constraints**: Offline-capable, server-side parsing only, last-write-wins sync
**Scale/Scope**: Single user, up to 10,000 vocabulary entries

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Test-First Development | ✅ Pass | Tests for parser, sync, UI components |
| II. Code Quality Standards | ✅ Pass | Linting/formatting enforced per platform |
| III. Observability | ✅ Pass | Structured logging, error tracking |
| IV. Simplicity (YAGNI) | ✅ Pass | Minimal new tables, reuses existing sync |
| V. Offline-First Architecture | ✅ Pass | Local SQLite, sync queue, graceful degradation |

## Project Structure

### Documentation (this feature)

```text
specs/002-vocabulary-import-display/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── api.yaml         # OpenAPI spec for vocabulary endpoints
└── tasks.md             # Phase 2 output (created by /speckit.tasks)
```

### Source Code (repository root)

```text
desktop/
├── src-tauri/src/
│   ├── kindle/
│   │   ├── mod.rs       # Existing: Kindle detection, vocab.db copy
│   │   └── mtp.rs       # Existing: MTP protocol support
│   ├── sync/
│   │   └── push.rs      # Existing: Sync to Supabase
│   └── vocab/           # NEW: Vocabulary upload to server
│       └── mod.rs
└── src/
    └── lib/
        └── api/
            └── vocab.ts # NEW: API calls for vocabulary parsing

supabase/
└── functions/
    ├── _shared/         # Existing: CORS, response helpers
    ├── sync/            # Existing: Push/pull sync
    └── parse-vocab/     # NEW: Parse vocab.db SQLite file
        └── index.ts

mobile/
└── lib/
    ├── data/
    │   ├── database/
    │   │   └── tables.dart    # UPDATE: Add vocabulary table
    │   └── repositories/
    │       └── vocabulary_repository.dart  # NEW
    └── features/
        └── vocabulary/        # NEW: Vocabulary list feature
            ├── vocabulary_screen.dart
            ├── vocabulary_provider.dart
            └── vocabulary_detail_screen.dart
```

**Structure Decision**: Extends existing multi-platform structure. Desktop handles device access, server handles parsing, mobile handles display. Reuses existing sync infrastructure.

## Complexity Tracking

> No violations - design aligns with Constitution principles.
