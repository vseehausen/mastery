/// Types of cues used in learning sessions.
/// Each cue type represents a different way to prompt the learner.
enum CueType {
  translation,
  definition,
  synonym,
  contextCloze,
  disambiguation,
  novelCloze,
  usageRecognition;

  /// Whether this cue type uses objective measurement (time + correctness)
  /// instead of self-rating buttons.
  bool get usesObjectiveMeasurement =>
      this == CueType.disambiguation ||
      this == CueType.contextCloze ||
      this == CueType.usageRecognition;

  /// Whether this cue type uses self-rating buttons (Again/Hard/Good/Easy).
  bool get usesSelfRating => !usesObjectiveMeasurement;

  /// Convert to the string stored in the database/API.
  String toDbString() {
    switch (this) {
      case CueType.translation:
        return 'translation';
      case CueType.definition:
        return 'definition';
      case CueType.synonym:
        return 'synonym';
      case CueType.contextCloze:
        return 'context_cloze';
      case CueType.disambiguation:
        return 'disambiguation';
      case CueType.novelCloze:
        return 'novel_cloze';
      case CueType.usageRecognition:
        return 'usage_recognition';
    }
  }

  /// Parse from the string stored in the database/API.
  static CueType fromDbString(String value) {
    switch (value) {
      case 'translation':
        return CueType.translation;
      case 'definition':
        return CueType.definition;
      case 'synonym':
        return CueType.synonym;
      case 'context_cloze':
        return CueType.contextCloze;
      case 'disambiguation':
        return CueType.disambiguation;
      case 'novel_cloze':
        return CueType.novelCloze;
      case 'usage_recognition':
        return CueType.usageRecognition;
      default:
        return CueType.translation;
    }
  }
}

/// Maturity stage of a learning card, derived from FSRS state and stability.
enum MaturityStage {
  /// New or early learning. stability < 1.0
  newCard,

  /// Consolidating knowledge. stability 1.0 - 21.0
  growing,

  /// Well-known word. stability >= 21.0
  mature,
}
