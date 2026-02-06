<!--
================================================================================
SYNC IMPACT REPORT
================================================================================
Version change: N/A (initial) → 1.0.0
Modified principles: N/A (initial creation)
Added sections:
  - Core Principles (5 principles)
  - Technology Stack
  - Development Workflow
  - Governance
Removed sections: N/A
Templates requiring updates:
  - .specify/templates/plan-template.md: ✅ Compatible (Constitution Check section exists)
  - .specify/templates/spec-template.md: ✅ Compatible (requirements align)
  - .specify/templates/tasks-template.md: ✅ Compatible (TDD workflow supported)
  - .specify/templates/checklist-template.md: ✅ Compatible (generic structure)
  - .specify/templates/agent-file-template.md: ✅ Compatible (generic structure)
Follow-up TODOs: None
================================================================================
-->

# Mastery Constitution

## Core Principles

### I. Test-First Development

All features MUST have tests written before implementation. Tests are required for:
- Business logic and domain rules
- API endpoints and edge functions
- Critical user flows across all platforms

**Enforcement**:
- Tests MUST be written alongside implementation (not after)
- Pull requests without adequate test coverage for new functionality will be rejected
- Developers must run tests locally before committing

**Rationale**: Tests document expected behavior and prevent regressions. Writing tests first clarifies requirements before implementation begins.

### II. Code Quality Standards

All code MUST meet project quality standards before merge:
- **Linting**: All code passes configured linters (Dart analyzer, ESLint, Rust clippy for Tauri)
- **Formatting**: Consistent formatting via automated tools (dart format, Prettier, rustfmt)
- **Type Safety**: Strict typing enabled; `any` types require justification
- **No Warnings**: Code MUST compile/analyze without warnings

**Enforcement**:
- Developers must run linting and formatting checks locally before committing
- Code review verifies adherence

**Rationale**: Consistent code quality reduces cognitive load, catches bugs early, and makes the codebase maintainable across multiple platforms.

### III. Observability

Code SHOULD be observable for debugging and incident response:
- **Development Logging**: Use debugPrint or console logging during development
- **Error Tracking**: Errors are captured with context where practical
- **Future Goal**: Structured logging (JSON) and performance metrics for production

**Current Approach**:
- Mobile (Flutter): debugPrint for development logging
- Backend (Supabase): Edge function logging, database query monitoring
- Desktop (Tauri): Console logging during development

**Rationale**: Observability aids debugging, though structured production logging is deferred until product maturity warrants the investment.

### IV. Simplicity (YAGNI)

Code MUST be as simple as possible for current requirements:
- **No Premature Abstraction**: Do not create abstractions until the third use case
- **No Speculative Features**: Only implement what is explicitly required
- **Minimal Dependencies**: Justify every external dependency added
- **Delete Dead Code**: Remove unused code immediately; do not comment out

**Complexity Justification**:
When complexity is unavoidable, document in the implementation plan:
| Complexity Added | Why Needed | Simpler Alternative Rejected Because |
|------------------|------------|--------------------------------------|

**Rationale**: Simpler code is easier to understand, test, maintain, and debug. Over-engineering creates technical debt.

### V. Online-Required Architecture

All client applications require an active internet connection:
- **No Local Database**: Mobile app uses direct Supabase queries with Riverpod caching (no local SQLite)
- **Online Operations**: All features require connectivity — there is no offline mode
- **Connection Status**: App indicates when connection is unavailable

**Platform Requirements**:
- Mobile (Flutter): Direct Supabase queries, Riverpod `FutureProvider.autoDispose` for caching
- Desktop (Tauri): Local file system for Kindle import staging, online sync to Supabase

**Rationale**: Core features (meaning generation, AI enrichment, learning sessions) depend on backend services. Local-first architecture was removed to reduce complexity (~25k lines). The app is designed for connected use.

## Technology Stack

**Mobile App**: Flutter (Dart) - iOS and Android from single codebase
**Backend**: Supabase - PostgreSQL database, Authentication, Storage, Edge Functions (TypeScript)
**Desktop Agent**: Tauri (Rust + TypeScript) - Kindle highlight auto-import tool

**Shared Code Strategy**:
- Business logic that must be consistent across platforms lives in Supabase Edge Functions
- Platform-specific UI code stays in respective apps
- API contracts defined in shared TypeScript types (where applicable)

## Development Workflow

### Branch Strategy

- `main`: Production-ready code only
- `feature/*`: Feature development branches
- `fix/*`: Bug fix branches

### Pull Request Requirements

1. All tests pass (run locally)
2. Linting and formatting verified (run locally)
3. Code review approval required
4. Constitution compliance verified
5. Documentation updated if applicable

### Commit Standards

- Use conventional commits format: `type(scope): description`
- Types: feat, fix, docs, style, refactor, test, chore
- Scope: mobile, extension, backend, desktop, shared

## Governance

This constitution supersedes all other development practices. When conflicts arise between this document and other guidance, the constitution takes precedence.

### Amendment Process

1. Propose amendment via pull request to this file
2. Document rationale for change
3. Update version according to semantic versioning:
   - MAJOR: Principle removal or fundamental redefinition
   - MINOR: New principle or significant expansion
   - PATCH: Clarifications, wording improvements
4. Update dependent templates if affected
5. Merge requires explicit approval

### Compliance Review

- All pull requests MUST verify compliance with Core Principles
- Violations require explicit justification in the PR description
- Justified violations MUST be tracked in Complexity Tracking table

**Version**: 1.0.0 | **Ratified**: 2026-01-24 | **Last Amended**: 2026-01-24
