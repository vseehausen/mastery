import 'dart:developer' as developer;
import 'dart:math';

import '../models/cue_type.dart';
import '../models/session_card.dart';

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
      return card.stability < 1.0 ? MaturityStage.newCard : MaturityStage.growing;
    }
    if (card.state == 2) {
      return card.stability >= 21.0 ? MaturityStage.mature : MaturityStage.growing;
    }
    // state == 3 (relearning) treated as growing
    return MaturityStage.growing;
  }

  /// Select a cue type for a given card based on maturity stage and available data.
  CueType selectCueType({
    required SessionCard card,
    required bool hasMeaning,
    bool hasEncounterContext = false,
    bool hasConfusables = false,
  }) {
    // No meaning data — can only do translation
    if (!hasMeaning) return CueType.translation;

    final stage = getMaturityStage(card);

    // New cards always get translation cues
    if (stage == MaturityStage.newCard) return CueType.translation;

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
      'hasMeaning=$hasMeaning, '
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
