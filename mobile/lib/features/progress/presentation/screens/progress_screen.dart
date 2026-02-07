import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../providers/supabase_provider.dart';
import '../../../learn/providers/session_providers.dart';
import '../../../learn/providers/streak_providers.dart';
import '../../../learn/screens/learning_settings_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';

/// Progress hub for outcomes and settings entry points.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final currentStreak = ref.watch(currentStreakProvider);
    final longestStreak = ref.watch(longestStreakProvider);
    final vocabularyCount = ref.watch(vocabularyCountProvider);
    final dueCards = ref.watch(dueCardsProvider);
    final completedToday = ref.watch(hasCompletedTodayProvider);

    final streakValue = currentStreak.valueOrNull ?? 0;
    final longestValue = longestStreak.valueOrNull ?? 0;
    final vocabularyValue = vocabularyCount.valueOrNull ?? 0;
    final dueCount = dueCards.valueOrNull?.length ?? 0;
    final completed = completedToday.valueOrNull ?? false;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(currentStreakProvider);
            ref.invalidate(longestStreakProvider);
            ref.invalidate(vocabularyCountProvider);
            ref.invalidate(dueCardsProvider);
            ref.invalidate(hasCompletedTodayProvider);
          },
          child: ListView(
            primary: false,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            children: [
              Text(
                'Progress',
                style: MasteryTextStyles.displayLarge.copyWith(
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Track outcomes and tune your plan',
                style: MasteryTextStyles.bodySmall.copyWith(
                  color: isDark
                      ? MasteryColors.mutedForegroundDark
                      : MasteryColors.mutedForegroundLight,
                ),
              ),
              const SizedBox(height: 16),
              _ProgressHero(
                currentStreak: streakValue,
                longestStreak: longestValue,
                completedToday: completed,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _DataCard(
                      label: 'Words',
                      value: '$vocabularyValue',
                      hint: 'in your library',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DataCard(
                      label: 'Due now',
                      value: '$dueCount',
                      hint: 'cards to review',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Settings',
                style: MasteryTextStyles.bodyBold.copyWith(
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              _ActionTile(
                icon: Icons.tune,
                title: 'Learning preferences',
                subtitle: 'Daily minutes, intensity, retention target',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => const LearningSettingsScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              _ActionTile(
                icon: Icons.settings_outlined,
                title: 'Account and app settings',
                subtitle: 'Profile, notifications, sign out',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? MasteryColors.cardDark : MasteryColors.secondaryLight,
        borderRadius: BorderRadius.circular(16),
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
              const SizedBox(width: 8),
              Text(
                'Streak performance',
                style: MasteryTextStyles.bodyBold.copyWith(
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StreakStat(
                  label: 'Current',
                  value: '$currentStreak days',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StreakStat(
                  label: 'Longest',
                  value: '$longestStreak days',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? MasteryColors.mutedDark : MasteryColors.cardLight,
        borderRadius: BorderRadius.circular(12),
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
          const SizedBox(height: 4),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? MasteryColors.cardDark : MasteryColors.cardLight,
        borderRadius: BorderRadius.circular(14),
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
          const SizedBox(height: 6),
          Text(
            value,
            style: MasteryTextStyles.bodyBold.copyWith(
              fontSize: 22,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 2),
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

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        decoration: BoxDecoration(
          color: isDark ? MasteryColors.cardDark : MasteryColors.cardLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? MasteryColors.borderDark
                : MasteryColors.borderLight,
          ),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDark
                  ? MasteryColors.accentDark
                  : MasteryColors.accentLight,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: MasteryTextStyles.bodyBold.copyWith(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: MasteryTextStyles.bodySmall.copyWith(
                      color: isDark
                          ? MasteryColors.mutedForegroundDark
                          : MasteryColors.mutedForegroundLight,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDark
                  ? MasteryColors.mutedForegroundDark
                  : MasteryColors.mutedForegroundLight,
            ),
          ],
        ),
      ),
    );
  }
}
