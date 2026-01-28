# Mastery Development Guidelines

Auto-generated from all feature plans. Last updated: 2026-01-28

## Active Technologies
- Rust 1.75+ (Tauri), Dart 3.x (Flutter), TypeScript (Deno Edge Functions) + Tauri 2.x, Flutter 3.x, Supabase, sql.js (SQLite in WASM for Deno) (002-vocabulary-import-display)
- PostgreSQL (Supabase), SQLite (mobile via Drift, desktop local cache) (002-vocabulary-import-display)
- Dart 3.x (Flutter), Rust 1.75+ (Tauri), TypeScript (Deno Edge Functions), Svelte 5 (desktop UI) + supabase_flutter 2.8.3, supabase-js (desktop), Tauri 2.x, sign_in_with_apple, google_sign_in (003-user-auth)
- Supabase Auth (session tokens stored locally per platform) (003-user-auth)

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

### Dart/Flutter Style Conventions

**MUST follow these conventions to pass `flutter analyze`:**

1. **Deprecated APIs**: Never use `withOpacity()`. Use `withValues(alpha: 0.1)` instead.
   ```dart
   // ❌ BAD
   Colors.white.withOpacity(0.1)
   
   // ✅ GOOD
   Colors.white.withValues(alpha: 0.1)
   ```

2. **Constructor Order**: Constructors MUST come before fields in class declarations.
   ```dart
   // ❌ BAD
   class MyWidget extends StatelessWidget {
     final String title;
     const MyWidget({required this.title});
   }
   
   // ✅ GOOD
   class MyWidget extends StatelessWidget {
     const MyWidget({required this.title});
     final String title;
   }
   ```

3. **String Quotes**: Use single quotes for string literals, not double quotes.
   ```dart
   // ❌ BAD
   Text("Hello")
   
   // ✅ GOOD
   Text('Hello')
   ```

4. **Type Safety**: Avoid dynamic calls. Cast to proper types first.
   ```dart
   // ❌ BAD
   for (final item in list) {
     final value = item['key'];
   }
   
   // ✅ GOOD
   for (final item in list) {
     final map = item as Map<String, dynamic>;
     final value = map['key'];
   }
   ```

5. **Await Usage**: Only await Future types. Don't await query builders directly.
   ```dart
   // ❌ BAD
   return (await db.select(table)..where(...)).getSingle();
   
   // ✅ GOOD
   return (db.select(table)..where(...)).getSingle();
   ```

6. **Super Parameters**: Use super parameters when passing to parent constructor.
   ```dart
   // ❌ BAD
   AppDatabase.forTesting(QueryExecutor e) : super(e);
   
   // ✅ GOOD
   AppDatabase.forTesting(super.e);
   ```

7. **Unused Code**: Remove unused fields, imports, and variables immediately.

8. **Const Constructors**: Prefer `const` constructors when values are compile-time constants.
   ```dart
   // ✅ GOOD
   const SizedBox(height: 16)
   const Text('Hello')
   ```

9. **Null Checks**: Remove unnecessary null comparisons when type is non-nullable.
   ```dart
   // ❌ BAD
   if (value == null || value.isEmpty) { ... }
   
   // ✅ GOOD (when value is non-nullable)
   if (value.isEmpty) { ... }
   ```

10. **Type Arguments**: Always provide explicit type arguments for generic constructors.
    ```dart
    // ❌ BAD
    MaterialPageRoute(builder: ...)
    Future.delayed(duration)
    
    // ✅ GOOD
    MaterialPageRoute<void>(builder: ...)
    Future<void>.delayed(duration)
    ```

**Always run `flutter analyze` before committing and fix all `error` and `warning` level issues.**

## Constitution Principles

1. **Test-First**: Tests written alongside implementation
2. **Code Quality**: Linting, formatting, strict typing, no warnings
3. **Observability**: Structured logging, error tracking, metrics
4. **Simplicity (YAGNI)**: No premature abstractions, minimal dependencies
5. **Offline-First**: Local-first data, sync when online, last-write-wins
6. **Continuous Learning**: After longer sessions, add only general, systematic learnings to this file (patterns, principles, architectural decisions). Avoid specific implementation details that are already documented in code. Keep entries concise and actionable.

## Recent Changes
- 003-user-auth: Added Dart 3.x (Flutter), Rust 1.75+ (Tauri), TypeScript (Deno Edge Functions), Svelte 5 (desktop UI) + supabase_flutter 2.8.3, supabase-js (desktop), Tauri 2.x, sign_in_with_apple, google_sign_in
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

## Desktop UI Stack

- **Tailwind CSS v4**: `@import "tailwindcss"` in `src/app.css`
- **shadcn-svelte**: Config in `components.json`, add components via `pnpm dlx shadcn-svelte@latest add [name]`
- **Theme**: Stone base color, CSS variables in `app.css`
- **MCP**: Use `user-shadcn/ui` MCP to list/search components:
  - `list_items_in_registries` with `registries: ["@shadcn"]`
  - `get_add_command_for_items` with `items: ["@shadcn/button", "@shadcn/card"]`

## Design Assets

- Design file: `design/mastery-design.pen`
- Design brief: `DESIGN_BRIEF_OPTIMIZED.md`

## Architecture Notes

- **Desktop**: Rust handles **only** native hardware access (Kindle USB/MTP). All other logic (auth, API calls, UI state, data processing) happens in Svelte frontend. Keep Rust minimal.
- **Mobile**: Import feature removed—capture is desktop-only. Mobile focuses on vocabulary display, learning, and sync.
- **Edge Functions**: `parse-vocab` handles SQLite parsing and creates `import_sessions` records.
- **OAuth**: Uses web-based OAuth flow with deep link callback (`mastery://auth/callback`). Deep links only work in built `.app` bundle, not dev mode.

## Quality Checks - REQUIRED AFTER EVERY TASK

**Always run these checks after completing any code changes to catch errors early:**

### Mobile (Flutter)
```bash
cd mobile
flutter analyze                              # Check for lint issues and type errors
flutter test                                 # Run unit and widget tests
flutter pub get                              # Verify dependencies
```

### Desktop (Tauri + Svelte)
```bash
cd desktop
cargo clippy --all-targets                  # Rust linting (pedantic mode)
cargo test                                   # Rust unit tests
npm run lint                                 # TypeScript/Svelte linting
npm run type-check                          # TypeScript type checking
```

**Exit criteria before commit:**
- ✅ No `error` level issues in analyze/lint output
- ✅ All tests passing (or marked as skipped with comment)
- ✅ No TypeScript/Rust compilation warnings related to new code
- ✅ Code follows formatter rules: `dart format .` (mobile), `rustfmt` (desktop)

<!-- MANUAL ADDITIONS END -->
