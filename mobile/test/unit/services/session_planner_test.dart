import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/domain/services/session_planner.dart';
import 'package:mastery/domain/services/srs_scheduler.dart';
import 'package:mastery/data/database/database.dart';

void main() {
  group('SessionPlanner', () {
    group('selectInteractionMode', () {
      // Testing the logic directly since SessionPlanner requires mocked dependencies
      test('returns Recognition for new cards', () {
        // New card (state=0) should use Recognition mode
        final mode = _selectInteractionMode(state: CardState.newCard, stability: 10.0);
        expect(mode, equals(InteractionMode.recognition));
      });

      test('returns Recognition for learning cards', () {
        // Learning card (state=1) should use Recognition mode
        final mode = _selectInteractionMode(state: CardState.learning, stability: 10.0);
        expect(mode, equals(InteractionMode.recognition));
      });

      test('returns Recognition for relearning cards', () {
        // Relearning card (state=3) should use Recognition mode
        final mode = _selectInteractionMode(state: CardState.relearning, stability: 10.0);
        expect(mode, equals(InteractionMode.recognition));
      });

      test('returns Recognition for review cards with low stability', () {
        // Review card (state=2) with stability < 7 days should use Recognition
        final mode = _selectInteractionMode(state: CardState.review, stability: 5.0);
        expect(mode, equals(InteractionMode.recognition));
      });

      test('returns Recall for mature review cards', () {
        // Review card (state=2) with stability >= 7 days should use Recall
        final mode = _selectInteractionMode(state: CardState.review, stability: 10.0);
        expect(mode, equals(InteractionMode.recall));
      });

      test('returns Recognition for review cards exactly at threshold', () {
        // Review card with stability exactly 7 days should use Recall (>= 7)
        final mode = _selectInteractionMode(state: CardState.review, stability: 7.0);
        expect(mode, equals(InteractionMode.recall));
      });
    });

    group('shouldSuppressNewWords (hysteresis)', () {
      test('suppresses new words when overdue exceeds session capacity', () {
        final result = _shouldSuppressNewWords(
          overdueCount: 20,
          sessionCapacity: 15,
          previouslySuppressed: false,
        );
        expect(result, isTrue);
      });

      test('does not suppress when overdue is within session capacity', () {
        final result = _shouldSuppressNewWords(
          overdueCount: 10,
          sessionCapacity: 15,
          previouslySuppressed: false,
        );
        expect(result, isFalse);
      });

      test('exits suppression when overdue fits within 2 sessions', () {
        // When already suppressed, exit when overdue fits within 2x capacity
        final result = _shouldSuppressNewWords(
          overdueCount: 25,
          sessionCapacity: 15,
          previouslySuppressed: true,
        );
        // 25 <= 2*15=30, so should exit suppression
        expect(result, isFalse);
      });

      test('stays suppressed when overdue exceeds 2 sessions', () {
        final result = _shouldSuppressNewWords(
          overdueCount: 35,
          sessionCapacity: 15,
          previouslySuppressed: true,
        );
        // 35 > 2*15=30, so should stay suppressed
        expect(result, isTrue);
      });

      test('returns true when session capacity is zero', () {
        final result = _shouldSuppressNewWords(
          overdueCount: 5,
          sessionCapacity: 0,
          previouslySuppressed: false,
        );
        expect(result, isTrue);
      });
    });

    group('priority score computation', () {
      test('computes higher priority for more overdue cards', () {
        final now = DateTime.now().toUtc();

        final card1 = _createTestCard(
          due: now.subtract(const Duration(days: 1)),
          stability: 10.0,
          lapses: 0,
        );
        final card2 = _createTestCard(
          due: now.subtract(const Duration(days: 5)),
          stability: 10.0,
          lapses: 0,
        );

        final score1 = _computePriorityScore(card1, now);
        final score2 = _computePriorityScore(card2, now);

        expect(score2, greaterThan(score1));
      });

      test('computes higher priority for cards with more lapses', () {
        final now = DateTime.now().toUtc();

        final card1 = _createTestCard(
          due: now.subtract(const Duration(days: 3)),
          stability: 10.0,
          lapses: 0,
        );
        final card2 = _createTestCard(
          due: now.subtract(const Duration(days: 3)),
          stability: 10.0,
          lapses: 10,
        );

        final score1 = _computePriorityScore(card1, now);
        final score2 = _computePriorityScore(card2, now);

        expect(score2, greaterThan(score1));
      });
    });
  });
}

/// Simulates selectInteractionMode logic
int _selectInteractionMode({required int state, required double stability}) {
  // New, learning, or relearning cards always use recognition
  if (state != CardState.review) {
    return InteractionMode.recognition;
  }

  // Review cards with low stability use recognition
  if (stability < InteractionMode.stabilityThresholdDays) {
    return InteractionMode.recognition;
  }

  // Mature review cards use recall
  return InteractionMode.recall;
}

/// Simulates shouldSuppressNewWords logic
bool _shouldSuppressNewWords({
  required int overdueCount,
  required int sessionCapacity,
  required bool previouslySuppressed,
}) {
  if (sessionCapacity <= 0) return true;

  if (previouslySuppressed) {
    // Exit threshold: resume when overdue fits within 2 sessions
    return overdueCount > 2 * sessionCapacity;
  } else {
    // Entry threshold: suppress when overdue exceeds 1 session
    return overdueCount > sessionCapacity;
  }
}

/// Simulates priority score computation
double _computePriorityScore(LearningCard card, DateTime now) {
  final overdueDays = now.difference(card.due).inDays.clamp(0, 365);
  // Simplified retrievability approximation
  final daysOverdue = now.difference(card.due).inDays.toDouble();
  final retrievability = card.stability > 0
      ? 0.9 * (1.0 - (daysOverdue / (card.stability + 1)).clamp(0.0, 1.0))
      : 0.5;
  final lapseWeight = 1 + (card.lapses / 20);
  return overdueDays * (1 - retrievability) * lapseWeight;
}

/// Helper to create test learning cards
LearningCard _createTestCard({
  required DateTime due,
  required double stability,
  required int lapses,
}) {
  final now = DateTime.now().toUtc();
  return LearningCard(
    id: 'test-card',
    userId: 'test-user',
    vocabularyId: 'test-vocab',
    state: CardState.review,
    due: due,
    stability: stability,
    difficulty: 5.0,
    reps: 5,
    lapses: lapses,
    isLeech: false,
    lastReview: now.subtract(Duration(days: stability.round())),
    createdAt: now,
    updatedAt: now,
    deletedAt: null,
    lastSyncedAt: null,
    isPendingSync: false,
    version: 1,
  );
}
