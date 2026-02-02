import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/database.dart';

/// Repository for Cue entity operations
class CueRepository {
  CueRepository(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  /// Get all cues for a meaning, optionally filtered by type
  Future<List<Cue>> getForMeaning(String meaningId, {String? cueType}) {
    var query = _db.select(_db.cues)
      ..where((c) => c.meaningId.equals(meaningId))
      ..where((c) => c.deletedAt.isNull());

    if (cueType != null) {
      query = query..where((c) => c.cueType.equals(cueType));
    }

    return query.get();
  }

  /// Get all cues for a vocabulary word (across all its meanings)
  Future<List<Cue>> getForVocabulary(String vocabularyId) async {
    final meanings = await (_db.select(_db.meanings)
          ..where((m) => m.vocabularyId.equals(vocabularyId))
          ..where((m) => m.deletedAt.isNull())
          ..where((m) => m.isActive.equals(true)))
        .get();

    if (meanings.isEmpty) return [];

    final meaningIds = meanings.map((m) => m.id).toList();
    return (_db.select(_db.cues)
          ..where((c) => c.meaningId.isIn(meaningIds))
          ..where((c) => c.deletedAt.isNull()))
        .get();
  }

  /// Get a cue by ID
  Future<Cue?> getById(String id) {
    return (_db.select(_db.cues)..where((c) => c.id.equals(id)))
        .getSingleOrNull();
  }

  /// Create a single cue
  Future<Cue> create({
    required String userId,
    required String meaningId,
    required String cueType,
    required String promptText,
    required String answerText,
    String? hintText,
    String metadata = '{}',
  }) async {
    final now = DateTime.now().toUtc();
    final id = _uuid.v4();

    final companion = CuesCompanion.insert(
      id: id,
      userId: userId,
      meaningId: meaningId,
      cueType: cueType,
      promptText: promptText,
      answerText: answerText,
      hintText: Value(hintText),
      metadata: Value(metadata),
      createdAt: now,
      updatedAt: now,
      isPendingSync: const Value(true),
    );

    await _db.into(_db.cues).insert(companion);
    return (await getById(id))!;
  }

  /// Bulk insert cues from enrichment response
  Future<void> bulkInsert(List<CuesCompanion> companions) async {
    await _db.batch((batch) {
      batch.insertAll(_db.cues, companions, mode: InsertMode.insertOrReplace);
    });
  }

  /// Get cues pending sync
  Future<List<Cue>> getPendingSync() {
    return (_db.select(_db.cues)
          ..where((c) => c.isPendingSync.equals(true)))
        .get();
  }

  /// Mark cue as synced
  Future<void> markSynced(String id) async {
    await (_db.update(_db.cues)..where((c) => c.id.equals(id))).write(
      CuesCompanion(
        isPendingSync: const Value(false),
        lastSyncedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }
}
