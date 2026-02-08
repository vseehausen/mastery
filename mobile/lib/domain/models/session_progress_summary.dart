import 'package:mastery/domain/models/progress_stage.dart';
import 'package:mastery/domain/models/stage_transition.dart';

/// Summary of all stage transitions that occurred during a completed learning session.
///
/// Aggregates transitions by type for compact display in the session recap.
/// Provides counts for each stage and methods for formatting the summary.
class SessionProgressSummary {
  /// All stage transitions that occurred during the session.
  final List<StageTransition> transitions;

  const SessionProgressSummary(this.transitions);

  /// Creates an empty summary with no transitions.
  const SessionProgressSummary.empty() : transitions = const [];

  /// Count of words that reached Stabilizing stage.
  int get stabilizingCount => transitions
      .where((t) => t.toStage == ProgressStage.stabilizing)
      .length;

  /// Count of words that reached Active stage.
  int get activeCount =>
      transitions.where((t) => t.toStage == ProgressStage.active).length;

  /// Count of words that reached Mastered stage.
  int get masteredCount =>
      transitions.where((t) => t.toStage == ProgressStage.mastered).length;

  /// Returns true if any transitions occurred during the session.
  bool get hasTransitions => transitions.isNotEmpty;

  /// Returns true if any rare achievements (Active or Mastered) occurred.
  bool get hasRareAchievements =>
      transitions.any((t) => t.isRareAchievement);

  /// Converts the summary to a human-readable display string.
  ///
  /// Format: "2 words → Stabilizing • 1 word → Active"
  /// Returns empty string if no transitions occurred.
  String toDisplayString() {
    if (!hasTransitions) return '';

    final parts = <String>[];

    if (stabilizingCount > 0) {
      final wordLabel = stabilizingCount == 1 ? 'word' : 'words';
      parts.add('$stabilizingCount $wordLabel → Stabilizing');
    }

    if (activeCount > 0) {
      final wordLabel = activeCount == 1 ? 'word' : 'words';
      parts.add('$activeCount $wordLabel → Active');
    }

    if (masteredCount > 0) {
      final wordLabel = masteredCount == 1 ? 'word' : 'words';
      parts.add('$masteredCount $wordLabel → Mastered');
    }

    return parts.join(' • ');
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SessionProgressSummary &&
        _listEquals(other.transitions, transitions);
  }

  @override
  int get hashCode => transitions.hashCode;

  /// Helper method for list equality comparison.
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
