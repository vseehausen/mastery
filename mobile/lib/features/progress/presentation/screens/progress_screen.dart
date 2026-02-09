import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../domain/models/progress_stage.dart';
import '../../../../providers/supabase_provider.dart';
import '../../../learn/providers/session_providers.dart';
import '../../../learn/providers/streak_providers.dart';

/// Progress hub for outcomes and settings entry points.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStreak = ref.watch(currentStreakProvider);
    final longestStreak = ref.watch(longestStreakProvider);
    final stageCounts = ref.watch(vocabularyStageCountsProvider);
    final completedToday = ref.watch(hasCompletedTodayProvider);

    final streakValue = currentStreak.valueOrNull ?? 0;
    final longestValue = longestStreak.valueOrNull ?? 0;
    final completed = completedToday.valueOrNull ?? false;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(currentStreakProvider);
            ref.invalidate(longestStreakProvider);
            ref.invalidate(vocabularyStageCountsProvider);
            ref.invalidate(hasCompletedTodayProvider);
          },
          child: ListView(
            primary: false,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s5,
              AppSpacing.s5,
              AppSpacing.s5,
              AppSpacing.s6,
            ),
            children: [
              Text(
                'Progress',
                style: MasteryTextStyles.displayLarge.copyWith(
                  color: context.masteryColors.foreground,
                ),
              ),
              const SizedBox(height: AppSpacing.s2),
              Text(
                'Track your outcomes',
                style: MasteryTextStyles.bodySmall.copyWith(
                  color: context.masteryColors.mutedForeground,
                ),
              ),
              const SizedBox(height: AppSpacing.s4),
              _ProgressHero(
                currentStreak: streakValue,
                longestStreak: longestValue,
                completedToday: completed,
              ),
              const SizedBox(height: AppSpacing.s3),
              _VocabularyOverview(stageCounts: stageCounts),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressHero extends StatelessWidget {
  const _ProgressHero({
    required this.currentStreak,
    required this.longestStreak,
    required this.completedToday,
  });

  final int currentStreak;
  final int longestStreak;
  final bool completedToday;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s5),
      decoration: BoxDecoration(
        color: context.masteryColors.secondaryAction,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.masteryColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_fire_department_outlined,
                color: context.masteryColors.warning,
              ),
              const SizedBox(width: AppSpacing.s2),
              Text(
                'Streak performance',
                style: MasteryTextStyles.bodyBold.copyWith(
                  color: context.masteryColors.foreground,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s3),
          Row(
            children: [
              Expanded(
                child: _StreakStat(
                  label: 'Current',
                  value: '$currentStreak days',
                ),
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: _StreakStat(
                  label: 'Longest',
                  value: '$longestStreak days',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(
            completedToday
                ? 'Today is completed. Nice consistency.'
                : 'Complete one session today to keep your streak.',
            style: MasteryTextStyles.bodySmall.copyWith(
              color: context.masteryColors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakStat extends StatelessWidget {
  const _StreakStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s3),
      decoration: BoxDecoration(
        color: context.masteryColors.muted,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: MasteryTextStyles.caption.copyWith(
              color: context.masteryColors.mutedForeground,
            ),
          ),
          const SizedBox(height: AppSpacing.s1),
          Text(
            value,
            style: MasteryTextStyles.bodyBold.copyWith(
              color: context.masteryColors.foreground,
            ),
          ),
        ],
      ),
    );
  }
}

/// Stage display order: mastered first (left) → captured last (right).
const _stageOrder = [
  ProgressStage.mastered,
  ProgressStage.active,
  ProgressStage.stabilizing,
  ProgressStage.practicing,
  ProgressStage.captured,
];

class _VocabularyOverview extends StatelessWidget {
  const _VocabularyOverview({required this.stageCounts});

  final AsyncValue<Map<ProgressStage, int>> stageCounts;

  @override
  Widget build(BuildContext context) {
    final colors = context.masteryColors;

    return stageCounts.when(
      loading: () => _buildShell(colors, null),
      error: (_, _) => _buildShell(colors, null),
      data: (counts) => _buildShell(colors, counts),
    );
  }

  Widget _buildShell(MasteryColorScheme colors, Map<ProgressStage, int>? counts) {
    final total = counts?.values.fold(0, (a, b) => a + b) ?? 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s5),
      decoration: BoxDecoration(
        color: colors.secondaryAction,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Vocabulary',
                style: MasteryTextStyles.bodyBold.copyWith(
                  color: colors.foreground,
                ),
              ),
              Text(
                '$total words',
                style: MasteryTextStyles.caption.copyWith(
                  color: colors.mutedForeground,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s3),

          // Stacked bar
          if (counts != null && total > 0)
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: SizedBox(
                height: 10,
                child: Row(
                  children: [
                    for (final stage in _stageOrder)
                      if ((counts[stage] ?? 0) > 0)
                        Expanded(
                          flex: counts[stage]!,
                          child: Container(color: stage.getColor(colors)),
                        ),
                  ],
                ),
              ),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: SizedBox(
                height: 10,
                child: Container(color: colors.muted),
              ),
            ),
          const SizedBox(height: AppSpacing.s3),

          // Legend
          Wrap(
            spacing: AppSpacing.s4,
            runSpacing: AppSpacing.s2,
            children: [
              for (final stage in _stageOrder)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
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
                      '${counts?[stage] ?? 0}',
                      style: MasteryTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.foreground,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
