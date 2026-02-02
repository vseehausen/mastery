import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/database.dart';

/// Repository for Meaning entity operations
class MeaningRepository {
  MeaningRepository(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  /// Get all active meanings for a vocabulary word
  Future<List<Meaning>> getForVocabulary(String vocabularyId) {
    return (_db.select(_db.meanings)
          ..where((m) => m.vocabularyId.equals(vocabularyId))
          ..where((m) => m.deletedAt.isNull())
          ..orderBy([(m) => OrderingTerm.asc(m.sortOrder)]))
        .get();
  }

  /// Get the primary meaning for a vocabulary word
  Future<Meaning?> getPrimary(String vocabularyId) {
    return (_db.select(_db.meanings)
          ..where((m) => m.vocabularyId.equals(vocabularyId))
          ..where((m) => m.isPrimary.equals(true))
          ..where((m) => m.deletedAt.isNull()))
        .getSingleOrNull();
  }

  /// Get a meaning by ID
  Future<Meaning?> getById(String id) {
    return (_db.select(_db.meanings)..where((m) => m.id.equals(id)))
        .getSingleOrNull();
  }

  /// Create a new meaning
  Future<Meaning> create({
    required String userId,
    required String vocabularyId,
    required String languageCode,
    required String primaryTranslation,
    required String englishDefinition,
    List<String> alternativeTranslations = const [],
    String? extendedDefinition,
    String? partOfSpeech,
    List<String> synonyms = const [],
    double confidence = 1.0,
    bool isPrimary = false,
    int sortOrder = 0,
    String source = 'ai',
  }) async {
    final now = DateTime.now().toUtc();
    final id = _uuid.v4();

    final companion = MeaningsCompanion.insert(
      id: id,
      userId: userId,
      vocabularyId: vocabularyId,
      languageCode: languageCode,
      primaryTranslation: primaryTranslation,
      englishDefinition: englishDefinition,
      alternativeTranslations:
          Value(_encodeJsonList(alternativeTranslations)),
      extendedDefinition: Value(extendedDefinition),
      partOfSpeech: Value(partOfSpeech),
      synonyms: Value(_encodeJsonList(synonyms)),
      confidence: Value(confidence),
      isPrimary: Value(isPrimary),
      sortOrder: Value(sortOrder),
      source: Value(source),
      createdAt: now,
      updatedAt: now,
      isPendingSync: const Value(true),
    );

    await _db.into(_db.meanings).insert(companion);
    return (await getById(id))!;
  }

  /// Update a meaning
  Future<Meaning> update({
    required String id,
    String? primaryTranslation,
    String? englishDefinition,
    List<String>? alternativeTranslations,
    String? extendedDefinition,
    String? partOfSpeech,
    List<String>? synonyms,
    bool? isPrimary,
    bool? isActive,
    int? sortOrder,
  }) async {
    final existing = await getById(id);
    if (existing == null) {
      throw StateError('Meaning not found: $id');
    }

    final now = DateTime.now().toUtc();
    await (_db.update(_db.meanings)..where((m) => m.id.equals(id))).write(
      MeaningsCompanion(
        primaryTranslation: primaryTranslation != null
            ? Value(primaryTranslation)
            : const Value.absent(),
        englishDefinition: englishDefinition != null
            ? Value(englishDefinition)
            : const Value.absent(),
        alternativeTranslations: alternativeTranslations != null
            ? Value(_encodeJsonList(alternativeTranslations))
            : const Value.absent(),
        extendedDefinition: extendedDefinition != null
            ? Value(extendedDefinition)
            : const Value.absent(),
        partOfSpeech: partOfSpeech != null
            ? Value(partOfSpeech)
            : const Value.absent(),
        synonyms: synonyms != null
            ? Value(_encodeJsonList(synonyms))
            : const Value.absent(),
        isPrimary:
            isPrimary != null ? Value(isPrimary) : const Value.absent(),
        isActive:
            isActive != null ? Value(isActive) : const Value.absent(),
        sortOrder:
            sortOrder != null ? Value(sortOrder) : const Value.absent(),
        updatedAt: Value(now),
        isPendingSync: const Value(true),
        version: Value(existing.version + 1),
      ),
    );
    return (await getById(id))!;
  }

  /// Pin a meaning as the primary meaning for its vocabulary word.
  /// Unsets is_primary on all other meanings for the same vocabulary.
  Future<void> pinAsPrimary(String meaningId) async {
    final meaning = await getById(meaningId);
    if (meaning == null) return;

    final now = DateTime.now().toUtc();

    // Unset all other primaries for this vocabulary
    await (_db.update(_db.meanings)
          ..where((m) => m.vocabularyId.equals(meaning.vocabularyId))
          ..where((m) => m.id.isNotValue(meaningId))
          ..where((m) => m.deletedAt.isNull()))
        .write(
      MeaningsCompanion(
        isPrimary: const Value(false),
        updatedAt: Value(now),
        isPendingSync: const Value(true),
      ),
    );

    // Set this one as primary
    await (_db.update(_db.meanings)..where((m) => m.id.equals(meaningId)))
        .write(
      MeaningsCompanion(
        isPrimary: const Value(true),
        updatedAt: Value(now),
        isPendingSync: const Value(true),
      ),
    );
  }

  /// Soft delete a meaning
  Future<void> softDelete(String id) async {
    final now = DateTime.now().toUtc();
    await (_db.update(_db.meanings)..where((m) => m.id.equals(id))).write(
      MeaningsCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
        isPendingSync: const Value(true),
      ),
    );
  }

  /// Check if a vocabulary word has any meanings
  Future<bool> hasEnrichedMeanings(String vocabularyId) async {
    final result = await (_db.select(_db.meanings)
          ..where((m) => m.vocabularyId.equals(vocabularyId))
          ..where((m) => m.deletedAt.isNull())
          ..limit(1))
        .getSingleOrNull();
    return result != null;
  }

  /// Get count of enriched vocabulary words for a user
  Future<int> getEnrichedCount(String userId) async {
    final result = await _db.customSelect(
      'SELECT COUNT(DISTINCT vocabulary_id) AS c FROM meanings '
      'WHERE user_id = ? AND deleted_at IS NULL',
      variables: [Variable.withString(userId)],
    ).getSingle();
    return result.read<int>('c');
  }

  /// Bulk insert meanings from enrichment response
  Future<void> bulkInsert(List<MeaningsCompanion> companions) async {
    await _db.batch((batch) {
      batch.insertAll(_db.meanings, companions, mode: InsertMode.insertOrReplace);
    });
  }

  /// Get meanings pending sync
  Future<List<Meaning>> getPendingSync() {
    return (_db.select(_db.meanings)
          ..where((m) => m.isPendingSync.equals(true)))
        .get();
  }

  /// Mark meaning as synced
  Future<void> markSynced(String id) async {
    await (_db.update(_db.meanings)..where((m) => m.id.equals(id))).write(
      MeaningsCompanion(
        isPendingSync: const Value(false),
        lastSyncedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  String _encodeJsonList(List<String> list) {
    final escaped =
        list.map((s) => '"${s.replaceAll('"', '\\"')}"').join(',');
    return '[$escaped]';
  }
}
