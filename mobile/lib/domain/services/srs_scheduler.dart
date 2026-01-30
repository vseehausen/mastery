import 'package:fsrs/fsrs.dart' as fsrs;

import '../../data/database/database.dart';

/// Review rating enum values (maps to FSRS ratings)
class ReviewRating {
  static const int again = 1;
  static const int hard = 2;
  static const int good = 3;
  static const int easy = 4;

  static fsrs.Rating toFsrs(int rating) {
    switch (rating) {
      case again:
        return fsrs.Rating.again;
      case hard:
        return fsrs.Rating.hard;
      case good:
        return fsrs.Rating.good;
      case easy:
        return fsrs.Rating.easy;
      default:
        return fsrs.Rating.good;
    }
  }
}

/// Card state enum values (maps to FSRS states)
/// Note: FSRS doesn't have a "new" state - we track it ourselves as state=0
/// FSRS states: learning=1, review=2, relearning=3
class CardState {
  static const int newCard = 0;
  static const int learning = 1;
  static const int review = 2;
  static const int relearning = 3;

  static int fromFsrs(fsrs.State state) {
    switch (state) {
      case fsrs.State.learning:
        return learning;
      case fsrs.State.review:
        return review;
      case fsrs.State.relearning:
        return relearning;
    }
  }

  static fsrs.State toFsrs(int state) {
    switch (state) {
      case newCard:
        // New cards start in learning state when first reviewed
        return fsrs.State.learning;
      case learning:
        return fsrs.State.learning;
      case review:
        return fsrs.State.review;
      case relearning:
        return fsrs.State.relearning;
      default:
        return fsrs.State.learning;
    }
  }
}

/// Result of reviewing a card
class ReviewResult {
  ReviewResult({
    required this.updatedCard,
    required this.reviewLog,
    required this.isLeech,
  });

  final LearningCardUpdate updatedCard;
  final ReviewLogData reviewLog;
  final bool isLeech;
}

/// Updated card data (fields to write back to database)
class LearningCardUpdate {
  LearningCardUpdate({
    required this.state,
    required this.due,
    required this.stability,
    required this.difficulty,
    required this.reps,
    required this.lapses,
    required this.isLeech,
  });

  final int state;
  final DateTime due;
  final double stability;
  final double difficulty;
  final int reps;
  final int lapses;
  final bool isLeech;
}

/// Review log data to insert
class ReviewLogData {
  ReviewLogData({
    required this.rating,
    required this.interactionMode,
    required this.stateBefore,
    required this.stateAfter,
    required this.stabilityBefore,
    required this.stabilityAfter,
    required this.difficultyBefore,
    required this.difficultyAfter,
    required this.retrievabilityAtReview,
  });

  final int rating;
  final int interactionMode;
  final int stateBefore;
  final int stateAfter;
  final double stabilityBefore;
  final double stabilityAfter;
  final double difficultyBefore;
  final double difficultyAfter;
  final double retrievabilityAtReview;
}

/// Thin wrapper around the FSRS Dart package.
/// Provides a stable internal API for reviewing cards, computing retrievability,
/// and managing FSRS state.
class SrsScheduler {
  SrsScheduler({double targetRetention = 0.90})
    : _scheduler = createScheduler(targetRetention: targetRetention);

  final fsrs.Scheduler _scheduler;

  /// Constants
  static const int leechThreshold = 8;
  static const int maxIntervalDays = 365;

  /// Create an FSRS scheduler with the given target retention
  static fsrs.Scheduler createScheduler({double targetRetention = 0.90}) {
    return fsrs.Scheduler(
      desiredRetention: targetRetention,
      maximumInterval: maxIntervalDays,
    );
  }

  /// Process a user's review of a learning card and return the updated card state
  ReviewResult reviewCard({
    required LearningCard card,
    required int rating,
    required int interactionMode,
    DateTime? now,
  }) {
    final reviewTime = now ?? DateTime.now().toUtc();

    // Capture before state
    final stateBefore = card.state;
    final stabilityBefore = card.stability;
    final difficultyBefore = card.difficulty;

    // Compute retrievability before review
    final retrievabilityBefore = getRetrievability(card, now: reviewTime);

    // Convert to FSRS card
    final fsrsCard = _toFsrsCard(card);

    // Review the card
    final fsrsRating = ReviewRating.toFsrs(rating);
    final result = _scheduler.reviewCard(
      fsrsCard,
      fsrsRating,
      reviewDateTime: reviewTime,
    );
    final newFsrsCard = result.card;

    // Compute lapses and leech status (we track these ourselves since FSRS doesn't)
    var newLapses = card.lapses;
    var newReps = card.reps;

    // Increment lapses if rating is "again" and card was in review state
    if (rating == ReviewRating.again && stateBefore == CardState.review) {
      newLapses++;
    }

    // Increment reps for successful reviews
    if (rating >= ReviewRating.hard) {
      newReps++;
    }

    final isLeech = newLapses >= leechThreshold;

    // Build updated card
    final updatedCard = LearningCardUpdate(
      state: CardState.fromFsrs(newFsrsCard.state),
      due: newFsrsCard.due,
      stability: newFsrsCard.stability ?? 0.0,
      difficulty: newFsrsCard.difficulty ?? 0.0,
      reps: newReps,
      lapses: newLapses,
      isLeech: isLeech,
    );

    // Build review log
    final reviewLog = ReviewLogData(
      rating: rating,
      interactionMode: interactionMode,
      stateBefore: stateBefore,
      stateAfter: updatedCard.state,
      stabilityBefore: stabilityBefore,
      stabilityAfter: updatedCard.stability,
      difficultyBefore: difficultyBefore,
      difficultyAfter: updatedCard.difficulty,
      retrievabilityAtReview: retrievabilityBefore,
    );

    return ReviewResult(
      updatedCard: updatedCard,
      reviewLog: reviewLog,
      isLeech: isLeech,
    );
  }

  /// Compute current probability of recall for a card
  double getRetrievability(LearningCard card, {DateTime? now}) {
    final currentTime = now ?? DateTime.now().toUtc();

    // For new cards or cards with zero stability, return 1.0 (assumed known)
    if (card.state == CardState.newCard || card.stability <= 0) {
      return 1.0;
    }

    // For cards without a lastReview, return 1.0
    if (card.lastReview == null) {
      return 1.0;
    }

    // Use FSRS scheduler's retrievability calculation
    final fsrsCard = _toFsrsCard(card);
    return _scheduler.getCardRetrievability(
      fsrsCard,
      currentDateTime: currentTime,
    );
  }

  /// Initialize a new learning card from a vocabulary item
  static LearningCardData initializeCard({
    required String vocabularyId,
    required String userId,
  }) {
    final now = DateTime.now().toUtc();
    return LearningCardData(
      vocabularyId: vocabularyId,
      userId: userId,
      state: CardState.newCard,
      due: now,
      stability: 0.0,
      difficulty: 0.0,
      reps: 0,
      lapses: 0,
      isLeech: false,
    );
  }

  /// Convert LearningCard to FSRS Card
  fsrs.Card _toFsrsCard(LearningCard card) {
    // Generate a cardId from the vocabulary id hash (FSRS needs an int cardId)
    final cardId = card.vocabularyId.hashCode;

    return fsrs.Card(
      cardId: cardId,
      due: card.due,
      stability: card.stability > 0 ? card.stability : null,
      difficulty: card.difficulty > 0 ? card.difficulty : null,
      state: CardState.toFsrs(card.state),
      lastReview: card.lastReview,
    );
  }
}

/// Data class for initializing a new learning card
class LearningCardData {
  LearningCardData({
    required this.vocabularyId,
    required this.userId,
    required this.state,
    required this.due,
    required this.stability,
    required this.difficulty,
    required this.reps,
    required this.lapses,
    required this.isLeech,
  });

  final String vocabularyId;
  final String userId;
  final int state;
  final DateTime due;
  final double stability;
  final double difficulty;
  final int reps;
  final int lapses;
  final bool isLeech;
}
