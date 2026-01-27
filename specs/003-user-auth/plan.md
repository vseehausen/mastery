# Implementation Plan: User Authentication

**Branch**: `003-user-auth` | **Date**: 2026-01-26 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/003-user-auth/spec.md`

## Summary

Implement multi-provider authentication using Supabase Auth across mobile (Flutter) and desktop (Tauri) platforms. Support email/password, Apple Sign In, Google Sign In, and extensible OAuth providers. Mobile uses native OAuth SDKs, desktop uses browser-based OAuth flow with deep link redirects. All platforms maintain persistent sessions and protect authenticated routes.

## Technical Context

**Language/Version**: Dart 3.x (Flutter), Rust 1.75+ (Tauri), TypeScript (Deno Edge Functions), Svelte 5 (desktop UI)
**Primary Dependencies**: supabase_flutter 2.8.3, supabase-js (desktop), Tauri 2.x, sign_in_with_apple, google_sign_in
**Storage**: Supabase Auth (session tokens stored locally per platform)
**Testing**: flutter_test, cargo test, vitest
**Target Platform**: iOS/Android (Flutter), macOS/Windows/Linux (Tauri)
**Project Type**: Multi-platform (mobile app + desktop app + backend)
**Performance Goals**: Sign-in completion <10s (email/password), <30s (mobile OAuth), <60s (desktop OAuth)
**Constraints**: Offline-capable (session persistence), secure token storage, browser redirect handling on desktop
**Scale/Scope**: Single-user apps, standard authentication patterns

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Test-First Development | ✅ Pass | Tests for auth flows, session management, error handling |
| II. Code Quality Standards | ✅ Pass | Linting/formatting enforced, strict typing |
| III. Observability | ✅ Pass | Structured logging for auth events, error tracking |
| IV. Simplicity (YAGNI) | ✅ Pass | Uses Supabase Auth (no custom auth), standard OAuth patterns |
| V. Offline-First Architecture | ✅ Pass | Session persistence, graceful degradation when offline |

## Project Structure

### Documentation (this feature)

```text
specs/003-user-auth/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── api.yaml         # OpenAPI spec for auth endpoints (if needed)
└── tasks.md             # Phase 2 output (created by /speckit.tasks)
```

### Source Code (repository root)

```text
mobile/
└── lib/
    ├── core/
    │   └── supabase_client.dart    # UPDATE: Already exists, verify config
    ├── data/
    │   └── repositories/
    │       └── auth_repository_impl.dart  # UPDATE: Add OAuth methods
    ├── domain/
    │   └── repositories/
    │       └── auth_repository.dart  # UPDATE: Add OAuth interface methods
    └── features/
        └── auth/                    # NEW: Auth UI screens
            ├── sign_in_screen.dart
            ├── sign_up_screen.dart
            └── auth_guard.dart      # Route protection

desktop/
├── src-tauri/src/
│   ├── auth/                        # NEW: Supabase auth module
│   │   └── mod.rs                   # Session management, OAuth flow
│   └── main.rs                      # UPDATE: Add auth commands
└── src/
    ├── lib/
    │   └── api/
    │       └── auth.ts               # NEW: Auth API calls
    └── routes/
        └── +layout.svelte            # UPDATE: Add auth guard

supabase/
└── config.toml                      # UPDATE: Configure OAuth providers
```

**Structure Decision**: Extends existing multi-platform structure. Mobile uses existing Supabase Flutter SDK with OAuth extensions. Desktop creates new auth module for browser-based OAuth flow. Both platforms share Supabase Auth backend.

## Complexity Tracking

> No violations - design aligns with Constitution principles. Using Supabase Auth eliminates need for custom authentication implementation.
