import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/app_defaults.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/text_styles.dart';
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
import '../widgets/progress_micro_feedback.dart';
import '../widgets/recall_card.dart';
import '../widgets/recognition_card.dart';
import '../widgets/session_progress_bar.dart';
import '../widgets/synonym_cue_card.dart';
import 'session_complete_screen.dart';

/// Main session screen for learning
/// Presents items one by one with timer, saves progress after each item.
/// Uses incremental batch loading: fetches 5 cards initially, prefetches
/// more in the background as the user progresses.
class SessionScreen extends ConsumerStatefulWidget {
  const SessionScreen({super.key});

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen> {
  static const _initialBatchSize = 5;
  static const _prefetchThreshold = 3;
  static const _batchSize = 5;

  // Incremental batch state
  List<PlannedItem> _items = [];
  final Set<String> _fetchedCardIds = {};
  int _estimatedTotalItems = 0;
  bool _isFetchingMore = false;
  bool _initStarted = false;
  Completer<void>? _fetchCompleter;
  int _newWordsQueued = 0;
  int _newWordCap = 0;

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
  Timer? _transitionFeedbackTimer;
  int _transitionFeedbackNonce = 0;
  // Track local count increments within session for accurate stage calculation
  final Map<String, int> _localSuccessCountDeltas = {};

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

      // Get user preferences
      final prefs = await dataService.getOrCreatePreferences(userId);
      final dailyTimeTargetMinutes =
          prefs['daily_time_target_minutes'] as int? ??
          AppDefaults.dailyTimeTargetMinutes;
      final intensity = prefs['intensity'] as int? ?? AppDefaults.intensity;

      // Step 1: Compute lightweight session params (no card data)
      final params = await planner.computeSessionParams(
        userId: userId,
        timeTargetMinutes: dailyTimeTargetMinutes,
        intensity: intensity,
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

      // Step 2: Fetch initial batch of cards only
      final initialItems = await planner.fetchBatch(
        userId: userId,
        batchSize: _initialBatchSize,
        newWordCap: params.newWordCap,
      );

      debugPrint('[Session] Initial batch: ${initialItems.length} items');
      for (final item in initialItems) {
        debugPrint(
          '[Session] Card: word=${item.word}, state=${item.isNewWord ? 0 : "review"}, '
          'cueType=${item.cueType}',
        );
      }

      if (initialItems.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No items available to practice')),
          );
          Navigator.of(context).pop();
        }
        return;
      }

      // Track fetched card IDs and count new words
      var newWords = 0;
      for (final item in initialItems) {
        _fetchedCardIds.add(item.cardId);
        if (item.isNewWord) newWords++;
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
      if (initialItems.isNotEmpty && initialItems[0].isRecognition) {
        _currentDistractors = null;
        await _loadDistractorsForItem(initialItems[0], userId);
      }

      // Proactively replenish enrichment buffer (fire-and-forget)
      unawaited(ref.read(enrichmentServiceProvider).replenishIfNeeded(userId));

      if (mounted) {
        // Self-correct estimate if initial batch is already smaller
        final estimate = initialItems.length < _initialBatchSize
            ? initialItems.length
            : params.estimatedItemCount;
        setState(() {
          _items = initialItems;
          _estimatedTotalItems = estimate;
          _newWordsQueued = newWords;
          _newWordCap = params.newWordCap;
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
    } catch (e, stackTrace) {
      debugPrint('[Session] Failed to initialize session: $e');
      debugPrint('[Session] $stackTrace');
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
      final newItems = await planner.fetchBatch(
        userId: userId,
        batchSize: _batchSize,
        excludeCardIds: _fetchedCardIds,
        newWordsAlreadyQueued: _newWordsQueued,
        newWordCap: _newWordCap,
      );

      if (mounted) {
        setState(() {
          if (newItems.isNotEmpty) {
            for (final item in newItems) {
              _fetchedCardIds.add(item.cardId);
              if (item.isNewWord) _newWordsQueued++;
            }
            _items = [..._items, ...newItems];
          }
          // Self-correct estimate: if batch returned fewer items than
          // requested, we've exhausted the pool — true total is _items.length
          if (newItems.length < _batchSize) {
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
      debugPrint('[Session] Prefetch failed: $e');
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

    final stageBefore = _progressStageService.calculateStage(
      card: learningCard,
      nonTranslationSuccessCount: currentCount,
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
    );

    // Show transition feedback immediately if stage progressed
    if (stageAfter != stageBefore && stageAfter.index > stageBefore.index) {
      final transition = StageTransition(
        vocabularyId: currentItem.vocabularyId,
        wordText: currentItem.displayWord,
        fromStage: stageBefore,
        toStage: stageAfter,
        timestamp: DateTime.now(),
      );
      _stageTransitions.add(transition);
      _showStageTransitionFeedback(stageAfter);
      debugPrint(
        '[Session] Stage transition: ${currentItem.word} '
        '${stageBefore.displayName} → ${stageAfter.displayName}',
      );
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

    // Move to next item (or complete) without waiting for network writes.
    final nextIndex = reviewedIndex + 1;
    if (nextIndex >= _items.length) {
      await _maybePrefetchMore(force: true);
      if (nextIndex >= _items.length) {
        await _completeSession();
        return;
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
    } catch (error, stackTrace) {
      // Layer 2: All retries failed — enqueue for later
      debugPrint('[Session] All retries failed, enqueueing write: $error');
      debugPrint('[Session] $stackTrace');

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

  void _showStageTransitionFeedback(ProgressStage stage) {
    _transitionFeedbackTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _lastTransitionStage = stage;
      _transitionFeedbackNonce++;
    });
    _transitionFeedbackTimer = Timer(const Duration(milliseconds: 2900), () {
      if (!mounted) return;
      setState(() {
        _lastTransitionStage = null;
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
      debugPrint('[Session] Queue drain failed: $error');
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

    // Increment streak if complete
    if (outcome == SessionOutcomeEnum.complete) {
      await ref.read(streakNotifierProvider.notifier).incrementStreak();
    }

    // Invalidate providers to refresh home screen
    ref.invalidate(hasCompletedTodayProvider);
    ref.invalidate(todayProgressProvider);
    ref.invalidate(currentStreakProvider);

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
                  IconButton(
                    onPressed: _handleClosePressed,
                    icon: Icon(Icons.close, color: colors.mutedForeground),
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
                    if (_lastTransitionStage != null)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: ProgressMicroFeedback(
                          key: ValueKey(
                            'stage_feedback_$_transitionFeedbackNonce',
                          ),
                          stage: _lastTransitionStage!,
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
  /// No additional queries needed - all data is already in the SessionCard!
  Widget _buildItemCard(PlannedItem item, BuildContext context) {
    final card = item.sessionCard;
    final meaning = card.primaryMeaning;

    // Get translation answer (primary translation or fallback to definition)
    final translationAnswer =
        meaning?.primaryTranslation ??
        meaning?.englishDefinition ??
        'Translation not available';

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
          answer: translationAnswer,
          context: null,
          onGrade: _handleRecallGrade,
        );
      }

      return RecognitionCard(
        word: card.displayWord,
        correctAnswer: translationAnswer,
        distractors: distractors,
        context: null, // Context would need encounter data
        onAnswer: _handleRecognitionAnswer,
      );
    }

    // Dispatch based on cue type - use data from SessionCard
    final cue = item.cueType != null ? card.getCue(item.cueType!) : null;

    switch (item.cueType) {
      case CueType.definition:
        return DefinitionCueCard(
          definition:
              cue?.promptText ??
              meaning?.englishDefinition ??
              translationAnswer,
          targetWord: cue?.answerText ?? card.displayWord,
          hintText: cue?.hintText,
          onGrade: _handleRecallGrade,
        );
      case CueType.synonym:
        return SynonymCueCard(
          synonymPhrase: cue?.promptText ?? _buildSynonymPrompt(meaning),
          targetWord: cue?.answerText ?? card.displayWord,
          onGrade: _handleRecallGrade,
        );
      case CueType.disambiguation:
        final options = _parseDisambiguationOptions(cue);
        if (options.options.isEmpty) {
          return RecallCard(
            word: card.displayWord,
            answer: translationAnswer,
            context: null,
            onGrade: _handleRecallGrade,
          );
        }
        return DisambiguationCard(
          clozeSentence: cue?.promptText ?? translationAnswer,
          options: options.options,
          correctIndex: options.correctIndex,
          explanation: cue?.hintText ?? '',
          onGrade: _handleRecallGrade,
        );
      case CueType.contextCloze:
        return ClozeCueCard(
          sentenceWithBlank: cue?.promptText ?? translationAnswer,
          targetWord: cue?.answerText ?? card.displayWord,
          hintText: cue?.hintText,
          onGrade: _handleRecallGrade,
        );
      case CueType.translation:
      case null:
        return RecallCard(
          word: card.displayWord,
          answer: translationAnswer,
          context: null, // Could load encounter context if needed
          onGrade: _handleRecallGrade,
        );
    }
  }

  Widget _buildBottomActionZone(BuildContext context) {
    // No longer showing inline error messages — graceful degradation with queue
    return const SizedBox.shrink();
  }

  /// Build a synonym prompt from the meaning's synonyms
  String _buildSynonymPrompt(SessionMeaning? meaning) {
    if (meaning == null || meaning.synonyms.isEmpty) {
      return 'What word means the same?';
    }
    return 'Synonym: ${meaning.synonyms.first}';
  }

  /// Parse disambiguation options from the cue
  ({List<String> options, int correctIndex}) _parseDisambiguationOptions(
    SessionCue? cue,
  ) {
    // No synthetic options. Until multi-option disambiguation payloads are
    // available in SessionCue, always fall back to recall mode.
    if (cue == null) return (options: <String>[], correctIndex: 0);
    return (options: <String>[], correctIndex: 0);
  }
}
