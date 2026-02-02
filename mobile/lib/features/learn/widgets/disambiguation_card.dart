import 'package:flutter/material.dart';

import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/text_styles.dart';
import '../../../domain/services/srs_scheduler.dart';

/// Card for disambiguation multiple-choice prompts.
/// Shows a cloze sentence with options; user picks the correct word.
class DisambiguationCard extends StatefulWidget {
  const DisambiguationCard({
    super.key,
    required this.clozeSentence,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    required this.onGrade,
  });

  /// The sentence with a blank (e.g., "The ___ was full of money.")
  final String clozeSentence;

  /// Multiple-choice options
  final List<String> options;

  /// Index of the correct option
  final int correctIndex;

  /// Explanation shown after answering
  final String explanation;

  /// Callback when user answers (ReviewRating.good for correct, .again for wrong)
  final void Function(int rating) onGrade;

  @override
  State<DisambiguationCard> createState() => _DisambiguationCardState();
}

class _DisambiguationCardState extends State<DisambiguationCard> {
  int? _selectedIndex;

  @override
  void didUpdateWidget(DisambiguationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clozeSentence != widget.clozeSentence) {
      setState(() {
        _selectedIndex = null;
      });
    }
  }

  bool get _hasAnswered => _selectedIndex != null;
  bool get _isCorrect => _selectedIndex == widget.correctIndex;

  void _selectOption(int index) {
    if (_hasAnswered) return;

    setState(() {
      _selectedIndex = index;
    });

    final rating = index == widget.correctIndex
        ? ReviewRating.good
        : ReviewRating.again;
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

          // Microcopy
          Text(
            'Choose the correct word.',
            style: MasteryTextStyles.bodySmall.copyWith(
              color: isDark
                  ? MasteryColors.mutedForegroundDark
                  : MasteryColors.mutedForegroundLight,
            ),
          ),
          const SizedBox(height: 16),

          // Cloze sentence
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
              widget.clozeSentence,
              style: MasteryTextStyles.bodyLarge.copyWith(
                color: isDark ? Colors.white : Colors.black,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),

          // Options
          ...List<Widget>.generate(widget.options.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildOption(index, isDark),
            );
          }),

          // Feedback
          if (_hasAnswered) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (_isCorrect
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444))
                    .withValues(alpha: isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (_isCorrect
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444))
                      .withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isCorrect ? 'Correct!' : 'Not quite.',
                    style: MasteryTextStyles.bodyBold.copyWith(
                      color: _isCorrect
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.explanation,
                    style: MasteryTextStyles.bodySmall.copyWith(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildOption(int index, bool isDark) {
    final isSelected = _selectedIndex == index;
    final isCorrectOption = index == widget.correctIndex;

    Color borderColor;
    Color bgColor;

    if (!_hasAnswered) {
      borderColor = isDark
          ? MasteryColors.borderDark
          : MasteryColors.borderLight;
      bgColor = isDark
          ? MasteryColors.cardDark
          : MasteryColors.cardLight;
    } else if (isCorrectOption) {
      borderColor = const Color(0xFF10B981);
      bgColor = const Color(0xFF10B981).withValues(alpha: isDark ? 0.2 : 0.1);
    } else if (isSelected) {
      borderColor = const Color(0xFFEF4444);
      bgColor = const Color(0xFFEF4444).withValues(alpha: isDark ? 0.2 : 0.1);
    } else {
      borderColor = isDark
          ? MasteryColors.borderDark
          : MasteryColors.borderLight;
      bgColor = isDark
          ? MasteryColors.cardDark
          : MasteryColors.cardLight;
    }

    return SizedBox(
      width: double.infinity,
      child: InkWell(
        onTap: _hasAnswered ? null : () => _selectOption(index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Text(
            widget.options[index],
            style: MasteryTextStyles.body.copyWith(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: (_hasAnswered && isCorrectOption)
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
