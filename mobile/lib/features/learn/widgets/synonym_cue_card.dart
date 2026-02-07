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
  });

  /// The synonym phrase shown as prompt
  final String synonymPhrase;

  /// The target word to recall
  final String targetWord;

  /// Callback when user grades themselves
  final void Function(int rating) onGrade;
  final bool isSubmitting;

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              color: isDark
                  ? MasteryColors.mutedForegroundDark
                  : MasteryColors.mutedForegroundLight,
            ),
          ),
          const SizedBox(height: 16),

          // Synonym prompt
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
              widget.synonymPhrase,
              style: MasteryTextStyles.bodyLarge.copyWith(
                color: isDark ? Colors.white : Colors.black,
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
                color: isDark
                    ? MasteryColors.mutedForegroundDark
                    : MasteryColors.mutedForegroundLight,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'How well did you remember?',
              style: MasteryTextStyles.bodySmall.copyWith(
                color: isDark
                    ? MasteryColors.mutedForegroundDark
                    : MasteryColors.mutedForegroundLight,
              ),
            ),
            const SizedBox(height: 8),
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
            const SizedBox(height: 16),
            _buildGradeButtons(isDark),
            if (widget.isSubmitting || _hasGraded) ...[
              const SizedBox(height: 10),
              Text(
                'Saving response…',
                style: MasteryTextStyles.caption.copyWith(
                  color: isDark
                      ? MasteryColors.mutedForegroundDark
                      : MasteryColors.mutedForegroundLight,
                ),
              ),
            ],
          ] else ...[
            Text(
              'Step 1 of 2: Recall the word',
              style: MasteryTextStyles.bodySmall.copyWith(
                color: isDark
                    ? MasteryColors.mutedForegroundDark
                    : MasteryColors.mutedForegroundLight,
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

  Widget _buildGradeButtons(bool isDark) {
    return Row(
      children: [
        _gradeButton(
          'Again',
          'Forgot',
          const Color(0xFFEF4444),
          ReviewRating.again,
          isDark,
        ),
        const SizedBox(width: 8),
        _gradeButton(
          'Hard',
          'Difficult',
          const Color(0xFFF59E0B),
          ReviewRating.hard,
          isDark,
        ),
        const SizedBox(width: 8),
        _gradeButton(
          'Good',
          'Correct',
          const Color(0xFF10B981),
          ReviewRating.good,
          isDark,
        ),
        const SizedBox(width: 8),
        _gradeButton(
          'Easy',
          'Perfect',
          const Color(0xFF3B82F6),
          ReviewRating.easy,
          isDark,
        ),
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
      ),
    );
  }
}
