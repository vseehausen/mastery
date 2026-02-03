import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/text_styles.dart';
import '../../../domain/models/cue_type.dart';
import '../../../domain/models/learning_enums.dart';
import '../../../domain/models/learning_session.dart';
import '../../../domain/models/planned_item.dart';
import '../../../domain/models/session_card.dart';
import '../../../domain/models/session_plan.dart';
import '../../../domain/services/srs_scheduler.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/learning_providers.dart';
import '../../../providers/supabase_provider.dart';
import '../providers/session_providers.dart';
import '../providers/streak_providers.dart';
import '../widgets/cloze_cue_card.dart';
import '../widgets/definition_cue_card.dart';
import '../widgets/disambiguation_card.dart';
import '../widgets/recall_card.dart';
import '../widgets/recognition_card.dart';
import '../widgets/session_progress_bar.dart';
import '../widgets/session_timer.dart';
import '../widgets/synonym_cue_card.dart';
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
  LearningSessionModel? _session;
  int _currentItemIndex = 0;
  int _elapsedSeconds = 0;
  bool _isPaused = false;
  bool _isLoading = true;
  bool _isSessionComplete = false;
  DateTime? _itemStartTime;
  List<String>? _currentDistractors;
  int _newWordsPresented = 0;
  int _reviewsPresented = 0;

  final _uuid = const Uuid();

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

    final dataService = ref.read(supabaseDataServiceProvider);
    final planner = ref.read(sessionPlannerProvider);

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

    // Get user preferences for building the plan
    final prefs = await dataService.getOrCreatePreferences(userId);
    final dailyTimeTargetMinutes =
        prefs['daily_time_target_minutes'] as int? ?? 10;
    final intensity = prefs['intensity'] as int? ?? 1;
    final targetRetention =
        (prefs['target_retention'] as num?)?.toDouble() ?? 0.90;

    // Build session plan
    final plan = await planner.buildSessionPlan(
      userId: userId,
      timeTargetMinutes: dailyTimeTargetMinutes,
      intensity: intensity,
      targetRetention: targetRetention,
    );

    debugPrint('[Session] Initial plan items: ${plan.items.length}');

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
    final distractorService = ref.read(distractorServiceProvider);

    final distractors = await distractorService.selectDistractors(
      targetItemId: item.vocabularyId,
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
    final dataService = ref.read(supabaseDataServiceProvider);

    // Track new words vs reviews
    if (currentItem.isNewWord) {
      _newWordsPresented++;
    } else {
      _reviewsPresented++;
    }

    // Convert SessionCard to LearningCardModel for SRS processing
    final learningCard = currentItem.sessionCard.toLearningCard(userId);

    // Process the review with SRS
    final result = srsScheduler.reviewCard(
      card: learningCard,
      rating: rating,
      interactionMode: currentItem.interactionMode,
    );

    // Save updated card to Supabase
    await dataService.updateLearningCard(
      cardId: currentItem.cardId,
      state: result.updatedCard.state,
      due: result.updatedCard.due,
      stability: result.updatedCard.stability,
      difficulty: result.updatedCard.difficulty,
      reps: result.updatedCard.reps,
      lapses: result.updatedCard.lapses,
      isLeech: result.updatedCard.isLeech,
    );

    // Save review log to Supabase
    final reviewLogId = _uuid.v4();
    await dataService.insertReviewLog(
      id: reviewLogId,
      userId: userId,
      learningCardId: currentItem.cardId,
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
      cueType: currentItem.cueType?.toDbString(),
    );

    // Update session progress
    await dataService.updateSessionProgress(
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

    final dataService = ref.read(supabaseDataServiceProvider);
    final userId = ref.read(currentUserProvider).valueOrNull?.id;
    if (userId == null) return;

    // Determine outcome
    final totalSeconds = _session!.plannedMinutes * 60;
    final outcome = _elapsedSeconds >= totalSeconds
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
                color: isDark ? MasteryColors.cardDark : MasteryColors.cardLight,
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
              // Current item card - now uses SessionCard data directly!
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

  /// Build the card widget for the current item using SessionCard data.
  /// No additional queries needed - all data is already in the SessionCard!
  Widget _buildItemCard(PlannedItem item, bool isDark) {
    final card = item.sessionCard;
    final meaning = card.primaryMeaning;

    // Get translation answer (primary translation or fallback to definition)
    final translationAnswer = meaning?.primaryTranslation ??
        meaning?.englishDefinition ??
        'Translation not available';

    if (item.isRecognition) {
      return RecognitionCard(
        word: card.word,
        correctAnswer: translationAnswer,
        distractors:
            _currentDistractors ?? ['Option A', 'Option B', 'Option C'],
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
              cue?.promptText ?? meaning?.englishDefinition ?? translationAnswer,
          targetWord: cue?.answerText ?? card.word,
          hintText: cue?.hintText,
          onGrade: _handleRecallGrade,
        );
      case CueType.synonym:
        return SynonymCueCard(
          synonymPhrase: cue?.promptText ?? _buildSynonymPrompt(meaning),
          targetWord: cue?.answerText ?? card.word,
          onGrade: _handleRecallGrade,
        );
      case CueType.disambiguation:
        final options = _parseDisambiguationOptions(cue);
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
          targetWord: cue?.answerText ?? card.word,
          hintText: cue?.hintText,
          onGrade: _handleRecallGrade,
        );
      case CueType.translation:
      case null:
        return RecallCard(
          word: card.word,
          answer: translationAnswer,
          context: null, // Could load encounter context if needed
          onGrade: _handleRecallGrade,
        );
    }
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
    // Default fallback
    if (cue == null) {
      return (options: ['Option 1'], correctIndex: 0);
    }

    // The answer text is the correct option; for now return it as the only option
    // In a real implementation, you'd parse the cue metadata for all options
    return (
      options: [cue.answerText],
      correctIndex: 0,
    );
  }
}
