import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/database.dart';

/// Repository for Encounter entity operations
class EncounterRepository {
  EncounterRepository(this._db);

  final AppDatabase _db;
  final _uuid = const Uuid();

  /// Create a new encounter
  Future<Encounter> create({
    required String userId,
    required String vocabularyId,
    String? sourceId,
    String? context,
    String? locatorJson,
    DateTime? occurredAt,
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();

    final companion = EncountersCompanion.insert(
      id: id,
      userId: userId,
      vocabularyId: vocabularyId,
      sourceId: Value(sourceId),
      context: Value(context),
      locatorJson: Value(locatorJson),
      occurredAt: Value(occurredAt),
      createdAt: now,
      updatedAt: now,
      isPendingSync: const Value(true),
    );

    await _db.into(_db.encounters).insert(companion);
    return (_db.select(
      _db.encounters,
    )..where((e) => e.id.equals(id))).getSingle();
  }

  /// Get encounters for a vocabulary item (most recent first)
  Future<List<Encounter>> getForVocabulary(String vocabularyId) async {
    return (_db.select(_db.encounters)
          ..where((e) => e.vocabularyId.equals(vocabularyId))
          ..where((e) => e.deletedAt.isNull())
          ..orderBy([(e) => OrderingTerm.desc(e.occurredAt)]))
        .get();
  }

  /// Get the most recent encounter for a vocabulary item
  Future<Encounter?> getMostRecentForVocabulary(String vocabularyId) async {
    return (_db.select(_db.encounters)
          ..where((e) => e.vocabularyId.equals(vocabularyId))
          ..where((e) => e.deletedAt.isNull())
          ..orderBy([(e) => OrderingTerm.desc(e.occurredAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Get encounters for a source
  Future<List<Encounter>> getForSource(String sourceId) async {
    return (_db.select(_db.encounters)
          ..where((e) => e.sourceId.equals(sourceId))
          ..where((e) => e.deletedAt.isNull())
          ..orderBy([(e) => OrderingTerm.desc(e.occurredAt)]))
        .get();
  }

  /// Get encounters pending sync
  Future<List<Encounter>> getPendingSync(String userId) async {
    return (_db.select(_db.encounters)
          ..where((e) => e.userId.equals(userId))
          ..where((e) => e.isPendingSync.equals(true)))
        .get();
  }

  /// Mark encounter as synced
  Future<void> markSynced(String id) async {
    await (_db.update(_db.encounters)..where((e) => e.id.equals(id))).write(
      EncountersCompanion(
        isPendingSync: const Value(false),
        lastSyncedAt: Value(DateTime.now()),
      ),
    );
  }
}
