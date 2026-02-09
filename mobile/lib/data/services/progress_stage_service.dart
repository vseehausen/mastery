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
  ///
  /// Returns the appropriate [ProgressStage] based on deterministic rules.
  ///
  /// Stage logic:
  /// - No card → Captured (word exists but not reviewed)
  /// - reps >= 1 → Practicing (first review completed)
  /// - stability >= 1.0 && reps >= 3 && lapses <= 2 && state == 2 → Stabilizing
  /// - Stabilizing criteria + nonTranslationSuccessCount >= 1 → Active
  /// - stability >= 90 && reps >= 12 && lapses <= 1 && state == 2 → Mastered
  ProgressStage calculateStage({
    required LearningCardModel? card,
    required int nonTranslationSuccessCount,
  }) {
    final stopwatch = Stopwatch()..start();

    try {
      // No card yet → Captured (word exists in vocabulary but not reviewed)
      if (card == null) {
        return ProgressStage.captured;
      }

      // Check for Mastered (highest tier, most restrictive)
      // Requires: exceptional stability (90+ days), many reps (12+), minimal lapses (0-1)
      if (card.stability >= 90.0 &&
          card.reps >= 12 &&
          card.lapses <= 1 &&
          card.state == 2) {
        return ProgressStage.mastered;
      }

      // Check for Active (requires non-translation success + stabilizing criteria)
      // Non-translation success = retrieved from definition/synonym/context cues (production recall)
      if (card.stability >= 1.0 &&
          card.reps >= 3 &&
          card.lapses <= 2 &&
          card.state == 2 &&
          nonTranslationSuccessCount >= 1) {
        return ProgressStage.active;
      }

      // Check for Stabilizing (memory consolidating, graduated from initial learning)
      // Requires: moderate stability (1+ days), multiple successful reviews (3+), low lapses (≤2)
      if (card.stability >= 1.0 &&
          card.reps >= 3 &&
          card.lapses <= 2 &&
          card.state == 2) {
        return ProgressStage.stabilizing;
      }

      // Check for Practicing (at least one review completed)
      // Any card with reps >= 1 is being actively practiced
      if (card.reps >= 1) {
        return ProgressStage.practicing;
      }

      // Fallback: Card exists but no reviews yet → Captured
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
