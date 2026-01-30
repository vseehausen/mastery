import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/database.dart';

/// Repository for managing learning cards (FSRS state per vocabulary item)
class LearningCardRepository {
  LearningCardRepository(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  /// Create a new learning card for a vocabulary item
  Future<LearningCard> create({
    required String userId,
    required String vocabularyId,
  }) async {
    final now = DateTime.now().toUtc();
    final companion = LearningCardsCompanion.insert(
      id: _uuid.v4(),
      userId: userId,
      vocabularyId: vocabularyId,
      due: now,
      createdAt: now,
      updatedAt: now,
    );

    await _db.into(_db.learningCards).insert(companion);
    return (await getById(companion.id.value))!;
  }

  /// Get a learning card by ID
  Future<LearningCard?> getById(String id) {
    return (_db.select(
      _db.learningCards,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Get a learning card by vocabulary ID
  Future<LearningCard?> getByVocabularyId(
    String userId,
    String vocabularyId,
  ) async {
    return (_db.select(_db.learningCards)
          ..where((t) => t.userId.equals(userId))
          ..where((t) => t.vocabularyId.equals(vocabularyId))
          ..where((t) => t.deletedAt.isNull()))
        .getSingleOrNull();
  }

  /// Get all learning cards for a user
  Future<List<LearningCard>> getAll(String userId) {
    return (_db.select(_db.learningCards)
          ..where((t) => t.userId.equals(userId))
          ..where((t) => t.deletedAt.isNull()))
        .get();
  }

  /// Get due cards (where due <= now), ordered by due date
  Future<List<LearningCard>> getDueCards(String userId, {int? limit}) {
    final now = DateTime.now().toUtc();
    var query = _db.select(_db.learningCards)
      ..where((t) => t.userId.equals(userId))
      ..where((t) => t.deletedAt.isNull())
      ..where((t) => t.due.isSmallerOrEqualValue(now))
      ..where((t) => t.state.isBiggerThanValue(0)) // Exclude new cards
      ..orderBy([(t) => OrderingTerm.asc(t.due)]);

    if (limit != null) {
      query = query..limit(limit);
    }

    return query.get();
  }

  /// Get due cards sorted by priority score (for session planning)
  /// Priority is computed based on overdue days, retrievability, and lapses
  Future<List<LearningCard>> getDueCardsSorted(
    String userId, {
    int? limit,
  }) async {
    final now = DateTime.now().toUtc();
    final dueCards = await getDueCards(userId);

    // Sort by priority score (higher = more urgent)
    dueCards.sort((a, b) {
      final priorityA = _computePriorityScore(a, now);
      final priorityB = _computePriorityScore(b, now);
      return priorityB.compareTo(priorityA); // Descending order
    });

    if (limit != null && dueCards.length > limit) {
      return dueCards.sublist(0, limit);
    }
    return dueCards;
  }

  /// Compute priority score for a card (used for session ordering)
  double _computePriorityScore(LearningCard card, DateTime now) {
    final overdueDays = now.difference(card.due).inDays.clamp(0, 365);
    // Approximate retrievability based on stability and overdue time
    // R = 0.9^(t/S) where t is days overdue and S is stability
    final daysOverdue = now.difference(card.due).inDays.toDouble();
    final retrievability = card.stability > 0
        ? 0.9 * (1.0 - (daysOverdue / (card.stability + 1)).clamp(0.0, 1.0))
        : 0.5;
    final lapseWeight = 1 + (card.lapses / 20);
    return overdueDays * (1 - retrievability) * lapseWeight;
  }

  /// Get new cards (state = 0), optionally limited
  Future<List<LearningCard>> getNewCards(String userId, {int? limit}) {
    var query = _db.select(_db.learningCards)
      ..where((t) => t.userId.equals(userId))
      ..where((t) => t.deletedAt.isNull())
      ..where((t) => t.state.equals(0)) // State.new
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);

    if (limit != null) {
      query = query..limit(limit);
    }

    return query.get();
  }

  /// Get leech cards (isLeech = true AND due)
  Future<List<LearningCard>> getLeeches(String userId) {
    final now = DateTime.now().toUtc();
    return (_db.select(_db.learningCards)
          ..where((t) => t.userId.equals(userId))
          ..where((t) => t.deletedAt.isNull())
          ..where((t) => t.isLeech.equals(true))
          ..where((t) => t.due.isSmallerOrEqualValue(now))
          ..orderBy([(t) => OrderingTerm.desc(t.lapses)]))
        .get();
  }

  /// Get count of overdue cards (for hysteresis calculation)
  Future<int> getOverdueCount(String userId) async {
    final now = DateTime.now().toUtc();
    final query = _db.select(_db.learningCards)
      ..where((t) => t.userId.equals(userId))
      ..where((t) => t.deletedAt.isNull())
      ..where((t) => t.due.isSmallerOrEqualValue(now))
      ..where((t) => t.state.isBiggerThanValue(0)); // Exclude new cards

    final cards = await query.get();
    return cards.length;
  }

  /// Update a learning card after review
  Future<LearningCard> updateAfterReview({
    required String cardId,
    required int state,
    required DateTime due,
    required double stability,
    required double difficulty,
    required int reps,
    required int lapses,
    required bool isLeech,
  }) async {
    final now = DateTime.now().toUtc();
    await (_db.update(
      _db.learningCards,
    )..where((t) => t.id.equals(cardId))).write(
      LearningCardsCompanion(
        state: Value(state),
        due: Value(due),
        stability: Value(stability),
        difficulty: Value(difficulty),
        reps: Value(reps),
        lapses: Value(lapses),
        isLeech: Value(isLeech),
        lastReview: Value(now),
        updatedAt: Value(now),
        isPendingSync: const Value(true),
        version: Value((await getById(cardId))!.version + 1),
      ),
    );

    return (await getById(cardId))!;
  }

  /// Soft delete a learning card
  Future<void> delete(String id) async {
    final now = DateTime.now().toUtc();
    await (_db.update(_db.learningCards)..where((t) => t.id.equals(id))).write(
      LearningCardsCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
        isPendingSync: const Value(true),
      ),
    );
  }

  /// Get cards pending sync
  Future<List<LearningCard>> getPendingSync() {
    return (_db.select(
      _db.learningCards,
    )..where((t) => t.isPendingSync.equals(true))).get();
  }

  /// Mark card as synced
  Future<void> markSynced(String id) async {
    final now = DateTime.now().toUtc();
    await (_db.update(_db.learningCards)..where((t) => t.id.equals(id))).write(
      LearningCardsCompanion(
        isPendingSync: const Value(false),
        lastSyncedAt: Value(now),
      ),
    );
  }

  /// Create learning cards for all vocabulary items that don't have one yet
  /// Returns the number of cards created
  Future<int> createCardsForNewVocabulary(String userId) async {
    // Get all vocabulary IDs for this user
    final vocabQuery = _db.select(_db.vocabularys)
      ..where((t) => t.userId.equals(userId))
      ..where((t) => t.deletedAt.isNull());
    final allVocab = await vocabQuery.get();

    // Get all existing learning card vocabulary IDs
    final existingCards = await getAll(userId);
    final existingVocabIds = existingCards.map((c) => c.vocabularyId).toSet();

    // Find vocabulary without cards
    final vocabWithoutCards = allVocab
        .where((v) => !existingVocabIds.contains(v.id))
        .toList();

    // Create cards for each
    final now = DateTime.now().toUtc();
    for (final vocab in vocabWithoutCards) {
      final companion = LearningCardsCompanion.insert(
        id: _uuid.v4(),
        userId: userId,
        vocabularyId: vocab.id,
        due: now,
        createdAt: now,
        updatedAt: now,
      );
      await _db.into(_db.learningCards).insert(companion);
    }

    return vocabWithoutCards.length;
  }
}
