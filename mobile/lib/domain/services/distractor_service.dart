import 'dart:math';

import '../../data/services/supabase_data_service.dart';

/// Service for selecting distractor options for multiple choice questions.
/// Implements 4-tier priority: confusables → morphological → same-stage → random.
class DistractorService {
  DistractorService(this._dataService);

  final SupabaseDataService _dataService;
  final _random = Random();

  /// Select distractors for a target vocabulary item using tiered priority.
  ///
  /// Tier 1: L1 confusable translations (max 2)
  /// Tier 2: Morphologically similar (same lemma, max 1)
  /// Tier 4: Random from user's vocabulary (fill remaining)
  Future<List<Distractor>> selectDistractors({
    required String targetItemId,
    required String userId,
    List<String> excludeIds = const [],
    int count = 3,
  }) async {
    // Get the target item with global dictionary data
    final targetData = await _dataService.getVocabularyWithGlobalDict(targetItemId);
    if (targetData == null) {
      return _generateFallbackDistractors(count);
    }

    final targetWord = targetData['word'] as String? ?? '';
    final targetStem = targetData['stem'] as String? ?? targetWord;
    final gd = targetData['global_dictionary'];

    // Extract confusable_alternatives and lemma from global_dictionary
    final confusableAlts = <String>[];
    String? targetLemma;
    if (gd is Map<String, dynamic>) {
      targetLemma = gd['lemma'] as String?;
      final translations = gd['translations'];
      if (translations is Map) {
        for (final entry in translations.entries) {
          final langData = entry.value;
          if (langData is Map) {
            final alts = langData['confusable_alternatives'];
            if (alts is List) {
              confusableAlts.addAll(alts.map((e) => e.toString().toLowerCase()));
            }
          }
        }
      }
    }

    // Get all vocabulary with global dict for the user
    final allVocabData = await _dataService.getVocabularyWithGlobalDictForUser(userId);

    final tier1Confusables = <Distractor>[];
    final tier2Morphological = <Distractor>[];
    final tier4Random = <Distractor>[];

    for (final item in allVocabData) {
      final itemId = item['id'] as String;
      if (itemId == targetItemId) continue;
      if (excludeIds.contains(itemId)) continue;

      final itemWord = item['word'] as String? ?? '';
      final itemStem = item['stem'] as String? ?? itemWord;
      if (itemWord.toLowerCase() == targetWord.toLowerCase()) continue;
      if (itemStem.toLowerCase() == targetStem.toLowerCase()) continue;

      final itemGd = item['global_dictionary'];
      String? itemTranslation;
      String? itemLemma;
      if (itemGd is Map<String, dynamic>) {
        itemLemma = itemGd['lemma'] as String?;
        final itemTranslations = itemGd['translations'];
        if (itemTranslations is Map) {
          for (final entry in itemTranslations.entries) {
            final langData = entry.value;
            if (langData is Map && langData['primary'] is String) {
              itemTranslation = langData['primary'] as String;
              break;
            }
          }
        }
      }

      final distractor = Distractor(
        itemId: itemId,
        surfaceForm: itemWord,
        gloss: itemTranslation ?? itemStem,
      );

      // Tier 1: Check if this item's translation is in target's confusable_alternatives
      if (confusableAlts.isNotEmpty &&
          itemTranslation != null &&
          confusableAlts.contains(itemTranslation.toLowerCase())) {
        tier1Confusables.add(distractor);
        continue;
      }

      // Tier 2: Same lemma (morphological)
      if (targetLemma != null &&
          targetLemma.isNotEmpty &&
          itemLemma != null &&
          itemLemma == targetLemma) {
        tier2Morphological.add(distractor);
        continue;
      }

      // Tier 4: Random
      tier4Random.add(distractor);
    }

    // Select from tiers in priority order
    final selected = <Distractor>[];

    // Tier 1: max 2 confusables
    if (tier1Confusables.isNotEmpty) {
      tier1Confusables.shuffle(_random);
      selected.addAll(
        tier1Confusables.take(min(2, count - selected.length)),
      );
    }

    // Tier 2: max 1 morphological
    if (selected.length < count && tier2Morphological.isNotEmpty) {
      tier2Morphological.shuffle(_random);
      selected.addAll(
        tier2Morphological.take(min(1, count - selected.length)),
      );
    }

    // Tier 4: fill remaining with random
    if (selected.length < count && tier4Random.isNotEmpty) {
      tier4Random.shuffle(_random);
      selected.addAll(
        tier4Random.take(count - selected.length),
      );
    }

    // If still not enough, generate fallbacks
    if (selected.length < count) {
      selected.addAll(_generateFallbackDistractors(count - selected.length));
    }

    return selected;
  }

  /// Generate fallback distractors when not enough vocabulary exists
  List<Distractor> _generateFallbackDistractors(int count) {
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
