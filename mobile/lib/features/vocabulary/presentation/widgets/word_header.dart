import 'package:flutter/material.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/theme/color_tokens.dart';

/// Header section of word detail showing word and status
class WordHeader extends StatelessWidget {
  const WordHeader({
    super.key,
    required this.word,
    this.pronunciation,
    this.status,
  });

  final String word;
  final String? pronunciation;
  final LearningStatus? status;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                word,
                style: MasteryTextStyles.displayLarge.copyWith(
                  color: isDark
                      ? MasteryColors.foregroundDark
                      : MasteryColors.foregroundLight,
                ),
              ),
              if (pronunciation != null && pronunciation!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  pronunciation!,
                  style: MasteryTextStyles.bodySmall.copyWith(
                    color: isDark
                        ? MasteryColors.mutedForegroundDark
                        : MasteryColors.mutedForegroundLight,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (status != null) ...[
          const SizedBox(width: 12),
          StatusBadge(status: status!),
        ],
      ],
    );
  }
}
