import 'package:flutter/material.dart';
import '../../../../core/theme/color_tokens.dart';
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
    final colors = context.masteryColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Learning Status',
          style: MasteryTextStyles.bodyBold.copyWith(
            color: colors.foreground,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatItem(
                label: 'Times Reviewed',
                value: timesReviewed?.toString() ?? '-',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatItem(
                label: 'Confidence',
                value: confidence != null ? '$confidence/5' : '-',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: _StatItem(
            label: 'Next Review',
            value: _formatDate(nextReview),
          ),
        ),
      ],
    );
  }
}

/// Compact inline learning statistics displayed in a single line
class LearningStatsInline extends StatelessWidget {
  const LearningStatsInline({
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
    final colors = context.masteryColors;

    final reviewsText = timesReviewed != null
        ? '$timesReviewed ${timesReviewed == 1 ? 'review' : 'reviews'}'
        : '0 reviews';

    final nextText = 'Next: ${_formatDate(nextReview)}';

    return Text(
      '$reviewsText · $nextText',
      style: MasteryTextStyles.bodySmall.copyWith(
        color: colors.mutedForeground,
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.masteryColors;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.secondaryAction,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: MasteryTextStyles.bodySmall.copyWith(
              color: colors.mutedForeground,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: MasteryTextStyles.bodyBold.copyWith(
              color: colors.foreground,
            ),
          ),
        ],
      ),
    );
  }
}
