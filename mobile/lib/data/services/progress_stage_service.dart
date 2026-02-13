import 'package:flutter/foundation.dart' show debugPrint;
import 'package:mastery/domain/models/learning_card.dart';
import 'package:mastery/domain/models/progress_stage.dart';

/// Service for calculating progress stages based on learning metrics.
///
/// All stage calculations are deterministic and based solely on:
/// - FSRS metrics (stability, reps, lapses, state)
/// - Review history (non-translation success count)
///
/// No randomness or ML is involved. Stages are computed client-side.
class ProgressStageService {
  /// Calculates the current progress stage for a vocabulary word.
  ///
  /// Parameters:
  /// - [card]: The learning card with FSRS metrics (null if word not reviewed yet)
  /// - [nonTranslationSuccessCount]: Count of successful non-translation reviews
  /// - [lapsesLast8]: Lapse count in the last 8 reviews (windowed); falls back to card.lapses if null
  /// - [lapsesLast12]: Lapse count in the last 12 reviews (windowed); falls back to card.lapses if null
  /// - [hardMethodSuccessCount]: Count of successful disambiguation reviews
  ///
  /// Returns the appropriate [ProgressStage] based on deterministic rules.
  ///
  /// Stage logic:
  /// - No card → Captured (word exists but not reviewed)
  /// - reps >= 1 → Practicing (first review completed)
  /// - stability >= 1.0 && lapsesLast8 <= 2 && state == 2 → Stabilizing
  /// - Stabilizing criteria + nonTranslationSuccessCount >= 1 → Known
  /// - stability >= 90 && lapsesLast12 <= 1 && state == 2 && hardMethodSuccessCount >= 1 → Mastered
  ProgressStage calculateStage({
    required LearningCardModel? card,
    required int nonTranslationSuccessCount,
    int? lapsesLast8,
    int? lapsesLast12,
    int hardMethodSuccessCount = 0,
  }) {
    final stopwatch = Stopwatch()..start();

    try {
      // No card yet → New (word exists in vocabulary but not reviewed)
      if (card == null) {
        return ProgressStage.captured;
      }

      final effectiveLapsesLast8 = lapsesLast8 ?? card.lapses;
      final effectiveLapsesLast12 = lapsesLast12 ?? card.lapses;

      // Check for Mastered (highest tier, most restrictive)
      // Requires: exceptional stability (90+ days), windowed lapses (≤1 in last 12),
      // review state, and at least one hard method (disambiguation) success
      if (card.stability >= 90.0 &&
          effectiveLapsesLast12 <= 1 &&
          card.state == 2 &&
          hardMethodSuccessCount >= 1) {
        return ProgressStage.mastered;
      }

      // Check for Known (requires non-translation success + stabilizing criteria)
      // Non-translation success = retrieved from definition/synonym/context cues (production recall)
      if (card.stability >= 1.0 &&
          effectiveLapsesLast8 <= 2 &&
          card.state == 2 &&
          nonTranslationSuccessCount >= 1) {
        return ProgressStage.known;
      }

      // Check for Stabilizing (memory consolidating, graduated from initial learning)
      // Requires: moderate stability (1+ days), low windowed lapses (≤2 in last 8), review state
      if (card.stability >= 1.0 &&
          effectiveLapsesLast8 <= 2 &&
          card.state == 2) {
        return ProgressStage.stabilizing;
      }

      // Check for Practicing (at least one review completed)
      // Any card with reps >= 1 is being actively practiced
      if (card.reps >= 1) {
        return ProgressStage.practicing;
      }

      // Fallback: Card exists but no reviews yet → New
      // Normal state for newly captured words before first review
      return ProgressStage.captured;
    } finally {
      stopwatch.stop();
      if (stopwatch.elapsedMilliseconds > 50) {
        debugPrint(
          '⚠️ ProgressStageService: Stage calculation took ${stopwatch.elapsedMilliseconds}ms (>50ms threshold)',
        );
      }
    }
  }
}
