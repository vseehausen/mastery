/// Card state enum for learning cards
/// Maps to LearningCards.state column
enum CardStateEnum {
  /// New card, never reviewed
  newCard(0),

  /// Learning state (initial learning steps)
  learning(1),

  /// Review state (graduated, reviewing at intervals)
  review(2),

  /// Relearning state (lapsed from review)
  relearning(3);

  const CardStateEnum(this.value);
  final int value;

  static CardStateEnum fromValue(int value) {
    return CardStateEnum.values.firstWhere(
      (e) => e.value == value,
      orElse: () => CardStateEnum.newCard,
    );
  }
}

/// Review rating enum
/// Maps to ReviewLogs.rating column
enum ReviewRatingEnum {
  /// Forgot the card
  again(1),

  /// Remembered with difficulty
  hard(2),

  /// Remembered after hesitation
  good(3),

  /// Remembered easily
  easy(4);

  const ReviewRatingEnum(this.value);
  final int value;

  static ReviewRatingEnum fromValue(int value) {
    return ReviewRatingEnum.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ReviewRatingEnum.good,
    );
  }
}

/// Interaction mode enum
/// Maps to ReviewLogs.interactionMode column
enum InteractionModeEnum {
  /// Multiple choice question
  recognition(0),

  /// Self-graded recall
  recall(1);

  const InteractionModeEnum(this.value);
  final int value;

  static InteractionModeEnum fromValue(int value) {
    return InteractionModeEnum.values.firstWhere(
      (e) => e.value == value,
      orElse: () => InteractionModeEnum.recognition,
    );
  }
}

/// Intensity level enum
/// Maps to UserLearningPreferences.intensity column
enum IntensityEnum {
  /// Light: fewer new words (2 per 10 min)
  light(0),

  /// Normal: default new words (5 per 10 min)
  normal(1),

  /// Intense: more new words (8 per 10 min)
  intense(2);

  const IntensityEnum(this.value);
  final int value;

  /// Get new words per 10 minutes for this intensity
  int get newWordsPerTenMinutes {
    switch (this) {
      case IntensityEnum.light:
        return 2;
      case IntensityEnum.normal:
        return 5;
      case IntensityEnum.intense:
        return 8;
    }
  }

  /// Get new word cap for a given time budget
  int getNewWordCap(int timeMinutes) {
    if (timeMinutes <= 0) return 0;
    return (timeMinutes * newWordsPerTenMinutes / 10).ceil();
  }

  static IntensityEnum fromValue(int value) {
    return IntensityEnum.values.firstWhere(
      (e) => e.value == value,
      orElse: () => IntensityEnum.normal,
    );
  }
}

/// Intensity constants class for backwards compatibility
/// Use IntensityEnum for type-safe usage
class Intensity {
  const Intensity._();

  static const int light = 0;
  static const int normal = 1;
  static const int intense = 2;

  /// Get new word cap for a given intensity value and time budget
  static int getNewWordCap(int intensityValue, int timeMinutes) {
    final intensity = IntensityEnum.fromValue(intensityValue);
    return intensity.getNewWordCap(timeMinutes);
  }
}

/// Session outcome enum
/// Maps to LearningSessions.outcome column
enum SessionOutcomeEnum {
  /// Session is in progress
  inProgress(0),

  /// Session completed normally
  complete(1),

  /// Session ended early (user quit)
  partial(2),

  /// Session expired (past expiresAt)
  expired(3);

  const SessionOutcomeEnum(this.value);
  final int value;

  static SessionOutcomeEnum fromValue(int value) {
    return SessionOutcomeEnum.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SessionOutcomeEnum.inProgress,
    );
  }
}
