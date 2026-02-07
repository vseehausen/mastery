import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/color_tokens.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            padding: MasterySpacing.screen,
            children: [
              Text(
                'Progress',
                style: MasteryTextStyles.displayLarge.copyWith(
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: MasterySpacing.sm),
              Text(
                'Track your outcomes',
                style: MasteryTextStyles.bodySmall.copyWith(
                  color: isDark
                      ? MasteryColors.mutedForegroundDark
                      : MasteryColors.mutedForegroundLight,
                ),
              ),
              const SizedBox(height: MasterySpacing.lg),
              _ProgressHero(
                currentStreak: streakValue,
                longestStreak: longestValue,
                completedToday: completed,
              ),
              const SizedBox(height: MasterySpacing.md),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(MasterySpacing.xl),
      decoration: BoxDecoration(
        color: isDark ? MasteryColors.cardDark : MasteryColors.secondaryLight,
        borderRadius: BorderRadius.circular(MasterySpacing.radiusLg),
        border: Border.all(
          color: isDark ? MasteryColors.borderDark : MasteryColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_fire_department_outlined,
                color: isDark
                    ? MasteryColors.warningDark
                    : MasteryColors.warningLight,
              ),
              const SizedBox(width: MasterySpacing.sm),
              Text(
                'Streak performance',
                style: MasteryTextStyles.bodyBold.copyWith(
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: MasterySpacing.md),
          Row(
            children: [
              Expanded(
                child: _StreakStat(
                  label: 'Current',
                  value: '$currentStreak days',
                ),
              ),
              const SizedBox(width: MasterySpacing.md),
              Expanded(
                child: _StreakStat(
                  label: 'Longest',
                  value: '$longestStreak days',
                ),
              ),
            ],
          ),
          const SizedBox(height: MasterySpacing.sm),
          Text(
            completedToday
                ? 'Today is completed. Nice consistency.'
                : 'Complete one session today to keep your streak.',
            style: MasteryTextStyles.bodySmall.copyWith(
              color: isDark
                  ? MasteryColors.mutedForegroundDark
                  : MasteryColors.mutedForegroundLight,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(MasterySpacing.md),
      decoration: BoxDecoration(
        color: isDark ? MasteryColors.mutedDark : MasteryColors.cardLight,
        borderRadius: BorderRadius.circular(MasterySpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: MasteryTextStyles.caption.copyWith(
              color: isDark
                  ? MasteryColors.mutedForegroundDark
                  : MasteryColors.mutedForegroundLight,
            ),
          ),
          const SizedBox(height: MasterySpacing.xs),
          Text(
            value,
            style: MasteryTextStyles.bodyBold.copyWith(
              color: isDark ? Colors.white : Colors.black,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(MasterySpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? MasteryColors.cardDark : MasteryColors.cardLight,
        borderRadius: BorderRadius.circular(MasterySpacing.radiusMd),
        border: Border.all(
          color: isDark ? MasteryColors.borderDark : MasteryColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: MasteryTextStyles.caption.copyWith(
              color: isDark
                  ? MasteryColors.mutedForegroundDark
                  : MasteryColors.mutedForegroundLight,
            ),
          ),
          const SizedBox(height: MasterySpacing.sm / 2),
          Text(
            value,
            style: MasteryTextStyles.bodyBold.copyWith(
              fontSize: 22,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: MasterySpacing.xs / 2),
          Text(
            hint,
            style: MasteryTextStyles.caption.copyWith(
              color: isDark
                  ? MasteryColors.mutedForegroundDark
                  : MasteryColors.mutedForegroundLight,
            ),
          ),
        ],
      ),
    );
  }
}
