import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/database.dart';

/// Repository for MeaningEdit operations — tracks user overrides
class MeaningEditRepository {
  MeaningEditRepository(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  /// Create a meaning edit record
  Future<MeaningEdit> create({
    required String userId,
    required String meaningId,
    required String fieldName,
    required String originalValue,
    required String userValue,
  }) async {
    final now = DateTime.now().toUtc();
    final id = _uuid.v4();

    final companion = MeaningEditsCompanion.insert(
      id: id,
      userId: userId,
      meaningId: meaningId,
      fieldName: fieldName,
      originalValue: originalValue,
      userValue: userValue,
      createdAt: now,
    );

    await _db.into(_db.meaningEdits).insert(companion);
    return (_db.select(_db.meaningEdits)..where((e) => e.id.equals(id)))
        .getSingle();
  }

  /// Get all edits for a meaning
  Future<List<MeaningEdit>> getForMeaning(String meaningId) {
    return (_db.select(_db.meaningEdits)
          ..where((e) => e.meaningId.equals(meaningId))
          ..orderBy([(e) => OrderingTerm.desc(e.createdAt)]))
        .get();
  }

  /// Get the most recent edit for a specific field of a meaning
  Future<MeaningEdit?> getLatestForField(
    String meaningId,
    String fieldName,
  ) {
    return (_db.select(_db.meaningEdits)
          ..where((e) => e.meaningId.equals(meaningId))
          ..where((e) => e.fieldName.equals(fieldName))
          ..orderBy([(e) => OrderingTerm.desc(e.createdAt)])
          ..limit(1))
        .getSingleOrNull();
  }
}
