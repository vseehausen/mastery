import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/text_styles.dart';

/// Multiple choice recognition card for learning
/// Shows a word and 4 answer options (1 correct, 3 distractors)
class RecognitionCard extends StatefulWidget {
  const RecognitionCard({
    super.key,
    required this.word,
    required this.correctAnswer,
    required this.distractors,
    required this.onAnswer,
    this.context,
  });

  /// The word being tested
  final String word;

  /// The correct translation/definition
  final String correctAnswer;

  /// List of 3 distractor options
  final List<String> distractors;

  /// Optional context sentence
  final String? context;

  /// Callback when user selects an answer
  /// Returns the selected answer and whether it was correct
  final void Function(String selected, bool isCorrect) onAnswer;

  @override
  State<RecognitionCard> createState() => _RecognitionCardState();
}

class _RecognitionCardState extends State<RecognitionCard> {
  String? _selectedAnswer;
  late List<String> _shuffledOptions;

  @override
  void initState() {
    super.initState();
    _shuffleOptions();
  }

  @override
  void didUpdateWidget(RecognitionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.word != widget.word) {
      setState(() {
        _selectedAnswer = null;
      });
      _shuffleOptions();
    }
  }

  void _shuffleOptions() {
    _shuffledOptions = [widget.correctAnswer, ...widget.distractors]..shuffle();
  }

  void _handleSelection(String answer) {
    if (_selectedAnswer != null) return; // Already answered

    final isCorrect = answer == widget.correctAnswer;
    setState(() {
      _selectedAnswer = answer;
    });

    // Delay before calling callback to show feedback
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        widget.onAnswer(answer, isCorrect);
      }
    });
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

          // Question prompt
          Text(
            'What does this word mean?',
            style: MasteryTextStyles.bodySmall.copyWith(
              color: colors.mutedForeground,
            ),
          ),

          const SizedBox(height: 16),

          // Answer options
          ...List.generate(_shuffledOptions.length, (index) {
            final option = _shuffledOptions[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildOptionButton(option, context),
            );
          }),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildOptionButton(String option, BuildContext context) {
    final colors = context.masteryColors;
    final isSelected = _selectedAnswer == option;
    final isCorrectOption = option == widget.correctAnswer;
    final showResult = _selectedAnswer != null;

    Color backgroundColor;
    Color textColor;

    if (showResult) {
      if (isCorrectOption) {
        // Highlight correct answer
        backgroundColor = colors.successMuted;
        textColor = colors.success;
      } else if (isSelected) {
        // Highlight incorrect selection
        backgroundColor = colors.destructive.withValues(alpha: 0.1);
        textColor = colors.destructive;
      } else {
        // Unselected option
        backgroundColor = colors.cardBackground;
        textColor = colors.mutedForeground;
      }
    } else {
      // Not answered yet
      backgroundColor = colors.cardBackground;
      textColor = colors.foreground;
    }

    return SizedBox(
      width: double.infinity,
      child: ShadButton.outline(
        onPressed: showResult ? null : () => _handleSelection(option),
        backgroundColor: backgroundColor,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                option,
                style: MasteryTextStyles.body.copyWith(color: textColor),
              ),
            ),
            if (showResult && isCorrectOption)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(Icons.check, color: textColor, size: 20),
              )
            else if (showResult && isSelected && !isCorrectOption)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(Icons.close, color: textColor, size: 20),
              ),
          ],
        ),
      ),
    );
  }
}
