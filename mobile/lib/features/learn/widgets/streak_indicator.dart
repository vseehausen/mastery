import 'package:flutter/material.dart';

import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/text_styles.dart';

/// Widget showing the current streak count
/// Displays as a flame icon with the streak number
class StreakIndicator extends StatelessWidget {
  const StreakIndicator({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.masteryColors;
    final hasStreak = count > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: hasStreak ? (colors.warningMuted) : (colors.muted),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department,
            size: 18,
            color: hasStreak ? (colors.warning) : (colors.mutedForeground),
          ),
          const SizedBox(width: 4),
          Text(
            count.toString(),
            style: MasteryTextStyles.bodyBold.copyWith(
              fontSize: 14,
              color: hasStreak ? (colors.warning) : (colors.mutedForeground),
            ),
          ),
        ],
      ),
    );
  }
}
