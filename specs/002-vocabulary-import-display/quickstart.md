# Quickstart: Vocabulary Import & Display

**Feature**: 002-vocabulary-import-display
**Date**: 2026-01-26

## Overview

This feature enables importing vocabulary from Kindle's Vocabulary Builder (vocab.db) via the desktop app, parsing on the server, and displaying the vocabulary list on the Flutter mobile app.

## Architecture Flow

```
┌─────────────┐      ┌─────────────────┐      ┌──────────────┐
│   Kindle    │      │  Desktop App    │      │   Supabase   │
│   Device    │      │    (Tauri)      │      │    Server    │
└──────┬──────┘      └────────┬────────┘      └──────┬───────┘
       │                      │                       │
       │  1. Connect USB      │                       │
       │─────────────────────>│                       │
       │                      │                       │
       │  2. Copy vocab.db    │                       │
       │─────────────────────>│                       │
       │                      │                       │
       │                      │  3. POST /parse-vocab │
       │                      │  (base64 file)        │
       │                      │──────────────────────>│
       │                      │                       │
       │                      │  4. Parsed entries    │
       │                      │<──────────────────────│
       │                      │                       │
       │                      │  5. POST /sync/push   │
       │                      │──────────────────────>│
       │                      │                       │
       │                      │                       │
                              │                       │
┌─────────────┐               │                       │
│ Mobile App  │               │                       │
│  (Flutter)  │               │                       │
└──────┬──────┘               │                       │
       │                                              │
       │           6. POST /sync/pull                 │
       │─────────────────────────────────────────────>│
       │                                              │
       │           7. Vocabulary data                 │
       │<─────────────────────────────────────────────│
       │                                              │
       │  8. Display list                             │
       │                                              │
```

## Development Setup

### Prerequisites

1. **Supabase CLI** installed and logged in
2. **Flutter** 3.x with Dart 3.x
3. **Rust** 1.75+ with Tauri CLI
4. **Node.js** 18+ for Supabase functions

### Environment Setup

```bash
# Clone and navigate to repo
cd mastery

# Install dependencies
cd desktop && npm install && cd ..
cd mobile && flutter pub get && cd ..

# Start Supabase local
cd supabase && supabase start

# Run database migrations
supabase db push
```

### Running Locally

**Desktop App (for importing):**
```bash
cd desktop
npm run tauri dev
```

**Mobile App (for viewing):**
```bash
cd mobile
flutter run
```

**Supabase Functions (local):**
```bash
cd supabase
supabase functions serve
```

## Key Implementation Points

### 1. Desktop: Read vocab.db

The desktop app already handles Kindle detection and vocab.db file access in `src-tauri/src/kindle/mod.rs`. The feature adds uploading to the server for parsing.

```rust
// Existing: Copy vocab.db to local path
pub fn sync_vocab_db(output_path: &Path) -> Result<u64, String>

// New: Upload to server for parsing
pub async fn upload_vocab_for_parsing(file_path: &Path) -> Result<Vec<VocabEntry>, String>
```

### 2. Server: Parse vocab.db

New Edge Function at `/parse-vocab` using sql.js to parse SQLite in WASM.

```typescript
// supabase/functions/parse-vocab/index.ts
import initSqlJs from 'sql.js';

Deno.serve(async (req) => {
  const { file } = await req.json();  // base64 encoded
  const buffer = Uint8Array.from(atob(file), c => c.charCodeAt(0));
  
  const SQL = await initSqlJs();
  const db = new SQL.Database(buffer);
  
  // Parse and return vocabulary entries
});
```

### 3. Mobile: Display Vocabulary List

New feature module at `lib/features/vocabulary/` with:

```dart
// vocabulary_screen.dart
class VocabularyScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vocabulary = ref.watch(vocabularyProvider);
    
    return ListView.builder(
      itemCount: vocabulary.length,
      itemBuilder: (context, index) {
        final entry = vocabulary[index];
        return ListTile(
          title: Text(entry.word, style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(
            entry.context?.truncate(50) ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => _showDetail(context, entry),
        );
      },
    );
  }
}
```

### 4. Sync Integration

Extend existing sync service to handle vocabulary table:

```dart
// data/services/sync_service.dart
Future<void> pull() async {
  final response = await _api.syncPull(lastSyncedAt);
  
  // Existing
  await _bookRepo.upsertMany(response.books);
  await _highlightRepo.upsertMany(response.highlights);
  
  // New
  await _vocabularyRepo.upsertMany(response.vocabulary);
}
```

## Testing Strategy

### Unit Tests

1. **Parser tests** (server): Verify vocab.db parsing with sample databases
2. **Hash generation**: Verify consistent deduplication hashes
3. **Repository tests**: Vocabulary CRUD operations

### Integration Tests

1. **End-to-end import**: Desktop → Server → Database
2. **Sync flow**: Mobile pull with vocabulary data
3. **Offline behavior**: Vocabulary accessible without network

### Test Data

Sample vocab.db files in `test/fixtures/`:
- `vocab_empty.db` - Empty database
- `vocab_small.db` - 10 entries
- `vocab_large.db` - 1000 entries
- `vocab_corrupt.db` - Invalid SQLite

## Deployment Checklist

1. [ ] Run database migration
2. [ ] Deploy `parse-vocab` Edge Function
3. [ ] Update `sync` Edge Function for vocabulary
4. [ ] Build and release desktop app
5. [ ] Build and release mobile app

## Troubleshooting

### vocab.db not found
- Kindle must be connected in USB storage mode (not MTP on some models)
- Check path: `/system/vocabulary/vocab.db`

### Parsing fails
- Verify file is valid SQLite: `file vocab.db` should show "SQLite 3.x database"
- Check file size is under 6MB

### Sync issues
- Check network connectivity
- Verify auth token is valid
- Check Supabase logs for errors
