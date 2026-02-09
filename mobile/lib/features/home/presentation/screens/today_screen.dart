import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../domain/models/progress_stage.dart';
import '../../../../providers/supabase_provider.dart';
import '../../../vocabulary/presentation/screens/vocabulary_screen.dart';
import '../../../learn/providers/session_providers.dart';
import '../../../learn/providers/streak_providers.dart';
import '../../../learn/screens/session_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';

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
    } finally {
      if (mounted) _isNavigating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.masteryColors;
    final hasItems = ref.watch(hasItemsToReviewProvider);
    final completedToday = ref.watch(hasCompletedTodayProvider);
    final streak = ref.watch(currentStreakProvider);
    final dueCount = ref.watch(dueItemCountProvider);
    final sessionStats = ref.watch(todaySessionStatsProvider);
    final nextReview = ref.watch(nextReviewLabelProvider);
    final stageCounts = ref.watch(vocabularyStageCountsProvider);
    final vocabCount = ref.watch(vocabularyCountProvider);

    final hasItemsToPractice = hasItems.valueOrNull ?? false;
    final isCompleted = completedToday.valueOrNull ?? false;
    final streakCount = streak.valueOrNull ?? 0;
    final itemsDue = dueCount.valueOrNull ?? 0;
    final totalVocab = vocabCount.valueOrNull ?? 0;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(hasItemsToReviewProvider);
            ref.invalidate(hasCompletedTodayProvider);
            ref.invalidate(currentStreakProvider);
            ref.invalidate(dueItemCountProvider);
            ref.invalidate(todaySessionStatsProvider);
            ref.invalidate(nextReviewLabelProvider);
            ref.invalidate(vocabularyStageCountsProvider);
            ref.invalidate(vocabularyCountProvider);
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

                // Streak
                if (streakCount > 0) ...[
                  const SizedBox(height: AppSpacing.s3),
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: '\u{1F525} '),
                        TextSpan(
                          text: '$streakCount',
                          style: MasteryTextStyles.bodyBold.copyWith(
                            color: colors.warning,
                          ),
                        ),
                        TextSpan(
                          text: ' day streak',
                          style: MasteryTextStyles.body.copyWith(
                            color: colors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.s6),

                // Session card
                _SessionCard(
                  isCompleted: isCompleted,
                  hasItems: hasItemsToPractice,
                  itemsDue: itemsDue,
                  sessionStats: sessionStats.valueOrNull,
                  nextReviewLabel: nextReview.valueOrNull,
                  onStartSession: _startSession,
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
    required this.onStartSession,
  });

  final bool isCompleted;
  final bool hasItems;
  final int itemsDue;
  final ({int itemsReviewed, double? accuracyPercent})? sessionStats;
  final String? nextReviewLabel;
  final VoidCallback onStartSession;

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
    if (isCompleted) return _completedState(context, colors);
    if (hasItems) return _dueState(context, colors);
    return _nothingDueState(context, colors);
  }

  // State 1: Items due
  Widget _dueState(BuildContext context, MasteryColorScheme colors) {
    final label = itemsDue == 1 ? '1 word due' : '$itemsDue words due';
    return Column(
      children: [
        Text(
          label,
          style: MasteryTextStyles.displayLarge.copyWith(
            color: colors.foreground,
          ),
          textAlign: TextAlign.center,
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
    return Column(
      children: [
        Text(
          'Done for today',
          style: MasteryTextStyles.displayLarge.copyWith(
            color: colors.foreground,
          ),
          textAlign: TextAlign.center,
        ),
        if (stats != null) ...[
          const SizedBox(height: AppSpacing.s2),
          Text(
            _statsLabel(stats),
            style: MasteryTextStyles.bodySmall.copyWith(
              color: colors.mutedForeground,
            ),
          ),
        ],
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
              onPressed: onStartSession,
              child: const Text('Review anyway'),
            ),
          ),
        ),
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

  String _statsLabel(({int itemsReviewed, double? accuracyPercent}) stats) {
    final parts = <String>['${stats.itemsReviewed} reviewed'];
    if (stats.accuracyPercent != null) {
      parts.add('${stats.accuracyPercent!.round()}% correct');
    }
    return parts.join(' \u00B7 ');
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
    ProgressStage.active,
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
