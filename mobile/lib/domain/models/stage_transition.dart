import 'package:mastery/domain/models/progress_stage.dart';

/// Represents a change from one progress stage to another during a learning session.
///
/// Stage transitions are triggered by user-driven learning events (reviews, recalls).
/// They are collected during a session and aggregated for the session recap display.
class StageTransition {
  /// The vocabulary word ID that transitioned.
  final String vocabularyId;

  /// The word display text (for UI).
  final String wordText;

  /// The previous stage (null if this is the first transition for this word).
  final ProgressStage? fromStage;

  /// The new stage after the transition.
  final ProgressStage toStage;

  /// When the transition occurred.
  final DateTime timestamp;

  const StageTransition({
    required this.vocabularyId,
    required this.wordText,
    this.fromStage,
    required this.toStage,
    required this.timestamp,
  });

  /// Returns true if this transition represents a rare achievement.
  ///
  /// Rare achievements are transitions to Active or Mastered stages,
  /// which deserve special visual emphasis in the session recap.
  bool get isRareAchievement =>
      toStage == ProgressStage.active || toStage == ProgressStage.mastered;

  /// Creates a StageTransition from a JSON map.
  factory StageTransition.fromJson(Map<String, dynamic> json) {
    return StageTransition(
      vocabularyId: json['vocabularyId'] as String,
      wordText: json['wordText'] as String,
      fromStage: json['fromStage'] != null
          ? ProgressStage.fromString(json['fromStage'] as String)
          : null,
      toStage: ProgressStage.fromString(json['toStage'] as String),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Converts this StageTransition to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'vocabularyId': vocabularyId,
      'wordText': wordText,
      'fromStage': fromStage?.toDbString(),
      'toStage': toStage.toDbString(),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is StageTransition &&
        other.vocabularyId == vocabularyId &&
        other.wordText == wordText &&
        other.fromStage == fromStage &&
        other.toStage == toStage &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return vocabularyId.hashCode ^
        wordText.hashCode ^
        fromStage.hashCode ^
        toStage.hashCode ^
        timestamp.hashCode;
  }

  @override
  String toString() {
    return 'StageTransition(word: $wordText, ${fromStage?.displayName ?? 'none'} → ${toStage.displayName})';
  }
}
