import '../../data/repositories/review_log_repository.dart';

/// Service for computing telemetry data (time-per-item estimation)
class TelemetryService {
  TelemetryService(this._reviewLogRepository);

  final ReviewLogRepository _reviewLogRepository;

  /// Default time per item for new users (in seconds)
  static const defaultSecondsPerItem = 15.0;

  /// Minimum reviews needed before using actual telemetry
  static const minReviewsForTelemetry = 10;

  /// Rolling window size for averaging
  static const rollingWindowSize = 50;

  /// Get estimated seconds per item for a user
  /// Uses rolling average from review logs, or default for new users
  Future<double> getEstimatedSecondsPerItem(String userId) async {
    final reviewCount = await _reviewLogRepository.getReviewCount(userId);

    // Use default for new users without enough data
    if (reviewCount < minReviewsForTelemetry) {
      return defaultSecondsPerItem;
    }

    // Get average response time in milliseconds
    final avgMs = await _reviewLogRepository.getAverageResponseTime(
      userId,
      windowSize: rollingWindowSize,
    );

    // Convert to seconds
    return avgMs / 1000.0;
  }

  /// Estimate how many items can fit in a given time budget
  Future<int> estimateSessionCapacity({
    required String userId,
    required int timeMinutes,
  }) async {
    final secondsPerItem = await getEstimatedSecondsPerItem(userId);
    final totalSeconds = timeMinutes * 60.0;

    return (totalSeconds / secondsPerItem).floor();
  }

  /// Estimate total duration for a given number of items
  Future<int> estimateSessionDuration({
    required String userId,
    required int itemCount,
  }) async {
    final secondsPerItem = await getEstimatedSecondsPerItem(userId);
    return (itemCount * secondsPerItem).round();
  }
}
