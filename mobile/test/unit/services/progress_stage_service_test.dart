import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/data/services/progress_stage_service.dart';
import 'package:mastery/domain/models/learning_card.dart';
import 'package:mastery/domain/models/progress_stage.dart';

void main() {
  group('ProgressStageService', () {
    late ProgressStageService service;

    setUp(() {
      service = ProgressStageService();
    });

    group('Captured stage', () {
      test('returns Captured when no card exists', () {
        final stage = service.calculateStage(
          card: null,
          nonTranslationSuccessCount: 0,
        );

        expect(stage, ProgressStage.captured);
      });

      test('returns Captured for card with 0 reps (edge case)', () {
        final card = _createCard(reps: 0, stability: 0, lapses: 0, state: 0);

        final stage = service.calculateStage(
          card: card,
          nonTranslationSuccessCount: 0,
        );

        expect(stage, ProgressStage.captured);
      });
    });

    group('Practicing stage', () {
      test('returns Practicing for card with 1 rep', () {
        final card = _createCard(
          reps: 1,
          stability: 0.5,
          lapses: 0,
          state: 1, // learning state
        );

        final stage = service.calculateStage(
          card: card,
          nonTranslationSuccessCount: 0,
        );

        expect(stage, ProgressStage.practicing);
      });

      test('returns Practicing for card with low stability', () {
        final card = _createCard(
          reps: 2,
          stability: 0.8, // < 1.0
          lapses: 0,
          state: 2,
        );

        final stage = service.calculateStage(
          card: card,
          nonTranslationSuccessCount: 0,
        );

        expect(stage, ProgressStage.practicing);
      });

      test('returns Practicing for card with insufficient reps', () {
        final card = _createCard(
          reps: 2, // < 3
          stability: 2.0,
          lapses: 0,
          state: 2,
        );

        final stage = service.calculateStage(
          card: card,
          nonTranslationSuccessCount: 0,
        );

        expect(stage, ProgressStage.practicing);
      });

      test('returns Practicing for card with too many lapses', () {
        final card = _createCard(
          reps: 5,
          stability: 2.0,
          lapses: 3, // > 2
          state: 2,
        );

        final stage = service.calculateStage(
          card: card,
          nonTranslationSuccessCount: 0,
        );

        expect(stage, ProgressStage.practicing);
      });

      test('returns Practicing for card not in review state', () {
        final card = _createCard(
          reps: 5,
          stability: 2.0,
          lapses: 1,
          state: 3, // relearning, not review
        );

        final stage = service.calculateStage(
          card: card,
          nonTranslationSuccessCount: 0,
        );

        expect(stage, ProgressStage.practicing);
      });
    });

    group('Stabilizing stage', () {
      test('returns Stabilizing for card meeting all criteria', () {
        final card = _createCard(reps: 3, stability: 1.0, lapses: 2, state: 2);

        final stage = service.calculateStage(
          card: card,
          nonTranslationSuccessCount: 0,
        );

        expect(stage, ProgressStage.stabilizing);
      });

      test('returns Stabilizing with higher stability', () {
        final card = _createCard(reps: 5, stability: 10.0, lapses: 1, state: 2);

        final stage = service.calculateStage(
          card: card,
          nonTranslationSuccessCount: 0,
        );

        expect(stage, ProgressStage.stabilizing);
      });

      test('returns Stabilizing at minimum thresholds', () {
        final card = _createCard(
          reps: 3, // minimum
          stability: 1.0, // minimum
          lapses: 2, // maximum allowed
          state: 2,
        );

        final stage = service.calculateStage(
          card: card,
          nonTranslationSuccessCount: 0,
        );

        expect(stage, ProgressStage.stabilizing);
      });
    });

    group('Active stage', () {
      test('returns Active for card with non-translation success', () {
        final card = _createCard(reps: 3, stability: 1.0, lapses: 2, state: 2);

        final stage = service.calculateStage(
          card: card,
          nonTranslationSuccessCount: 1,
        );

        expect(stage, ProgressStage.active);
      });

      test('returns Active with multiple non-translation successes', () {
        final card = _createCard(reps: 5, stability: 10.0, lapses: 0, state: 2);

        final stage = service.calculateStage(
          card: card,
          nonTranslationSuccessCount: 5,
        );

        expect(stage, ProgressStage.active);
      });

      test('returns Stabilizing without non-translation success', () {
        final card = _createCard(reps: 3, stability: 1.0, lapses: 2, state: 2);

        final stage = service.calculateStage(
          card: card,
          nonTranslationSuccessCount: 0, // no non-translation success
        );

        expect(stage, ProgressStage.stabilizing); // not Active
      });
    });

    group('Mastered stage', () {
      test('returns Mastered for card meeting all criteria', () {
        final card = _createCard(
          reps: 12,
          stability: 90.0,
          lapses: 1,
          state: 2,
        );

        final stage = service.calculateStage(
          card: card,
          nonTranslationSuccessCount: 1,
        );

        expect(stage, ProgressStage.mastered);
      });

      test('returns Mastered with higher stats', () {
        final card = _createCard(
          reps: 20,
          stability: 150.0,
          lapses: 0,
          state: 2,
        );

        final stage = service.calculateStage(
          card: card,
          nonTranslationSuccessCount: 5,
        );

        expect(stage, ProgressStage.mastered);
      });

      test('returns Mastered at minimum thresholds', () {
        final card = _createCard(
          reps: 12, // minimum
          stability: 90.0, // minimum
          lapses: 1, // maximum allowed
          state: 2,
        );

        final stage = service.calculateStage(
          card: card,
          nonTranslationSuccessCount: 0,
        );

        expect(stage, ProgressStage.mastered);
      });

      test('returns Active when stability too low for Mastered', () {
        final card = _createCard(
          reps: 12,
          stability: 89.9, // just below threshold
          lapses: 1,
          state: 2,
        );

        final stage = service.calculateStage(
          card: card,
          nonTranslationSuccessCount: 1,
        );

        expect(stage, ProgressStage.active); // not Mastered
      });

      test('returns Active when reps too low for Mastered', () {
        final card = _createCard(
          reps: 11, // just below threshold
          stability: 90.0,
          lapses: 1,
          state: 2,
        );

        final stage = service.calculateStage(
          card: card,
          nonTranslationSuccessCount: 1,
        );

        expect(stage, ProgressStage.active); // not Mastered
      });

      test('returns Active when too many lapses for Mastered', () {
        final card = _createCard(
          reps: 12,
          stability: 90.0,
          lapses: 2, // too many
          state: 2,
        );

        final stage = service.calculateStage(
          card: card,
          nonTranslationSuccessCount: 1,
        );

        expect(stage, ProgressStage.active); // not Mastered
      });
    });

    group('Regression paths', () {
      test('regresses from Active to Practicing with high lapses', () {
        final card = _createCard(
          reps: 5,
          stability: 2.0,
          lapses: 3, // too many
          state: 2,
        );

        final stage = service.calculateStage(
          card: card,
          nonTranslationSuccessCount: 1,
        );

        expect(stage, ProgressStage.practicing);
      });

      test(
        'regresses from Stabilizing to Practicing when not in review state',
        () {
          final card = _createCard(
            reps: 5,
            stability: 2.0,
            lapses: 1,
            state: 3, // relearning
          );

          final stage = service.calculateStage(
            card: card,
            nonTranslationSuccessCount: 0,
          );

          expect(stage, ProgressStage.practicing);
        },
      );

      test('regresses from Stabilizing to Practicing with low stability', () {
        final card = _createCard(
          reps: 5,
          stability: 0.9, // just below threshold
          lapses: 1,
          state: 2,
        );

        final stage = service.calculateStage(
          card: card,
          nonTranslationSuccessCount: 0,
        );

        expect(stage, ProgressStage.practicing);
      });
    });

    group('Edge cases', () {
      test('handles very high stability', () {
        final card = _createCard(
          reps: 20,
          stability: 365.0, // 1 year
          lapses: 0,
          state: 2,
        );

        final stage = service.calculateStage(
          card: card,
          nonTranslationSuccessCount: 5,
        );

        expect(stage, ProgressStage.mastered);
      });

      test('handles zero stability', () {
        final card = _createCard(reps: 1, stability: 0.0, lapses: 0, state: 1);

        final stage = service.calculateStage(
          card: card,
          nonTranslationSuccessCount: 0,
        );

        expect(stage, ProgressStage.practicing);
      });

      test('handles fractional stability at boundary', () {
        final card = _createCard(
          reps: 3,
          stability: 1.00001, // just above 1.0
          lapses: 2,
          state: 2,
        );

        final stage = service.calculateStage(
          card: card,
          nonTranslationSuccessCount: 0,
        );

        expect(stage, ProgressStage.stabilizing);
      });
    });

    group('Performance', () {
      test('calculates stage in under 50ms', () {
        final card = _createCard(reps: 5, stability: 10.0, lapses: 1, state: 2);

        final stopwatch = Stopwatch()..start();
        service.calculateStage(card: card, nonTranslationSuccessCount: 1);
        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(50));
      });

      test('handles bulk calculations efficiently', () {
        final cards = List.generate(
          100,
          (i) => _createCard(
            reps: i % 10,
            stability: (i % 20).toDouble(),
            lapses: i % 3,
            state: 2,
          ),
        );

        final stopwatch = Stopwatch()..start();
        for (var i = 0; i < cards.length; i++) {
          service.calculateStage(
            card: cards[i],
            nonTranslationSuccessCount: i % 2,
          );
        }
        stopwatch.stop();

        // Average should be well under 50ms per calculation
        final averageMs = stopwatch.elapsedMilliseconds / cards.length;
        expect(averageMs, lessThan(5.0));
      });
    });
  });
}

/// Helper to create test learning cards
LearningCardModel _createCard({
  required int reps,
  required double stability,
  required int lapses,
  required int state,
}) {
  final now = DateTime.now();
  return LearningCardModel(
    id: 'test-card-id',
    userId: 'test-user-id',
    vocabularyId: 'test-vocab-id',
    state: state,
    due: now.add(Duration(days: stability.toInt())),
    stability: stability,
    difficulty: 5.0,
    reps: reps,
    lapses: lapses,
    lastReview: reps > 0 ? now.subtract(const Duration(hours: 1)) : null,
    isLeech: false,
    createdAt: now.subtract(const Duration(days: 30)),
    updatedAt: now,
  );
}
