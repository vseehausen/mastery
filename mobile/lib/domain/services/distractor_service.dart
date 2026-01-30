import 'dart:math';

import '../../data/database/database.dart';
import '../../data/repositories/vocabulary_repository.dart';

/// Service for selecting distractor options for multiple choice questions
/// Implements the contract from contracts/distractor-service.md
class DistractorService {
  DistractorService(this._vocabularyRepository);

  final VocabularyRepository _vocabularyRepository;
  final _random = Random();

  /// Select distractors for a target vocabulary item
  ///
  /// Args:
  ///   targetItemId: The ID of the vocabulary item being tested
  ///   userId: The user's ID
  ///   excludeIds: IDs to exclude from selection (e.g., recent items)
  ///   count: Number of distractors to return (default 3)
  ///
  /// Returns:
  ///   List of distractor vocabulary items
  Future<List<Distractor>> selectDistractors({
    required String targetItemId,
    required String userId,
    List<String> excludeIds = const [],
    int count = 3,
  }) async {
    // Get the target item to understand what we need
    final targetItem = await _vocabularyRepository.getById(targetItemId);
    if (targetItem == null) {
      return [];
    }

    // Get all vocabulary for this user (excluding target and excluded items)
    final allVocabulary = await _vocabularyRepository.getAllForUser(userId);
    final candidates = allVocabulary.where((v) {
      if (v.id == targetItemId) return false;
      if (excludeIds.contains(v.id)) return false;
      // Exclude items with the same word (different meanings of same word)
      if (v.word.toLowerCase() == targetItem.word.toLowerCase()) return false;
      return true;
    }).toList();

    if (candidates.isEmpty) {
      return _generateFallbackDistractors(targetItem, count);
    }

    // Shuffle and take up to count items
    candidates.shuffle(_random);
    final selected = candidates.take(count).toList();

    // If we don't have enough, generate fallbacks
    if (selected.length < count) {
      final fallbacks = _generateFallbackDistractors(
        targetItem,
        count - selected.length,
      );
      return [
        ...selected.map(
          (v) => Distractor(
            itemId: v.id,
            surfaceForm: v.word,
            gloss: v.context ?? v.word,
          ),
        ),
        ...fallbacks,
      ];
    }

    return selected
        .map(
          (v) => Distractor(
            itemId: v.id,
            surfaceForm: v.word,
            gloss: v.context ?? v.word,
          ),
        )
        .toList();
  }

  /// Generate fallback distractors when not enough vocabulary exists
  List<Distractor> _generateFallbackDistractors(Vocabulary target, int count) {
    // Simple fallbacks - in production these would be from a larger pool
    final fallbacks = <String>[
      'something else',
      'another meaning',
      'different word',
      'not this one',
      'alternative',
    ];

    fallbacks.shuffle(_random);
    return fallbacks
        .take(count)
        .map((f) => Distractor(itemId: '', surfaceForm: f, gloss: f))
        .toList();
  }
}

/// Represents a distractor option for MCQ
class Distractor {
  const Distractor({
    required this.itemId,
    required this.surfaceForm,
    required this.gloss,
  });

  /// The vocabulary item ID (empty if fallback)
  final String itemId;

  /// The word to display
  final String surfaceForm;

  /// The definition/translation to show as the answer option
  final String gloss;
}
