import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/radius_tokens.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/text_styles.dart';
import '../../../domain/models/progress_stage.dart';
import '../../../domain/models/session_progress_summary.dart';
import '../../../domain/models/stage_transition.dart';
import '../../../providers/review_write_queue_provider.dart';
import '../../../providers/supabase_provider.dart';
import '../providers/streak_providers.dart';
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
    this.transitions = const [],
    this.isQuickReview = false,
  });

  final String sessionId;
  final int itemsCompleted;
  final int totalItems;
  final int elapsedSeconds;
  final int plannedSeconds;
  final bool isFullCompletion;
  final bool allItemsExhausted;
  final List<StageTransition> transitions;
  final bool isQuickReview;

  @override
  ConsumerState<SessionCompleteScreen> createState() =>
      _SessionCompleteScreenState();
}

class _SessionCompleteScreenState extends ConsumerState<SessionCompleteScreen> {
  bool _isAddingBonus = false;
  int _queuedWritesCount = 0;

  @override
  void initState() {
    super.initState();
    _checkQueuedWrites();
  }

  Future<void> _checkQueuedWrites() async {
    final queue = ref.read(reviewWriteQueueProvider);
    final count = await queue.getQueueSize();
    if (mounted) {
      setState(() {
        _queuedWritesCount = count;
      });
    }
  }

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

              // Hero icon - double-circle with checkmark
              _DoubleCircleHeroIcon(
                isFullCompletion: widget.isFullCompletion,
              ),
              const SizedBox(height: 32),

              // Title (no subtitle)
              Text(
                _getTitle(),
                style: MasteryTextStyles.displayLarge.copyWith(
                  color: colors.foreground,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Progress card (only when transitions exist)
              if (widget.transitions.isNotEmpty) ...[
                _ProgressCard(
                  summary: SessionProgressSummary(widget.transitions),
                ),
                const SizedBox(height: 16),
              ],

              // Stats + streak as one muted line
              currentStreak.when(
                data: (streak) => Text(
                  _buildStatsLine(streak),
                  style: MasteryTextStyles.bodySmall.copyWith(
                    color: colors.mutedForeground,
                  ),
                  textAlign: TextAlign.center,
                ),
                loading: () => Text(
                  _buildStatsLine(null),
                  style: MasteryTextStyles.bodySmall.copyWith(
                    color: colors.mutedForeground,
                  ),
                  textAlign: TextAlign.center,
                ),
                error: (error, stack) => Text(
                  _buildStatsLine(null),
                  style: MasteryTextStyles.bodySmall.copyWith(
                    color: colors.mutedForeground,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Subtle sync notice (only when queue has pending writes)
              if (_queuedWritesCount > 0) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.cardBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.cloud_sync,
                        size: 16,
                        color: colors.mutedForeground,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Some reviews will sync when connection returns',
                          style: MasteryTextStyles.caption.copyWith(
                            color: colors.mutedForeground,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

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
    if (widget.isQuickReview) {
      return 'Quick review done!';
    }
    if (widget.allItemsExhausted) {
      return "You've reviewed everything!";
    }
    if (widget.isFullCompletion) {
      return "You're done for today!";
    }
    return 'Session ended';
  }

  String _buildStatsLine(int? streak) {
    final parts = <String>[];

    // Items
    parts.add('${widget.itemsCompleted} items');

    // Time
    parts.add(_formatTime(widget.elapsedSeconds));

    // Streak (if exists)
    if (streak != null && streak > 0) {
      parts.add('$streak-day streak');
    }

    return parts.join(' · ');
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

/// Double-circle hero icon with checkmark
class _DoubleCircleHeroIcon extends StatelessWidget {
  const _DoubleCircleHeroIcon({required this.isFullCompletion});

  final bool isFullCompletion;

  @override
  Widget build(BuildContext context) {
    final colors = context.masteryColors;

    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring at 18% opacity
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: isFullCompletion
                  ? colors.success.withValues(alpha: 0.18)
                  : colors.warning.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
          ),
          // Inner solid circle with icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isFullCompletion ? colors.success : colors.warning,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isFullCompletion ? Icons.check : Icons.access_time,
              size: 40,
              color: colors.background,
            ),
          ),
        ],
      ),
    );
  }
}

/// Progress card showing stage transitions without star icons or header
class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.summary});

  final SessionProgressSummary summary;

  @override
  Widget build(BuildContext context) {
    final colors = context.masteryColors;

    // Build list of transition rows with spacing between them
    final rows = <Widget>[];
    if (summary.masteredCount > 0) {
      rows.add(_TransitionRow(
        stage: ProgressStage.mastered,
        count: summary.masteredCount,
      ));
    }
    if (summary.knownCount > 0) {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: AppSpacing.s2));
      rows.add(_TransitionRow(
        stage: ProgressStage.known,
        count: summary.knownCount,
      ));
    }
    if (summary.stabilizingCount > 0) {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: AppSpacing.s2));
      rows.add(_TransitionRow(
        stage: ProgressStage.stabilizing,
        count: summary.stabilizingCount,
      ));
    }
    if (summary.practicingCount > 0) {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: AppSpacing.s2));
      rows.add(_TransitionRow(
        stage: ProgressStage.practicing,
        count: summary.practicingCount,
      ));
    }

    return Semantics(
      liveRegion: true,
      label: summary.toDisplayString(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.s5),
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rows,
        ),
      ),
    );
  }
}

class _TransitionRow extends StatelessWidget {
  const _TransitionRow({
    required this.stage,
    required this.count,
  });

  final ProgressStage stage;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.masteryColors;
    final stageColor = stage.getColor(colors);
    final wordLabel = count == 1 ? 'word' : 'words';

    return Row(
      children: [
        Container(
          width: AppSpacing.s2,
          height: AppSpacing.s2,
          decoration: BoxDecoration(
            color: stageColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpacing.s2 + AppSpacing.s1), // 12px
        Expanded(
          child: Text(
            '$count $wordLabel → ${stage.displayName}',
            style: MasteryTextStyles.body.copyWith(
              color: colors.foreground,
            ),
          ),
        ),
      ],
    );
  }
}
