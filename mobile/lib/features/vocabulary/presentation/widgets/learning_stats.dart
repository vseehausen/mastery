import 'package:flutter/material.dart';
import '../../../../core/theme/text_styles.dart';

/// Learning statistics for a word
class LearningStats extends StatelessWidget {
  const LearningStats({
    super.key,
    this.timesReviewed,
    this.confidence,
    this.nextReview,
  });

  final int? timesReviewed;
  final int? confidence; // 1-5
  final DateTime? nextReview;

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    final now = DateTime.now();
    final diff = date.difference(now);

    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Tomorrow';
    if (diff.inDays < 0) return 'Overdue';
    return 'In ${diff.inDays} days';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Learning Status',
          style: MasteryTextStyles.bodyBold.copyWith(
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatItem(
                label: 'Times Reviewed',
                value: timesReviewed?.toString() ?? '-',
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatItem(
                label: 'Confidence',
                value: confidence != null ? '$confidence/5' : '-',
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _StatItem(
          label: 'Next Review',
          value: _formatDate(nextReview),
          isDark: isDark,
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.isDark,
  });

  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: MasteryTextStyles.bodySmall.copyWith(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: MasteryTextStyles.bodyBold.copyWith(
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
