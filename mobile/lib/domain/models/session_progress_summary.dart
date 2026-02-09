import 'package:mastery/domain/models/progress_stage.dart';
import 'package:mastery/domain/models/stage_transition.dart';

/// Summary of all stage transitions that occurred during a completed learning session.
///
/// Aggregates transitions by type for compact display in the session recap.
/// Provides counts for each stage and methods for formatting the summary.
class SessionProgressSummary {
  const SessionProgressSummary(this.transitions);

  /// Creates an empty summary with no transitions.
  const SessionProgressSummary.empty() : transitions = const [];

  /// All stage transitions that occurred during the session.
  final List<StageTransition> transitions;

  /// Count of words that reached Stabilizing stage.
  int get stabilizingCount =>
      transitions.where((t) => t.toStage == ProgressStage.stabilizing).length;

  /// Count of words that reached Known stage.
  int get knownCount =>
      transitions.where((t) => t.toStage == ProgressStage.known).length;

  /// Count of words that reached Mastered stage.
  int get masteredCount =>
      transitions.where((t) => t.toStage == ProgressStage.mastered).length;

  /// Returns true if any transitions occurred during the session.
  bool get hasTransitions => transitions.isNotEmpty;

  /// Returns true if any rare achievements (Known or Mastered) occurred.
  bool get hasRareAchievements => transitions.any((t) => t.isRareAchievement);

  /// Converts the summary to a human-readable display string.
  ///
  /// Format: "2 words moved to Stabilizing • 1 word moved to Known"
  /// Returns empty string if no transitions occurred.
  String toDisplayString() {
    if (!hasTransitions) return '';

    final parts = <String>[];

    if (stabilizingCount > 0) {
      final wordLabel = stabilizingCount == 1 ? 'word' : 'words';
      parts.add('$stabilizingCount $wordLabel moved to Stabilizing');
    }

    if (knownCount > 0) {
      final wordLabel = knownCount == 1 ? 'word' : 'words';
      parts.add('$knownCount $wordLabel moved to Known');
    }

    if (masteredCount > 0) {
      final wordLabel = masteredCount == 1 ? 'word' : 'words';
      parts.add('$masteredCount $wordLabel moved to Mastered');
    }

    return parts.join(' • ');
  }

  /// Gets the word text for a specific stage when count is 1.
  /// Returns null if count is not 1 or stage has no transitions.
  String? getWordTextForStage(ProgressStage stage) {
    final stageTransitions = transitions.where((t) => t.toStage == stage).toList();
    if (stageTransitions.length == 1) {
      return stageTransitions.first.wordText;
    }
    return null;
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
