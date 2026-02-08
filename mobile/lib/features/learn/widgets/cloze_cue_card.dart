import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/text_styles.dart';
import '../../../domain/services/srs_scheduler.dart';

/// Card for context cloze fill-in-the-blank exercises.
/// Shows a sentence with a blank, user must recall the missing word.
class ClozeCueCard extends StatefulWidget {
  const ClozeCueCard({
    super.key,
    required this.sentenceWithBlank,
    required this.targetWord,
    required this.onGrade,
    this.hintText,
    this.isSubmitting = false,
    this.isPreview = false,
  });

  /// The sentence with ___ blank
  final String sentenceWithBlank;

  /// The target word that fills the blank
  final String targetWord;

  /// Optional meaning-based hint
  final String? hintText;

  /// Callback when user grades themselves
  final void Function(int rating) onGrade;
  final bool isSubmitting;

  /// Preview mode - hides grade buttons and saving message
  final bool isPreview;

  @override
  State<ClozeCueCard> createState() => _ClozeCueCardState();
}

class _ClozeCueCardState extends State<ClozeCueCard> {
  bool _isRevealed = false;
  bool _showHint = false;
  bool _hasGraded = false;

  @override
  void didUpdateWidget(ClozeCueCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sentenceWithBlank != widget.sentenceWithBlank ||
        oldWidget.targetWord != widget.targetWord) {
      setState(() {
        _isRevealed = false;
        _showHint = false;
        _hasGraded = false;
      });
    }
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

          // Microcopy
          Text(
            'Fill the blank.',
            style: MasteryTextStyles.bodySmall.copyWith(
              color: colors.mutedForeground,
            ),
          ),
          const SizedBox(height: 16),

          // Cloze sentence
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.muted,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.sentenceWithBlank,
              style: MasteryTextStyles.bodyLarge.copyWith(
                color: colors.foreground,
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
                  color: colors.mutedForeground,
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
                    color: colors.accent,
                  ),
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.border),
              ),
              child: Text(
                widget.targetWord,
                style: MasteryTextStyles.displayLarge.copyWith(
                  fontSize: 28,
                  color: colors.foreground,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            const SizedBox(height: 16),
            if (!widget.isPreview) ...[
              _buildGradeButtons(context),
              if (widget.isSubmitting || _hasGraded) ...[
                const SizedBox(height: 10),
                Text(
                  'Saving response…',
                  style: MasteryTextStyles.caption.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
              ],
            ],
          ] else ...[
            Text(
              'Step 1 of 2: Recall the missing word',
              style: MasteryTextStyles.bodySmall.copyWith(
                color: colors.mutedForeground,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ShadButton(
                onPressed: widget.isSubmitting
                    ? null
                    : () => setState(() => _isRevealed = true),
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

  Widget _buildGradeButtons(BuildContext context) {
    final colors = context.masteryColors;
    return Row(
      children: [
        _gradeButton(
          context,
          'Again',
          'Forgot',
          colors.destructive,
          ReviewRating.again,
        ),
        const SizedBox(width: 8),
        _gradeButton(
          context,
          'Hard',
          'Difficult',
          colors.warning,
          ReviewRating.hard,
        ),
        const SizedBox(width: 8),
        _gradeButton(
          context,
          'Good',
          'Correct',
          colors.success,
          ReviewRating.good,
        ),
        const SizedBox(width: 8),
        _gradeButton(
          context,
          'Easy',
          'Perfect',
          colors.info,
          ReviewRating.easy,
        ),
      ],
    );
  }

  Widget _gradeButton(
    BuildContext context,
    String label,
    String description,
    Color color,
    int rating,
  ) {
    final colors = context.masteryColors;
    return Expanded(
      child: InkWell(
        onTap: (!_hasGraded && !widget.isSubmitting)
            ? () {
                setState(() {
                  _hasGraded = true;
                });
                widget.onGrade(rating);
              }
            : null,
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
      ),
    );
  }
}
