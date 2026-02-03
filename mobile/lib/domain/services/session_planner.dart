import 'dart:developer' as developer;

import '../../data/services/supabase_data_service.dart';
import '../models/learning_card.dart';
import '../models/learning_enums.dart';
import '../models/planned_item.dart';
import '../models/session_plan.dart';
import 'cue_selector.dart';
import 'srs_scheduler.dart';
import 'telemetry_service.dart';

/// Interaction mode enum values
class InteractionMode {
  static const int recognition = 0; // MCQ
  static const int recall = 1; // Self-grade

  /// Stability threshold for switching from Recognition to Recall (7 days)
  static const double stabilityThresholdDays = 7.0;
}

/// Service for building time-boxed session plans
class SessionPlanner {
  SessionPlanner({
    required SupabaseDataService dataService,
    required TelemetryService telemetryService,
    required SrsScheduler srsScheduler,
    CueSelector? cueSelector,
  }) : _dataService = dataService,
       _telemetryService = telemetryService,
       _srsScheduler = srsScheduler,
       _cueSelector = cueSelector ?? CueSelector();

  final SupabaseDataService _dataService;
  final TelemetryService _telemetryService;
  final SrsScheduler _srsScheduler;
  final CueSelector _cueSelector;

  /// Build a session plan for the current user
  Future<SessionPlan> buildSessionPlan({
    required String userId,
    required int timeTargetMinutes,
    required int intensity,
    required double targetRetention,
  }) async {
    // Get estimated time per item
    final estimatedSecondsPerItem = await _telemetryService
        .getEstimatedSecondsPerItem(userId);

    // Compute session capacity
    final maxItems = (timeTargetMinutes * 60 / estimatedSecondsPerItem).floor();

    if (maxItems <= 0) {
      return SessionPlan.empty();
    }

    // Get overdue count for hysteresis check
    final overdueCount = await _dataService.getOverdueCount(userId);

    // Check if we should suppress new words (hysteresis)
    final prefs = await _dataService.getOrCreatePreferences(userId);
    final previouslySuppressed =
        prefs['new_word_suppression_active'] as bool? ?? false;
    final shouldSuppress = shouldSuppressNewWords(
      overdueCount: overdueCount,
      sessionCapacity: maxItems,
      previouslySuppressed: previouslySuppressed,
    );

    // Update suppression state if changed
    if (shouldSuppress != previouslySuppressed) {
      await _dataService.updatePreferences(
        userId: userId,
        newWordSuppressionActive: shouldSuppress,
      );
    }

    // Compute new word cap based on intensity (or 0 if suppressed)
    final newWordCap = shouldSuppress
        ? 0
        : Intensity.getNewWordCap(intensity, timeTargetMinutes);

    // Get cards in priority order
    final dueCardsData = await _dataService.getDueCards(userId);
    final dueCards = dueCardsData.map(LearningCardModel.fromJson).toList();

    final leechCardsData = await _dataService.getLeechCards(userId);
    final leeches = leechCardsData.map(LearningCardModel.fromJson).toList();

    final newCardsData = await _dataService.getNewCards(
      userId,
      limit: newWordCap,
    );
    final newCards = newCardsData.map(LearningCardModel.fromJson).toList();

    // Build plan: due reviews first -> leeches -> new words
    final items = <PlannedItem>[];
    var reviewCount = 0;
    var leechCount = 0;
    var newWordCount = 0;

    // Add due reviews (already sorted by priority)
    for (final card in dueCards) {
      if (items.length >= maxItems) break;

      // Skip leeches here (they'll be added separately)
      if (card.isLeech) continue;

      items.add(
        PlannedItem(
          learningCard: card,
          interactionMode: selectInteractionMode(card),
          priority: _computePriorityScore(card),
        ),
      );
      reviewCount++;
    }

    // Add leeches
    for (final card in leeches) {
      if (items.length >= maxItems) break;

      // Avoid duplicates (leech might already be in due cards)
      if (items.any((i) => i.learningCard.id == card.id)) continue;

      items.add(
        PlannedItem(
          learningCard: card,
          interactionMode: selectInteractionMode(card),
          priority: _computePriorityScore(card) * 1.5, // Boost leech priority
        ),
      );
      leechCount++;
    }

    // Add new words
    for (final card in newCards) {
      if (items.length >= maxItems) break;
      if (newWordCount >= newWordCap) break;

      items.add(
        PlannedItem(
          learningCard: card,
          interactionMode: selectInteractionMode(card),
          priority: 0.0, // Lowest priority
        ),
      );
      newWordCount++;
    }

    // Assign cue types to items with meaning data
    final itemsWithCues = await _assignCueTypes(items);

    // Log session composition
    final cueTypeCounts = <String, int>{};
    for (final item in itemsWithCues) {
      final key = item.cueType?.name ?? 'translation';
      cueTypeCounts[key] = (cueTypeCounts[key] ?? 0) + 1;
    }
    developer.log(
      'Session plan: ${itemsWithCues.length} items, '
      'cueTypes=$cueTypeCounts, '
      'reviews=$reviewCount, leeches=$leechCount, new=$newWordCount',
      name: 'SessionPlanner',
    );

    // Compute estimated duration
    final estimatedDurationSeconds = (itemsWithCues.length *
            estimatedSecondsPerItem)
        .round();

    return SessionPlan(
      items: itemsWithCues,
      estimatedDurationSeconds: estimatedDurationSeconds,
      newWordCount: newWordCount,
      reviewCount: reviewCount,
      leechCount: leechCount,
    );
  }

  /// Select interaction mode for a card
  /// Currently using recall (self-grade) for all cards
  int selectInteractionMode(LearningCardModel card) {
    // Use recall mode for all cards - show word, reveal answer, self-grade
    return InteractionMode.recall;
  }

  /// Compute priority score for a card (higher = more urgent)
  double _computePriorityScore(LearningCardModel card) {
    final now = DateTime.now().toUtc();
    final overdueDays = now.difference(card.due).inDays.clamp(0, 365);
    final retrievability = _srsScheduler.getRetrievability(card, now: now);
    final lapseWeight = 1 + (card.lapses / 20);

    return overdueDays * (1 - retrievability) * lapseWeight;
  }

  /// Compute priority score for external use
  double computePriorityScore(LearningCardModel card) {
    return _computePriorityScore(card);
  }

  /// Assign cue types to planned items using CueSelector.
  /// Falls back to translation cue when meaning data is unavailable.
  Future<List<PlannedItem>> _assignCueTypes(List<PlannedItem> items) async {
    final result = <PlannedItem>[];
    for (final item in items) {
      final vocabId = item.vocabularyId;
      final meanings = await _dataService.getMeanings(vocabId);
      final hasMeaning = meanings.isNotEmpty;

      final encounters = await _dataService.getEncounters(vocabId);
      final hasEncounterContext = encounters.any(
        (e) => e['context'] != null && (e['context'] as String).isNotEmpty,
      );

      final confusables = await _dataService.getConfusableSetsForVocabulary(
        vocabId,
      );
      final hasConfusables = confusables.isNotEmpty;

      final cueType = _cueSelector.selectCueType(
        card: item.learningCard,
        hasMeaning: hasMeaning,
        hasEncounterContext: hasEncounterContext,
        hasConfusables: hasConfusables,
      );

      result.add(PlannedItem(
        learningCard: item.learningCard,
        interactionMode: item.interactionMode,
        priority: item.priority,
        cueType: cueType,
      ));
    }
    return result;
  }

  /// Determine if new-word introduction should be suppressed (hysteresis logic)
  bool shouldSuppressNewWords({
    required int overdueCount,
    required int sessionCapacity,
    required bool previouslySuppressed,
  }) {
    if (sessionCapacity <= 0) return true;

    if (previouslySuppressed) {
      // Exit threshold: resume when overdue fits within 2 sessions
      return overdueCount > 2 * sessionCapacity;
    } else {
      // Entry threshold: suppress when overdue exceeds 1 session
      return overdueCount > sessionCapacity;
    }
  }
}
