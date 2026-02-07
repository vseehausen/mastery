import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/supabase_provider.dart';
import '../../../learn/providers/session_providers.dart';
import '../../../learn/providers/streak_providers.dart';
import '../../../learn/screens/no_items_ready_screen.dart';
import '../../../learn/screens/session_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';

/// Main daily decision screen. Merges the old home + learn entry intent.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = ref.watch(currentUserProvider);
    final dueCards = ref.watch(dueCardsProvider);
    final vocabularyCount = ref.watch(vocabularyCountProvider);
    final dailyTarget = ref.watch(dailyTimeTargetProvider);
    final todayProgress = ref.watch(todayProgressProvider);
    final hasItems = ref.watch(hasItemsToReviewProvider);
    final completedToday = ref.watch(hasCompletedTodayProvider);
    final streak = ref.watch(currentStreakProvider);

    final dueCount = dueCards.valueOrNull?.length ?? 0;
    final vocabCount = vocabularyCount.valueOrNull ?? 0;
    final progress = todayProgress.valueOrNull ?? 0.0;
    final timeTarget = dailyTarget.valueOrNull ?? 10;
    final hasItemsToPractice = hasItems.valueOrNull ?? false;
    final isCompleted = completedToday.valueOrNull ?? false;
    final displayName =
        (currentUser.valueOrNull?.userMetadata?['full_name'] as String?) ??
        'Learner';

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(dueCardsProvider);
            ref.invalidate(vocabularyCountProvider);
            ref.invalidate(dailyTimeTargetProvider);
            ref.invalidate(todayProgressProvider);
            ref.invalidate(hasItemsToReviewProvider);
            ref.invalidate(hasCompletedTodayProvider);
            ref.invalidate(currentStreakProvider);
          },
          child: ListView(
            primary: false,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Today',
                          style: MasteryTextStyles.displayLarge.copyWith(
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Welcome back, $displayName',
                          style: MasteryTextStyles.bodySmall.copyWith(
                            color: isDark
                                ? MasteryColors.mutedForegroundDark
                                : MasteryColors.mutedForegroundLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.settings_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _HeroCard(
                dueCount: dueCount,
                targetMinutes: timeTarget,
                progress: progress,
                isCompleted: isCompleted,
                hasItems: hasItemsToPractice,
                onPrimaryAction: () {
                  if (!hasItemsToPractice) {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => const NoItemsReadyScreen(),
                      ),
                    );
                    return;
                  }
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => const SessionScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      title: 'Due now',
                      value: dueCards.isLoading ? '...' : '$dueCount',
                      subtitle: 'Cards ready',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      title: 'Vocabulary',
                      value: vocabularyCount.isLoading ? '...' : '$vocabCount',
                      subtitle: 'Words saved',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _WideMetricCard(
                title: 'Current streak',
                value: streak.isLoading ? '...' : '${streak.valueOrNull ?? 0}',
                subtitle: 'Consecutive learning days',
                icon: Icons.local_fire_department_outlined,
              ),
              const SizedBox(height: 20),
              Text(
                'Quick actions',
                style: MasteryTextStyles.bodyBold.copyWith(
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ShadButton.outline(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => const NoItemsReadyScreen(),
                        ),
                      );
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inventory_2_outlined),
                        SizedBox(width: 8),
                        Text('No-cards guidance'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.dueCount,
    required this.targetMinutes,
    required this.progress,
    required this.isCompleted,
    required this.hasItems,
    required this.onPrimaryAction,
  });

  final int dueCount;
  final int targetMinutes;
  final double progress;
  final bool isCompleted;
  final bool hasItems;
  final VoidCallback onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = _title();
    final subtitle = _subtitle();
    final buttonLabel = _buttonLabel();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? MasteryColors.cardDark : MasteryColors.secondaryLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? MasteryColors.borderDark : MasteryColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: MasteryTextStyles.bodyBold.copyWith(
              fontSize: 20,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: MasteryTextStyles.bodySmall.copyWith(
              color: isDark
                  ? MasteryColors.mutedForegroundDark
                  : MasteryColors.mutedForegroundLight,
            ),
          ),
          const SizedBox(height: 16),
          if (progress > 0 && progress < 1) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: isDark
                    ? MasteryColors.mutedDark
                    : MasteryColors.mutedLight,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDark ? MasteryColors.accentDark : MasteryColors.accentLight,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${(progress * 100).toInt()}% completed',
              style: MasteryTextStyles.caption.copyWith(
                color: isDark
                    ? MasteryColors.mutedForegroundDark
                    : MasteryColors.mutedForegroundLight,
              ),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            child: ShadButton(
              onPressed: onPrimaryAction,
              child: Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }

  String _title() {
    if (!hasItems) return 'No cards ready right now';
    if (isCompleted) return 'You are done for today';
    if (progress > 0 && progress < 1) return 'Continue your session';
    return 'Start your focused session';
  }

  String _subtitle() {
    if (!hasItems) {
      return 'You are caught up. Import new words or wait until cards become due.';
    }
    if (isCompleted) {
      return 'Great consistency. You can still do an optional review.';
    }
    if (progress > 0 && progress < 1) {
      return '$dueCount cards available. Keep momentum with a short finish.';
    }
    return '$dueCount cards are ready. Estimated time: $targetMinutes minutes.';
  }

  String _buttonLabel() {
    if (!hasItems) return 'Open no-items guidance';
    if (isCompleted) return 'Review anyway';
    if (progress > 0 && progress < 1) return 'Continue session';
    return 'Start $targetMinutes-minute session';
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final String title;
  final String value;
  final String subtitle;

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
            title,
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
              fontSize: 24,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
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

class _WideMetricCard extends StatelessWidget {
  const _WideMetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

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
      child: Row(
        children: [
          Icon(
            icon,
            color: isDark
                ? MasteryColors.warningDark
                : MasteryColors.warningLight,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: MasteryTextStyles.caption.copyWith(
                    color: isDark
                        ? MasteryColors.mutedForegroundDark
                        : MasteryColors.mutedForegroundLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$value days',
                  style: MasteryTextStyles.bodyBold.copyWith(
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  subtitle,
                  style: MasteryTextStyles.caption.copyWith(
                    color: isDark
                        ? MasteryColors.mutedForegroundDark
                        : MasteryColors.mutedForegroundLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
