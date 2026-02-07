import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
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
    final vocabularyCount = ref.watch(vocabularyCountProvider);
    final completedToday = ref.watch(hasCompletedTodayProvider);

    final streakValue = currentStreak.valueOrNull ?? 0;
    final longestValue = longestStreak.valueOrNull ?? 0;
    final vocabularyValue = vocabularyCount.valueOrNull ?? 0;
    final completed = completedToday.valueOrNull ?? false;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(currentStreakProvider);
            ref.invalidate(longestStreakProvider);
            ref.invalidate(vocabularyCountProvider);
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
              _DataCard(
                label: 'Vocabulary',
                value: '$vocabularyValue',
                hint: 'words in your library',
              ),
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

class _DataCard extends StatelessWidget {
  const _DataCard({
    required this.label,
    required this.value,
    required this.hint,
  });

  final String label;
  final String value;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        color: context.masteryColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.masteryColors.border),
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
          const SizedBox(height: AppSpacing.s2 / 2),
          Text(
            value,
            style: MasteryTextStyles.bodyBold.copyWith(
              fontSize: 22,
              color: context.masteryColors.foreground,
            ),
          ),
          const SizedBox(height: AppSpacing.s1 / 2),
          Text(
            hint,
            style: MasteryTextStyles.caption.copyWith(
              color: context.masteryColors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}
