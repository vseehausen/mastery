import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/text_styles.dart';
import '../../../domain/services/srs_scheduler.dart';

/// Card for definition-based active recall (C→A).
/// Shows an English definition as prompt, user must recall the word.
class DefinitionCueCard extends StatefulWidget {
  const DefinitionCueCard({
    super.key,
    required this.definition,
    required this.targetWord,
    required this.onGrade,
    this.hintText,
  });

  /// The English definition shown as prompt
  final String definition;

  /// The target word to recall
  final String targetWord;

  /// Optional hint text
  final String? hintText;

  /// Callback when user grades themselves
  final void Function(int rating) onGrade;

  @override
  State<DefinitionCueCard> createState() => _DefinitionCueCardState();
}

class _DefinitionCueCardState extends State<DefinitionCueCard> {
  bool _isRevealed = false;
  bool _showHint = false;

  @override
  void didUpdateWidget(DefinitionCueCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.definition != widget.definition ||
        oldWidget.targetWord != widget.targetWord) {
      setState(() {
        _isRevealed = false;
        _showHint = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(),

          // Microcopy
          Text(
            'Which word fits best?',
            style: MasteryTextStyles.bodySmall.copyWith(
              color: isDark
                  ? MasteryColors.mutedForegroundDark
                  : MasteryColors.mutedForegroundLight,
            ),
          ),
          const SizedBox(height: 16),

          // Definition prompt
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark
                  ? MasteryColors.mutedDark
                  : MasteryColors.mutedLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.definition,
              style: MasteryTextStyles.bodyLarge.copyWith(
                color: isDark ? Colors.white : Colors.black,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Hint
          if (widget.hintText != null && !_isRevealed) ...[
            const SizedBox(height: 12),
            if (_showHint)
              Text(
                widget.hintText!,
                style: MasteryTextStyles.bodySmall.copyWith(
                  color: isDark
                      ? MasteryColors.mutedForegroundDark
                      : MasteryColors.mutedForegroundLight,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              )
            else
              GestureDetector(
                onTap: () => setState(() => _showHint = true),
                child: Text(
                  'Show hint',
                  style: MasteryTextStyles.bodySmall.copyWith(
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
          ],

          const Spacer(),

          // Answer section
          if (_isRevealed) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark
                    ? MasteryColors.cardDark
                    : MasteryColors.cardLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? MasteryColors.borderDark
                      : MasteryColors.borderLight,
                ),
              ),
              child: Text(
                widget.targetWord,
                style: MasteryTextStyles.displayLarge.copyWith(
                  fontSize: 28,
                  color: isDark ? Colors.white : Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'How well did you remember?',
              style: MasteryTextStyles.bodySmall.copyWith(
                color: isDark
                    ? MasteryColors.mutedForegroundDark
                    : MasteryColors.mutedForegroundLight,
              ),
            ),
            const SizedBox(height: 16),
            _buildGradeButtons(isDark),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ShadButton(
                onPressed: () => setState(() => _isRevealed = true),
                size: ShadButtonSize.lg,
                child: const Text('Show Answer'),
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildGradeButtons(bool isDark) {
    return Row(
      children: [
        _gradeButton('Again', 'Forgot', const Color(0xFFEF4444),
            ReviewRating.again, isDark),
        const SizedBox(width: 8),
        _gradeButton('Hard', 'Difficult', const Color(0xFFF59E0B),
            ReviewRating.hard, isDark),
        const SizedBox(width: 8),
        _gradeButton('Good', 'Correct', const Color(0xFF10B981),
            ReviewRating.good, isDark),
        const SizedBox(width: 8),
        _gradeButton('Easy', 'Perfect', const Color(0xFF3B82F6),
            ReviewRating.easy, isDark),
      ],
    );
  }

  Widget _gradeButton(
    String label,
    String description,
    Color color,
    int rating,
    bool isDark,
  ) {
    return Expanded(
      child: InkWell(
        onTap: () => widget.onGrade(rating),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: MasteryTextStyles.bodyBold
                    .copyWith(fontSize: 14, color: color),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: MasteryTextStyles.caption.copyWith(
                  color: isDark
                      ? MasteryColors.mutedForegroundDark
                      : MasteryColors.mutedForegroundLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
