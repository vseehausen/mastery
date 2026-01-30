import '../../data/database/database.dart';
import '../../data/repositories/learning_card_repository.dart';
import '../../data/repositories/user_preferences_repository.dart';
import '../models/planned_item.dart';
import '../models/session_plan.dart';
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
    required LearningCardRepository learningCardRepository,
    required UserPreferencesRepository userPreferencesRepository,
    required TelemetryService telemetryService,
    required SrsScheduler srsScheduler,
  })  : _learningCardRepository = learningCardRepository,
        _userPreferencesRepository = userPreferencesRepository,
        _telemetryService = telemetryService,
        _srsScheduler = srsScheduler;

  final LearningCardRepository _learningCardRepository;
  final UserPreferencesRepository _userPreferencesRepository;
  final TelemetryService _telemetryService;
  final SrsScheduler _srsScheduler;

  /// Build a session plan for the current user
  Future<SessionPlan> buildSessionPlan({
    required String userId,
    required int timeTargetMinutes,
    required int intensity,
    required double targetRetention,
  }) async {
    // Get estimated time per item
    final estimatedSecondsPerItem =
        await _telemetryService.getEstimatedSecondsPerItem(userId);

    // Compute session capacity
    final maxItems =
        (timeTargetMinutes * 60 / estimatedSecondsPerItem).floor();

    if (maxItems <= 0) {
      return SessionPlan.empty();
    }

    // Get overdue count for hysteresis check
    final overdueCount = await _learningCardRepository.getOverdueCount(userId);

    // Check if we should suppress new words (hysteresis)
    final prefs = await _userPreferencesRepository.getOrCreateWithDefaults(userId);
    final shouldSuppress = shouldSuppressNewWords(
      overdueCount: overdueCount,
      sessionCapacity: maxItems,
      previouslySuppressed: prefs.newWordSuppressionActive,
    );

    // Update suppression state if changed
    if (shouldSuppress != prefs.newWordSuppressionActive) {
      await _userPreferencesRepository.updateNewWordSuppression(
          userId, shouldSuppress);
    }

    // Compute new word cap based on intensity (or 0 if suppressed)
    final newWordCap = shouldSuppress
        ? 0
        : Intensity.getNewWordCap(intensity, timeTargetMinutes);

    // Get cards in priority order
    final dueCards =
        await _learningCardRepository.getDueCardsSorted(userId);
    final leeches = await _learningCardRepository.getLeeches(userId);
    final newCards =
        await _learningCardRepository.getNewCards(userId, limit: newWordCap);

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

      items.add(PlannedItem(
        learningCard: card,
        interactionMode: selectInteractionMode(card),
        priority: _computePriorityScore(card),
      ));
      reviewCount++;
    }

    // Add leeches
    for (final card in leeches) {
      if (items.length >= maxItems) break;

      // Avoid duplicates (leech might already be in due cards)
      if (items.any((i) => i.learningCard.id == card.id)) continue;

      items.add(PlannedItem(
        learningCard: card,
        interactionMode: InteractionMode.recognition, // Always MCQ for leeches
        priority: _computePriorityScore(card) * 1.5, // Boost leech priority
      ));
      leechCount++;
    }

    // Add new words
    for (final card in newCards) {
      if (items.length >= maxItems) break;
      if (newWordCount >= newWordCap) break;

      items.add(PlannedItem(
        learningCard: card,
        interactionMode: InteractionMode.recognition, // Always MCQ for new cards
        priority: 0.0, // Lowest priority
      ));
      newWordCount++;
    }

    // Compute estimated duration
    final estimatedDurationSeconds =
        (items.length * estimatedSecondsPerItem).round();

    return SessionPlan(
      items: items,
      estimatedDurationSeconds: estimatedDurationSeconds,
      newWordCount: newWordCount,
      reviewCount: reviewCount,
      leechCount: leechCount,
    );
  }

  /// Select interaction mode for a card
  /// Recognition for new/learning/relearning or stability < 7 days
  /// Recall for review state with stability >= 7 days
  int selectInteractionMode(LearningCard card) {
    // New, learning, or relearning cards always use recognition
    if (card.state != CardState.review) {
      return InteractionMode.recognition;
    }

    // Review cards with low stability use recognition
    if (card.stability < InteractionMode.stabilityThresholdDays) {
      return InteractionMode.recognition;
    }

    // Mature review cards use recall
    return InteractionMode.recall;
  }

  /// Compute priority score for a card (higher = more urgent)
  double _computePriorityScore(LearningCard card) {
    final now = DateTime.now().toUtc();
    final overdueDays = now.difference(card.due).inDays.clamp(0, 365);
    final retrievability = _srsScheduler.getRetrievability(card, now: now);
    final lapseWeight = 1 + (card.lapses / 20);

    return overdueDays * (1 - retrievability) * lapseWeight;
  }

  /// Compute priority score for external use
  double computePriorityScore(LearningCard card) {
    return _computePriorityScore(card);
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
