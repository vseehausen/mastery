import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/app_defaults.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../learn/providers/session_providers.dart';
import '../../../learn/screens/no_items_ready_screen.dart';
import '../../../learn/screens/session_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';

/// Main daily decision screen. Merges the old home + learn entry intent.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyTarget = ref.watch(dailyTimeTargetProvider);
    final todayProgress = ref.watch(todayProgressProvider);
    final hasItems = ref.watch(hasItemsToReviewProvider);
    final completedToday = ref.watch(hasCompletedTodayProvider);

    final progress = todayProgress.valueOrNull ?? 0.0;
    final timeTarget =
        dailyTarget.valueOrNull ?? AppDefaults.dailyTimeTargetMinutes;
    final hasItemsToPractice = hasItems.valueOrNull ?? false;
    final isCompleted = completedToday.valueOrNull ?? false;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: MasterySpacing.screen,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Today',
                    style: MasteryTextStyles.displayLarge.copyWith(
                      color: context.masteryColors.foreground,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.settings_outlined,
                      color: context.masteryColors.foreground,
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
            ),
            Expanded(
              child: Center(
                child: RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(dailyTimeTargetProvider);
                    ref.invalidate(todayProgressProvider);
                    ref.invalidate(hasItemsToReviewProvider);
                    ref.invalidate(hasCompletedTodayProvider);
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: MasterySpacing.screen,
                    child: _HeroCard(
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
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.targetMinutes,
    required this.progress,
    required this.isCompleted,
    required this.hasItems,
    required this.onPrimaryAction,
  });

  final int targetMinutes;
  final double progress;
  final bool isCompleted;
  final bool hasItems;
  final VoidCallback onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    final title = _title();
    final subtitle = _subtitle();
    final buttonLabel = _buttonLabel();

    return Container(
      padding: const EdgeInsets.all(MasterySpacing.xxl),
      decoration: BoxDecoration(
        color: context.masteryColors.secondaryAction,
        borderRadius: BorderRadius.circular(MasterySpacing.radiusXl),
        border: Border.all(
          color: context.masteryColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: MasteryTextStyles.bodyBold.copyWith(
              fontSize: 20,
              color: context.masteryColors.foreground,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: MasterySpacing.sm),
          Text(
            subtitle,
            style: MasteryTextStyles.bodySmall.copyWith(
              color: context.masteryColors.mutedForeground,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: MasterySpacing.lg),
          if (progress > 0 && progress < 1) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(MasterySpacing.radiusSm / 2),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: context.masteryColors.muted,
                valueColor: AlwaysStoppedAnimation<Color>(
                  context.masteryColors.accent,
                ),
              ),
            ),
            const SizedBox(height: MasterySpacing.sm),
            Text(
              _progressLabel(),
              style: MasteryTextStyles.caption.copyWith(
                color: context.masteryColors.mutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: MasterySpacing.md),
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
      return 'Almost there. Keep momentum with a short finish.';
    }
    return 'Ready for your $targetMinutes-minute session.';
  }

  String _buttonLabel() {
    if (!hasItems) return 'Open no-items guidance';
    if (isCompleted) return 'Review anyway';
    if (progress > 0 && progress < 1) return 'Continue session';
    return 'Start session';
  }

  String _progressLabel() {
    final remainingMinutes = ((1 - progress) * targetMinutes).ceil();
    return '$remainingMinutes ${remainingMinutes == 1 ? 'minute' : 'minutes'} remaining';
  }
}
