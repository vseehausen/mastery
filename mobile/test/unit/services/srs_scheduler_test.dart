import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/domain/services/srs_scheduler.dart';
import 'package:mastery/data/database/database.dart';

void main() {
  group('SrsScheduler', () {
    late SrsScheduler scheduler;

    setUp(() {
      scheduler = SrsScheduler(targetRetention: 0.90);
    });

    group('reviewCard', () {
      test('processes a new card with Good rating', () {
        final card = _createTestCard(
          id: 'card-1',
          vocabularyId: 'vocab-1',
          state: CardState.newCard,
          due: DateTime.now().toUtc(),
          stability: 0.0,
          difficulty: 0.0,
          reps: 0,
          lapses: 0,
        );

        final result = scheduler.reviewCard(
          card: card,
          rating: ReviewRating.good,
          interactionMode: 0,
        );

        expect(result.updatedCard.state, isNot(CardState.newCard));
        expect(result.updatedCard.stability, greaterThan(0));
        expect(result.updatedCard.difficulty, greaterThan(0));
        expect(result.updatedCard.reps, equals(1));
        expect(result.updatedCard.lapses, equals(0));
        expect(result.isLeech, isFalse);
      });

      test('processes a review card with Again rating and increments lapses', () {
        final card = _createTestCard(
          id: 'card-1',
          vocabularyId: 'vocab-1',
          state: CardState.review,
          due: DateTime.now().subtract(const Duration(days: 1)).toUtc(),
          stability: 10.0,
          difficulty: 5.0,
          reps: 5,
          lapses: 0,
        );

        final result = scheduler.reviewCard(
          card: card,
          rating: ReviewRating.again,
          interactionMode: 0,
        );

        // Rating Again on review card increments lapses
        expect(result.updatedCard.lapses, equals(1));
        // Reps should not increment for Again rating
        expect(result.updatedCard.reps, equals(5));
      });

      test('marks card as leech when lapses reach threshold', () {
        final card = _createTestCard(
          id: 'card-1',
          vocabularyId: 'vocab-1',
          state: CardState.review,
          due: DateTime.now().subtract(const Duration(days: 1)).toUtc(),
          stability: 10.0,
          difficulty: 5.0,
          reps: 5,
          lapses: 7, // One away from threshold (8)
        );

        final result = scheduler.reviewCard(
          card: card,
          rating: ReviewRating.again,
          interactionMode: 0,
        );

        expect(result.updatedCard.lapses, equals(8));
        expect(result.updatedCard.isLeech, isTrue);
        expect(result.isLeech, isTrue);
      });

      test('increments reps for Hard rating', () {
        final card = _createTestCard(
          id: 'card-1',
          vocabularyId: 'vocab-1',
          state: CardState.review,
          due: DateTime.now().subtract(const Duration(days: 1)).toUtc(),
          stability: 10.0,
          difficulty: 5.0,
          reps: 5,
          lapses: 0,
        );

        final result = scheduler.reviewCard(
          card: card,
          rating: ReviewRating.hard,
          interactionMode: 0,
        );

        expect(result.updatedCard.reps, equals(6));
      });

      test('increments reps for Easy rating', () {
        final card = _createTestCard(
          id: 'card-1',
          vocabularyId: 'vocab-1',
          state: CardState.review,
          due: DateTime.now().subtract(const Duration(days: 1)).toUtc(),
          stability: 10.0,
          difficulty: 5.0,
          reps: 5,
          lapses: 0,
        );

        final result = scheduler.reviewCard(
          card: card,
          rating: ReviewRating.easy,
          interactionMode: 0,
        );

        expect(result.updatedCard.reps, equals(6));
      });

      test('records review log data correctly', () {
        final card = _createTestCard(
          id: 'card-1',
          vocabularyId: 'vocab-1',
          state: CardState.review,
          due: DateTime.now().subtract(const Duration(days: 1)).toUtc(),
          stability: 10.0,
          difficulty: 5.0,
          reps: 5,
          lapses: 0,
        );

        final result = scheduler.reviewCard(
          card: card,
          rating: ReviewRating.good,
          interactionMode: 1,
        );

        expect(result.reviewLog.rating, equals(ReviewRating.good));
        expect(result.reviewLog.interactionMode, equals(1));
        expect(result.reviewLog.stateBefore, equals(CardState.review));
        expect(result.reviewLog.stabilityBefore, equals(10.0));
        expect(result.reviewLog.difficultyBefore, equals(5.0));
      });
    });

    group('getRetrievability', () {
      test('returns 1.0 for new cards', () {
        final card = _createTestCard(
          id: 'card-1',
          vocabularyId: 'vocab-1',
          state: CardState.newCard,
          due: DateTime.now().toUtc(),
          stability: 0.0,
          difficulty: 0.0,
          reps: 0,
          lapses: 0,
        );

        final retrievability = scheduler.getRetrievability(card);
        expect(retrievability, equals(1.0));
      });

      test('returns 1.0 for cards with zero stability', () {
        final card = _createTestCard(
          id: 'card-1',
          vocabularyId: 'vocab-1',
          state: CardState.review,
          due: DateTime.now().toUtc(),
          stability: 0.0,
          difficulty: 5.0,
          reps: 1,
          lapses: 0,
        );

        final retrievability = scheduler.getRetrievability(card);
        expect(retrievability, equals(1.0));
      });

      test('returns 1.0 for cards without lastReview', () {
        final card = _createTestCard(
          id: 'card-1',
          vocabularyId: 'vocab-1',
          state: CardState.review,
          due: DateTime.now().toUtc(),
          stability: 10.0,
          difficulty: 5.0,
          reps: 1,
          lapses: 0,
          lastReview: null,
        );

        final retrievability = scheduler.getRetrievability(card);
        expect(retrievability, equals(1.0));
      });

      test('returns value between 0 and 1 for reviewed cards', () {
        final card = _createTestCard(
          id: 'card-1',
          vocabularyId: 'vocab-1',
          state: CardState.review,
          due: DateTime.now().subtract(const Duration(days: 5)).toUtc(),
          stability: 10.0,
          difficulty: 5.0,
          reps: 5,
          lapses: 0,
          lastReview: DateTime.now().subtract(const Duration(days: 10)).toUtc(),
        );

        final retrievability = scheduler.getRetrievability(card);
        expect(retrievability, greaterThan(0));
        expect(retrievability, lessThanOrEqualTo(1.0));
      });
    });

    group('initializeCard', () {
      test('creates a card with new state and default values', () {
        final cardData = SrsScheduler.initializeCard(
          vocabularyId: 'vocab-1',
          userId: 'user-1',
        );

        expect(cardData.vocabularyId, equals('vocab-1'));
        expect(cardData.userId, equals('user-1'));
        expect(cardData.state, equals(CardState.newCard));
        expect(cardData.stability, equals(0.0));
        expect(cardData.difficulty, equals(0.0));
        expect(cardData.reps, equals(0));
        expect(cardData.lapses, equals(0));
        expect(cardData.isLeech, isFalse);
      });
    });

    group('constants', () {
      test('has correct leech threshold', () {
        expect(SrsScheduler.leechThreshold, equals(8));
      });

      test('has correct max interval', () {
        expect(SrsScheduler.maxIntervalDays, equals(365));
      });
    });
  });
}

/// Helper to create test learning cards
LearningCard _createTestCard({
  required String id,
  required String vocabularyId,
  required int state,
  required DateTime due,
  required double stability,
  required double difficulty,
  required int reps,
  required int lapses,
  bool isLeech = false,
  DateTime? lastReview,
}) {
  final now = DateTime.now().toUtc();
  return LearningCard(
    id: id,
    userId: 'test-user',
    vocabularyId: vocabularyId,
    state: state,
    due: due,
    stability: stability,
    difficulty: difficulty,
    reps: reps,
    lapses: lapses,
    isLeech: isLeech,
    lastReview: lastReview,
    createdAt: now,
    updatedAt: now,
    deletedAt: null,
    lastSyncedAt: null,
    isPendingSync: false,
    version: 1,
  );
}
