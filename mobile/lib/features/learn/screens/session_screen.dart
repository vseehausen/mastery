import 'dart:async';
import 'dart:math' show min;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/app_defaults.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/mastery_back_button.dart';
import '../../../data/services/progress_stage_service.dart';
import '../../../data/services/review_write_queue.dart';
import '../../../data/services/supabase_data_service.dart';
import '../../../domain/models/cue_type.dart';
import '../../../domain/models/learning_enums.dart';
import '../../../domain/models/learning_session.dart';
import '../../../domain/models/planned_item.dart';
import '../../../domain/models/progress_stage.dart';
import '../../../domain/models/session_card.dart';
import '../../../domain/models/stage_transition.dart';
import '../../../domain/services/srs_scheduler.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/learning_providers.dart';
import '../../../providers/review_write_queue_provider.dart';
import '../../../providers/supabase_provider.dart';
import '../providers/session_providers.dart';
import '../providers/streak_providers.dart';
import '../widgets/cloze_cue_card.dart';
import '../widgets/definition_cue_card.dart';
import '../widgets/disambiguation_card.dart';
import '../widgets/novel_cloze_cue_card.dart';
import '../widgets/progress_micro_feedback.dart';
import '../widgets/recall_card.dart';
import '../widgets/recognition_card.dart';
import '../widgets/session_progress_bar.dart';
import '../widgets/synonym_cue_card.dart';
import '../widgets/usage_recognition_card.dart';
import 'session_complete_screen.dart';

/// Main session screen for learning
/// Presents items one by one with timer, saves progress after each item.
/// Uses incremental batch loading: fetches 5 cards initially, prefetches
/// more in the background as the user progresses.
class SessionScreen extends ConsumerStatefulWidget {
  const SessionScreen({
    super.key,
    this.isQuickReview = false,
  });

  final bool isQuickReview;

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen> {
  static const _prefetchThreshold = 3;
  static const _batchSize = 5;

  // Incremental batch state
  List<PlannedItem> _items = [];
  final Set<String> _fetchedCardIds = {};
  int _estimatedTotalItems = 0;
  bool _isFetchingMore = false;
  bool _initStarted = false;
  Completer<void>? _fetchCompleter;
  int _maxItems = 0;

  // Retry queue for "Again" cards
  final List<PlannedItem> _retryQueue = [];
  final Map<String, int> _retryAttempts = {};

  // Bookend closer: held aside to serve as the very last card
  PlannedItem? _closerItem;

  LearningSessionModel? _session;
  int _currentItemIndex = 0;
  int _elapsedSeconds = 0;
  Timer? _elapsedTimer;
  bool _isLoading = true;
  bool _isSessionComplete = false;
  String? _errorMessage;
  DateTime? _itemStartTime;
  List<String>? _currentDistractors;
  int _newWordsPresented = 0;
  int _reviewsPresented = 0;
  String? _loadingDistractorsForCardId;
  final Set<Future<void>> _pendingReviewWrites = <Future<void>>{};

  // Progress tracking
  final _progressStageService = ProgressStageService();
  final List<StageTransition> _stageTransitions = [];
  ProgressStage? _lastTransitionStage;
  String? _lastTransitionWord;
  Timer? _transitionFeedbackTimer;
  int _transitionFeedbackNonce = 0;
  // Track local count increments within session for accurate stage calculation
  final Map<String, int> _localSuccessCountDeltas = {};
  final Map<String, int> _localLapseDeltas = {};
  final Map<String, int> _localHardMethodDeltas = {};

  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _initializeSession();
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    _transitionFeedbackTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeSession() async {
    if (_initStarted) return;
    _initStarted = true;

    final currentUser = ref.read(currentUserProvider);
    final userId = currentUser.valueOrNull?.id;
    if (userId == null) {
      if (mounted) {
        Navigator.of(context).pop();
      }
      return;
    }

    try {
      final dataService = ref.read(supabaseDataServiceProvider);
      final planner = ref.read(sessionPlannerProvider);
      final queue = ref.read(reviewWriteQueueProvider);

      // Drain any queued writes from previous sessions (Layer 3: startup drain)
      unawaited(_drainQueueSilently(queue, dataService, userId));

      // Check for existing active session
      final activeSessionData = await dataService.getActiveSession(userId);
      LearningSessionModel? activeSession;
      final now = DateTime.now().toUtc();

      if (activeSessionData != null) {
        activeSession = LearningSessionModel.fromJson(activeSessionData);
        // Check if session is expired
        if (activeSession.expiresAt.isBefore(now)) {
          // Expire the old session
          await dataService.endSession(
            sessionId: activeSession.id,
            outcome: SessionOutcomeEnum.expired.value,
          );
          activeSession = null;
        }
      }

      // Try to use prefetch data for instant start (both normal and quick review)
      SessionPrefetch? prefetchData;
      try {
        prefetchData = await ref.read(sessionPrefetchProvider.future);
      } catch (_) {
        // Prefetch failed — fall back to fresh computation below
      }

      // Get user preferences (from prefetch if available)
      final prefs = prefetchData?.preferences ??
          await dataService.getOrCreatePreferences(userId);
      final dailyTimeTargetMinutes =
          prefs['daily_time_target_minutes'] as int? ??
          AppDefaults.sessionDefault;
      final newWordsPerSession =
          prefs['new_words_per_session'] as int? ??
          AppDefaults.newWordsDefault;

      // Step 1: Get session params (from prefetch if available)
      final int timeTarget = dailyTimeTargetMinutes;

      final params = prefetchData?.params ??
          await planner.computeSessionParams(
            userId: userId,
            timeTargetMinutes: timeTarget,
            newWordsPerSession: newWordsPerSession,
          );

      if (params.maxItems <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No items available to practice')),
          );
          Navigator.of(context).pop();
        }
        return;
      }

      // Store maxItems limit for enforcement
      _maxItems = params.maxItems;

      // Step 2: Get initial batch (from prefetch if available, else fetch fresh)
      // Normal session: front-load new words in initial batch (reviewLimit = maxItems - newWordCap, newLimit = newWordCap)
      // Quick review: binary logic based on dueCount (if dueCount > 0: reviews only, else: new words only)
      final int reviewLimit;
      final int newLimit;

      if (widget.isQuickReview) {
        final quickReviewSize = timeTarget; // e.g., 3, 5, or 8 items
        if (params.dueCount > 0) {
          // Has due reviews: reviews only
          reviewLimit = quickReviewSize;
          newLimit = 0;
        } else {
          // No due reviews: new words only
          reviewLimit = 0;
          newLimit = quickReviewSize;
        }
      } else {
        // Front-load new words, clamp so reviewLimit never goes negative
        final cappedNew = min(params.newWordCap, params.maxItems);
        reviewLimit = params.maxItems - cappedNew;
        newLimit = cappedNew;
      }

      // For normal sessions, use prefetched items. For quick review, always
      // fetch fresh (different limits than the prefetched batch).
      final initialItems = (!widget.isQuickReview && prefetchData != null)
          ? prefetchData.initialItems
          : await planner.fetchBatch(
              userId: userId,
              reviewLimit: reviewLimit,
              newLimit: newLimit,
            );

      if (initialItems.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No items available to practice')),
          );
          Navigator.of(context).pop();
        }
        return;
      }

      // Apply bookend ordering for emotional arc
      final bookendResult = planner.applyBookendOrder(initialItems);
      final orderedItems = bookendResult.ordered;
      final closerItem = bookendResult.closer;

      // Track fetched card IDs
      for (final item in orderedItems) {
        _fetchedCardIds.add(item.cardId);
      }
      if (closerItem != null) {
        _fetchedCardIds.add(closerItem.cardId);
      }

      // Create new session if needed
      if (activeSession == null) {
        final plannedMinutes = dailyTimeTargetMinutes;
        final expiresAt = DateTime(
          now.year,
          now.month,
          now.day,
          23,
          59,
          59,
        ).toUtc();

        final sessionId = _uuid.v4();
        final sessionData = await dataService.createSession(
          id: sessionId,
          userId: userId,
          plannedMinutes: plannedMinutes,
          expiresAt: expiresAt,
        );
        activeSession = LearningSessionModel.fromJson(sessionData);
      }

      // Load distractors for first item if it's recognition mode
      if (orderedItems.isNotEmpty && orderedItems[0].isRecognition) {
        _currentDistractors = null;
        await _loadDistractorsForItem(orderedItems[0], userId);
      }

      // Proactively replenish enrichment buffer (fire-and-forget)
      unawaited(ref.read(enrichmentServiceProvider).replenishIfNeeded(userId));

      if (mounted) {
        // Estimate: ordered items + closer (if any)
        final estimate =
            orderedItems.length + (closerItem != null ? 1 : 0);

        setState(() {
          _items = orderedItems;
          _closerItem = closerItem;
          _estimatedTotalItems = estimate;
          _session = activeSession;
          _elapsedSeconds = activeSession?.elapsedSeconds ?? 0;
          _currentItemIndex = 0;
          _newWordsPresented = activeSession?.newWordsPresented ?? 0;
          _reviewsPresented = activeSession?.reviewsPresented ?? 0;
          _isLoading = false;
          _itemStartTime = DateTime.now();
        });
        _startElapsedTimer();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load session: $e';
        });
      }
    }
  }

  /// Prefetch more cards when the user is running low on queued items.
  /// When [force] is true, waits for any in-flight fetch and always attempts
  /// to load more (used when the user has exhausted the current batch).
  Future<void> _maybePrefetchMore({bool force = false}) async {
    // Skip prefetching in quick review mode — fixed item count
    if (widget.isQuickReview) return;

    // Stop prefetching if we've reached the maxItems limit
    if (_maxItems > 0 && _items.length >= _maxItems) return;

    if (!force) {
      final remaining = _items.length - _currentItemIndex - 1;
      if (remaining >= _prefetchThreshold || _isFetchingMore) return;
    } else if (_isFetchingMore) {
      // Wait for the in-flight fetch to complete
      await _fetchCompleter?.future;
      // Check if that fetch already gave us items
      if (_currentItemIndex < _items.length) return;
    }

    final userId = ref.read(currentUserProvider).valueOrNull?.id;
    if (userId == null) return;

    _isFetchingMore = true;
    _fetchCompleter = Completer<void>();

    try {
      final planner = ref.read(sessionPlannerProvider);
      // Calculate how many items we can still fetch without exceeding maxItems
      final remainingSlots = _maxItems > 0 ? _maxItems - _items.length : _batchSize;
      final effectiveBatchSize = remainingSlots > 0
          ? (remainingSlots < _batchSize ? remainingSlots : _batchSize)
          : 0;

      if (effectiveBatchSize <= 0) {
        // Already at max capacity
        return;
      }

      // Prefetches are reviews-only (newLimit=0) with excludeIds
      final newItems = await planner.fetchBatch(
        userId: userId,
        reviewLimit: effectiveBatchSize,
        newLimit: 0, // Reviews-only for prefetch
        excludeCardIds: _fetchedCardIds,
      );

      if (mounted) {
        setState(() {
          if (newItems.isNotEmpty) {
            for (final item in newItems) {
              _fetchedCardIds.add(item.cardId);
            }
            _items = [..._items, ...newItems];
          }
          // Self-correct estimate: if batch returned fewer items than
          // requested, or we've hit maxItems, true total is _items.length
          if (newItems.length < effectiveBatchSize ||
              (_maxItems > 0 && _items.length >= _maxItems)) {
            _estimatedTotalItems = _items.length;
          }
        });
      }

      if (newItems.isNotEmpty) {
        // Proactively replenish enrichment buffer after prefetch (fire-and-forget)
        unawaited(
          ref.read(enrichmentServiceProvider).replenishIfNeeded(userId),
        );
      }
    } catch (e) {
      // Prefetch failure is silent - session continues with current batch
    } finally {
      _isFetchingMore = false;
      _fetchCompleter?.complete();
      _fetchCompleter = null;
    }
  }

  Future<void> _loadDistractorsForItem(PlannedItem item, String userId) async {
    if (_loadingDistractorsForCardId == item.cardId) return;

    _loadingDistractorsForCardId = item.cardId;
    final distractorService = ref.read(distractorServiceProvider);

    try {
      final distractors = await distractorService.selectDistractors(
        targetItemId: item.vocabularyId,
        userId: userId,
        count: 3,
      );

      if (!mounted) return;
      setState(() {
        _currentDistractors = distractors.map((d) => d.gloss).toList();
      });
    } finally {
      _loadingDistractorsForCardId = null;
    }
  }

  void _startElapsedTimer() {
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _elapsedSeconds++;
      });
      // Save progress periodically (every 5 seconds)
      if (_elapsedSeconds % 5 == 0 && _session != null) {
        _saveProgress();
      }
    });
  }

  Future<void> _handleRecognitionAnswer(String selected, bool isCorrect) async {
    final responseTimeMs = _itemStartTime != null
        ? DateTime.now().difference(_itemStartTime!).inMilliseconds
        : 5000;

    // Convert to rating: correct=Good, incorrect=Again
    final rating = isCorrect ? ReviewRating.good : ReviewRating.again;
    await _processReview(rating, responseTimeMs);
  }

  Future<void> _handleRecallGrade(int rating) async {
    final responseTimeMs = _itemStartTime != null
        ? DateTime.now().difference(_itemStartTime!).inMilliseconds
        : 5000;

    await _processReview(rating, responseTimeMs);
  }

  Future<void> _processReview(int rating, int responseTimeMs) async {
    if (_session == null) return;
    if (_currentItemIndex >= _items.length) return;

    final reviewedIndex = _currentItemIndex;
    final currentItem = _items[reviewedIndex];
    final userId = ref.read(currentUserProvider).valueOrNull?.id;
    if (userId == null) return;

    // Track counters immediately to keep UI responsive.
    if (currentItem.isNewWord) {
      _newWordsPresented++;
    } else {
      _reviewsPresented++;
    }

    // Retry queue logic: Add "Again" cards (rating < 3) to retry queue
    // Cap at 2 attempts per card
    if (rating < 3) {
      final attempts = _retryAttempts[currentItem.cardId] ?? 0;
      if (attempts < 2) {
        _retryQueue.add(currentItem);
        _retryAttempts[currentItem.cardId] = attempts + 1;
        _estimatedTotalItems++;
      }
    }

    final elapsedSecondsSnapshot = _elapsedSeconds;
    final itemsCompletedSnapshot = reviewedIndex + 1;
    final newWordsPresentedSnapshot = _newWordsPresented;
    final reviewsPresentedSnapshot = _reviewsPresented;
    final sessionId = _session!.id;

    // Calculate stage transition INSTANTLY (before advancing to next card)
    final srsScheduler = ref.read(srsSchedulerProvider());
    final learningCard = currentItem.sessionCard.toLearningCard(userId);

    // Get base count + any increments from earlier reviews in this session
    final baseCount = currentItem.sessionCard.nonTranslationSuccessCount;
    final localDelta = _localSuccessCountDeltas[currentItem.cardId] ?? 0;
    final currentCount = baseCount + localDelta;

    // Windowed lapse counts + local deltas
    final baseLapsesLast8 = currentItem.sessionCard.lapsesLast8;
    final baseLapsesLast12 = currentItem.sessionCard.lapsesLast12;
    final lapseDelta = _localLapseDeltas[currentItem.cardId] ?? 0;
    final currentLapsesLast8 = baseLapsesLast8 + lapseDelta;
    final currentLapsesLast12 = baseLapsesLast12 + lapseDelta;

    // Hard method success count + local deltas
    final baseHardMethod = currentItem.sessionCard.hardMethodSuccessCount;
    final hardMethodDelta = _localHardMethodDeltas[currentItem.cardId] ?? 0;
    final currentHardMethod = baseHardMethod + hardMethodDelta;

    final stageBefore = _progressStageService.calculateStage(
      card: learningCard,
      nonTranslationSuccessCount: currentCount,
      lapsesLast8: currentLapsesLast8,
      lapsesLast12: currentLapsesLast12,
      hardMethodSuccessCount: currentHardMethod,
    );

    final reviewResult = srsScheduler.reviewCard(
      card: learningCard,
      rating: rating,
      interactionMode: currentItem.interactionMode,
    );

    // Check if this review increments the non-translation success count
    final isNonTransSuccess = rating >= 3 &&
        currentItem.cueType != null &&
        currentItem.cueType != CueType.translation;
    final newCount = currentCount + (isNonTransSuccess ? 1 : 0);

    // Update local delta tracking
    if (isNonTransSuccess) {
      _localSuccessCountDeltas[currentItem.cardId] = localDelta + 1;
    }

    // Track lapse deltas for windowed counts
    final isLapse = rating == 1;
    if (isLapse) {
      _localLapseDeltas[currentItem.cardId] = lapseDelta + 1;
    }

    // Track hard method (disambiguation/usage recognition) success deltas
    final isHardMethodSuccess = rating >= 3 &&
        (currentItem.cueType == CueType.disambiguation ||
         currentItem.cueType == CueType.usageRecognition);
    if (isHardMethodSuccess) {
      _localHardMethodDeltas[currentItem.cardId] = hardMethodDelta + 1;
    }

    final newLapsesLast8 = currentLapsesLast8 + (isLapse ? 1 : 0);
    final newLapsesLast12 = currentLapsesLast12 + (isLapse ? 1 : 0);
    final newHardMethod = currentHardMethod + (isHardMethodSuccess ? 1 : 0);

    final updatedCard = learningCard.copyWith(
      state: reviewResult.updatedCard.state,
      stability: reviewResult.updatedCard.stability,
      difficulty: reviewResult.updatedCard.difficulty,
      reps: reviewResult.updatedCard.reps,
      lapses: reviewResult.updatedCard.lapses,
    );

    final stageAfter = _progressStageService.calculateStage(
      card: updatedCard,
      nonTranslationSuccessCount: newCount,
      lapsesLast8: newLapsesLast8,
      lapsesLast12: newLapsesLast12,
      hardMethodSuccessCount: newHardMethod,
    );

    // Show transition feedback immediately if stage progressed
    if (stageAfter != stageBefore &&
        stageAfter.index > stageBefore.index) {
      final transition = StageTransition(
        vocabularyId: currentItem.vocabularyId,
        wordText: currentItem.displayWord,
        fromStage: stageBefore,
        toStage: stageAfter,
        timestamp: DateTime.now(),
      );
      _stageTransitions.add(transition);
      _showStageTransitionFeedback(stageAfter, currentItem.displayWord);
    }

    // Persist review in the background with pre-computed stage data.
    final persistFuture = _persistReview(
      userId: userId,
      currentItem: currentItem,
      rating: rating,
      responseTimeMs: responseTimeMs,
      sessionId: sessionId,
      elapsedSecondsSnapshot: elapsedSecondsSnapshot,
      itemsCompletedSnapshot: itemsCompletedSnapshot,
      newWordsPresentedSnapshot: newWordsPresentedSnapshot,
      reviewsPresentedSnapshot: reviewsPresentedSnapshot,
      reviewResult: reviewResult,
      stageAfter: stageAfter,
    );
    _trackPendingReviewWrite(persistFuture);

    // Update session progress immediately (sequential, monotonic)
    final dataService = ref.read(supabaseDataServiceProvider);
    unawaited(
      dataService.updateSessionProgress(
        sessionId: sessionId,
        elapsedSeconds: elapsedSecondsSnapshot,
        itemsPresented: itemsCompletedSnapshot,
        itemsCompleted: itemsCompletedSnapshot,
        newWordsPresented: newWordsPresentedSnapshot,
        reviewsPresented: reviewsPresentedSnapshot,
      ),
    );

    // Move to next item (or drain retry queue, serve closer, or complete).
    final nextIndex = reviewedIndex + 1;
    if (nextIndex >= _items.length) {
      // Main items exhausted - check retry queue
      if (_retryQueue.isNotEmpty) {
        // Drain retry queue: add retry items to main queue
        if (!mounted) return;
        setState(() {
          _items.addAll(_retryQueue);
          _retryQueue.clear();
        });
        // Continue with next item (first retry)
      } else if (_closerItem != null) {
        // Serve the bookend closer as the very last card
        if (!mounted) return;
        setState(() {
          _items.add(_closerItem!);
          _closerItem = null;
        });
        // Continue with closer item
      } else {
        // No retry items, no closer - try prefetching more
        await _maybePrefetchMore(force: true);
        if (nextIndex >= _items.length) {
          // No more items available - complete session
          await _completeSession();
          return;
        }
      }
    } else {
      unawaited(_maybePrefetchMore());
    }

    if (!mounted) return;
    final nextItem = _items[nextIndex];
    setState(() {
      _currentItemIndex = nextIndex;
      _itemStartTime = DateTime.now();
      _currentDistractors = null;
    });

    if (nextItem.isRecognition) {
      unawaited(_loadDistractorsForItem(nextItem, userId));
    }
  }

  Future<void> _persistReview({
    required String userId,
    required PlannedItem currentItem,
    required int rating,
    required int responseTimeMs,
    required String sessionId,
    required int elapsedSecondsSnapshot,
    required int itemsCompletedSnapshot,
    required int newWordsPresentedSnapshot,
    required int reviewsPresentedSnapshot,
    required ReviewResult reviewResult,
    required ProgressStage stageAfter,
  }) async {
    final dataService = ref.read(supabaseDataServiceProvider);
    final queue = ref.read(reviewWriteQueueProvider);

    try {
      // Layer 1: Retry with exponential backoff (3 attempts, 1s/2s/4s)
      await retryWithBackoff(() async {
        await dataService.updateLearningCard(
          cardId: currentItem.cardId,
          state: reviewResult.updatedCard.state,
          due: reviewResult.updatedCard.due,
          stability: reviewResult.updatedCard.stability,
          difficulty: reviewResult.updatedCard.difficulty,
          reps: reviewResult.updatedCard.reps,
          lapses: reviewResult.updatedCard.lapses,
          isLeech: reviewResult.updatedCard.isLeech,
          progressStage: stageAfter.toDbString(),
        );

        final reviewLogId = _uuid.v4();
        await dataService.insertReviewLog(
          id: reviewLogId,
          userId: userId,
          learningCardId: currentItem.cardId,
          rating: rating,
          interactionMode: currentItem.interactionMode,
          stateBefore: reviewResult.reviewLog.stateBefore,
          stateAfter: reviewResult.reviewLog.stateAfter,
          stabilityBefore: reviewResult.reviewLog.stabilityBefore,
          stabilityAfter: reviewResult.reviewLog.stabilityAfter,
          difficultyBefore: reviewResult.reviewLog.difficultyBefore,
          difficultyAfter: reviewResult.reviewLog.difficultyAfter,
          responseTimeMs: responseTimeMs,
          retrievabilityAtReview: reviewResult.reviewLog.retrievabilityAtReview,
          sessionId: sessionId,
          cueType: currentItem.cueType?.toDbString(),
        );
      });
    } catch (error) {
      // Layer 2: All retries failed — enqueue for later
      await queue.enqueue(
        QueuedReviewWrite(
          cardId: currentItem.cardId,
          vocabularyId: currentItem.vocabularyId,
          userId: userId,
          sessionId: sessionId,
          rating: rating,
          responseTimeMs: responseTimeMs,
          interactionMode: currentItem.interactionMode,
          stateBefore: reviewResult.reviewLog.stateBefore,
          stateAfter: reviewResult.reviewLog.stateAfter,
          stabilityBefore: reviewResult.reviewLog.stabilityBefore,
          stabilityAfter: reviewResult.reviewLog.stabilityAfter,
          difficultyBefore: reviewResult.reviewLog.difficultyBefore,
          difficultyAfter: reviewResult.reviewLog.difficultyAfter,
          retrievabilityAtReview: reviewResult.reviewLog.retrievabilityAtReview,
          cueType: currentItem.cueType?.toDbString(),
          due: reviewResult.updatedCard.due,
          state: reviewResult.updatedCard.state,
          stability: reviewResult.updatedCard.stability,
          difficulty: reviewResult.updatedCard.difficulty,
          reps: reviewResult.updatedCard.reps,
          lapses: reviewResult.updatedCard.lapses,
          isLeech: reviewResult.updatedCard.isLeech,
          progressStage: stageAfter.toDbString(),
          timestamp: DateTime.now(),
        ),
      );
      // No user-facing error during the session — graceful degradation
    }
  }

  void _trackPendingReviewWrite(Future<void> writeFuture) {
    _pendingReviewWrites.add(writeFuture);
    writeFuture.whenComplete(() {
      _pendingReviewWrites.remove(writeFuture);
    });
  }

  Future<void> _flushPendingReviewWrites() async {
    if (_pendingReviewWrites.isEmpty) return;
    await Future.wait(_pendingReviewWrites.toList(), eagerError: false);
  }

  void _showStageTransitionFeedback(ProgressStage stage, String wordText) {
    _transitionFeedbackTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _lastTransitionStage = stage;
      _lastTransitionWord = wordText;
      _transitionFeedbackNonce++;
    });
    _transitionFeedbackTimer = Timer(const Duration(milliseconds: 2900), () {
      if (!mounted) return;
      setState(() {
        _lastTransitionStage = null;
        _lastTransitionWord = null;
      });
    });
  }

  Future<void> _drainQueueSilently(
    ReviewWriteQueue queue,
    SupabaseDataService dataService,
    String userId,
  ) async {
    try {
      await queue.drain((write) async {
        await dataService.updateLearningCard(
          cardId: write.cardId,
          state: write.state,
          due: write.due,
          stability: write.stability,
          difficulty: write.difficulty,
          reps: write.reps,
          lapses: write.lapses,
          isLeech: write.isLeech,
          progressStage: write.progressStage,
        );

        await dataService.insertReviewLog(
          id: _uuid.v4(),
          userId: userId,
          learningCardId: write.cardId,
          rating: write.rating,
          interactionMode: write.interactionMode,
          stateBefore: write.stateBefore,
          stateAfter: write.stateAfter,
          stabilityBefore: write.stabilityBefore,
          stabilityAfter: write.stabilityAfter,
          difficultyBefore: write.difficultyBefore,
          difficultyAfter: write.difficultyAfter,
          responseTimeMs: write.responseTimeMs,
          retrievabilityAtReview: write.retrievabilityAtReview,
          sessionId: write.sessionId,
          cueType: write.cueType,
        );
      });
    } catch (error) {
      // Silent failure — queue will retry on next app start
    }
  }

  Future<void> _completeSession() async {
    if (_session == null || _isSessionComplete) return;
    _elapsedTimer?.cancel();

    final dataService = ref.read(supabaseDataServiceProvider);
    final userId = ref.read(currentUserProvider).valueOrNull?.id;
    if (userId == null) return;

    await _flushPendingReviewWrites();

    // Determine outcome — session is always item-based now,
    // but mark as "complete" if all items were exhausted
    final totalSeconds = _session!.plannedMinutes * 60;
    final allItemsExhausted = _currentItemIndex + 1 >= _items.length;
    final outcome = allItemsExhausted
        ? SessionOutcomeEnum.complete
        : SessionOutcomeEnum.partial;

    await dataService.endSession(
      sessionId: _session!.id,
      outcome: outcome.value,
    );

    // Increment streak if complete AND not a quick review
    // Quick reviews are bonus rounds and don't affect streak
    if (outcome == SessionOutcomeEnum.complete && !widget.isQuickReview) {
      await ref.read(streakNotifierProvider.notifier).incrementStreak();
    }

    // Invalidate providers to refresh home screen
    ref.invalidate(hasCompletedTodayProvider);
    ref.invalidate(todayProgressProvider);
    ref.invalidate(currentStreakProvider);
    ref.invalidate(sessionPrefetchProvider);

    setState(() {
      _isSessionComplete = true;
    });

    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (context) => SessionCompleteScreen(
          sessionId: _session!.id,
          itemsCompleted: _currentItemIndex + 1,
          totalItems: _estimatedTotalItems,
          elapsedSeconds: _elapsedSeconds,
          plannedSeconds: totalSeconds,
          isFullCompletion: outcome == SessionOutcomeEnum.complete,
          allItemsExhausted: allItemsExhausted,
          transitions: _stageTransitions,
          isQuickReview: widget.isQuickReview,
        ),
      ),
    );
  }

  Future<void> _saveProgress() async {
    if (_session == null) return;

    final dataService = ref.read(supabaseDataServiceProvider);
    await dataService.updateSessionProgress(
      sessionId: _session!.id,
      elapsedSeconds: _elapsedSeconds,
      itemsPresented: _currentItemIndex,
      itemsCompleted: _currentItemIndex,
      newWordsPresented: _newWordsPresented,
      reviewsPresented: _reviewsPresented,
    );
  }

  Future<void> _handleClosePressed() async {
    _elapsedTimer?.cancel();
    await _saveProgress();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.masteryColors;

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Preparing your session...',
                style: MasteryTextStyles.body.copyWith(
                  color: colors.mutedForeground,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null || _items.isEmpty || _session == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: colors.mutedForeground,
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage ?? 'Unable to start session',
                  textAlign: TextAlign.center,
                  style: MasteryTextStyles.body.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Go back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentItem = _currentItemIndex < _items.length
        ? _items[_currentItemIndex]
        : null;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header with close button and progress bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: colors.cardBackground,
                border: Border(bottom: BorderSide(color: colors.border)),
              ),
              child: Row(
                children: [
                  MasteryBackButton.close(
                    onPressed: _handleClosePressed,
                  ),
                  Expanded(
                    child: SessionProgressBar(
                      completedItems: _currentItemIndex,
                      totalItems: _estimatedTotalItems,
                    ),
                  ),
                  const SizedBox(width: 48), // Balance close button width
                ],
              ),
            ),

            if (currentItem != null)
              // Current item card - now uses SessionCard data directly!
              Expanded(
                child: Stack(
                  children: [
                    _buildItemCard(currentItem, context),
                    if (_lastTransitionStage != null && _lastTransitionWord != null)
                      Positioned(
                        top: 12,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: ProgressMicroFeedback(
                            key: ValueKey(
                              'stage_feedback_$_transitionFeedbackNonce',
                            ),
                            stage: _lastTransitionStage!,
                            wordText: _lastTransitionWord!,
                          ),
                        ),
                      ),
                  ],
                ),
              )
            else
              Expanded(
                child: Center(
                  child: Text(
                    'Session complete!',
                    style: MasteryTextStyles.bodyBold.copyWith(
                      color: colors.foreground,
                    ),
                  ),
                ),
              ),
            _buildBottomActionZone(context),
          ],
        ),
      ),
    );
  }

  /// Build the card widget for the current item using SessionCard data.
  /// Uses CueSelector to build cue content at runtime from global dictionary data.
  Widget _buildItemCard(PlannedItem item, BuildContext context) {
    final card = item.sessionCard;
    final cueSelector = ref.read(cueSelectorProvider);

    // Build cue content for the selected cue type
    final cueType = item.cueType ?? CueType.translation;
    final cueContent = cueSelector.buildCueContent(card, cueType);

    if (item.isRecognition) {
      final distractors = _currentDistractors;

      // Never inject fake answer options. If distractors are unavailable,
      // degrade to recall mode for this card instead of showing placeholders.
      if (distractors == null || distractors.length < 3) {
        final userId = ref.read(currentUserProvider).valueOrNull?.id;
        if (userId != null && _loadingDistractorsForCardId != item.cardId) {
          unawaited(_loadDistractorsForItem(item, userId));
        }

        return RecallCard(
          word: card.displayWord,
          answer: cueContent.answer,
          alternatives: _getAlternatives(card),
          context: card.encounterContext,
          onGrade: _handleRecallGrade,
        );
      }

      return RecognitionCard(
        word: card.displayWord,
        correctAnswer: cueContent.answer,
        distractors: distractors,
        context: card.encounterContext,
        onAnswer: _handleRecognitionAnswer,
      );
    }

    // Dispatch based on cue type - use runtime-built content
    switch (item.cueType) {
      case CueType.definition:
        return DefinitionCueCard(
          definition: cueContent.prompt,
          targetWord: cueContent.answer,
          hintText: null,
          onGrade: _handleRecallGrade,
        );
      case CueType.synonym:
        return SynonymCueCard(
          synonymPhrase: cueContent.prompt,
          targetWord: cueContent.answer,
          onGrade: _handleRecallGrade,
        );
      case CueType.disambiguation:
        // For disambiguation, we need to parse confusables into options
        final options = _parseDisambiguationOptions(card);
        if (options.options.isEmpty) {
          return RecallCard(
            word: card.displayWord,
            answer: cueContent.answer,
            context: card.encounterContext,
            onGrade: _handleRecallGrade,
          );
        }
        return DisambiguationCard(
          clozeSentence: cueContent.prompt,
          options: options.options,
          correctIndex: options.correctIndex,
          explanation: '',
          onGrade: _handleRecallGrade,
        );
      case CueType.contextCloze:
        return ClozeCueCard(
          sentenceWithBlank: cueContent.prompt,
          targetWord: cueContent.answer,
          hintText: null,
          onGrade: _handleRecallGrade,
        );
      case CueType.novelCloze:
        return NovelClozeCueCard(
          sentenceWithBlank: cueContent.prompt,
          targetWord: cueContent.answer,
          hintText: null,
          onGrade: _handleRecallGrade,
        );
      case CueType.usageRecognition:
        if (card.usageExamples.isNotEmpty) {
          final usage = card.usageExamples.first;
          return UsageRecognitionCard(
            word: card.displayWord,
            correctSentence: usage.correctSentence.sentence,
            incorrectSentences:
                usage.incorrectSentences.map((s) => s.sentence).toList(),
            onGrade: _handleRecallGrade,
          );
        }
        // Fallback if no usage examples
        return RecallCard(
          word: card.displayWord,
          answer: cueContent.answer,
          context: card.encounterContext,
          onGrade: _handleRecallGrade,
        );
      case CueType.translation:
      case null:
        return RecallCard(
          word: card.displayWord,
          answer: cueContent.answer,
          alternatives: _getAlternatives(card),
          context: card.encounterContext,
          onGrade: _handleRecallGrade,
        );
    }
  }

  Widget _buildBottomActionZone(BuildContext context) {
    // No longer showing inline error messages — graceful degradation with queue
    return const SizedBox.shrink();
  }

  /// Parse disambiguation options from confusables
  ({List<String> options, int correctIndex}) _parseDisambiguationOptions(
    SessionCard card,
  ) {
    if (card.confusables.isEmpty) return (options: <String>[], correctIndex: 0);

    // Build options from confusables - target word + confusable words
    final options = <String>[card.displayWord];
    for (final confusable in card.confusables) {
      options.add(confusable.word);
    }

    // Shuffle and track correct index
    final correctWord = card.displayWord;
    options.shuffle();
    final correctIndex = options.indexOf(correctWord);

    return (options: options, correctIndex: correctIndex);
  }

  /// Get alternative translations from the session card
  List<String>? _getAlternatives(SessionCard card) {
    // Get alternatives from the first available language
    // In a real app, this would use the user's language preference
    if (card.translations.isEmpty) return null;
    final firstLang = card.translations.values.first;
    return firstLang.alternatives.isNotEmpty ? firstLang.alternatives : null;
  }
}
