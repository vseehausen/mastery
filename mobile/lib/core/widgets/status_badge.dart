import 'package:flutter/material.dart';
import '../theme/color_tokens.dart';
import '../theme/text_styles.dart';

/// Status badge for vocabulary learning status
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status, this.compact = false});

  final LearningStatus status;
  final bool compact;

  String get _label {
    switch (status) {
      case LearningStatus.known:
        return 'Known';
      case LearningStatus.learning:
        return 'Learning';
      case LearningStatus.unknown:
        return 'New';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get colors based on status
    final (bgColor, textColor) = _getColors(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _label,
        style:
            (compact ? MasteryTextStyles.caption : MasteryTextStyles.bodySmall)
                .copyWith(color: textColor, fontWeight: FontWeight.w500),
      ),
    );
  }

  (Color, Color) _getColors(BuildContext context) {
    final colors = context.masteryColors;
    switch (status) {
      case LearningStatus.known:
        return (colors.successMuted, colors.success);
      case LearningStatus.learning:
        return (colors.warningMuted, colors.warning);
      case LearningStatus.unknown:
        return (colors.muted, colors.mutedForeground);
    }
  }
}
