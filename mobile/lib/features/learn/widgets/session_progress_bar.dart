import 'package:flutter/material.dart';

import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/text_styles.dart';

/// Widget showing progress through session items
/// Displays completed vs total items as a progress bar
class SessionProgressBar extends StatelessWidget {
  const SessionProgressBar({
    super.key,
    required this.completedItems,
    required this.totalItems,
    this.showLabel = true,
    this.isQuickReview = false,
  });

  /// Number of items completed
  final int completedItems;

  /// Total items in session
  final int totalItems;

  /// Whether to show the text label
  final bool showLabel;

  /// Whether this is a quick review session
  final bool isQuickReview;

  @override
  Widget build(BuildContext context) {
    final colors = context.masteryColors;
    final progress = totalItems > 0 ? completedItems / totalItems : 0.0;
    // Clamp displayed values to prevent showing completion beyond total
    final displayCompleted = completedItems.clamp(0, totalItems);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: colors.muted,
            valueColor: AlwaysStoppedAnimation<Color>(colors.success),
          ),
        ),
        if (showLabel) ...[
          const SizedBox(height: 4),
          Text(
            isQuickReview
                ? 'Quick review • $displayCompleted/$totalItems'
                : '$displayCompleted of $totalItems items',
            style: MasteryTextStyles.caption.copyWith(
              color: colors.mutedForeground,
            ),
          ),
        ],
      ],
    );
  }
}
