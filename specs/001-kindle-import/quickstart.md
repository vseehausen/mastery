# Quickstart: Kindle Import

**Feature**: 001-kindle-import
**Date**: 2026-01-24

## Prerequisites

Before starting, ensure you have:

- [ ] Flutter SDK 3.x installed
- [ ] Dart 3.x installed
- [ ] Rust toolchain (for Tauri desktop agent)
- [ ] Node.js 18+ (for Supabase CLI)
- [ ] Supabase CLI installed (`npm install -g supabase`)
- [ ] A Supabase project created

## Project Setup

### 1. Clone and Configure

```bash
# Clone the repository
git clone <repo-url> mastery
cd mastery

# Checkout feature branch
git checkout 001-kindle-import

# Copy environment template
cp .env.example .env.local
```

### 2. Environment Variables

Edit `.env.local`:

```bash
# Supabase
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# Mobile (copy to mobile/.env)
FLUTTER_SUPABASE_URL=${SUPABASE_URL}
FLUTTER_SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}
```

### 3. Backend Setup (Supabase)

```bash
cd supabase

# Link to your project
supabase link --project-ref your-project-id

# Run migrations
supabase db push

# Deploy edge functions
supabase functions deploy

# Verify
supabase functions list
```

### 4. Mobile App Setup (Flutter)

```bash
cd mobile

# Get dependencies
flutter pub get

# Generate Drift database code
dart run build_runner build --delete-conflicting-outputs

# Run tests
flutter test

# Run on simulator/device
flutter run
```

### 5. Desktop Agent Setup (Tauri)

```bash
cd desktop

# Install dependencies
npm install

# Build Rust backend
cargo build

# Run in development
npm run tauri dev

# Build for distribution
npm run tauri build
```

## Development Workflow

### Running the Full Stack

```bash
# Terminal 1: Supabase local (optional)
cd supabase && supabase start

# Terminal 2: Mobile app
cd mobile && flutter run

# Terminal 3: Desktop agent
cd desktop && npm run tauri dev
```

### Database Migrations

```bash
# Create new migration
cd supabase
supabase migration new <migration-name>

# Apply migrations locally
supabase db reset

# Push to production
supabase db push
```

### Drift Schema Changes

```bash
cd mobile

# After modifying tables in lib/data/database/
dart run build_runner build --delete-conflicting-outputs

# If migration needed, bump schemaVersion in database.dart
```

## Testing

### Unit Tests

```bash
# Mobile
cd mobile && flutter test test/unit/

# Desktop (Rust)
cd desktop/src-tauri && cargo test
```

### Integration Tests

```bash
# Mobile
cd mobile && flutter test integration_test/

# Edge Functions
cd supabase && supabase functions serve
# Then run tests against local endpoint
```

### Manual Testing

1. **Import Test File**:
   - Copy `test/fixtures/sample_clippings.txt` to test imports
   - Open mobile app → Import → Select file
   - Verify highlights appear grouped by book

2. **Desktop Auto-Import**:
   - Run desktop agent
   - Connect Kindle device
   - Verify automatic detection and import

3. **Search**:
   - Import sample file with multiple books
   - Search for specific text
   - Verify results highlight matches

## Sample Data

### Test Clippings File

Create `test/fixtures/sample_clippings.txt`:

```text
The Great Gatsby (F. Scott Fitzgerald)
- Your Highlight on page 5 | Location 72-75 | Added on Monday, January 20, 2026 10:30:00 AM

In my younger and more vulnerable years my father gave me some advice that I've been turning over in my mind ever since.
==========
The Great Gatsby (F. Scott Fitzgerald)
- Your Highlight on page 180 | Location 2845-2847 | Added on Monday, January 20, 2026 11:45:00 AM

So we beat on, boats against the current, borne back ceaselessly into the past.
==========
1984 (George Orwell)
- Your Highlight on page 1 | Location 10-12 | Added on Tuesday, January 21, 2026 9:00:00 AM

It was a bright cold day in April, and the clocks were striking thirteen.
==========
1984 (George Orwell)
- Your Note on page 50 | Location 750 | Added on Tuesday, January 21, 2026 9:30:00 AM

This reminds me of modern surveillance concerns.
==========
```

## Troubleshooting

### Common Issues

**Flutter: Drift code generation fails**
```bash
# Clean and regenerate
flutter clean
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

**Supabase: Edge function deployment fails**
```bash
# Check logs
supabase functions logs <function-name>

# Ensure Deno types are correct
cd supabase/functions && deno cache --reload deps.ts
```

**Tauri: USB detection not working**
- macOS: Ensure app has disk access permissions
- Linux: Add udev rules for Kindle (see research.md)
- Windows: Install proper USB drivers

**Import: Duplicates still appearing**
- Check contentHash generation is consistent
- Verify SQLite index on (userId, contentHash) exists
- Clear local database and re-import

## Architecture Quick Reference

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Mobile    │────▶│  Supabase   │◀────│   Desktop   │
│  (Flutter)  │     │  (Backend)  │     │   (Tauri)   │
└─────────────┘     └─────────────┘     └─────────────┘
       │                   │                   │
       ▼                   ▼                   ▼
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   SQLite    │     │ PostgreSQL  │     │   SQLite    │
│   (Local)   │     │   (Cloud)   │     │   (Local)   │
└─────────────┘     └─────────────┘     └─────────────┘
```

## Key Files

| File | Purpose |
|------|---------|
| `mobile/lib/data/database/database.dart` | Drift database definition |
| `mobile/lib/features/import/parser.dart` | Kindle clippings parser |
| `desktop/src-tauri/src/kindle/` | USB detection & file reading |
| `supabase/functions/sync/` | Sync push/pull endpoints |
| `supabase/migrations/` | Database schema |

## Next Steps

After setup:

1. Run `/speckit.tasks` to generate implementation tasks
2. Start with User Story 1 (Manual File Import)
3. Tests first, then implementation
4. Commit after each completed task
