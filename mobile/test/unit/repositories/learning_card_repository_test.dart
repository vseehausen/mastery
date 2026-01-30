import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/data/database/database.dart';
import 'package:mastery/data/repositories/learning_card_repository.dart';
import 'package:mastery/data/repositories/vocabulary_repository.dart';
import 'package:mastery/domain/services/srs_scheduler.dart';
import '../../helpers/test_helpers.dart';

void main() {
  group('LearningCardRepository', () {
    late AppDatabase db;
    late LearningCardRepository repository;
    late VocabularyRepository vocabRepository;

    setUp(() async {
      db = createTestDatabase();
      repository = LearningCardRepository(db);
      vocabRepository = VocabularyRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    Future<String> createTestVocabulary(String userId) async {
      final vocab = await vocabRepository.create(
        userId: userId,
        word: 'test-word-${DateTime.now().millisecondsSinceEpoch}',
        contentHash: 'hash-${DateTime.now().millisecondsSinceEpoch}',
      );
      return vocab.id;
    }

    group('create', () {
      test('creates a new learning card with default values', () async {
        final vocabId = await createTestVocabulary('user-1');
        final card = await repository.create(
          userId: 'user-1',
          vocabularyId: vocabId,
        );

        expect(card.id, isNotEmpty);
        expect(card.userId, equals('user-1'));
        expect(card.vocabularyId, equals(vocabId));
        expect(card.state, equals(CardState.newCard));
        expect(card.stability, equals(0.0));
        expect(card.difficulty, equals(0.0));
        expect(card.reps, equals(0));
        expect(card.lapses, equals(0));
        expect(card.isLeech, isFalse);
      });

      test('creates cards with unique IDs', () async {
        final vocabId1 = await createTestVocabulary('user-1');
        final vocabId2 = await createTestVocabulary('user-1');

        final card1 = await repository.create(
          userId: 'user-1',
          vocabularyId: vocabId1,
        );
        final card2 = await repository.create(
          userId: 'user-1',
          vocabularyId: vocabId2,
        );

        expect(card1.id, isNot(equals(card2.id)));
      });
    });

    group('getById', () {
      test('returns card when it exists', () async {
        final vocabId = await createTestVocabulary('user-1');
        final created = await repository.create(
          userId: 'user-1',
          vocabularyId: vocabId,
        );

        final retrieved = await repository.getById(created.id);

        expect(retrieved, isNotNull);
        expect(retrieved!.id, equals(created.id));
      });

      test('returns null when card does not exist', () async {
        final retrieved = await repository.getById('non-existent-id');
        expect(retrieved, isNull);
      });
    });

    group('getByVocabularyId', () {
      test('returns card for vocabulary', () async {
        final vocabId = await createTestVocabulary('user-1');
        final created = await repository.create(
          userId: 'user-1',
          vocabularyId: vocabId,
        );

        final retrieved = await repository.getByVocabularyId('user-1', vocabId);

        expect(retrieved, isNotNull);
        expect(retrieved!.id, equals(created.id));
      });

      test('returns null for non-existent vocabulary', () async {
        final retrieved = await repository.getByVocabularyId('user-1', 'non-existent');
        expect(retrieved, isNull);
      });
    });

    group('getAll', () {
      test('returns all cards for user', () async {
        final vocabId1 = await createTestVocabulary('user-1');
        final vocabId2 = await createTestVocabulary('user-1');

        await repository.create(userId: 'user-1', vocabularyId: vocabId1);
        await repository.create(userId: 'user-1', vocabularyId: vocabId2);

        final cards = await repository.getAll('user-1');

        expect(cards.length, equals(2));
      });

      test('returns empty list when no cards exist', () async {
        final cards = await repository.getAll('user-1');
        expect(cards, isEmpty);
      });

      test('only returns cards for specified user', () async {
        final vocabId1 = await createTestVocabulary('user-1');
        final vocabId2 = await createTestVocabulary('user-2');

        await repository.create(userId: 'user-1', vocabularyId: vocabId1);
        await repository.create(userId: 'user-2', vocabularyId: vocabId2);

        final cards = await repository.getAll('user-1');

        expect(cards.length, equals(1));
        expect(cards.first.userId, equals('user-1'));
      });
    });

    group('getNewCards', () {
      test('returns only new cards (state=0)', () async {
        final vocabId = await createTestVocabulary('user-1');
        await repository.create(userId: 'user-1', vocabularyId: vocabId);

        final newCards = await repository.getNewCards('user-1');

        expect(newCards.length, equals(1));
        expect(newCards.first.state, equals(CardState.newCard));
      });

      test('respects limit parameter', () async {
        for (var i = 0; i < 5; i++) {
          final vocabId = await createTestVocabulary('user-1');
          await repository.create(userId: 'user-1', vocabularyId: vocabId);
        }

        final newCards = await repository.getNewCards('user-1', limit: 3);

        expect(newCards.length, equals(3));
      });
    });

    group('updateAfterReview', () {
      test('updates card with new FSRS values', () async {
        final vocabId = await createTestVocabulary('user-1');
        final card = await repository.create(userId: 'user-1', vocabularyId: vocabId);

        final updated = await repository.updateAfterReview(
          cardId: card.id,
          state: CardState.review,
          due: DateTime.now().add(const Duration(days: 7)).toUtc(),
          stability: 7.0,
          difficulty: 5.0,
          reps: 1,
          lapses: 0,
          isLeech: false,
        );

        expect(updated.state, equals(CardState.review));
        expect(updated.stability, equals(7.0));
        expect(updated.difficulty, equals(5.0));
        expect(updated.reps, equals(1));
        expect(updated.lastReview, isNotNull);
        expect(updated.isPendingSync, isTrue);
      });

      test('marks card as leech when isLeech is true', () async {
        final vocabId = await createTestVocabulary('user-1');
        final card = await repository.create(userId: 'user-1', vocabularyId: vocabId);

        final updated = await repository.updateAfterReview(
          cardId: card.id,
          state: CardState.review,
          due: DateTime.now().add(const Duration(days: 1)).toUtc(),
          stability: 1.0,
          difficulty: 8.0,
          reps: 10,
          lapses: 8,
          isLeech: true,
        );

        expect(updated.isLeech, isTrue);
        expect(updated.lapses, equals(8));
      });
    });

    group('getLeeches', () {
      test('returns only leech cards that are due', () async {
        // Create a regular card (not a leech)
        final vocabId1 = await createTestVocabulary('user-1');
        await repository.create(userId: 'user-1', vocabularyId: vocabId1);

        // Create a leech card
        final vocabId2 = await createTestVocabulary('user-1');
        final leechCard = await repository.create(userId: 'user-1', vocabularyId: vocabId2);
        await repository.updateAfterReview(
          cardId: leechCard.id,
          state: CardState.review,
          due: DateTime.now().subtract(const Duration(days: 1)).toUtc(),
          stability: 1.0,
          difficulty: 8.0,
          reps: 10,
          lapses: 8,
          isLeech: true,
        );

        final leeches = await repository.getLeeches('user-1');

        expect(leeches.length, equals(1));
        expect(leeches.first.isLeech, isTrue);
      });
    });

    group('getOverdueCount', () {
      test('returns count of overdue cards', () async {
        // Create a due card (not new)
        final vocabId = await createTestVocabulary('user-1');
        final card = await repository.create(userId: 'user-1', vocabularyId: vocabId);
        await repository.updateAfterReview(
          cardId: card.id,
          state: CardState.review,
          due: DateTime.now().subtract(const Duration(days: 1)).toUtc(),
          stability: 7.0,
          difficulty: 5.0,
          reps: 1,
          lapses: 0,
          isLeech: false,
        );

        final count = await repository.getOverdueCount('user-1');

        expect(count, equals(1));
      });

      test('excludes new cards from overdue count', () async {
        final vocabId = await createTestVocabulary('user-1');
        await repository.create(userId: 'user-1', vocabularyId: vocabId);

        final count = await repository.getOverdueCount('user-1');

        expect(count, equals(0));
      });
    });

    group('delete', () {
      test('soft deletes card', () async {
        final vocabId = await createTestVocabulary('user-1');
        final card = await repository.create(userId: 'user-1', vocabularyId: vocabId);

        await repository.delete(card.id);

        // Card should still exist but be soft deleted
        final allCards = await repository.getAll('user-1');
        expect(allCards, isEmpty); // getAll excludes deleted
      });
    });

    group('getPendingSync', () {
      test('returns cards with isPendingSync=true', () async {
        final vocabId = await createTestVocabulary('user-1');
        final card = await repository.create(userId: 'user-1', vocabularyId: vocabId);

        // Update card to set isPendingSync
        await repository.updateAfterReview(
          cardId: card.id,
          state: CardState.review,
          due: DateTime.now().add(const Duration(days: 7)).toUtc(),
          stability: 7.0,
          difficulty: 5.0,
          reps: 1,
          lapses: 0,
          isLeech: false,
        );

        final pendingCards = await repository.getPendingSync();

        expect(pendingCards.length, equals(1));
        expect(pendingCards.first.isPendingSync, isTrue);
      });
    });

    group('markSynced', () {
      test('clears pending sync flag and sets synced timestamp', () async {
        final vocabId = await createTestVocabulary('user-1');
        final card = await repository.create(userId: 'user-1', vocabularyId: vocabId);

        // Set pending sync
        await repository.updateAfterReview(
          cardId: card.id,
          state: CardState.review,
          due: DateTime.now().add(const Duration(days: 7)).toUtc(),
          stability: 7.0,
          difficulty: 5.0,
          reps: 1,
          lapses: 0,
          isLeech: false,
        );

        await repository.markSynced(card.id);

        final synced = await repository.getById(card.id);
        expect(synced!.isPendingSync, isFalse);
        expect(synced.lastSyncedAt, isNotNull);
      });
    });
  });
}
