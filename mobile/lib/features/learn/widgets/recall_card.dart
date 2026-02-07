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
    this.isSubmitting = false,
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
  final bool isSubmitting;

  @override
  State<RecallCard> createState() => _RecallCardState();
}

class _RecallCardState extends State<RecallCard> {
  bool _isRevealed = false;
  bool _hasGraded = false;

  @override
  void didUpdateWidget(RecallCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.word != widget.word) {
      setState(() {
        _isRevealed = false;
        _hasGraded = false;
      });
    }
  }

  void _reveal() {
    setState(() {
      _isRevealed = true;
    });
  }

  void _handleGrade(int rating) {
    if (_hasGraded || widget.isSubmitting) return;
    setState(() {
      _hasGraded = true;
    });
    widget.onGrade(rating);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.masteryColors;

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
              color: colors.foreground,
            ),
            textAlign: TextAlign.center,
          ),

          // Context if available
          if (widget.context != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colors.muted,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.context!,
                style: MasteryTextStyles.bodySmall.copyWith(
                  color: colors.mutedForeground,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],

          const Spacer(),

          // Answer section
          if (_isRevealed) ...[
            Text(
              'Step 2 of 2: Grade your recall',
              style: MasteryTextStyles.bodySmall.copyWith(
                color: colors.mutedForeground,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'How well did you remember?',
              style: MasteryTextStyles.bodySmall.copyWith(
                color: colors.mutedForeground,
              ),
            ),
            const SizedBox(height: 8),
            // Show the answer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colors.border,
                ),
              ),
              child: Text(
                widget.answer,
                style: MasteryTextStyles.bodyLarge.copyWith(
                  color: colors.foreground,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 24),

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
                    isEnabled: !_hasGraded && !widget.isSubmitting,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _GradeButton(
                    label: 'Hard',
                    description: 'Difficult',
                    color: const Color(0xFFF59E0B),
                    onPressed: () => _handleGrade(ReviewRating.hard),
                    isEnabled: !_hasGraded && !widget.isSubmitting,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _GradeButton(
                    label: 'Good',
                    description: 'Correct',
                    color: const Color(0xFF10B981),
                    onPressed: () => _handleGrade(ReviewRating.good),
                    isEnabled: !_hasGraded && !widget.isSubmitting,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _GradeButton(
                    label: 'Easy',
                    description: 'Perfect',
                    color: const Color(0xFF3B82F6),
                    onPressed: () => _handleGrade(ReviewRating.easy),
                    isEnabled: !_hasGraded && !widget.isSubmitting,
                  ),
                ),
              ],
            ),
            if (widget.isSubmitting || _hasGraded) ...[
              const SizedBox(height: 10),
              Text(
                'Saving response…',
                style: MasteryTextStyles.caption.copyWith(
                  color: colors.mutedForeground,
                ),
              ),
            ],
          ] else ...[
            Text(
              'Step 1 of 2: Try to recall first',
              style: MasteryTextStyles.bodySmall.copyWith(
                color: colors.mutedForeground,
              ),
            ),
            const SizedBox(height: 10),
            // Show reveal button
            SizedBox(
              width: double.infinity,
              child: ShadButton(
                onPressed: widget.isSubmitting ? null : _reveal,
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
    required this.isEnabled,
  });

  final String label;
  final String description;
  final Color color;
  final VoidCallback onPressed;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.masteryColors;

    return InkWell(
      onTap: isEnabled ? onPressed : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
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
                color: colors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
