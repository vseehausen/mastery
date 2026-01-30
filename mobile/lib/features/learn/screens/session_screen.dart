import 'dart:async';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/text_styles.dart';
import '../../../data/database/database.dart';
import '../../../domain/models/learning_enums.dart';
import '../../../domain/models/planned_item.dart';
import '../../../domain/models/session_plan.dart';
import '../../../domain/services/distractor_service.dart';
import '../../../domain/services/srs_scheduler.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/database_provider.dart';
import '../../../providers/learning_providers.dart';
import '../providers/session_providers.dart';
import '../providers/streak_providers.dart';
import '../widgets/recall_card.dart';
import '../widgets/recognition_card.dart';
import '../widgets/session_progress_bar.dart';
import '../widgets/session_timer.dart';
import 'session_complete_screen.dart';

/// Main session screen for learning
/// Presents items one by one with timer, saves progress after each item
class SessionScreen extends ConsumerStatefulWidget {
  const SessionScreen({super.key});

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen> {
  SessionPlan? _sessionPlan;
  LearningSession? _session;
  int _currentItemIndex = 0;
  int _elapsedSeconds = 0;
  bool _isPaused = false;
  bool _isLoading = true;
  bool _isSessionComplete = false;
  DateTime? _itemStartTime;
  DistractorService? _distractorService;
  List<String>? _currentDistractors;
  int _newWordsPresented = 0;
  int _reviewsPresented = 0;

  @override
  void initState() {
    super.initState();
    _initializeSession();
  }

  Future<void> _initializeSession() async {
    final currentUser = ref.read(currentUserProvider);
    final userId = currentUser.valueOrNull?.id;
    if (userId == null) {
      if (mounted) {
        Navigator.of(context).pop();
      }
      return;
    }

    final sessionRepo = ref.read(sessionRepositoryProvider);
    final planner = ref.read(sessionPlannerProvider);
    final vocabRepo = ref.read(vocabularyRepositoryProvider);
    final userPrefsRepo = ref.read(userPreferencesRepositoryProvider);

    // Initialize distractor service
    _distractorService = DistractorService(vocabRepo);

    // Check for existing active session
    var activeSession = await sessionRepo.getActiveSession(userId);
    final now = DateTime.now().toUtc();

    if (activeSession != null) {
      // Check if session is expired
      if (activeSession.expiresAt.isBefore(now)) {
        // Expire the old session
        await sessionRepo.expireStaleSessions(userId);
        activeSession = null;
      }
    }

    // Get user preferences for building the plan
    final prefs = await userPrefsRepo.getOrCreateWithDefaults(userId);

    // Build session plan
    var plan = await planner.buildSessionPlan(
      userId: userId,
      timeTargetMinutes: prefs.dailyTimeTargetMinutes,
      intensity: prefs.intensity,
      targetRetention: prefs.targetRetention,
    );

    debugPrint('[Session] Initial plan items: ${plan.items.length}');

    // If no items locally, fetch learning cards directly from Supabase
    if (plan.items.isEmpty) {
      debugPrint('[Session] No items locally, fetching from server...');

      try {
        // Direct query to Supabase for learning cards
        final cardsResponse = await Supabase.instance.client
            .from('learning_cards')
            .select()
            .eq('user_id', userId);

        final cards = cardsResponse as List<dynamic>;
        debugPrint('[Session] Fetched ${cards.length} cards from server');

        // Save to local database
        final db = ref.read(databaseProvider);
        for (final item in cards) {
          final c = item as Map<String, dynamic>;
          final entry = LearningCardsCompanion(
            id: Value(c['id'] as String),
            userId: Value(c['user_id'] as String),
            vocabularyId: Value(c['vocabulary_id'] as String),
            state: Value(c['state'] as int),
            due: Value(DateTime.parse(c['due'] as String)),
            stability: Value((c['stability'] as num).toDouble()),
            difficulty: Value((c['difficulty'] as num).toDouble()),
            reps: Value(c['reps'] as int),
            lapses: Value(c['lapses'] as int),
            lastReview: Value(
              c['last_review'] != null
                  ? DateTime.parse(c['last_review'] as String)
                  : null,
            ),
            isLeech: Value(c['is_leech'] as bool),
            createdAt: Value(DateTime.parse(c['created_at'] as String)),
            updatedAt: Value(DateTime.parse(c['updated_at'] as String)),
            deletedAt: Value(
              c['deleted_at'] != null
                  ? DateTime.parse(c['deleted_at'] as String)
                  : null,
            ),
            version: Value(c['version'] as int? ?? 1),
            lastSyncedAt: Value(DateTime.now()),
            isPendingSync: const Value(false),
          );
          await db.into(db.learningCards).insertOnConflictUpdate(entry);
        }

        // Retry building the plan after fetching cards
        plan = await planner.buildSessionPlan(
          userId: userId,
          timeTargetMinutes: prefs.dailyTimeTargetMinutes,
          intensity: prefs.intensity,
          targetRetention: prefs.targetRetention,
        );
        debugPrint('[Session] Plan after fetch: ${plan.items.length} items');
      } catch (e) {
        debugPrint('[Session] Error fetching cards: $e');
      }
    }

    if (plan.items.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No items available to practice')),
        );
        Navigator.of(context).pop();
      }
      return;
    }

    // Create new session if needed
    if (activeSession == null) {
      final plannedMinutes = prefs.dailyTimeTargetMinutes;
      final expiresAt = DateTime(
        now.year,
        now.month,
        now.day,
        23,
        59,
        59,
      ).toUtc();

      activeSession = await sessionRepo.create(
        userId: userId,
        plannedMinutes: plannedMinutes,
        expiresAt: expiresAt,
      );
    }

    // Load distractors for first item if it's recognition mode
    if (plan.items.isNotEmpty && plan.items[0].isRecognition) {
      await _loadDistractorsForItem(plan.items[0], userId);
    }

    if (mounted) {
      setState(() {
        _sessionPlan = plan;
        _session = activeSession;
        _elapsedSeconds = activeSession?.elapsedSeconds ?? 0;
        _currentItemIndex = activeSession?.itemsCompleted ?? 0;
        _newWordsPresented = activeSession?.newWordsPresented ?? 0;
        _reviewsPresented = activeSession?.reviewsPresented ?? 0;
        _isLoading = false;
        _itemStartTime = DateTime.now();
      });
    }
  }

  Future<void> _loadDistractorsForItem(PlannedItem item, String userId) async {
    if (_distractorService == null) return;

    // Get vocabulary for the learning card
    final vocabRepo = ref.read(vocabularyRepositoryProvider);
    final vocab = await vocabRepo.getById(item.vocabularyId);

    if (vocab == null) {
      setState(() {
        _currentDistractors = ['Option A', 'Option B', 'Option C'];
      });
      return;
    }

    final distractors = await _distractorService!.selectDistractors(
      targetItemId: vocab.id,
      userId: userId,
      count: 3,
    );

    setState(() {
      _currentDistractors = distractors.map((d) => d.gloss).toList();
    });
  }

  void _handleTimerTick(int seconds) {
    setState(() {
      _elapsedSeconds = seconds;
    });

    // Save progress periodically (every 5 seconds)
    if (seconds % 5 == 0 && _session != null) {
      _saveProgress();
    }
  }

  void _handleTimeUp() {
    // Allow current item to finish, then complete
    _completeSession();
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
    if (_sessionPlan == null || _session == null) return;
    if (_currentItemIndex >= _sessionPlan!.items.length) return;

    final currentItem = _sessionPlan!.items[_currentItemIndex];
    final userId = ref.read(currentUserProvider).valueOrNull?.id;
    if (userId == null) return;

    final srsScheduler = ref.read(srsSchedulerProvider());
    final learningCardRepo = ref.read(learningCardRepositoryProvider);
    final reviewLogRepo = ref.read(reviewLogRepositoryProvider);
    final sessionRepo = ref.read(sessionRepositoryProvider);

    // Track new words vs reviews
    if (currentItem.isNewWord) {
      _newWordsPresented++;
    } else {
      _reviewsPresented++;
    }

    // Process the review with SRS
    final result = srsScheduler.reviewCard(
      card: currentItem.learningCard,
      rating: rating,
      interactionMode: currentItem.interactionMode,
    );

    // Save updated card
    await learningCardRepo.updateAfterReview(
      cardId: currentItem.learningCard.id,
      state: result.updatedCard.state,
      due: result.updatedCard.due,
      stability: result.updatedCard.stability,
      difficulty: result.updatedCard.difficulty,
      reps: result.updatedCard.reps,
      lapses: result.updatedCard.lapses,
      isLeech: result.updatedCard.isLeech,
    );

    // Save review log
    await reviewLogRepo.insert(
      userId: userId,
      learningCardId: currentItem.learningCard.id,
      rating: rating,
      interactionMode: currentItem.interactionMode,
      stateBefore: result.reviewLog.stateBefore,
      stateAfter: result.reviewLog.stateAfter,
      stabilityBefore: result.reviewLog.stabilityBefore,
      stabilityAfter: result.reviewLog.stabilityAfter,
      difficultyBefore: result.reviewLog.difficultyBefore,
      difficultyAfter: result.reviewLog.difficultyAfter,
      responseTimeMs: responseTimeMs,
      retrievabilityAtReview: result.reviewLog.retrievabilityAtReview,
      sessionId: _session!.id,
    );

    // Update session progress
    await sessionRepo.updateProgress(
      sessionId: _session!.id,
      elapsedSeconds: _elapsedSeconds,
      itemsPresented: _currentItemIndex + 1,
      itemsCompleted: _currentItemIndex + 1,
      newWordsPresented: _newWordsPresented,
      reviewsPresented: _reviewsPresented,
    );

    // Move to next item or complete
    final nextIndex = _currentItemIndex + 1;

    // Check if time is up or no more items
    final totalSeconds = _session!.plannedMinutes * 60 + _session!.bonusSeconds;
    final timeUp = _elapsedSeconds >= totalSeconds;

    if (timeUp || nextIndex >= _sessionPlan!.items.length) {
      await _completeSession();
    } else {
      // Load distractors for next item if needed
      final nextItem = _sessionPlan!.items[nextIndex];
      if (nextItem.isRecognition) {
        await _loadDistractorsForItem(nextItem, userId);
      }

      setState(() {
        _currentItemIndex = nextIndex;
        _itemStartTime = DateTime.now();
      });
    }
  }

  Future<void> _completeSession() async {
    if (_session == null || _isSessionComplete) return;

    final sessionRepo = ref.read(sessionRepositoryProvider);
    final syncService = ref.read(syncServiceProvider);
    final userId = ref.read(currentUserProvider).valueOrNull?.id;
    if (userId == null) return;

    // Determine outcome
    final totalSeconds = _session!.plannedMinutes * 60;
    final outcome = _elapsedSeconds >= totalSeconds
        ? SessionOutcomeEnum.complete
        : SessionOutcomeEnum.partial;

    await sessionRepo.endSession(
      sessionId: _session!.id,
      outcome: outcome.value,
    );

    // Increment streak if complete
    if (outcome == SessionOutcomeEnum.complete) {
      await ref.read(streakNotifierProvider.notifier).incrementStreak();
    }

    // Trigger sync to push learning data to server
    // Fire-and-forget sync to avoid blocking UI
    unawaited(syncService.pushChanges());

    // Invalidate providers to refresh home screen
    ref.invalidate(hasCompletedTodayProvider);
    ref.invalidate(todayProgressProvider);
    ref.invalidate(currentStreakProvider);

    setState(() {
      _isSessionComplete = true;
    });

    // Check if all items are exhausted
    final allItemsExhausted =
        _currentItemIndex + 1 >= (_sessionPlan?.items.length ?? 0);

    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (context) => SessionCompleteScreen(
          sessionId: _session!.id,
          itemsCompleted: _currentItemIndex + 1,
          totalItems: _sessionPlan?.items.length ?? 0,
          elapsedSeconds: _elapsedSeconds,
          plannedSeconds: totalSeconds,
          isFullCompletion: outcome == SessionOutcomeEnum.complete,
          allItemsExhausted: allItemsExhausted,
        ),
      ),
    );
  }

  Future<void> _saveProgress() async {
    if (_session == null) return;

    final sessionRepo = ref.read(sessionRepositoryProvider);
    await sessionRepo.updateProgress(
      sessionId: _session!.id,
      elapsedSeconds: _elapsedSeconds,
      itemsPresented: _currentItemIndex,
      itemsCompleted: _currentItemIndex,
      newWordsPresented: _newWordsPresented,
      reviewsPresented: _reviewsPresented,
    );
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                  color: isDark
                      ? MasteryColors.mutedForegroundDark
                      : MasteryColors.mutedForegroundLight,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_sessionPlan == null || _session == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'Unable to start session',
            style: MasteryTextStyles.body.copyWith(
              color: isDark
                  ? MasteryColors.mutedForegroundDark
                  : MasteryColors.mutedForegroundLight,
            ),
          ),
        ),
      );
    }

    final totalSeconds = _session!.plannedMinutes * 60 + _session!.bonusSeconds;
    final currentItem = _currentItemIndex < _sessionPlan!.items.length
        ? _sessionPlan!.items[_currentItemIndex]
        : null;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header with timer and progress
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? MasteryColors.cardDark
                    : MasteryColors.cardLight,
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? MasteryColors.borderDark
                        : MasteryColors.borderLight,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Close button
                      IconButton(
                        onPressed: () async {
                          await _saveProgress();
                          if (!context.mounted) return;
                          Navigator.of(context).pop();
                        },
                        icon: Icon(
                          Icons.close,
                          color: isDark
                              ? MasteryColors.mutedForegroundDark
                              : MasteryColors.mutedForegroundLight,
                        ),
                      ),
                      // Timer
                      Expanded(
                        child: SessionTimer(
                          totalSeconds: totalSeconds,
                          onTimeUp: _handleTimeUp,
                          onTick: _handleTimerTick,
                          isPaused: _isPaused,
                          initialElapsed: _elapsedSeconds,
                        ),
                      ),
                      // Pause button
                      IconButton(
                        onPressed: _togglePause,
                        icon: Icon(
                          _isPaused ? Icons.play_arrow : Icons.pause,
                          color: isDark
                              ? MasteryColors.mutedForegroundDark
                              : MasteryColors.mutedForegroundLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Progress bar
                  SessionProgressBar(
                    completedItems: _currentItemIndex,
                    totalItems: _sessionPlan!.items.length,
                  ),
                ],
              ),
            ),

            // Pause overlay
            if (_isPaused)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.pause_circle_outline,
                        size: 64,
                        color: isDark
                            ? MasteryColors.mutedForegroundDark
                            : MasteryColors.mutedForegroundLight,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Session Paused',
                        style: MasteryTextStyles.bodyBold.copyWith(
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the play button to continue',
                        style: MasteryTextStyles.bodySmall.copyWith(
                          color: isDark
                              ? MasteryColors.mutedForegroundDark
                              : MasteryColors.mutedForegroundLight,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (currentItem != null)
              // Current item card
              Expanded(child: _buildItemCard(currentItem, isDark))
            else
              Expanded(
                child: Center(
                  child: Text(
                    'Session complete!',
                    style: MasteryTextStyles.bodyBold.copyWith(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(PlannedItem item, bool isDark) {
    // Get vocabulary data and encounter context for the item
    return FutureBuilder<_VocabWithContext>(
      future: _loadVocabWithContext(item.vocabularyId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!;
        final contextText = data.encounterContext ?? data.vocab.word;

        if (item.isRecognition) {
          return RecognitionCard(
            word: data.vocab.word,
            correctAnswer: contextText,
            distractors:
                _currentDistractors ?? ['Option A', 'Option B', 'Option C'],
            context: data.encounterContext,
            onAnswer: _handleRecognitionAnswer,
          );
        } else {
          return RecallCard(
            word: data.vocab.word,
            answer: contextText,
            onGrade: _handleRecallGrade,
          );
        }
      },
    );
  }

  Future<_VocabWithContext> _loadVocabWithContext(String vocabularyId) async {
    final vocabRepo = ref.read(vocabularyRepositoryProvider);
    final encounterRepo = ref.read(encounterRepositoryProvider);

    final vocab = await vocabRepo.getById(vocabularyId);
    if (vocab == null) {
      return _VocabWithContext(
        vocab: Vocabulary(
          id: vocabularyId,
          userId: '',
          word: '???',
          stem: null,
          contentHash: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          deletedAt: null,
          lastSyncedAt: null,
          isPendingSync: false,
          version: 1,
        ),
        encounterContext: null,
      );
    }

    final encounter = await encounterRepo.getMostRecentForVocabulary(
      vocabularyId,
    );

    return _VocabWithContext(
      vocab: vocab,
      encounterContext: encounter?.context,
    );
  }
}

class _VocabWithContext {
  _VocabWithContext({required this.vocab, this.encounterContext});

  final Vocabulary vocab;
  final String? encounterContext;
}
