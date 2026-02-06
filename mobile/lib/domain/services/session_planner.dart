import 'dart:developer' as developer;

import '../../data/services/supabase_data_service.dart';
import '../models/learning_enums.dart';
import '../models/planned_item.dart';
import '../models/session_card.dart';
import '../models/session_plan.dart';
import 'cue_selector.dart';
import 'telemetry_service.dart';

/// Interaction mode enum values
class InteractionMode {
  static const int recognition = 0; // MCQ
  static const int recall = 1; // Self-grade

  /// Stability threshold for switching from Recognition to Recall (7 days)
  static const double stabilityThresholdDays = 7.0;
}

/// Lightweight session parameters computed before any card data is fetched.
class SessionParams {
  const SessionParams({
    required this.maxItems,
    required this.newWordCap,
    required this.estimatedSecondsPerItem,
  });

  /// Total session capacity (number of items that fit in the time budget)
  final int maxItems;

  /// Maximum new words allowed in this session
  final int newWordCap;

  /// Estimated seconds per item from telemetry
  final double estimatedSecondsPerItem;
}

/// Service for building time-boxed session plans
class SessionPlanner {
  SessionPlanner({
    required SupabaseDataService dataService,
    required TelemetryService telemetryService,
    CueSelector? cueSelector,
  }) : _dataService = dataService,
       _telemetryService = telemetryService,
       _cueSelector = cueSelector ?? CueSelector();

  final SupabaseDataService _dataService;
  final TelemetryService _telemetryService;
  final CueSelector _cueSelector;

  /// Compute lightweight session parameters (no card data fetched).
  /// Used by incremental batch loading to know capacity before first fetch.
  Future<SessionParams> computeSessionParams({
    required String userId,
    required int timeTargetMinutes,
    required int intensity,
  }) async {
    final estimatedSecondsPerItem = await _telemetryService
        .getEstimatedSecondsPerItem(userId);

    final maxItems = (timeTargetMinutes * 60 / estimatedSecondsPerItem).floor();

    if (maxItems <= 0) {
      return const SessionParams(
        maxItems: 0,
        newWordCap: 0,
        estimatedSecondsPerItem: 0,
      );
    }

    final overdueCount = await _dataService.getOverdueCount(userId);

    final prefs = await _dataService.getOrCreatePreferences(userId);
    final previouslySuppressed =
        prefs['new_word_suppression_active'] as bool? ?? false;
    final shouldSuppress = shouldSuppressNewWords(
      overdueCount: overdueCount,
      sessionCapacity: maxItems,
      previouslySuppressed: previouslySuppressed,
    );

    if (shouldSuppress != previouslySuppressed) {
      await _dataService.updatePreferences(
        userId: userId,
        newWordSuppressionActive: shouldSuppress,
      );
    }

    final newWordCap = shouldSuppress
        ? 0
        : Intensity.getNewWordCap(intensity, timeTargetMinutes);

    return SessionParams(
      maxItems: maxItems,
      newWordCap: newWordCap,
      estimatedSecondsPerItem: estimatedSecondsPerItem,
    );
  }

  /// Fetch a batch of cards for incremental session loading.
  ///
  /// [batchSize] — how many new items to return.
  /// [excludeCardIds] — card IDs already queued locally (for dedup).
  /// [newWordsAlreadyQueued] — how many new words are already in the queue.
  /// [newWordCap] — max new words allowed across the whole session.
  Future<List<PlannedItem>> fetchBatch({
    required String userId,
    required int batchSize,
    Set<String> excludeCardIds = const {},
    int newWordsAlreadyQueued = 0,
    int newWordCap = 0,
  }) async {
    // Fetch extra cards to account for dedup filtering
    final fetchLimit = batchSize + excludeCardIds.length;
    final cardsData = await _dataService.getSessionCards(
      userId,
      limit: fetchLimit,
    );
    final allCards = cardsData.map(SessionCard.fromJson).toList();

    // Filter out already-fetched cards
    final freshCards = excludeCardIds.isEmpty
        ? allCards
        : allCards.where((c) => !excludeCardIds.contains(c.cardId)).toList();

    // Separate by type and build items (same order as buildSessionPlan)
    final items = <PlannedItem>[];
    var newWordCount = newWordsAlreadyQueued;

    for (final card in freshCards) {
      if (items.length >= batchSize) break;

      // Enforce new word cap
      if (card.state == 0) {
        if (newWordCount >= newWordCap) continue;
        newWordCount++;
      }

      final cueType = _cueSelector.selectCueType(
        card: card,
        hasMeaning: card.hasMeaning,
        hasEncounterContext: card.hasEncounterContext,
        hasConfusables: card.hasConfusables,
      );

      items.add(
        PlannedItem(
          sessionCard: card,
          interactionMode: selectInteractionMode(card),
          priority: card.state == 0 ? 0.0 : _computePriorityScore(card),
          cueType: cueType,
        ),
      );
    }

    final words = items.map((i) => i.word).join(', ');
    developer.log(
      'fetchBatch returned ${items.length} items '
      '(fetched ${allCards.length}, excluded ${excludeCardIds.length}, '
      'newWords=$newWordCount/$newWordCap) - words: $words',
      name: 'SessionPlanner',
    );

    return items;
  }

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

    // Fetch session cards with all data in ONE query
    final cardsData = await _dataService.getSessionCards(
      userId,
      limit: maxItems * 2, // Fetch extra to filter
    );
    final allCards = cardsData.map(SessionCard.fromJson).toList();

    developer.log(
      'getSessionCards returned ${allCards.length} cards',
      name: 'SessionPlanner',
    );

    // Separate cards by type
    final dueCards = <SessionCard>[];
    final leechCards = <SessionCard>[];
    final newCards = <SessionCard>[];

    for (final card in allCards) {
      if (card.state == 0) {
        newCards.add(card);
      } else if (card.isLeech) {
        leechCards.add(card);
      } else {
        dueCards.add(card);
      }
    }

    // Build plan: due reviews first -> leeches -> new words
    final items = <PlannedItem>[];
    var reviewCount = 0;
    var leechCount = 0;
    var newWordCount = 0;

    // Add due reviews (already sorted by priority from RPC)
    for (final card in dueCards) {
      if (items.length >= maxItems) break;

      final cueType = _cueSelector.selectCueType(
        card: card,
        hasMeaning: card.hasMeaning,
        hasEncounterContext: card.hasEncounterContext,
        hasConfusables: card.hasConfusables,
      );

      items.add(
        PlannedItem(
          sessionCard: card,
          interactionMode: selectInteractionMode(card),
          priority: _computePriorityScore(card),
          cueType: cueType,
        ),
      );
      reviewCount++;
    }

    // Add leeches
    for (final card in leechCards) {
      if (items.length >= maxItems) break;

      final cueType = _cueSelector.selectCueType(
        card: card,
        hasMeaning: card.hasMeaning,
        hasEncounterContext: card.hasEncounterContext,
        hasConfusables: card.hasConfusables,
      );

      items.add(
        PlannedItem(
          sessionCard: card,
          interactionMode: selectInteractionMode(card),
          priority: _computePriorityScore(card) * 1.5, // Boost leech priority
          cueType: cueType,
        ),
      );
      leechCount++;
    }

    // Add new words
    for (final card in newCards) {
      if (items.length >= maxItems) break;
      if (newWordCount >= newWordCap) break;

      final cueType = _cueSelector.selectCueType(
        card: card,
        hasMeaning: card.hasMeaning,
        hasEncounterContext: card.hasEncounterContext,
        hasConfusables: card.hasConfusables,
      );

      items.add(
        PlannedItem(
          sessionCard: card,
          interactionMode: selectInteractionMode(card),
          priority: 0.0, // Lowest priority
          cueType: cueType,
        ),
      );
      newWordCount++;
    }

    // Log session composition
    final cueTypeCounts = <String, int>{};
    for (final item in items) {
      final key = item.cueType?.name ?? 'translation';
      cueTypeCounts[key] = (cueTypeCounts[key] ?? 0) + 1;
    }
    developer.log(
      'Session plan: ${items.length} items, '
      'cueTypes=$cueTypeCounts, '
      'reviews=$reviewCount, leeches=$leechCount, new=$newWordCount',
      name: 'SessionPlanner',
    );

    // Compute estimated duration
    final estimatedDurationSeconds = (items.length * estimatedSecondsPerItem)
        .round();

    return SessionPlan(
      items: items,
      estimatedDurationSeconds: estimatedDurationSeconds,
      newWordCount: newWordCount,
      reviewCount: reviewCount,
      leechCount: leechCount,
    );
  }

  /// Select interaction mode for a card
  /// Currently using recall (self-grade) for all cards
  int selectInteractionMode(SessionCard card) {
    // Use recall mode for all cards - show word, reveal answer, self-grade
    return InteractionMode.recall;
  }

  /// Compute priority score for a card (higher = more urgent)
  double _computePriorityScore(SessionCard card) {
    final now = DateTime.now().toUtc();
    final overdueDays = now.difference(card.due).inDays.clamp(0, 365);

    // For cards with low stability, treat retrievability as low
    double retrievability;
    if (card.state == 0 || card.stability <= 0) {
      retrievability = 1.0;
    } else {
      // Use a simple exponential decay approximation
      final daysSinceReview = card.lastReview != null
          ? now.difference(card.lastReview!).inDays.toDouble()
          : 0.0;
      if (card.stability > 0) {
        retrievability =
            (0.9 * (card.stability / (card.stability + daysSinceReview))).clamp(
              0.0,
              1.0,
            );
      } else {
        retrievability = 1.0;
      }
    }

    final lapseWeight = 1 + (card.lapses / 20);

    return overdueDays * (1 - retrievability) * lapseWeight;
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
