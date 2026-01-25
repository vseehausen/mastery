import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/database.dart';

/// Repository for Highlight entity operations
class HighlightRepository {
  final AppDatabase _db;
  final _uuid = const Uuid();

  HighlightRepository(this._db);

  /// Check if highlight already exists by content hash
  Future<bool> existsByContentHash({
    required String userId,
    required String contentHash,
  }) async {
    final result = await (_db.select(_db.highlights)
          ..where((h) => h.userId.equals(userId))
          ..where((h) => h.contentHash.equals(contentHash)))
        .getSingleOrNull();
    return result != null;
  }

  /// Create a new highlight
  Future<Highlight> create({
    required String userId,
    required String bookId,
    required String content,
    required String type,
    required String contentHash,
    String? location,
    int? page,
    DateTime? kindleDate,
    String? note,
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();

    final companion = HighlightsCompanion.insert(
      id: id,
      userId: userId,
      bookId: bookId,
      content: content,
      type: type,
      contentHash: contentHash,
      location: Value(location),
      page: Value(page),
      kindleDate: Value(kindleDate),
      note: Value(note),
      createdAt: now,
      updatedAt: now,
      isPendingSync: const Value(true),
    );

    await _db.into(_db.highlights).insert(companion);
    return (await _db.select(_db.highlights)
          ..where((h) => h.id.equals(id)))
        .getSingle();
  }

  /// Get all highlights for a book
  Future<List<Highlight>> getForBook(String bookId) async {
    return (_db.select(_db.highlights)
          ..where((h) => h.bookId.equals(bookId))
          ..where((h) => h.deletedAt.isNull())
          ..orderBy([
            (h) => OrderingTerm.asc(h.page),
            (h) => OrderingTerm.asc(h.location),
          ]))
        .get();
  }

  /// Get all highlights for a user
  Future<List<Highlight>> getAllForUser(String userId) async {
    return (_db.select(_db.highlights)
          ..where((h) => h.userId.equals(userId))
          ..where((h) => h.deletedAt.isNull())
          ..orderBy([(h) => OrderingTerm.desc(h.createdAt)]))
        .get();
  }

  /// Get highlight by ID
  Future<Highlight?> getById(String id) async {
    return (_db.select(_db.highlights)..where((h) => h.id.equals(id)))
        .getSingleOrNull();
  }

  /// Update highlight note
  Future<void> updateNote(String id, String? note) async {
    final highlight = await getById(id);
    if (highlight == null) return;

    await (_db.update(_db.highlights)..where((h) => h.id.equals(id))).write(
      HighlightsCompanion(
        note: Value(note),
        updatedAt: Value(DateTime.now()),
        version: Value(highlight.version + 1),
        isPendingSync: const Value(true),
      ),
    );
  }

  /// Update highlight content
  Future<void> updateContent(String id, String content) async {
    final highlight = await getById(id);
    if (highlight == null) return;

    await (_db.update(_db.highlights)..where((h) => h.id.equals(id))).write(
      HighlightsCompanion(
        content: Value(content),
        updatedAt: Value(DateTime.now()),
        version: Value(highlight.version + 1),
        isPendingSync: const Value(true),
      ),
    );
  }

  /// Soft delete a highlight
  Future<void> softDelete(String id) async {
    await (_db.update(_db.highlights)..where((h) => h.id.equals(id))).write(
      HighlightsCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
        isPendingSync: const Value(true),
      ),
    );
  }

  /// Search highlights by content
  Future<List<Highlight>> search({
    required String userId,
    required String query,
    String? bookId,
  }) async {
    // Simple LIKE search - could be enhanced with FTS5
    final select = _db.select(_db.highlights)
      ..where((h) => h.userId.equals(userId))
      ..where((h) => h.deletedAt.isNull())
      ..where((h) => h.content.like('%$query%'));

    if (bookId != null) {
      select.where((h) => h.bookId.equals(bookId));
    }

    return select.get();
  }

  /// Get highlights pending sync
  Future<List<Highlight>> getPendingSync(String userId) async {
    return (_db.select(_db.highlights)
          ..where((h) => h.userId.equals(userId))
          ..where((h) => h.isPendingSync.equals(true)))
        .get();
  }

  /// Mark highlight as synced
  Future<void> markSynced(String id) async {
    await (_db.update(_db.highlights)..where((h) => h.id.equals(id))).write(
      HighlightsCompanion(
        isPendingSync: const Value(false),
        lastSyncedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Count highlights for a book
  Future<int> countForBook(String bookId) async {
    final result = await (_db.selectOnly(_db.highlights)
          ..addColumns([_db.highlights.id.count()])
          ..where(_db.highlights.bookId.equals(bookId))
          ..where(_db.highlights.deletedAt.isNull()))
        .getSingle();
    return result.read(_db.highlights.id.count()) ?? 0;
  }
}
