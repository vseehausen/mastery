# Implementation Plan: Kindle Import

**Branch**: `001-kindle-import` | **Date**: 2026-01-24 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-kindle-import/spec.md`

## Summary

Import Kindle highlights from "My Clippings.txt" files into Mastery, the vocabulary learning application. This is the first vocabulary import source, providing manual file upload (P1), automatic desktop import via Tauri agent (P2), and highlight browsing/search (P3). Highlights are stored locally for offline access and synced to Supabase when online. Data model is designed for future vocabulary extraction pipeline.

## Technical Context

**Language/Version**:
- Mobile: Dart 3.x (Flutter 3.x)
- Desktop Agent: Rust (Tauri 2.x) + TypeScript
- Backend: TypeScript (Supabase Edge Functions)
- Database: PostgreSQL (Supabase)

**Primary Dependencies**:
- Mobile: Flutter, Drift (SQLite), Supabase Flutter SDK
- Desktop: Tauri, notify (file system watching), tokio (async runtime)
- Backend: Supabase Auth, Supabase Storage, Supabase Edge Functions

**Storage**:
- Local: SQLite via Drift (mobile), SQLite via rusqlite (desktop)
- Cloud: PostgreSQL via Supabase

**Testing**:
- Mobile: flutter_test, integration_test
- Desktop: cargo test, Tauri test utilities
- Backend: Deno test (Edge Functions)

**Target Platform**:
- Mobile: iOS 14+, Android 8+ (API 26+)
- Desktop: macOS 11+, Windows 10+, Linux (Ubuntu 20.04+)

**Project Type**: Monorepo (mobile + desktop + backend)

**Performance Goals**:
- Import 1000 highlights in <30 seconds
- Search results in <3 seconds
- Device detection in <5 seconds
- Sync completion in <60 seconds when online

**Constraints**:
- Offline-capable (all features work without network)
- Support files up to 10MB (~50,000 highlights)
- Last-write-wins conflict resolution

**Scale/Scope**:
- Single user per device
- ~50,000 highlights per user maximum
- English language content initially

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Implementation Notes |
|-----------|--------|---------------------|
| I. Test-First Development | ✅ PASS | Tests written alongside implementation for parser, sync logic, CRUD operations |
| II. Code Quality Standards | ✅ PASS | Dart analyzer, ESLint, Rust clippy configured; strict typing enforced |
| III. Observability | ✅ PASS | Crashlytics (mobile), file logging (desktop), Edge Function logs (backend) |
| IV. Simplicity (YAGNI) | ✅ PASS | Import + storage + CRUD only; vocabulary extraction deferred to future feature |
| V. Offline-First Architecture | ✅ PASS | SQLite local storage, sync queue for cloud operations, last-write-wins conflicts |

**Gate Status**: ✅ All principles satisfied. Proceeding to Phase 0.

## Project Structure

### Documentation (this feature)

```text
specs/001-kindle-import/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── api.yaml         # OpenAPI spec for Supabase Edge Functions
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
# Monorepo structure for Mastery

mobile/                          # Flutter mobile app
├── lib/
│   ├── core/                    # Shared utilities, constants
│   ├── data/
│   │   ├── datasources/         # Local (Drift) and remote (Supabase) sources
│   │   ├── models/              # Data classes
│   │   └── repositories/        # Repository implementations
│   ├── domain/
│   │   ├── entities/            # Domain entities
│   │   └── repositories/        # Repository interfaces
│   ├── features/
│   │   ├── auth/                # Authentication screens/logic
│   │   ├── import/              # File picker, import progress
│   │   ├── library/             # Book list, highlight browsing
│   │   └── search/              # Full-text search
│   └── main.dart
├── test/
│   ├── unit/                    # Parser, models, services
│   └── integration/             # Full import flow
└── pubspec.yaml

desktop/                         # Tauri desktop agent
├── src-tauri/
│   ├── src/
│   │   ├── main.rs              # Entry point
│   │   ├── kindle/              # Kindle detection, file reading
│   │   ├── parser/              # Clippings parser (shared logic)
│   │   ├── sync/                # Supabase sync
│   │   └── db/                  # Local SQLite
│   └── Cargo.toml
├── src/                         # TypeScript UI
│   ├── components/
│   └── App.tsx
└── package.json

supabase/                        # Backend
├── functions/
│   ├── highlights/              # Highlight CRUD edge functions
│   └── sync/                    # Sync endpoints
├── migrations/                  # Database migrations
└── config.toml
```

**Structure Decision**: Monorepo with three projects (mobile, desktop, supabase) following constitution's technology stack. Shared parser logic in desktop Rust crate, mobile uses Dart port. Backend is Supabase-native with Edge Functions.

## Complexity Tracking

> No complexity violations. All implementations follow simplest viable approach.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| N/A | — | — |
