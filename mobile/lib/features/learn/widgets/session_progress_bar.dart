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
  });

  /// Number of items completed
  final int completedItems;

  /// Total items in session
  final int totalItems;

  /// Whether to show the text label
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = totalItems > 0 ? completedItems / totalItems : 0.0;

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
            backgroundColor: isDark
                ? MasteryColors.mutedDark
                : MasteryColors.mutedLight,
            valueColor: AlwaysStoppedAnimation<Color>(
              isDark ? MasteryColors.successDark : MasteryColors.successLight,
            ),
          ),
        ),
        if (showLabel) ...[
          const SizedBox(height: 4),
          Text(
            '$completedItems of $totalItems items',
            style: MasteryTextStyles.caption.copyWith(
              color: isDark
                  ? MasteryColors.mutedForegroundDark
                  : MasteryColors.mutedForegroundLight,
            ),
          ),
        ],
      ],
    );
  }
}
