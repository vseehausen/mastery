import 'cue_type.dart';
import 'session_card.dart';

/// Model representing a planned item in a session
class PlannedItem {
  PlannedItem({
    required this.sessionCard,
    required this.interactionMode,
    required this.priority,
    this.cueType,
  });

  /// The session card with all data needed for learning
  final SessionCard sessionCard;

  /// Interaction mode: 0=recognition (MCQ), 1=recall (self-grade)
  final int interactionMode;

  /// Priority score (higher = more urgent)
  final double priority;

  /// The cue type for this item (assigned by CueSelector)
  final CueType? cueType;

  /// Whether this is a recognition (MCQ) item
  bool get isRecognition => interactionMode == 0;

  /// Whether this is a recall (self-grade) item
  bool get isRecall => interactionMode == 1;

  /// Whether this is a new word
  bool get isNewWord => sessionCard.state == 0;

  /// Whether this is a leech
  bool get isLeech => sessionCard.isLeech;

  /// Get the vocabulary ID
  String get vocabularyId => sessionCard.vocabularyId;

  /// Get the word being learned
  String get word => sessionCard.word;

  /// The display form of the word (stem if available, otherwise raw word)
  String get displayWord => sessionCard.displayWord;

  /// Get the card ID
  String get cardId => sessionCard.cardId;

  @override
  String toString() {
    final mode = isRecognition ? 'MCQ' : 'Recall';
    return 'PlannedItem(word: $word, mode: $mode, priority: ${priority.toStringAsFixed(2)})';
  }
}
