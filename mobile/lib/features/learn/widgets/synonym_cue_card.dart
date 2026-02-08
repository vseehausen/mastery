import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/text_styles.dart';
import '../../../domain/services/srs_scheduler.dart';

/// Card for synonym-based active recall (D→A).
/// Shows a synonym phrase as prompt, user must recall the target word.
class SynonymCueCard extends StatefulWidget {
  const SynonymCueCard({
    super.key,
    required this.synonymPhrase,
    required this.targetWord,
    required this.onGrade,
    this.isSubmitting = false,
    this.isPreview = false,
  });

  /// The synonym phrase shown as prompt
  final String synonymPhrase;

  /// The target word to recall
  final String targetWord;

  /// Callback when user grades themselves
  final void Function(int rating) onGrade;
  final bool isSubmitting;

  /// Preview mode - hides grade buttons and saving message
  final bool isPreview;

  @override
  State<SynonymCueCard> createState() => _SynonymCueCardState();
}

class _SynonymCueCardState extends State<SynonymCueCard> {
  bool _isRevealed = false;
  bool _hasGraded = false;

  @override
  void didUpdateWidget(SynonymCueCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.synonymPhrase != widget.synonymPhrase ||
        oldWidget.targetWord != widget.targetWord) {
      setState(() {
        _isRevealed = false;
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
            'Recall the word.',
            style: MasteryTextStyles.bodySmall.copyWith(
              color: colors.mutedForeground,
            ),
          ),
          const SizedBox(height: 16),

          // Synonym prompt
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.muted,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.synonymPhrase,
              style: MasteryTextStyles.bodyLarge.copyWith(
                color: colors.foreground,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),

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
              _buildGradeButtons(),
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
              'Step 1 of 2: Recall the word',
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

  Widget _buildGradeButtons() {
    final colors = context.masteryColors;
    return Row(
      children: [
        _gradeButton('Again', 'Forgot', colors.destructive, ReviewRating.again),
        const SizedBox(width: 8),
        _gradeButton('Hard', 'Difficult', colors.warning, ReviewRating.hard),
        const SizedBox(width: 8),
        _gradeButton('Good', 'Correct', colors.success, ReviewRating.good),
        const SizedBox(width: 8),
        _gradeButton('Easy', 'Perfect', colors.info, ReviewRating.easy),
      ],
    );
  }

  Widget _gradeButton(
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
