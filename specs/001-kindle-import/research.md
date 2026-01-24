# Research: Kindle Import

**Feature**: 001-kindle-import
**Date**: 2026-01-24

## 1. Kindle Clippings File Format

### Decision
Parse "My Clippings.txt" using a delimiter-based parser that handles all clipping types (highlights, notes, bookmarks) and multiple date/location format variations.

### Format Structure

Each entry follows this pattern:
```
Book Title (Author Name)
- Your [Type] on page X | Location Y-Z | Added on [DateTime]

[Content text]
==========
```

**Delimiter**: `==========` (exactly 10 equal signs)
**Line endings**: `\r\n` (CRLF)
**Encoding**: UTF-8 (sometimes with BOM)

### Clipping Types

| Type | Metadata Pattern | Has Content |
|------|------------------|-------------|
| Highlight | `- Your Highlight on page X \| Location Y-Z \| Added on...` | Yes |
| Note | `- Your Note on page X \| Location Y \| Added on...` | Yes |
| Bookmark | `- Your Bookmark at location X \| Added on...` | No (ignore) |

### Location Format Variations
- `Location X` - single position
- `Location X-Y` - range
- `page X | Location Y-Z` - page + location
- `location` (lowercase) - some devices

### Date Format Variations
- US: `Tuesday, October 2, 2017 8:47:09 PM`
- UK/International: `Saturday, 26 March 2016 18:37:26`

### Edge Cases to Handle
1. **Clipping limit**: Content = `<You have reached the clipping limit for this item>`
2. **Parentheses in titles**: Can break author extraction
3. **Extra blank lines**: Kindle occasionally inserts extra newlines
4. **Duplicate entries**: Edits create new entries (append-only file)
5. **Missing page numbers**: Some books have location only

### Alternatives Considered
- **Amazon API**: Requires authentication, limited to 10% of book, not available for all regions
- **Kindle Cloud Reader scraping**: Fragile, ToS concerns
- **Direct file parsing**: ✅ Chosen - reliable, offline, no dependencies

---

## 2. Drift (SQLite) Best Practices

### Decision
Use Drift with FTS5 for full-text search, WAL mode for performance, and sync metadata columns on all tables.

### Schema Design for Sync

Every syncable table includes:
```dart
TextColumn get id => text()();  // UUID primary key
DateTimeColumn get createdAt => dateTime()();
DateTimeColumn get updatedAt => dateTime()();
DateTimeColumn get deletedAt => dateTime().nullable()();  // Soft delete
DateTimeColumn get lastSyncedAt => dateTime().nullable()();
IntColumn get version => integer().withDefault(const Constant(1))();
BoolColumn get isPendingSync => boolean().withDefault(const Constant(false))();
```

### Sync Outbox Pattern
```dart
class SyncOutbox extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get tableName => text()();
  TextColumn get recordId => text()();
  TextColumn get operation => text()();  // insert, update, delete
  TextColumn get payload => text()();     // JSON
  DateTimeColumn get createdAt => dateTime()();
}
```

### Full-Text Search (FTS5)
- Declare FTS tables in `.drift` files (not Dart)
- Use content-less FTS for smaller size
- Maintain sync with triggers
- Use `bm25()` for ranking, `highlight()`/`snippet()` for display

### Performance Optimizations
1. **Background isolates**: `NativeDatabase.createInBackground()`
2. **Batch operations**: Chunk 1000-5000 records per transaction
3. **WAL mode**: `PRAGMA journal_mode = WAL`
4. **Indexes**: On sync status, search fields, timestamps
5. **Cache**: `PRAGMA cache_size = -64000` (64MB)

### Migration Strategy
- Use `make-migrations` command for schema versioning
- Test all migration paths
- Never run complex queries during migrations

### Rationale
Drift provides type-safe SQL with excellent FTS5 support. The sync outbox pattern enables reliable offline-first behavior with conflict resolution.

### Alternatives Considered
- **Isar**: Faster but less mature FTS, no SQL compatibility
- **Hive**: No SQL, limited query capabilities
- **Drift**: ✅ Chosen - best FTS5 support, mature ecosystem, sync-friendly

---

## 3. Tauri USB Device Detection

### Decision
Use `nusb` for USB detection + `mountpoints` for filesystem access. Poll every 2 seconds with Tauri async runtime.

### Kindle Identification

**Vendor ID**: `0x1949` (Lab126/Amazon)

**Product IDs for e-readers**:
| ID | Device |
|----|--------|
| `0x0001` | Kindle 1st Gen |
| `0x0002` | Kindle 2nd Gen |
| `0x0003` | Kindle DX |
| `0x0004` | Kindle 3/4/Touch/Paperwhite/Voyage |
| `0x0324` | Kindle Paperwhite (newer) |

### Detection Strategy
1. Poll USB devices every 2-3 seconds via `nusb::list_devices()`
2. Check vendor/product ID match
3. Find mount point via `mountpoints` crate
4. Verify Kindle by checking for `/documents/My Clippings.txt`
5. Emit Tauri event on state change

### Mount Points by Platform
- **macOS**: `/Volumes/Kindle`
- **Windows**: Drive letter (scan removable drives)
- **Linux**: `/media/<user>/Kindle`

### Cargo Dependencies
```toml
nusb = "0.2"
mountpoints = "0.2"
tokio = { version = "1", features = ["time"] }
```

### Rationale
`nusb` is pure Rust with no C dependencies, cross-platform, and actively maintained. Polling is simpler than hotplug events for this use case.

### Alternatives Considered
- **libusb bindings**: C dependency, more complex
- **OS-specific APIs**: Not cross-platform
- **nusb + polling**: ✅ Chosen - simple, reliable, pure Rust

---

## 4. Supabase Sync Strategy

### Decision
Use Supabase Edge Functions for sync API, PostgreSQL for storage, with client-side sync queue and last-write-wins conflict resolution.

### Sync Flow
1. Local changes written to SQLite + sync outbox
2. Background sync worker processes outbox when online
3. Edge Function validates auth, applies changes to PostgreSQL
4. Server returns updated `lastSyncedAt` timestamps
5. Client marks outbox entries as synced

### Conflict Resolution
- **Strategy**: Last-write-wins based on `updatedAt` timestamp
- **Implementation**: Server compares timestamps, newer wins
- **Edge case**: Clock skew handled by 1-second tolerance

### Edge Function Endpoints
- `POST /sync/push` - Upload local changes
- `POST /sync/pull` - Download remote changes since timestamp
- `POST /highlights` - Create highlight (via push)
- `PATCH /highlights/:id` - Update highlight (via push)
- `DELETE /highlights/:id` - Soft delete (via push)

### Rationale
Supabase provides auth, storage, and edge functions in one platform. Last-write-wins is simple and sufficient for single-user highlights.

---

## 5. Parser Implementation Strategy

### Decision
Implement parser in Dart for mobile (shared with desktop via FFI if needed later). Use regex for metadata extraction with fallbacks.

### Parsing Algorithm
```
1. Split file by "==========" delimiter
2. For each entry:
   a. Extract title line (line 1)
   b. Parse author from parentheses (last occurrence)
   c. Extract metadata line (line 2)
   d. Determine type (Highlight/Note/Bookmark)
   e. Parse location (page/location)
   f. Parse date (try multiple formats)
   g. Extract content (remaining lines)
3. Skip bookmarks (no content)
4. Generate unique ID from hash(title + location + content)
5. Return list of parsed highlights
```

### Duplicate Detection
- **Hash**: SHA-256 of `${bookTitle}|${location}|${content}`
- **Check**: Query local DB before insert
- **Skip**: If hash exists, don't re-import

### Error Handling
- **Corrupted entry**: Log warning, skip to next delimiter
- **Unknown format**: Try flexible regex, fall back to raw content
- **Encoding issues**: Detect BOM, normalize to UTF-8

---

## Summary

| Component | Technology | Rationale |
|-----------|------------|-----------|
| Parser | Dart (regex) | Type-safe, shareable, no native deps |
| Local DB | Drift + SQLite | FTS5, sync-friendly, mature |
| USB Detection | nusb + mountpoints | Pure Rust, cross-platform |
| Backend | Supabase | Auth + DB + Functions in one |
| Sync | Outbox pattern + last-write-wins | Simple, offline-first |
