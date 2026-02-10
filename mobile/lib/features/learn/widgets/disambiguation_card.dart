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
    this.isPreview = false,
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

  /// Preview mode - pre-selects correct answer to show explanation
  final bool isPreview;

  @override
  State<DisambiguationCard> createState() => _DisambiguationCardState();
}

class _DisambiguationCardState extends State<DisambiguationCard> {
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    if (widget.isPreview) {
      _selectedIndex = widget.correctIndex;
    }
  }

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
    final colors = context.masteryColors;

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
              widget.clozeSentence,
              style: MasteryTextStyles.bodyLarge.copyWith(
                color: colors.foreground,
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
              child: _buildOption(index, context),
            );
          }),

          // Feedback
          if (_hasAnswered) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (_isCorrect ? colors.success : colors.destructive)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (_isCorrect ? colors.success : colors.destructive)
                      .withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isCorrect ? 'Correct!' : 'Not quite.',
                    style: MasteryTextStyles.bodyBold.copyWith(
                      color: _isCorrect ? colors.success : colors.destructive,
                    ),
                  ),
                  if (widget.explanation.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.explanation,
                      style: MasteryTextStyles.bodySmall.copyWith(
                        color: colors.foreground,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildOption(int index, BuildContext context) {
    final colors = context.masteryColors;
    final isSelected = _selectedIndex == index;
    final isCorrectOption = index == widget.correctIndex;

    Color borderColor;
    Color bgColor;

    if (!_hasAnswered) {
      borderColor = colors.border;
      bgColor = colors.cardBackground;
    } else if (isCorrectOption) {
      borderColor = colors.success;
      bgColor = colors.success.withValues(alpha: 0.15);
    } else if (isSelected) {
      borderColor = colors.destructive;
      bgColor = colors.destructive.withValues(alpha: 0.15);
    } else {
      borderColor = colors.border;
      bgColor = colors.cardBackground;
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
              color: colors.foreground,
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
