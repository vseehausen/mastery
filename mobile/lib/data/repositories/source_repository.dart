import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/database.dart';

/// Repository for Source entity operations
class SourceRepository {
  SourceRepository(this._db);

  final AppDatabase _db;
  final _uuid = const Uuid();

  /// Find source by type and title for a user
  Future<Source?> findByTypeAndTitle({
    required String userId,
    required String type,
    required String title,
    String? author,
  }) async {
    final query = _db.select(_db.sources)
      ..where((s) => s.userId.equals(userId))
      ..where((s) => s.type.equals(type))
      ..where((s) => s.title.equals(title))
      ..where((s) => s.deletedAt.isNull());

    if (author != null) {
      query.where((s) => s.author.equals(author));
    } else {
      query.where((s) => s.author.isNull());
    }

    return query.getSingleOrNull();
  }

  /// Create a new source
  Future<Source> create({
    required String userId,
    required String type,
    required String title,
    String? author,
    String? asin,
    String? url,
    String? domain,
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();

    final companion = SourcesCompanion.insert(
      id: id,
      userId: userId,
      type: type,
      title: title,
      author: Value(author),
      asin: Value(asin),
      url: Value(url),
      domain: Value(domain),
      createdAt: now,
      updatedAt: now,
      isPendingSync: const Value(true),
    );

    await _db.into(_db.sources).insert(companion);
    return (_db.select(_db.sources)..where((s) => s.id.equals(id))).getSingle();
  }

  /// Find or create source
  Future<Source> findOrCreate({
    required String userId,
    required String type,
    required String title,
    String? author,
    String? asin,
  }) async {
    final existing = await findByTypeAndTitle(
      userId: userId,
      type: type,
      title: title,
      author: author,
    );

    if (existing != null) return existing;

    return create(
      userId: userId,
      type: type,
      title: title,
      author: author,
      asin: asin,
    );
  }

  /// Get all sources for a user
  Future<List<Source>> getAllForUser(String userId) async {
    return (_db.select(_db.sources)
          ..where((s) => s.userId.equals(userId))
          ..where((s) => s.deletedAt.isNull())
          ..orderBy([(s) => OrderingTerm.desc(s.updatedAt)]))
        .get();
  }

  /// Get source by ID
  Future<Source?> getById(String id) async {
    return (_db.select(
      _db.sources,
    )..where((s) => s.id.equals(id))).getSingleOrNull();
  }

  /// Soft delete a source
  Future<void> softDelete(String id) async {
    await (_db.update(_db.sources)..where((s) => s.id.equals(id))).write(
      SourcesCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
        isPendingSync: const Value(true),
      ),
    );
  }

  /// Get sources pending sync
  Future<List<Source>> getPendingSync(String userId) async {
    return (_db.select(_db.sources)
          ..where((s) => s.userId.equals(userId))
          ..where((s) => s.isPendingSync.equals(true)))
        .get();
  }

  /// Mark source as synced
  Future<void> markSynced(String id) async {
    await (_db.update(_db.sources)..where((s) => s.id.equals(id))).write(
      SourcesCompanion(
        isPendingSync: const Value(false),
        lastSyncedAt: Value(DateTime.now()),
      ),
    );
  }
}
