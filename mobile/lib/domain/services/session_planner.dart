import 'dart:async';
import 'dart:math' show min;

import 'package:sentry_flutter/sentry_flutter.dart';

import '../../core/logging/decision_log.dart';
import '../../data/services/supabase_data_service.dart';
import '../models/cue_type.dart';
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
    required this.estimatedItemCount,
    required this.dueCount,
  });

  /// Total session capacity (number of items that fit in the time budget)
  final int maxItems;

  /// Maximum new words allowed in this session
  final int newWordCap;

  /// Estimated seconds per item from telemetry
  final double estimatedSecondsPerItem;

  /// Estimated actual items available (overdue reviews + capped new words)
  final int estimatedItemCount;

  /// Count of cards currently due for review (same as overdueCount)
  final int dueCount;
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
    required int newWordsPerSession,
  }) async {
    final estimatedSecondsPerItem = await _telemetryService
        .getEstimatedSecondsPerItem(userId);

    final maxItems = (timeTargetMinutes * 60 / estimatedSecondsPerItem).floor();

    if (maxItems <= 0) {
      return const SessionParams(
        maxItems: 0,
        newWordCap: 0,
        estimatedSecondsPerItem: 0,
        estimatedItemCount: 0,
        dueCount: 0,
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

    // Check for brand-new word when suppressed
    int newWordCap;
    if (shouldSuppress) {
      final hasBrandNew = await _dataService.hasBrandNewWord(userId);
      newWordCap = hasBrandNew ? 1 : 0;
    } else {
      newWordCap = NewWordsPerSession.getNewWordCap(
        newWordsPerSession,
        timeTargetMinutes,
      );
    }

    // Clamp newWordCap so it never exceeds total session capacity
    newWordCap = min(newWordCap, maxItems);

    final availableNewWords = await _dataService.countEnrichedNewWords(userId);

    final estimatedItemCount = min<int>(
      maxItems,
      overdueCount + min<int>(newWordCap, availableNewWords),
    );

    DecisionLog.log('session_params', {
      'max_items': maxItems,
      'new_word_cap': newWordCap,
      'overdue_count': overdueCount,
      'suppressed': shouldSuppress,
      'time_target_minutes': timeTargetMinutes,
      'seconds_per_item': estimatedSecondsPerItem,
    });
    unawaited(Sentry.addBreadcrumb(Breadcrumb(message: 'session_params: max=$maxItems, due=$overdueCount, new=$newWordCap')));

    return SessionParams(
      maxItems: maxItems,
      newWordCap: newWordCap,
      estimatedSecondsPerItem: estimatedSecondsPerItem,
      estimatedItemCount: estimatedItemCount,
      dueCount: overdueCount,
    );
  }

  /// Fetch a batch of cards for incremental session loading.
  ///
  /// [reviewLimit] — maximum number of review cards to fetch.
  /// [newLimit] — maximum number of new cards to fetch.
  /// [excludeCardIds] — card IDs already queued locally (for server-side dedup).
  Future<List<PlannedItem>> fetchBatch({
    required String userId,
    required int reviewLimit,
    required int newLimit,
    Set<String> excludeCardIds = const {},
  }) async {
    final cardsData = await _dataService.getSessionCards(
      userId,
      reviewLimit: reviewLimit,
      newLimit: newLimit,
      excludeIds: excludeCardIds.toList(),
    );

    final allCards = cardsData.map(SessionCard.fromJson).toList();

    // Build planned items
    final items = <PlannedItem>[];

    for (final card in allCards) {
      final cueType = _cueSelector.selectCueType(
        card: card,
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

    return items;
  }

  /// Build a session plan for the current user
  Future<SessionPlan> buildSessionPlan({
    required String userId,
    required int timeTargetMinutes,
    required int newWordsPerSession,
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

    // Compute new word cap based on new-words-per-session setting
    // If suppressed, check for brand-new word guarantee
    int newWordCap;
    if (shouldSuppress) {
      final hasBrandNew = await _dataService.hasBrandNewWord(userId);
      newWordCap = hasBrandNew ? 1 : 0;
    } else {
      newWordCap = NewWordsPerSession.getNewWordCap(
        newWordsPerSession,
        timeTargetMinutes,
      );
    }

    // Fetch session cards using new RPC signature
    final cardsData = await _dataService.getSessionCards(
      userId,
      reviewLimit: maxItems,
      newLimit: newWordCap,
      excludeIds: [],
    );
    final allCards = cardsData.map(SessionCard.fromJson).toList();

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

  /// Compute a near-promotion score (0.0–1.0) for a review card.
  /// Higher = closer to advancing to the next stage.
  /// Returns 0.0 for new cards or cards not close to promotion.
  double nearPromotionScore(SessionCard card) {
    if (card.state == 0) return 0.0; // New cards can't be near-promotion

    // Practicing → Stabilizing: stability >= 1.0, lapsesLast8 <= 2, state == 2
    // Near-promotion signal: state == 2 && stability >= 0.5 && lapsesLast8 <= 2
    if (card.stability < 1.0) {
      // Could be Practicing stage
      if (card.state == 2 && card.stability >= 0.5 && card.lapsesLast8 <= 2) {
        final stabilityRatio = (card.stability / 1.0).clamp(0.0, 1.0);
        return stabilityRatio.clamp(0.0, 1.0);
      }
    }

    // Stabilizing → Known: stabilizing criteria met + nonTranslationSuccessCount >= 1
    // Near-promotion signal: nonTranslationSuccessCount == 0 + stabilizing criteria met
    final meetsStabilizing = card.stability >= 1.0 &&
        card.lapsesLast8 <= 2 && card.state == 2;
    if (meetsStabilizing && card.nonTranslationSuccessCount == 0) {
      // One non-translation success away from Known
      return 0.9;
    }

    // Known → Mastered: stability >= 90, lapsesLast12 <= 1, state == 2, hardMethodSuccessCount >= 1
    // Near-promotion signal: stability >= 70 && lapsesLast12 <= 1 && state == 2 && hardMethodSuccessCount == 0
    if (card.stability >= 70 && card.lapsesLast12 <= 1 && card.state == 2 &&
        card.hardMethodSuccessCount == 0) {
      final stabilityRatio = (card.stability / 90.0).clamp(0.0, 1.0);
      return stabilityRatio.clamp(0.0, 1.0);
    }

    return 0.0;
  }

  /// Apply bookend ordering to a list of planned items.
  /// Returns the reordered list and an optional closer item to serve last.
  ({List<PlannedItem> ordered, PlannedItem? closer}) applyBookendOrder(
    List<PlannedItem> items,
  ) {
    if (items.isEmpty) return (ordered: items, closer: null);

    // Score all review items
    final scored = <(PlannedItem, double)>[];
    final newWords = <PlannedItem>[];
    final reviews = <PlannedItem>[];

    for (final item in items) {
      if (item.isNewWord) {
        newWords.add(item);
      } else {
        final score = nearPromotionScore(item.sessionCard);
        if (score > 0.0) {
          scored.add((item, score));
        } else {
          reviews.add(item);
        }
      }
    }

    // Sort candidates by score descending (best candidates first)
    scored.sort((a, b) => b.$2.compareTo(a.$2));

    final candidateCount = scored.length;

    if (candidateCount == 0) {
      // No near-promotion candidates — move easiest review to last position
      // Easiest = highest stability, lowest difficulty
      PlannedItem? easiest;
      if (reviews.isNotEmpty) {
        easiest = reviews.reduce((a, b) {
          if (a.sessionCard.stability != b.sessionCard.stability) {
            return a.sessionCard.stability > b.sessionCard.stability ? a : b;
          }
          return a.sessionCard.difficulty < b.sessionCard.difficulty ? a : b;
        });
        reviews.remove(easiest);
      }
      final ordered = [...reviews, ...newWords];
      return (ordered: ordered, closer: easiest);
    }

    PlannedItem? closer;
    final openers = <PlannedItem>[];
    final remainingCandidates = <PlannedItem>[];

    if (candidateCount == 1) {
      // 1 candidate → closer only
      closer = scored[0].$1;
    } else if (candidateCount == 2) {
      // 2 candidates → 1 opener + 1 closer
      openers.add(scored[0].$1);
      closer = scored[1].$1;
    } else {
      // 3+ candidates → 2 openers + 1 closer, rest in core
      openers.add(scored[0].$1);
      openers.add(scored[1].$1);
      closer = scored[2].$1;
      for (var i = 3; i < scored.length; i++) {
        remainingCandidates.add(scored[i].$1);
      }
    }

    // Force disambiguation cue on bookend items that are near Mastered
    // and still need a hard method success to unlock the gate.
    for (var i = 0; i < openers.length; i++) {
      openers[i] = _ensurePromotionCue(openers[i]);
    }
    closer = _ensurePromotionCue(closer);

    final ordered = [
      ...openers,
      ...newWords,
      ...remainingCandidates,
      ...reviews,
    ];
    return (ordered: ordered, closer: closer);
  }

  /// If a bookend item is near a promotion gate that requires a specific cue
  /// type success, override its cue type to help unlock that gate.
  ///
  /// - Near Mastered (hardMethodSuccessCount == 0): force disambiguation
  /// - Near Known (nonTranslationSuccessCount == 0): force non-translation cue
  PlannedItem _ensurePromotionCue(PlannedItem item) {
    final card = item.sessionCard;

    // Near Mastered: needs hardMethodSuccess (disambiguation)
    if (card.hardMethodSuccessCount == 0 &&
        card.stability >= 70 &&
        card.lapsesLast12 <= 1 &&
        card.state == 2 &&
        card.hasConfusables &&
        card.confusables.isNotEmpty) {
      return item.withCueType(CueType.disambiguation);
    }

    // Near Known: needs nonTranslationSuccess (any non-translation cue)
    if (card.nonTranslationSuccessCount == 0 &&
        card.stability >= 1.0 &&
        card.lapsesLast8 <= 2 &&
        card.state == 2 &&
        item.cueType == CueType.translation) {
      // Pick best available non-translation cue
      if (card.hasConfusables && card.confusables.isNotEmpty) {
        return item.withCueType(CueType.disambiguation);
      }
      if (card.synonyms.isNotEmpty) {
        return item.withCueType(CueType.synonym);
      }
      return item.withCueType(CueType.definition);
    }

    return item;
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
