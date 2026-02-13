import '../../core/app_defaults.dart';
import 'srs_scheduler.dart';

/// Maps MC card response time + correctness to an FSRS rating.
///
/// Fast correct → Easy, normal correct → Good, slow correct → Hard,
/// incorrect → Again.
class ResponseTimeRating {
  const ResponseTimeRating({
    this.fastThresholdMs = AppDefaults.mcFastThresholdMs,
    this.slowThresholdMs = AppDefaults.mcSlowThresholdMs,
  });

  final int fastThresholdMs;
  final int slowThresholdMs;

  int rate(int responseTimeMs, {required bool isCorrect}) {
    if (!isCorrect) return ReviewRating.again;
    if (responseTimeMs < fastThresholdMs) return ReviewRating.easy;
    if (responseTimeMs > slowThresholdMs) return ReviewRating.hard;
    return ReviewRating.good;
  }
}
