import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/text_styles.dart';
import '../../../domain/services/srs_scheduler.dart';

/// Recall card for self-graded learning
/// Shows a word, user reveals answer, then grades themselves
class RecallCard extends StatefulWidget {
  const RecallCard({
    super.key,
    required this.word,
    required this.answer,
    required this.onGrade,
    this.context,
  });

  /// The word being tested
  final String word;

  /// The correct translation/definition
  final String answer;

  /// Optional context sentence
  final String? context;

  /// Callback when user grades themselves
  /// Returns the rating (1=Again, 2=Hard, 3=Good, 4=Easy)
  final void Function(int rating) onGrade;

  @override
  State<RecallCard> createState() => _RecallCardState();
}

class _RecallCardState extends State<RecallCard> {
  bool _isRevealed = false;

  @override
  void didUpdateWidget(RecallCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.word != widget.word) {
      setState(() {
        _isRevealed = false;
      });
    }
  }

  void _reveal() {
    setState(() {
      _isRevealed = true;
    });
  }

  void _handleGrade(int rating) {
    widget.onGrade(rating);
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

          // Word being tested
          Text(
            widget.word,
            style: MasteryTextStyles.displayLarge.copyWith(
              fontSize: 32,
              color: isDark ? Colors.white : Colors.black,
            ),
            textAlign: TextAlign.center,
          ),

          // Context if available
          if (widget.context != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? MasteryColors.mutedDark : MasteryColors.mutedLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.context!,
                style: MasteryTextStyles.bodySmall.copyWith(
                  color: isDark
                      ? MasteryColors.mutedForegroundDark
                      : MasteryColors.mutedForegroundLight,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],

          const Spacer(),

          // Answer section
          if (_isRevealed) ...[
            // Show the answer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? MasteryColors.cardDark : MasteryColors.cardLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? MasteryColors.borderDark : MasteryColors.borderLight,
                ),
              ),
              child: Text(
                widget.answer,
                style: MasteryTextStyles.bodyLarge.copyWith(
                  color: isDark ? Colors.white : Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 24),

            // Grade prompt
            Text(
              'How well did you remember?',
              style: MasteryTextStyles.bodySmall.copyWith(
                color: isDark
                    ? MasteryColors.mutedForegroundDark
                    : MasteryColors.mutedForegroundLight,
              ),
            ),

            const SizedBox(height: 16),

            // Grade buttons
            Row(
              children: [
                Expanded(
                  child: _GradeButton(
                    label: 'Again',
                    description: 'Forgot',
                    color: const Color(0xFFEF4444),
                    onPressed: () => _handleGrade(ReviewRating.again),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _GradeButton(
                    label: 'Hard',
                    description: 'Difficult',
                    color: const Color(0xFFF59E0B),
                    onPressed: () => _handleGrade(ReviewRating.hard),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _GradeButton(
                    label: 'Good',
                    description: 'Correct',
                    color: const Color(0xFF10B981),
                    onPressed: () => _handleGrade(ReviewRating.good),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _GradeButton(
                    label: 'Easy',
                    description: 'Perfect',
                    color: const Color(0xFF3B82F6),
                    onPressed: () => _handleGrade(ReviewRating.easy),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Show reveal button
            SizedBox(
              width: double.infinity,
              child: ShadButton(
                onPressed: _reveal,
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
}

/// Individual grade button
class _GradeButton extends StatelessWidget {
  const _GradeButton({
    required this.label,
    required this.description,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final String description;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onPressed,
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
              style: MasteryTextStyles.bodyBold.copyWith(
                fontSize: 14,
                color: color,
              ),
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
    );
  }
}
