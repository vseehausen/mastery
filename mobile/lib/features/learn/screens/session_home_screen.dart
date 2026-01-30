import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/text_styles.dart';
import '../../../providers/auth_provider.dart';
import '../providers/session_providers.dart';
import '../providers/streak_providers.dart';
import '../widgets/streak_indicator.dart';
import 'learning_settings_screen.dart';
import 'session_screen.dart';

/// Home screen for the learning feature
/// Shows: "Start Session (X min)" CTA, progress bar for today, streak indicator
/// Calm UX: no backlog numbers, no overdue indicators
class SessionHomeScreen extends ConsumerWidget {
  const SessionHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = ref.watch(currentUserProvider);
    final userId = currentUser.valueOrNull?.id;

    // Watch session state and preferences
    final dailyTimeTarget = ref.watch(dailyTimeTargetProvider);
    final hasCompletedToday = ref.watch(hasCompletedTodayProvider);
    final todayProgress = ref.watch(todayProgressProvider);
    final currentStreak = ref.watch(currentStreakProvider);
    final hasItemsToReview = ref.watch(hasItemsToReviewProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Learn',
                    style: MasteryTextStyles.displayLarge.copyWith(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  Row(
                    children: [
                      // Streak indicator
                      currentStreak.when(
                        data: (streak) => StreakIndicator(count: streak),
                        loading: () => const SizedBox.shrink(),
                        error: (_, _) => const StreakIndicator(count: 0),
                      ),
                      const SizedBox(width: 8),
                      // Settings button
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (context) =>
                                  const LearningSettingsScreen(),
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.settings_outlined,
                          color: isDark
                              ? MasteryColors.mutedForegroundDark
                              : MasteryColors.mutedForegroundLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Main content
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Session card
                      _buildSessionCard(
                        context: context,
                        ref: ref,
                        isDark: isDark,
                        userId: userId,
                        dailyTimeTarget: dailyTimeTarget,
                        hasCompletedToday: hasCompletedToday,
                        todayProgress: todayProgress,
                        hasItemsToReview: hasItemsToReview,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionCard({
    required BuildContext context,
    required WidgetRef ref,
    required bool isDark,
    required String? userId,
    required AsyncValue<int> dailyTimeTarget,
    required AsyncValue<bool> hasCompletedToday,
    required AsyncValue<double> todayProgress,
    required AsyncValue<bool> hasItemsToReview,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? MasteryColors.cardDark : MasteryColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? MasteryColors.borderDark : MasteryColors.borderLight,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isDark
                  ? MasteryColors.accentDark.withValues(alpha: 0.1)
                  : MasteryColors.accentLight.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lightbulb_outline,
              size: 40,
              color: isDark
                  ? MasteryColors.accentDark
                  : MasteryColors.accentLight,
            ),
          ),
          const SizedBox(height: 24),

          // Status-specific content
          _buildStatusContent(
            context: context,
            ref: ref,
            isDark: isDark,
            userId: userId,
            dailyTimeTarget: dailyTimeTarget,
            hasCompletedToday: hasCompletedToday,
            todayProgress: todayProgress,
            hasItemsToReview: hasItemsToReview,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusContent({
    required BuildContext context,
    required WidgetRef ref,
    required bool isDark,
    required String? userId,
    required AsyncValue<int> dailyTimeTarget,
    required AsyncValue<bool> hasCompletedToday,
    required AsyncValue<double> todayProgress,
    required AsyncValue<bool> hasItemsToReview,
  }) {
    // Loading state
    if (dailyTimeTarget.isLoading || hasCompletedToday.isLoading) {
      return Column(
        children: [
          Text(
            'Loading...',
            style: MasteryTextStyles.bodyBold.copyWith(
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          const CircularProgressIndicator(),
        ],
      );
    }

    final timeTarget = dailyTimeTarget.valueOrNull ?? 10;
    final completed = hasCompletedToday.valueOrNull ?? false;
    final progress = todayProgress.valueOrNull ?? 0.0;
    final hasItems = hasItemsToReview.valueOrNull ?? true;

    // Already completed today
    if (completed) {
      return Column(
        children: [
          Text(
            "You're done for today!",
            style: MasteryTextStyles.bodyBold.copyWith(
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Great work! Come back tomorrow.',
            style: MasteryTextStyles.bodySmall.copyWith(
              color: isDark
                  ? MasteryColors.mutedForegroundDark
                  : MasteryColors.mutedForegroundLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Icon(
            Icons.check_circle,
            size: 48,
            color: isDark
                ? MasteryColors.successDark
                : MasteryColors.successLight,
          ),
        ],
      );
    }

    // No items to review
    if (!hasItems) {
      return Column(
        children: [
          Text(
            'Nothing to practice',
            style: MasteryTextStyles.bodyBold.copyWith(
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some vocabulary to get started!',
            style: MasteryTextStyles.bodySmall.copyWith(
              color: isDark
                  ? MasteryColors.mutedForegroundDark
                  : MasteryColors.mutedForegroundLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    // Partial progress
    if (progress > 0 && progress < 1.0) {
      return Column(
        children: [
          Text(
            'Continue your session',
            style: MasteryTextStyles.bodyBold.copyWith(
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).toInt()}% complete',
            style: MasteryTextStyles.bodySmall.copyWith(
              color: isDark
                  ? MasteryColors.mutedForegroundDark
                  : MasteryColors.mutedForegroundLight,
            ),
          ),
          const SizedBox(height: 16),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
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
          const SizedBox(height: 24),
          _buildStartButton(
            context: context,
            ref: ref,
            userId: userId,
            label: 'Continue',
          ),
        ],
      );
    }

    // Ready to start
    return Column(
      children: [
        Text(
          'Ready to learn?',
          style: MasteryTextStyles.bodyBold.copyWith(
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'A focused $timeTarget-minute session awaits.',
          style: MasteryTextStyles.bodySmall.copyWith(
            color: isDark
                ? MasteryColors.mutedForegroundDark
                : MasteryColors.mutedForegroundLight,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        _buildStartButton(
          context: context,
          ref: ref,
          userId: userId,
          label: 'Start Session ($timeTarget min)',
        ),
      ],
    );
  }

  Widget _buildStartButton({
    required BuildContext context,
    required WidgetRef ref,
    required String? userId,
    required String label,
  }) {
    return ShadButton(
      onPressed: userId == null
          ? null
          : () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const SessionScreen(),
                ),
              );
            },
      size: ShadButtonSize.lg,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.play_arrow, size: 20),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}
