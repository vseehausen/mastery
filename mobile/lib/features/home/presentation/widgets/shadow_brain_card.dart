import 'package:flutter/material.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../../../core/theme/text_styles.dart';

/// Card showing vocabulary statistics and learning progress
class ShadowBrainCard extends StatelessWidget {
  const ShadowBrainCard({
    super.key,
    required this.totalWords,
    required this.activeWords,
    required this.progressPercent,
  });

  final int totalWords;
  final int activeWords;
  final double progressPercent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Shadow Brain',
          style: MasteryTextStyles.bodyBold.copyWith(
            fontSize: 18,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: 'Total',
                value: totalWords.toString(),
                icon: Icons.auto_stories,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                label: 'Active',
                value: activeWords.toString(),
                icon: Icons.local_fire_department_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Learning progress bar
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Learning Progress',
              style: MasteryTextStyles.bodySmall.copyWith(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progressPercent / 100,
                minHeight: 8,
                backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${progressPercent.toStringAsFixed(0)}%',
              style: MasteryTextStyles.bodySmall.copyWith(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
