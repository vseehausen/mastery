import 'package:flutter/material.dart';
import 'package:mastery/core/theme/color_tokens.dart';

/// Represents a vocabulary word's current competence level.
///
/// Progress through stages is driven exclusively by user actions (reviews, recalls).
/// All transitions are deterministic based on FSRS metrics and review history.
///
/// Stage progression:
/// - Captured: Word captured from reading, not yet reviewed
/// - Practicing: First review completed, active in SRS rotation
/// - Stabilizing: Multiple successful recalls, memory consolidating
/// - Active: Retrieved from non-translation cues (production recall)
/// - Mastered: High stability, rare reviews, minimal lapses
enum ProgressStage {
  captured,
  practicing,
  stabilizing,
  active,
  mastered;

  /// Returns the display name for the stage (capitalized).
  String get displayName {
    switch (this) {
      case ProgressStage.captured:
        return 'Captured';
      case ProgressStage.practicing:
        return 'Practicing';
      case ProgressStage.stabilizing:
        return 'Stabilizing';
      case ProgressStage.active:
        return 'Active';
      case ProgressStage.mastered:
        return 'Mastered';
    }
  }

  /// Returns the appropriate color for this stage from the theme.
  ///
  /// Color mapping:
  /// - Captured: mutedForeground (gray)
  /// - Practicing/Stabilizing: accent (amber)
  /// - Active/Mastered: success (green)
  Color getColor(MasteryColorScheme colors) {
    switch (this) {
      case ProgressStage.captured:
        return colors.mutedForeground;
      case ProgressStage.practicing:
      case ProgressStage.stabilizing:
        return colors.accent;
      case ProgressStage.active:
      case ProgressStage.mastered:
        return colors.success;
    }
  }

  /// Creates a ProgressStage from a string value (database deserialization).
  ///
  /// Throws [ArgumentError] if the string doesn't match any stage.
  static ProgressStage fromString(String value) {
    switch (value.toLowerCase()) {
      case 'captured':
        return ProgressStage.captured;
      case 'practicing':
        return ProgressStage.practicing;
      case 'stabilizing':
        return ProgressStage.stabilizing;
      case 'active':
        return ProgressStage.active;
      case 'mastered':
        return ProgressStage.mastered;
      default:
        throw ArgumentError('Invalid progress stage: $value');
    }
  }

  /// Converts this stage to a string for database serialization.
  String toDbString() => name;
}
