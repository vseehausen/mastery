import 'package:flutter/material.dart';
import '../../domain/models/progress_stage.dart';
import '../theme/color_tokens.dart';
import '../theme/text_styles.dart';

/// Badge widget displaying a vocabulary word's progress stage.
///
/// Uses the stage's color from the theme and displays the stage name
/// in a compact pill-shaped badge.
class ProgressStageBadge extends StatelessWidget {
  const ProgressStageBadge({
    super.key,
    required this.stage,
    this.compact = false,
  });

  final ProgressStage stage;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.masteryColors;
    final stageColor = stage.getColor(colors);
    final stageBgColor = stage.getBgColor(colors);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: stageBgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        stage.displayName,
        style:
            (compact ? MasteryTextStyles.caption : MasteryTextStyles.bodySmall)
                .copyWith(color: stageColor, fontWeight: FontWeight.w500),
      ),
    );
  }
}
