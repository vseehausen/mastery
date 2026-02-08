import 'package:flutter/material.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/text_styles.dart';

/// Displays a preview of a learning cue (question/answer pair)
/// Used to show how vocabulary will be tested in learning sessions
class CuePreviewCard extends StatelessWidget {
  const CuePreviewCard({super.key, required this.cue});

  final Map<String, dynamic> cue;

  /// Returns the display name and color for each cue type
  (String label, Color color) _getCueTypeInfo(
    String cueType,
    BuildContext context,
  ) {
    switch (cueType) {
      case 'translation':
        return (
          'Translation',
          MasteryColors.getCueColor(context, cueType),
        );
      case 'definition':
        return (
          'Definition',
          MasteryColors.getCueColor(context, cueType),
        );
      case 'synonym':
        return ('Synonym', MasteryColors.getCueColor(context, cueType));
      case 'cloze':
        return (
          'Fill in the Blank',
          MasteryColors.getCueColor(context, cueType),
        );
      case 'multiple_choice':
        return (
          'Choose the Word',
          MasteryColors.getCueColor(context, cueType),
        );
      default:
        return (cueType, MasteryColors.getCueColor(context, cueType));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.masteryColors;

    final cueType = cue['cue_type'] as String? ?? 'unknown';
    final promptText = cue['prompt_text'] as String? ?? '';
    final answerText = cue['answer_text'] as String? ?? '';

    final (typeLabel, typeColor) = _getCueTypeInfo(cueType, context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.secondaryAction,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cue type chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: typeColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              typeLabel,
              style: MasteryTextStyles.caption.copyWith(
                color: typeColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Prompt text
          if (promptText.isNotEmpty) ...[
            Text(
              promptText,
              style: MasteryTextStyles.body.copyWith(
                color: colors.mutedForeground,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Answer text (always visible in preview mode)
          if (answerText.isNotEmpty)
            Text(
              answerText,
              style: MasteryTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.foreground,
              ),
            ),
        ],
      ),
    );
  }
}
