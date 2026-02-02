import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/database.dart';

/// Repository for ConfusableSet and ConfusableSetMember operations
class ConfusableSetRepository {
  ConfusableSetRepository(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  /// Get confusable sets for a vocabulary word
  Future<List<ConfusableSet>> getForVocabulary(String vocabularyId) async {
    final members = await (_db.select(_db.confusableSetMembers)
          ..where((m) => m.vocabularyId.equals(vocabularyId)))
        .get();

    if (members.isEmpty) return [];

    final setIds = members.map((m) => m.confusableSetId).toList();
    return (_db.select(_db.confusableSets)
          ..where((s) => s.id.isIn(setIds))
          ..where((s) => s.deletedAt.isNull()))
        .get();
  }

  /// Get a confusable set by ID
  Future<ConfusableSet?> getById(String id) {
    return (_db.select(_db.confusableSets)..where((s) => s.id.equals(id)))
        .getSingleOrNull();
  }

  /// Create a confusable set with member links
  Future<ConfusableSet> create({
    required String userId,
    required String languageCode,
    required String words,
    required String explanations,
    String exampleSentences = '{}',
    required List<String> vocabularyIds,
  }) async {
    final now = DateTime.now().toUtc();
    final id = _uuid.v4();

    final companion = ConfusableSetsCompanion.insert(
      id: id,
      userId: userId,
      languageCode: languageCode,
      words: words,
      explanations: explanations,
      exampleSentences: Value(exampleSentences),
      createdAt: now,
      updatedAt: now,
      isPendingSync: const Value(true),
    );

    await _db.into(_db.confusableSets).insert(companion);

    // Create member links
    for (final vocabId in vocabularyIds) {
      await _db.into(_db.confusableSetMembers).insert(
        ConfusableSetMembersCompanion.insert(
          id: _uuid.v4(),
          confusableSetId: id,
          vocabularyId: vocabId,
          createdAt: now,
        ),
      );
    }

    return (await getById(id))!;
  }

  /// Bulk insert confusable sets
  Future<void> bulkInsertSets(List<ConfusableSetsCompanion> companions) async {
    await _db.batch((batch) {
      batch.insertAll(_db.confusableSets, companions,
          mode: InsertMode.insertOrReplace);
    });
  }

  /// Bulk insert confusable set members
  Future<void> bulkInsertMembers(
      List<ConfusableSetMembersCompanion> companions) async {
    await _db.batch((batch) {
      batch.insertAll(_db.confusableSetMembers, companions,
          mode: InsertMode.insertOrReplace);
    });
  }

  /// Check if a vocabulary word has any confusable sets
  Future<bool> hasConfusables(String vocabularyId) async {
    final member = await (_db.select(_db.confusableSetMembers)
          ..where((m) => m.vocabularyId.equals(vocabularyId))
          ..limit(1))
        .getSingleOrNull();
    return member != null;
  }

  /// Get confusable sets pending sync
  Future<List<ConfusableSet>> getPendingSync() {
    return (_db.select(_db.confusableSets)
          ..where((s) => s.isPendingSync.equals(true)))
        .get();
  }

  /// Mark confusable set as synced
  Future<void> markSynced(String id) async {
    await (_db.update(_db.confusableSets)..where((s) => s.id.equals(id)))
        .write(
      ConfusableSetsCompanion(
        isPendingSync: const Value(false),
        lastSyncedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }
}
