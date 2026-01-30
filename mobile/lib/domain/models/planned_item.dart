import '../../data/database/database.dart';

/// Model representing a planned item in a session
class PlannedItem {
  PlannedItem({
    required this.learningCard,
    required this.interactionMode,
    required this.priority,
  });

  /// The learning card to present
  final LearningCard learningCard;

  /// Interaction mode: 0=recognition (MCQ), 1=recall (self-grade)
  final int interactionMode;

  /// Priority score (higher = more urgent)
  final double priority;

  /// Whether this is a recognition (MCQ) item
  bool get isRecognition => interactionMode == 0;

  /// Whether this is a recall (self-grade) item
  bool get isRecall => interactionMode == 1;

  /// Whether this is a new word
  bool get isNewWord => learningCard.state == 0;

  /// Whether this is a leech
  bool get isLeech => learningCard.isLeech;

  /// Get the vocabulary ID
  String get vocabularyId => learningCard.vocabularyId;

  @override
  String toString() {
    final mode = isRecognition ? 'MCQ' : 'Recall';
    return 'PlannedItem(vocab: $vocabularyId, mode: $mode, priority: ${priority.toStringAsFixed(2)})';
  }
}
