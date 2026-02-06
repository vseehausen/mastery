import 'package:flutter/material.dart';
import '../../../../core/theme/text_styles.dart';

/// Displays a preview of a learning cue (question/answer pair)
/// Used to show how vocabulary will be tested in learning sessions
class CuePreviewCard extends StatelessWidget {
  const CuePreviewCard({
    super.key,
    required this.cue,
  });

  final Map<String, dynamic> cue;

  /// Returns the display name and color for each cue type
  (String label, Color color) _getCueTypeInfo(String cueType) {
    switch (cueType) {
      case 'translation':
        return ('Translation', const Color(0xFF3B82F6)); // Blue
      case 'definition':
        return ('Definition', const Color(0xFF10B981)); // Green
      case 'synonym':
        return ('Synonym', const Color(0xFF8B5CF6)); // Purple
      case 'cloze':
        return ('Fill in the Blank', const Color(0xFFF59E0B)); // Amber
      case 'multiple_choice':
        return ('Choose the Word', const Color(0xFFEC4899)); // Pink
      default:
        return (cueType, const Color(0xFF6B7280)); // Gray
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.grey.withValues(alpha: 0.1);

    final cueType = cue['cue_type'] as String? ?? 'unknown';
    final promptText = cue['prompt_text'] as String? ?? '';
    final answerText = cue['answer_text'] as String? ?? '';

    final (typeLabel, typeColor) = _getCueTypeInfo(cueType);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.2),
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
                color: isDark ? Colors.white70 : Colors.black87,
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
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
        ],
      ),
    );
  }
}
