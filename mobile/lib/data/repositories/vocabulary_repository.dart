import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/database.dart';

/// Repository for Vocabulary entity operations
class VocabularyRepository {
  VocabularyRepository(this._db);

  final AppDatabase _db;
  final _uuid = const Uuid();

  /// Check if vocabulary entry already exists by content hash
  Future<bool> existsByContentHash({
    required String userId,
    required String contentHash,
  }) async {
    final result =
        await (_db.select(_db.vocabularys)
              ..where((v) => v.userId.equals(userId))
              ..where((v) => v.contentHash.equals(contentHash)))
            .getSingleOrNull();
    return result != null;
  }

  /// Create a new vocabulary entry
  Future<Vocabulary> create({
    required String userId,
    required String word,
    required String contentHash,
    String? stem,
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();

    final companion = VocabularysCompanion.insert(
      id: id,
      userId: userId,
      word: word,
      contentHash: contentHash,
      stem: Value(stem),
      createdAt: now,
      updatedAt: now,
      isPendingSync: const Value(true),
    );

    await _db.into(_db.vocabularys).insert(companion);
    return (_db.select(
      _db.vocabularys,
    )..where((v) => v.id.equals(id))).getSingle();
  }

  /// Upsert vocabulary entries from server sync
  Future<void> upsertMany(List<Map<String, dynamic>> entries) async {
    await _db.batch((batch) {
      for (final entry in entries) {
        final companion = VocabularysCompanion(
          id: Value(entry['id'] as String),
          userId: Value(entry['user_id'] as String),
          word: Value(entry['word'] as String),
          stem: Value(entry['stem'] as String?),
          contentHash: Value(entry['content_hash'] as String),
          createdAt: Value(DateTime.parse(entry['created_at'] as String)),
          updatedAt: Value(DateTime.parse(entry['updated_at'] as String)),
          deletedAt: Value(
            entry['deleted_at'] != null
                ? DateTime.parse(entry['deleted_at'] as String)
                : null,
          ),
          lastSyncedAt: Value(DateTime.now()),
          isPendingSync: const Value(false),
          version: Value(entry['version'] as int? ?? 1),
        );

        batch.insert(
          _db.vocabularys,
          companion,
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  /// Get all vocabulary for a user, sorted by newest first
  Future<List<Vocabulary>> getAllForUser(String userId) async {
    return (_db.select(_db.vocabularys)
          ..where((v) => v.userId.equals(userId))
          ..where((v) => v.deletedAt.isNull())
          ..orderBy([(v) => OrderingTerm.desc(v.createdAt)]))
        .get();
  }

  /// Get vocabulary by ID
  Future<Vocabulary?> getById(String id) async {
    return (_db.select(
      _db.vocabularys,
    )..where((v) => v.id.equals(id))).getSingleOrNull();
  }

  /// Soft delete a vocabulary entry
  Future<void> softDelete(String id) async {
    final vocab = await getById(id);
    if (vocab == null) return;

    await (_db.update(_db.vocabularys)..where((v) => v.id.equals(id))).write(
      VocabularysCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
        version: Value(vocab.version + 1),
        isPendingSync: const Value(true),
      ),
    );
  }

  /// Search vocabulary by word
  Future<List<Vocabulary>> search({
    required String userId,
    required String query,
  }) async {
    return (_db.select(_db.vocabularys)
          ..where((v) => v.userId.equals(userId))
          ..where((v) => v.deletedAt.isNull())
          ..where((v) => v.word.like('%$query%')))
        .get();
  }

  /// Get vocabulary pending sync
  Future<List<Vocabulary>> getPendingSync(String userId) async {
    return (_db.select(_db.vocabularys)
          ..where((v) => v.userId.equals(userId))
          ..where((v) => v.isPendingSync.equals(true)))
        .get();
  }

  /// Mark vocabulary as synced
  Future<void> markSynced(String id) async {
    await (_db.update(_db.vocabularys)..where((v) => v.id.equals(id))).write(
      VocabularysCompanion(
        isPendingSync: const Value(false),
        lastSyncedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Count vocabulary for a user
  Future<int> countForUser(String userId) async {
    final result =
        await (_db.selectOnly(_db.vocabularys)
              ..addColumns([_db.vocabularys.id.count()])
              ..where(_db.vocabularys.userId.equals(userId))
              ..where(_db.vocabularys.deletedAt.isNull()))
            .getSingle();
    return result.read(_db.vocabularys.id.count()) ?? 0;
  }

  /// Watch all vocabulary for a user (reactive stream)
  Stream<List<Vocabulary>> watchAllForUser(String userId) {
    return (_db.select(_db.vocabularys)
          ..where((v) => v.userId.equals(userId))
          ..where((v) => v.deletedAt.isNull())
          ..orderBy([(v) => OrderingTerm.desc(v.createdAt)]))
        .watch();
  }
}
