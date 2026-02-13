import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/text_styles.dart';

/// Card for usage recognition exercises (Method 7).
/// Shows 3 shuffled sentences (1 correct + 2 incorrect); user picks the correct one.
class UsageRecognitionCard extends StatefulWidget {
  const UsageRecognitionCard({
    super.key,
    required this.word,
    required this.correctSentence,
    required this.incorrectSentences,
    required this.onAnswer,
    this.isPreview = false,
    this.onAnswered,
  });

  final String word;
  final String correctSentence;
  final List<String> incorrectSentences;
  final void Function(bool isCorrect) onAnswer;
  final bool isPreview;

  /// Called when user selects an answer
  final VoidCallback? onAnswered;

  @override
  State<UsageRecognitionCard> createState() => _UsageRecognitionCardState();
}

class _UsageRecognitionCardState extends State<UsageRecognitionCard> {
  int? _selectedIndex;
  late int _correctIndex;
  late List<String> _shuffledSentences;

  @override
  void initState() {
    super.initState();
    _shuffleSentences();
    if (widget.isPreview) {
      _selectedIndex = _correctIndex;
    }
  }

  @override
  void didUpdateWidget(UsageRecognitionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.correctSentence != widget.correctSentence ||
        oldWidget.word != widget.word) {
      _shuffleSentences();
      setState(() {
        _selectedIndex = null;
      });
    }
  }

  void _shuffleSentences() {
    final all = <_IndexedSentence>[
      _IndexedSentence(widget.correctSentence, true),
      ...widget.incorrectSentences.map((s) => _IndexedSentence(s, false)),
    ];
    all.shuffle(Random());
    _shuffledSentences = all.map((s) => s.sentence).toList();
    _correctIndex = all.indexWhere((s) => s.isCorrect);
  }

  bool get _hasAnswered => _selectedIndex != null;
  bool get _isCorrect => _selectedIndex == _correctIndex;

  void _selectOption(int index) {
    if (_hasAnswered) return;

    setState(() {
      _selectedIndex = index;
    });

    widget.onAnswered?.call();
    widget.onAnswer(index == _correctIndex);
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
            'Which sentence uses the word correctly?',
            style: MasteryTextStyles.bodySmall.copyWith(
              color: colors.mutedForeground,
            ),
          ),
          const SizedBox(height: 12),

          // Word display
          Text(
            widget.word,
            style: MasteryTextStyles.displayLarge.copyWith(
              fontSize: 28,
              color: colors.foreground,
            ),
          ),
          const SizedBox(height: 24),

          // Sentence options
          ...List<Widget>.generate(_shuffledSentences.length, (index) {
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
              child: Text(
                _isCorrect ? 'Correct!' : 'Not quite.',
                style: MasteryTextStyles.bodyBold.copyWith(
                  color: _isCorrect ? colors.success : colors.destructive,
                ),
                textAlign: TextAlign.center,
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
    final isCorrectOption = index == _correctIndex;

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
            _shuffledSentences[index],
            style: MasteryTextStyles.body.copyWith(
              color: colors.foreground,
              fontWeight: (_hasAnswered && isCorrectOption)
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class _IndexedSentence {
  const _IndexedSentence(this.sentence, this.isCorrect);
  final String sentence;
  final bool isCorrect;
}
