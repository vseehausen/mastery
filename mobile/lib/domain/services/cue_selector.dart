import 'dart:developer' as developer;
import 'dart:math';

import '../models/cue_type.dart';
import '../models/session_card.dart';

/// Cue content generated at runtime
class CueContent {
  const CueContent({
    required this.prompt,
    required this.answer,
  });

  final String prompt;
  final String answer;
}

/// Service for selecting cue types based on card maturity and available data.
/// Implements the weighted random selection algorithm from research.md R4.
class CueSelector {
  CueSelector({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// Get the maturity stage based on FSRS card state and stability.
  /// - New: state == 0 (new) or state == 1 (learning) with stability < 1.0
  /// - Growing: state == 1 with stability >= 1.0, or state == 2 (review) with stability < 21.0
  /// - Mature: state == 2 (review) with stability >= 21.0
  MaturityStage getMaturityStage(SessionCard card) {
    if (card.state == 0) return MaturityStage.newCard;
    if (card.state == 1) {
      return card.stability < 1.0
          ? MaturityStage.newCard
          : MaturityStage.growing;
    }
    if (card.state == 2) {
      return card.stability >= 21.0
          ? MaturityStage.mature
          : MaturityStage.growing;
    }
    // state == 3 (relearning) treated as growing
    return MaturityStage.growing;
  }

  /// Build cue content (prompt and answer) at runtime based on cue type
  CueContent buildCueContent(SessionCard card, CueType type) {
    switch (type) {
      case CueType.translation:
        return CueContent(
          prompt: card.englishDefinition,
          answer: card.primaryTranslation,
        );

      case CueType.definition:
        return CueContent(
          prompt: card.displayWord,
          answer: card.englishDefinition,
        );

      case CueType.synonym:
        final synonym = card.synonyms.isNotEmpty ? card.synonyms.first : '';
        return CueContent(
          prompt: card.displayWord,
          answer: synonym,
        );

      case CueType.contextCloze:
        // Use encounter context if available, otherwise use first example sentence
        if (card.encounterContext != null && card.encounterContext!.isNotEmpty) {
          // For encounter context, we need to create cloze manually (legacy format)
          final clozeContext = card.encounterContext!.replaceAll(
            RegExp(card.word, caseSensitive: false),
            '_____',
          );
          return CueContent(
            prompt: clozeContext,
            answer: card.displayWord,
          );
        } else if (card.exampleSentences.isNotEmpty) {
          // Use pre-split format from global dictionary
          final example = card.exampleSentences.first;
          final clozePrompt = '${example.before}_____${example.after}';
          return CueContent(
            prompt: clozePrompt,
            answer: example.blank,
          );
        }
        // Fallback to translation if no context available
        return CueContent(
          prompt: card.englishDefinition,
          answer: card.primaryTranslation,
        );

      case CueType.disambiguation:
        // Use the first confusable's disambiguation sentence
        if (card.confusables.isNotEmpty) {
          final confusable = card.confusables.first;
          final disambig = confusable.disambiguationSentence;
          if (disambig != null) {
            final clozePrompt = '${disambig.before}_____${disambig.after}';
            return CueContent(
              prompt: clozePrompt,
              answer: disambig.blank,
            );
          }
        }
        // Fallback to definition if no confusables
        return CueContent(
          prompt: card.displayWord,
          answer: card.englishDefinition,
        );
    }
  }

  /// Select a cue type for a given card based on maturity stage and available data.
  CueType selectCueType({
    required SessionCard card,
  }) {
    final stage = getMaturityStage(card);

    // New cards always get translation cues
    if (stage == MaturityStage.newCard) return CueType.translation;

    final hasEncounterContext = card.encounterContext != null &&
        card.encounterContext!.isNotEmpty;
    final hasConfusables = card.hasConfusables && card.confusables.isNotEmpty;

    final candidates = <_WeightedCue>[];

    if (stage == MaturityStage.growing) {
      candidates.addAll([
        const _WeightedCue(CueType.translation, 70),
        const _WeightedCue(CueType.definition, 15),
        const _WeightedCue(CueType.synonym, 10),
        if (hasEncounterContext) const _WeightedCue(CueType.contextCloze, 5),
      ]);
    } else {
      // Mature
      candidates.addAll([
        const _WeightedCue(CueType.translation, 20),
        const _WeightedCue(CueType.definition, 25),
        const _WeightedCue(CueType.synonym, 20),
        if (hasEncounterContext) const _WeightedCue(CueType.contextCloze, 15),
        if (hasConfusables) const _WeightedCue(CueType.disambiguation, 20),
      ]);
    }

    final selected = _weightedRandomPick(candidates);

    developer.log(
      'selectCueType: stage=$stage, '
      'hasContext=$hasEncounterContext, '
      'hasConfusables=$hasConfusables, '
      'candidates=${candidates.map((c) => c.type.name).join(",")}, '
      'selected=${selected.name}',
      name: 'CueSelector',
    );

    return selected;
  }

  /// Perform a weighted random selection from candidates.
  /// Normalizes weights to handle missing cue types.
  CueType _weightedRandomPick(List<_WeightedCue> candidates) {
    if (candidates.isEmpty) return CueType.translation;
    if (candidates.length == 1) return candidates.first.type;

    final totalWeight = candidates.fold<int>(0, (sum, c) => sum + c.weight);
    var roll = _random.nextInt(totalWeight);

    for (final candidate in candidates) {
      roll -= candidate.weight;
      if (roll < 0) return candidate.type;
    }

    return candidates.last.type;
  }
}

class _WeightedCue {
  const _WeightedCue(this.type, this.weight);

  final CueType type;
  final int weight;
}
