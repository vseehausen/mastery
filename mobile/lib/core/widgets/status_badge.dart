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
    switch (status) {
      case LearningStatus.known:
        return (context.masteryColors.successMuted, context.masteryColors.success);
      case LearningStatus.learning:
        return (context.masteryColors.warningMuted, context.masteryColors.warning);
      case LearningStatus.unknown:
        // Subtle gray for "New" - less prominent
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return isDark
            ? (const Color(0xFF27272A), const Color(0xFF71717A))
            : (const Color(0xFFF4F4F5), const Color(0xFF71717A));
    }
  }
}
