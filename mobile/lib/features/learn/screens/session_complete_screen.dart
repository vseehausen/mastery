import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/text_styles.dart';
import '../providers/streak_providers.dart';
import '../widgets/streak_indicator.dart';

/// Screen shown after completing a learning session
class SessionCompleteScreen extends ConsumerWidget {
  const SessionCompleteScreen({
    super.key,
    required this.itemsCompleted,
    required this.totalItems,
    required this.elapsedSeconds,
    required this.plannedSeconds,
    required this.isFullCompletion,
  });

  final int itemsCompleted;
  final int totalItems;
  final int elapsedSeconds;
  final int plannedSeconds;
  final bool isFullCompletion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentStreak = ref.watch(currentStreakProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),

              // Success icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: isFullCompletion
                      ? (isDark
                          ? MasteryColors.successMutedDark
                          : MasteryColors.successMutedLight)
                      : (isDark
                          ? MasteryColors.warningMutedDark
                          : MasteryColors.warningMutedLight),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isFullCompletion ? Icons.check_circle : Icons.access_time,
                  size: 64,
                  color: isFullCompletion
                      ? (isDark ? MasteryColors.successDark : MasteryColors.successLight)
                      : (isDark ? MasteryColors.warningDark : MasteryColors.warningLight),
                ),
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                isFullCompletion
                    ? "You're done for today!"
                    : 'Session ended',
                style: MasteryTextStyles.displayLarge.copyWith(
                  color: isDark ? Colors.white : Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Subtitle
              Text(
                isFullCompletion
                    ? 'Great work! Come back tomorrow.'
                    : 'You made progress today.',
                style: MasteryTextStyles.body.copyWith(
                  color: isDark
                      ? MasteryColors.mutedForegroundDark
                      : MasteryColors.mutedForegroundLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Stats
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? MasteryColors.cardDark : MasteryColors.cardLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? MasteryColors.borderDark : MasteryColors.borderLight,
                  ),
                ),
                child: Column(
                  children: [
                    _StatRow(
                      label: 'Items reviewed',
                      value: '$itemsCompleted',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _StatRow(
                      label: 'Time practiced',
                      value: _formatTime(elapsedSeconds),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    Divider(
                      color: isDark ? MasteryColors.borderDark : MasteryColors.borderLight,
                    ),
                    const SizedBox(height: 12),
                    // Streak
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Current streak',
                          style: MasteryTextStyles.bodySmall.copyWith(
                            color: isDark
                                ? MasteryColors.mutedForegroundDark
                                : MasteryColors.mutedForegroundLight,
                          ),
                        ),
                        currentStreak.when(
                          data: (streak) => StreakIndicator(count: streak),
                          loading: () => const SizedBox.shrink(),
                          error: (_, _) => const StreakIndicator(count: 0),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Bonus time button (for future implementation)
              if (isFullCompletion) ...[
                ShadButton.outline(
                  onPressed: () {
                    // TODO: Implement bonus time (US6)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Bonus time coming soon!')),
                    );
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 18),
                      SizedBox(width: 8),
                      Text('+2 min bonus'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Done button
              SizedBox(
                width: double.infinity,
                child: ShadButton(
                  onPressed: () {
                    // Pop back to home
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  size: ShadButtonSize.lg,
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    if (minutes > 0) {
      return '$minutes min ${secs > 0 ? '$secs sec' : ''}';
    }
    return '$secs sec';
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    required this.isDark,
  });


  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: MasteryTextStyles.bodySmall.copyWith(
            color: isDark
                ? MasteryColors.mutedForegroundDark
                : MasteryColors.mutedForegroundLight,
          ),
        ),
        Text(
          value,
          style: MasteryTextStyles.bodyBold.copyWith(
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ],
    );
  }
}
