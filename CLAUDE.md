# Mastery Development Guidelines

Auto-generated from all feature plans. Last updated: 2026-01-24

## Active Technologies
- Rust 1.75+ (Tauri), Dart 3.x (Flutter), TypeScript (Deno Edge Functions) + Tauri 2.x, Flutter 3.x, Supabase, sql.js (SQLite in WASM for Deno) (002-vocabulary-import-display)
- PostgreSQL (Supabase), SQLite (mobile via Drift, desktop local cache) (002-vocabulary-import-display)

- **Mobile**: Flutter 3.x (Dart 3.x), Drift, Supabase Flutter SDK
- **Desktop**: Tauri 2.x (Rust), nusb, mountpoints
- **Backend**: Supabase (PostgreSQL, Edge Functions, Auth)
- **Testing**: flutter_test, cargo test, Deno test

## Project Structure

```text
mastery/
├── mobile/                    # Flutter mobile app
│   ├── lib/
│   │   ├── core/              # Shared utilities
│   │   ├── data/              # Datasources, models, repositories
│   │   ├── domain/            # Entities, repository interfaces
│   │   └── features/          # auth, import, library, search
│   └── test/
├── desktop/                   # Tauri desktop agent
│   ├── src-tauri/src/         # Rust: kindle, parser, sync, db
│   └── src/                   # TypeScript UI
├── supabase/                  # Backend
│   ├── functions/             # Edge functions
│   └── migrations/            # Database schema
└── specs/                     # Feature specifications
```

## Commands

```bash
# Mobile
cd mobile && flutter pub get
cd mobile && dart run build_runner build --delete-conflicting-outputs
cd mobile && flutter test
cd mobile && flutter run

# Desktop
cd desktop && npm install
cd desktop && cargo build
cd desktop && npm run tauri dev

# Backend
cd supabase && supabase db push
cd supabase && supabase functions deploy
```

## Code Style

- **Dart**: dart format, Dart analyzer (strict)
- **Rust**: rustfmt, clippy (pedantic)
- **TypeScript**: Prettier, ESLint (strict)
- **Commits**: Conventional commits (`type(scope): description`)
- **Scopes**: mobile, desktop, backend, shared

## Constitution Principles

1. **Test-First**: Tests written alongside implementation
2. **Code Quality**: Linting, formatting, strict typing, no warnings
3. **Observability**: Structured logging, error tracking, metrics
4. **Simplicity (YAGNI)**: No premature abstractions, minimal dependencies
5. **Offline-First**: Local-first data, sync when online, last-write-wins

## Recent Changes
- 002-vocabulary-import-display: Added Rust 1.75+ (Tauri), Dart 3.x (Flutter), TypeScript (Deno Edge Functions) + Tauri 2.x, Flutter 3.x, Supabase, sql.js (SQLite in WASM for Deno)

- 001-kindle-import: Kindle highlight import feature (in progress)

## Key Entities

- **Highlight**: Text passage with content, location, type, sync metadata
- **Book**: Source containing highlights (title, author, ASIN)
- **ImportSession**: Record of import operation
- **Language**: Supported vocabulary language (English first)

## Sync Strategy

- Local SQLite stores data for offline access
- SyncOutbox queues changes for cloud sync
- Last-write-wins conflict resolution (updatedAt timestamp)
- Supabase Edge Functions handle sync/push and sync/pull

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
