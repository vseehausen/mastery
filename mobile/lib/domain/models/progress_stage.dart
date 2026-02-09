import 'package:flutter/material.dart';
import 'package:mastery/core/theme/color_tokens.dart';

/// Represents a vocabulary word's current competence level.
///
/// Progress through stages is driven exclusively by user actions (reviews, recalls).
/// All transitions are deterministic based on FSRS metrics and review history.
///
/// Stage progression:
/// - New: Word captured from reading, not yet reviewed
/// - Practicing: First review completed, active in SRS rotation
/// - Stabilizing: Multiple successful recalls, memory consolidating
/// - Known: Retrieved from non-translation cues (production recall)
/// - Mastered: High stability, rare reviews, minimal lapses
enum ProgressStage {
  captured,
  practicing,
  stabilizing,
  known,
  mastered;

  /// Returns the display name for the stage (capitalized).
  String get displayName {
    switch (this) {
      case ProgressStage.captured:
        return 'New';
      case ProgressStage.practicing:
        return 'Practicing';
      case ProgressStage.stabilizing:
        return 'Stabilizing';
      case ProgressStage.known:
        return 'Known';
      case ProgressStage.mastered:
        return 'Mastered';
    }
  }

  /// Returns the foreground color for this stage from the theme.
  Color getColor(MasteryColorScheme colors) {
    switch (this) {
      case ProgressStage.captured:
        return colors.stageNew;
      case ProgressStage.practicing:
        return colors.stagePracticing;
      case ProgressStage.stabilizing:
        return colors.stageStabilizing;
      case ProgressStage.known:
        return colors.stageKnown;
      case ProgressStage.mastered:
        return colors.stageMastered;
    }
  }

  /// Returns the background color for this stage from the theme.
  Color getBgColor(MasteryColorScheme colors) {
    switch (this) {
      case ProgressStage.captured:
        return colors.stageNewBg;
      case ProgressStage.practicing:
        return colors.stagePracticingBg;
      case ProgressStage.stabilizing:
        return colors.stageStabilizingBg;
      case ProgressStage.known:
        return colors.stageKnownBg;
      case ProgressStage.mastered:
        return colors.stageMasteredBg;
    }
  }

  /// Creates a ProgressStage from a string value (database deserialization).
  ///
  /// Throws [ArgumentError] if the string doesn't match any stage.
  static ProgressStage fromString(String value) {
    switch (value.toLowerCase()) {
      case 'new':
        return ProgressStage.captured;
      case 'captured':
        return ProgressStage.captured;
      case 'practicing':
        return ProgressStage.practicing;
      case 'stabilizing':
        return ProgressStage.stabilizing;
      case 'known':
        return ProgressStage.known;
      case 'active':
        return ProgressStage.known;
      case 'mastered':
        return ProgressStage.mastered;
      default:
        throw ArgumentError('Invalid progress stage: $value');
    }
  }

  /// Converts this stage to a string for database serialization.
  ///
  /// Uses canonical DB values ("new", "known") while still reading legacy
  /// values ("captured", "active") in [fromString].
  String toDbString() {
    switch (this) {
      case ProgressStage.captured:
        return 'new';
      case ProgressStage.practicing:
        return 'practicing';
      case ProgressStage.stabilizing:
        return 'stabilizing';
      case ProgressStage.known:
        return 'known';
      case ProgressStage.mastered:
        return 'mastered';
    }
  }
}
