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

    group('New stage', () {
      test('returns New when no card exists', () {
        final stage = service.calculateStage(
          card: null,
          nonTranslationSuccessCount: 0,
        );

        expect(stage, ProgressStage.captured);
      });

      test('returns New for card with 0 reps (edge case)', () {
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
          reps: 1, // reps no longer required for stabilizing
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

    group('Known stage', () {
      test('returns Known for card with non-translation success', () {
        final card = _createCard(reps: 3, stability: 1.0, lapses: 2, state: 2);

        final stage = service.calculateStage(
          card: card,
          nonTranslationSuccessCount: 1,
        );

        expect(stage, ProgressStage.known);
      });

      test('returns Known with multiple non-translation successes', () {
        final card = _createCard(reps: 5, stability: 10.0, lapses: 0, state: 2);

        final stage = service.calculateStage(
          card: card,
          nonTranslationSuccessCount: 5,
        );

        expect(stage, ProgressStage.known);
      });

      test('returns Stabilizing without non-translation success', () {
        final card = _createCard(reps: 3, stability: 1.0, lapses: 2, state: 2);

        final stage = service.calculateStage(
          card: card,
          nonTranslationSuccessCount: 0, // no non-translation success
        );

        expect(stage, ProgressStage.stabilizing); // not Known
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
          hardMethodSuccessCount: 1,
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
          hardMethodSuccessCount: 3,
        );

        expect(stage, ProgressStage.mastered);
      });

      test('returns Known when stability too low for Mastered', () {
        final card = _createCard(
          reps: 12,
          stability: 89.9, // just below threshold
          lapses: 1,
          state: 2,
        );

        final stage = service.calculateStage(
          card: card,
          nonTranslationSuccessCount: 1,
          hardMethodSuccessCount: 1,
        );

        expect(stage, ProgressStage.known); // not Mastered
      });

      test('returns Known when too many lapses for Mastered', () {
        final card = _createCard(
          reps: 12,
          stability: 90.0,
          lapses: 2, // too many
          state: 2,
        );

        final stage = service.calculateStage(
          card: card,
          nonTranslationSuccessCount: 1,
          hardMethodSuccessCount: 1,
        );

        expect(stage, ProgressStage.known); // not Mastered
      });

      test('returns Known when hardMethodSuccessCount is 0', () {
        final card = _createCard(
          reps: 12,
          stability: 90.0,
          lapses: 0,
          state: 2,
        );

        final stage = service.calculateStage(
          card: card,
          nonTranslationSuccessCount: 1,
          hardMethodSuccessCount: 0, // no disambiguation success
        );

        expect(stage, ProgressStage.known); // not Mastered
      });
    });

    group('Regression paths', () {
      test('regresses from Known to Practicing with high lapses', () {
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
          hardMethodSuccessCount: 1,
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

    group('Aligned stage thresholds (windowed lapses)', () {
      test('Mastered with windowed lapses: lifetime=5 but lapsesLast12=0', () {
        final card = _createCard(
          reps: 15,
          stability: 100.0,
          lapses: 5, // lifetime high
          state: 2,
        );

        final stage = service.calculateStage(
          card: card,
          nonTranslationSuccessCount: 3,
          lapsesLast12: 0, // windowed low
          hardMethodSuccessCount: 1,
        );

        expect(stage, ProgressStage.mastered);
      });

      test('Mastered blocked by hardMethodSuccess=0', () {
        final card = _createCard(
          reps: 15,
          stability: 100.0,
          lapses: 0,
          state: 2,
        );

        final stage = service.calculateStage(
          card: card,
          nonTranslationSuccessCount: 3,
          lapsesLast12: 0,
          hardMethodSuccessCount: 0,
        );

        expect(stage, ProgressStage.known);
      });

      test('Mastered blocked by lapsesLast12=2', () {
        final card = _createCard(
          reps: 15,
          stability: 100.0,
          lapses: 0,
          state: 2,
        );

        final stage = service.calculateStage(
          card: card,
          nonTranslationSuccessCount: 3,
          lapsesLast12: 2,
          hardMethodSuccessCount: 1,
        );

        expect(stage, ProgressStage.known);
      });

      test('Mastered allowed at lapsesLast12=1', () {
        final card = _createCard(
          reps: 15,
          stability: 100.0,
          lapses: 0,
          state: 2,
        );

        final stage = service.calculateStage(
          card: card,
          nonTranslationSuccessCount: 3,
          lapsesLast12: 1,
          hardMethodSuccessCount: 1,
        );

        expect(stage, ProgressStage.mastered);
      });

      test('Mastered: reps no longer required', () {
        final card = _createCard(
          reps: 5, // low reps — used to block mastered
          stability: 90.0,
          lapses: 0,
          state: 2,
        );

        final stage = service.calculateStage(
          card: card,
          nonTranslationSuccessCount: 1,
          lapsesLast12: 0,
          hardMethodSuccessCount: 1,
        );

        expect(stage, ProgressStage.mastered);
      });

      test('Stabilizing without reps requirement', () {
        final card = _createCard(
          reps: 1, // low reps — used to block stabilizing
          stability: 1.0,
          lapses: 0,
          state: 2,
        );

        final stage = service.calculateStage(
          card: card,
          nonTranslationSuccessCount: 0,
          lapsesLast8: 2,
        );

        expect(stage, ProgressStage.stabilizing);
      });

      test('Stabilizing blocked by lapsesLast8=3', () {
        final card = _createCard(
          reps: 5,
          stability: 2.0,
          lapses: 0,
          state: 2,
        );

        final stage = service.calculateStage(
          card: card,
          nonTranslationSuccessCount: 0,
          lapsesLast8: 3,
        );

        expect(stage, ProgressStage.practicing);
      });

      test('Known: stabilizing criteria + nonTransSuccess=1', () {
        final card = _createCard(
          reps: 2,
          stability: 1.5,
          lapses: 0,
          state: 2,
        );

        final stage = service.calculateStage(
          card: card,
          nonTranslationSuccessCount: 1,
          lapsesLast8: 1,
        );

        expect(stage, ProgressStage.known);
      });

      test('Fallback: no windowed params uses lifetime lapses', () {
        final card = _createCard(
          reps: 5,
          stability: 2.0,
          lapses: 1, // lifetime lapses used as fallback
          state: 2,
        );

        final stage = service.calculateStage(
          card: card,
          nonTranslationSuccessCount: 0,
          // no lapsesLast8/12 passed → falls back to card.lapses
        );

        expect(stage, ProgressStage.stabilizing);
      });

      test('Mastered fallback: no windowed params, lifetime lapses=0', () {
        final card = _createCard(
          reps: 15,
          stability: 100.0,
          lapses: 0,
          state: 2,
        );

        final stage = service.calculateStage(
          card: card,
          nonTranslationSuccessCount: 3,
          hardMethodSuccessCount: 1,
          // no lapsesLast12 → falls back to card.lapses=0
        );

        expect(stage, ProgressStage.mastered);
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
