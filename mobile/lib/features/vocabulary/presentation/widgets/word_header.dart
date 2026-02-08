import 'package:flutter/material.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/progress_stage_badge.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../domain/models/progress_stage.dart';

/// Header section of word detail showing word and status
class WordHeader extends StatelessWidget {
  const WordHeader({
    super.key,
    required this.word,
    this.pronunciation,
    this.progressStage,
  });

  final String word;
  final String? pronunciation;
  final ProgressStage? progressStage;

  @override
  Widget build(BuildContext context) {
    final colors = context.masteryColors;

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
                  color: colors.foreground,
                ),
              ),
              if (pronunciation != null && pronunciation!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  pronunciation!,
                  style: MasteryTextStyles.bodySmall.copyWith(
                    color: colors.mutedForeground,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (progressStage != null) ...[
          const SizedBox(width: 12),
          ProgressStageBadge(stage: progressStage!),
        ],
      ],
    );
  }
}
