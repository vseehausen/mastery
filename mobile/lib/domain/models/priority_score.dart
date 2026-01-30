/// Value object for priority score calculation
class PriorityScore {
  PriorityScore({
    required this.overdueDays,
    required this.retrievability,
    required this.lapseWeight,
  });

  /// Create a priority score from card data
  factory PriorityScore.fromCard({
    required DateTime due,
    required double stability,
    required int lapses,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now().toUtc();

    // Calculate overdue days
    final overdueDays = currentTime.difference(due).inDays.clamp(0, 365);

    // Calculate retrievability (simplified FSRS formula)
    double retrievability;
    if (stability <= 0) {
      retrievability = 0.5;
    } else {
      final daysOverdue = currentTime.difference(due).inDays.toDouble();
      if (daysOverdue <= 0) {
        retrievability = 0.9;
      } else {
        retrievability =
            0.9 * (1.0 - (daysOverdue / (stability + 1)).clamp(0.0, 1.0));
      }
    }

    // Calculate lapse weight
    final lapseWeight = 1 + (lapses / 20);

    return PriorityScore(
      overdueDays: overdueDays,
      retrievability: retrievability,
      lapseWeight: lapseWeight,
    );
  }

  /// Days overdue (clamped to 0-365)
  final int overdueDays;

  /// Current retrievability (0.0 to 1.0)
  final double retrievability;

  /// Weight based on lapses (1 + lapses/20)
  final double lapseWeight;

  /// Compute the priority score
  /// Higher score = more urgent
  double get score => overdueDays * (1 - retrievability) * lapseWeight;

  /// Compare two priority scores
  int compareTo(PriorityScore other) {
    return score.compareTo(other.score);
  }

  @override
  String toString() {
    return 'PriorityScore(overdue: $overdueDays, R: ${retrievability.toStringAsFixed(2)}, lapseW: ${lapseWeight.toStringAsFixed(2)}, score: ${score.toStringAsFixed(2)})';
  }
}
