import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/logging/decision_log.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../domain/models/progress_stage.dart';
import '../../../../providers/supabase_provider.dart';
import '../../../vocabulary/presentation/screens/vocabulary_screen.dart';
import '../../../learn/providers/learning_preferences_providers.dart';
import '../../../learn/providers/session_providers.dart';
import '../../../learn/providers/streak_providers.dart';
import '../../../learn/screens/session_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import 'dart:math' show min;

/// Main home screen. Streak, session, vocabulary — the whole app in one glance.
class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  bool _isNavigating = false;

  Future<void> _startSession() async {
    if (_isNavigating) return;
    _isNavigating = true;
    try {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => const SessionScreen(),
        ),
      );

      // Invalidate all providers to refresh data after session
      if (mounted) {
        ref.invalidate(hasItemsToReviewProvider);
        ref.invalidate(hasCompletedTodayProvider);
        ref.invalidate(currentStreakProvider);
        ref.invalidate(dueItemCountProvider);
        ref.invalidate(todaySessionStatsProvider);
        ref.invalidate(nextReviewLabelProvider);
        ref.invalidate(vocabularyStageCountsProvider);
        ref.invalidate(vocabularyCountProvider);
        ref.invalidate(sessionPrefetchProvider);
      }
    } finally {
      if (mounted) _isNavigating = false;
    }
  }

  Future<void> _startQuickReview() async {
    if (_isNavigating) return;
    _isNavigating = true;
    try {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => const SessionScreen(isQuickReview: true),
        ),
      );

      // Invalidate all providers to refresh data after session
      if (mounted) {
        ref.invalidate(hasItemsToReviewProvider);
        ref.invalidate(hasCompletedTodayProvider);
        ref.invalidate(currentStreakProvider);
        ref.invalidate(dueItemCountProvider);
        ref.invalidate(todaySessionStatsProvider);
        ref.invalidate(nextReviewLabelProvider);
        ref.invalidate(vocabularyStageCountsProvider);
        ref.invalidate(vocabularyCountProvider);
        ref.invalidate(sessionPrefetchProvider);
      }
    } finally {
      if (mounted) _isNavigating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.masteryColors;
    final hasItems = ref.watch(hasItemsToReviewProvider);
    final completedToday = ref.watch(hasCompletedTodayProvider);
    final dueCount = ref.watch(dueItemCountProvider);
    final sessionStats = ref.watch(todaySessionStatsProvider);
    final nextReview = ref.watch(nextReviewLabelProvider);
    final stageCounts = ref.watch(vocabularyStageCountsProvider);
    final vocabCount = ref.watch(vocabularyCountProvider);
    final userPrefs = ref.watch(userLearningPreferencesProvider);
    final sessionPrefetch = ref.watch(sessionPrefetchProvider);

    final hasItemsToPractice = hasItems.valueOrNull ?? false;
    final isCompleted = completedToday.valueOrNull ?? false;
    final itemsDue = dueCount.valueOrNull ?? 0;
    final totalVocab = vocabCount.valueOrNull ?? 0;
    final dailyTimeTarget = userPrefs.valueOrNull?.dailyTimeTargetMinutes ?? 5;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(hasItemsToReviewProvider);
            ref.invalidate(hasCompletedTodayProvider);
            ref.invalidate(dueItemCountProvider);
            ref.invalidate(todaySessionStatsProvider);
            ref.invalidate(nextReviewLabelProvider);
            ref.invalidate(vocabularyStageCountsProvider);
            ref.invalidate(vocabularyCountProvider);
            ref.invalidate(sessionPrefetchProvider);
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPaddingX,
                      vertical: AppSpacing.screenPaddingY,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                // Header: Mastery + settings
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Mastery',
                      style: MasteryTextStyles.displayLarge.copyWith(
                        color: colors.foreground,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.settings_outlined,
                        color: colors.foreground,
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.s6),

                // Session card
                _SessionCard(
                  isCompleted: isCompleted,
                  hasItems: hasItemsToPractice,
                  itemsDue: itemsDue,
                  sessionStats: sessionStats.valueOrNull,
                  nextReviewLabel: nextReview.valueOrNull,
                  dailyTimeTarget: dailyTimeTarget,
                  prefetchData: sessionPrefetch.valueOrNull,
                  onStartSession: _startSession,
                  onStartQuickReview: _startQuickReview,
                ),

                const SizedBox(height: AppSpacing.s4),

                // Vocabulary summary card
                if (totalVocab > 0)
                  _VocabularyCard(
                    totalCount: totalVocab,
                    stageCounts: stageCounts.valueOrNull ?? {},
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => const VocabularyScreenNew(),
                        ),
                      );
                    },
                  ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Session Card
// =============================================================================

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.isCompleted,
    required this.hasItems,
    required this.itemsDue,
    required this.sessionStats,
    required this.nextReviewLabel,
    required this.dailyTimeTarget,
    required this.prefetchData,
    required this.onStartSession,
    required this.onStartQuickReview,
  });

  final bool isCompleted;
  final bool hasItems;
  final int itemsDue;
  final ({int itemsReviewed, double? accuracyPercent})? sessionStats;
  final String? nextReviewLabel;
  final int dailyTimeTarget;
  final SessionPrefetch? prefetchData;
  final VoidCallback onStartSession;
  final VoidCallback onStartQuickReview;

  @override
  Widget build(BuildContext context) {
    final colors = context.masteryColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s8),
      decoration: BoxDecoration(
        color: colors.secondaryAction,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: colors.border),
      ),
      child: _buildContent(context, colors),
    );
  }

  Widget _buildContent(BuildContext context, MasteryColorScheme colors) {
    final String sessionResult;
    if (isCompleted) {
      sessionResult = 'completed';
    } else if (hasItems) {
      sessionResult = 'due';
    } else {
      sessionResult = 'nothing_due';
    }
    DecisionLog.log('session_check', {
      'result': sessionResult,
      'is_completed': isCompleted,
      'has_items': hasItems,
      'items_due': itemsDue,
    });
    unawaited(Sentry.addBreadcrumb(Breadcrumb(message: 'session_check: $sessionResult')));

    if (isCompleted) return _completedState(context, colors);
    if (hasItems) return _dueState(context, colors);
    return _nothingDueState(context, colors);
  }

  // State 1: Items due
  Widget _dueState(BuildContext context, MasteryColorScheme colors) {
    // Use prefetch data if available, otherwise fall back to itemsDue
    final dueCount = prefetchData?.dueCount ?? itemsDue;
    final availableNew = prefetchData?.availableNewWords ?? 0;
    final timeCap = prefetchData?.params.newWordCap ?? 0;

    // Calculate how many words are ready (reviews + capped new words)
    final newWordsReady = min(timeCap, availableNew);
    final totalReady = dueCount + newWordsReady;

    final label = totalReady == 1 ? '1 word ready' : '$totalReady words ready';
    final estimatedMinutes = prefetchData != null
        ? (totalReady * prefetchData!.params.estimatedSecondsPerItem / 60).ceil()
        : dailyTimeTarget;
    final timeLabel = '~$estimatedMinutes min';

    return Column(
      children: [
        Text(
          label,
          style: MasteryTextStyles.displayLarge.copyWith(
            color: colors.foreground,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.s1),
        Text(
          timeLabel,
          style: MasteryTextStyles.bodySmall.copyWith(
            color: colors.mutedForeground,
          ),
        ),
        const SizedBox(height: AppSpacing.s6),
        SizedBox(
          width: double.infinity,
          child: ShadButton(
            size: ShadButtonSize.lg,
            onPressed: onStartSession,
            child: const Text('Start session'),
          ),
        ),
      ],
    );
  }

  // State 2: Completed today
  Widget _completedState(BuildContext context, MasteryColorScheme colors) {
    final stats = sessionStats;
    final dueCount = prefetchData?.dueCount ?? itemsDue;
    final availableNew = prefetchData?.availableNewWords ?? 0;
    final reviewedCount = stats?.itemsReviewed ?? 0;

    // Determine what action is available after main session
    String? buttonLabel;
    VoidCallback? buttonAction;

    if (dueCount > 0) {
      // Reviews still due: show quick review option
      final reviewCount = min(dueCount, dailyTimeTarget);
      buttonLabel = 'Quick review — $reviewCount ${reviewCount == 1 ? 'word' : 'words'}';
      buttonAction = onStartQuickReview;
    } else if (availableNew > 0) {
      // No reviews due, but new words available
      final newWordsToShow = min(dailyTimeTarget, availableNew);
      buttonLabel = 'Learn $newWordsToShow new ${newWordsToShow == 1 ? 'word' : 'words'}';
      buttonAction = onStartQuickReview;
    }
    // else: no button (all caught up)

    return Column(
      children: [
        Text(
          'Done for today',
          style: MasteryTextStyles.displayLarge.copyWith(
            color: colors.foreground,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.s2),
        Text(
          '$reviewedCount reviewed',
          style: MasteryTextStyles.bodySmall.copyWith(
            color: colors.mutedForeground,
          ),
        ),
        if (buttonLabel != null && buttonAction != null) ...[
          const SizedBox(height: AppSpacing.s6),
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ShadButton.outline(
                size: ShadButtonSize.lg,
                backgroundColor: colors.background,
                onPressed: buttonAction,
                child: Text(buttonLabel),
              ),
            ),
          ),
        ] else
          const SizedBox(height: AppSpacing.s2),
        if (buttonLabel == null) ...[
          Text(
            'All caught up!',
            style: MasteryTextStyles.bodySmall.copyWith(
              color: colors.mutedForeground,
            ),
          ),
        ],
      ],
    );
  }

  // State 3: Nothing due
  Widget _nothingDueState(BuildContext context, MasteryColorScheme colors) {
    return Column(
      children: [
        Text(
          'No words due',
          style: MasteryTextStyles.displayLarge.copyWith(
            color: colors.foreground,
          ),
          textAlign: TextAlign.center,
        ),
        if (nextReviewLabel != null) ...[
          const SizedBox(height: AppSpacing.s2),
          Text(
            nextReviewLabel!,
            style: MasteryTextStyles.bodySmall.copyWith(
              color: colors.mutedForeground,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

}

// =============================================================================
// Vocabulary Card
// =============================================================================

class _VocabularyCard extends StatelessWidget {
  const _VocabularyCard({
    required this.totalCount,
    required this.stageCounts,
    required this.onTap,
  });

  final int totalCount;
  final Map<ProgressStage, int> stageCounts;
  final VoidCallback onTap;

  static const _stageOrder = [
    ProgressStage.mastered,
    ProgressStage.known,
    ProgressStage.stabilizing,
    ProgressStage.practicing,
    ProgressStage.captured,
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.masteryColors;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xxl),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.s6),
        decoration: BoxDecoration(
          color: colors.secondaryAction,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: Vocabulary ... count →
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Vocabulary',
                  style: MasteryTextStyles.bodyBold.copyWith(
                    color: colors.foreground,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$totalCount',
                      style: MasteryTextStyles.bodyBold.copyWith(
                        color: colors.foreground,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s1),
                    Icon(
                      Icons.chevron_right,
                      size: AppSpacing.s5,
                      color: colors.mutedForeground,
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.s3),

            // Segmented progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: SizedBox(
                height: AppSpacing.s3,
                child: Row(
                  children: [
                    for (final stage in _stageOrder)
                      if ((stageCounts[stage] ?? 0) > 0)
                        Expanded(
                          flex: stageCounts[stage]!,
                          child: Container(color: stage.getColor(colors)),
                        ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.s3),

            // Stage legend
            Wrap(
              spacing: AppSpacing.s3,
              runSpacing: AppSpacing.s2,
              children: [
                for (final stage in _stageOrder)
                  if ((stageCounts[stage] ?? 0) > 0)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: AppSpacing.s2,
                          height: AppSpacing.s2,
                          decoration: BoxDecoration(
                            color: stage.getColor(colors),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s1),
                        Text(
                          stage.displayName,
                          style: MasteryTextStyles.caption.copyWith(
                            color: colors.mutedForeground,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s1),
                        Text(
                          '${stageCounts[stage]}',
                          style: MasteryTextStyles.caption.copyWith(
                            color: colors.foreground,
                          ),
                        ),
                      ],
                    ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
