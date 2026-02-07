import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/text_styles.dart';
import '../../../providers/supabase_provider.dart';
import '../providers/streak_providers.dart';
import '../widgets/streak_indicator.dart';
import 'session_screen.dart';

/// Screen shown after completing a learning session
class SessionCompleteScreen extends ConsumerStatefulWidget {
  const SessionCompleteScreen({
    super.key,
    required this.sessionId,
    required this.itemsCompleted,
    required this.totalItems,
    required this.elapsedSeconds,
    required this.plannedSeconds,
    required this.isFullCompletion,
    this.allItemsExhausted = false,
  });

  final String sessionId;
  final int itemsCompleted;
  final int totalItems;
  final int elapsedSeconds;
  final int plannedSeconds;
  final bool isFullCompletion;
  final bool allItemsExhausted;

  @override
  ConsumerState<SessionCompleteScreen> createState() =>
      _SessionCompleteScreenState();
}

class _SessionCompleteScreenState extends ConsumerState<SessionCompleteScreen> {
  bool _isAddingBonus = false;

  Future<void> _addBonusTime() async {
    if (_isAddingBonus) return;

    setState(() {
      _isAddingBonus = true;
    });

    try {
      final dataService = ref.read(supabaseDataServiceProvider);

      // Add 2 minutes (120 seconds) of bonus time
      await dataService.addBonusTime(
        sessionId: widget.sessionId,
        bonusSeconds: 120,
      );

      // Navigate back to session screen to continue
      if (mounted) {
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (context) => const SessionScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding bonus time: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAddingBonus = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.masteryColors;
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
                  color: widget.isFullCompletion
                      ? (colors.successMuted)
                      : (colors.warningMuted),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.isFullCompletion
                      ? Icons.check_circle
                      : Icons.access_time,
                  size: 64,
                  color: widget.isFullCompletion
                      ? (colors.success)
                      : (colors.warning),
                ),
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                _getTitle(),
                style: MasteryTextStyles.displayLarge.copyWith(
                  color: colors.foreground,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Subtitle
              Text(
                _getSubtitle(),
                style: MasteryTextStyles.body.copyWith(
                  color: colors.mutedForeground,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Stats
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colors.border,
                  ),
                ),
                child: Column(
                  children: [
                    _StatRow(
                      label: 'Items reviewed',
                      value: '${widget.itemsCompleted}',
                      
                    ),
                    const SizedBox(height: 12),
                    _StatRow(
                      label: 'Time practiced',
                      value: _formatTime(widget.elapsedSeconds),
                      
                    ),
                    const SizedBox(height: 12),
                    Divider(
                      color: colors.border,
                    ),
                    const SizedBox(height: 12),
                    // Streak
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Current streak',
                          style: MasteryTextStyles.bodySmall.copyWith(
                            color: colors.mutedForeground,
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

              // Bonus time button (only if full completion and items available)
              if (widget.isFullCompletion && !widget.allItemsExhausted) ...[
                ShadButton.outline(
                  onPressed: _isAddingBonus ? null : _addBonusTime,
                  child: _isAddingBonus
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Row(
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

  String _getTitle() {
    if (widget.allItemsExhausted) {
      return "You've reviewed everything!";
    }
    if (widget.isFullCompletion) {
      return "You're done for today!";
    }
    return 'Session ended';
  }

  String _getSubtitle() {
    if (widget.allItemsExhausted) {
      return 'No more items available right now.';
    }
    if (widget.isFullCompletion) {
      return 'Great work! Come back tomorrow.';
    }
    return 'You made progress today.';
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
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.masteryColors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: MasteryTextStyles.bodySmall.copyWith(
            color: colors.mutedForeground,
          ),
        ),
        Text(
          value,
          style: MasteryTextStyles.bodyBold.copyWith(
            color: colors.foreground,
          ),
        ),
      ],
    );
  }
}
