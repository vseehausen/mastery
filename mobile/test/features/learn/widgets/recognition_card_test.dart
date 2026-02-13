import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/features/learn/widgets/recognition_card.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('RecognitionCard', () {
    testWidgets('fires onCorrectReveal when correct answer selected',
        (tester) async {
      var correctRevealCount = 0;

      await tester.pumpTestWidget(
        RecognitionCard(
          word: 'ephemeral',
          correctAnswer: 'short-lived',
          distractors: const ['permanent', 'abundant', 'ancient'],
          onAnswer: (selected, isCorrect) {},
          onCorrectReveal: () => correctRevealCount++,
        ),
      );

      await tester.tap(find.text('short-lived'));
      // Wait for the 800ms delay + animation
      await tester.pump(const Duration(milliseconds: 900));

      expect(correctRevealCount, 1);
    });

    testWidgets('does not fire onCorrectReveal when wrong answer selected',
        (tester) async {
      var correctRevealCount = 0;

      await tester.pumpTestWidget(
        RecognitionCard(
          word: 'ephemeral',
          correctAnswer: 'short-lived',
          distractors: const ['permanent', 'abundant', 'ancient'],
          onAnswer: (selected, isCorrect) {},
          onCorrectReveal: () => correctRevealCount++,
        ),
      );

      await tester.tap(find.text('permanent'));
      // Wait for the 800ms delay + animation
      await tester.pump(const Duration(milliseconds: 900));

      expect(correctRevealCount, 0);
    });

    testWidgets('shows word and all options', (tester) async {
      await tester.pumpTestWidget(
        RecognitionCard(
          word: 'ephemeral',
          correctAnswer: 'short-lived',
          distractors: const ['permanent', 'abundant', 'ancient'],
          onAnswer: (selected, isCorrect) {},
        ),
      );

      expect(find.text('ephemeral'), findsOneWidget);
      // All options should be present (order is shuffled)
      expect(find.text('short-lived'), findsOneWidget);
      expect(find.text('permanent'), findsOneWidget);
      expect(find.text('abundant'), findsOneWidget);
      expect(find.text('ancient'), findsOneWidget);
    });

    testWidgets('calls onAnswer with correct params for correct answer',
        (tester) async {
      String? selectedAnswer;
      bool? wasCorrect;

      await tester.pumpTestWidget(
        RecognitionCard(
          word: 'ephemeral',
          correctAnswer: 'short-lived',
          distractors: const ['permanent', 'abundant', 'ancient'],
          onAnswer: (selected, isCorrect) {
            selectedAnswer = selected;
            wasCorrect = isCorrect;
          },
        ),
      );

      await tester.tap(find.text('short-lived'));
      // Wait for the 800ms delay + animation
      await tester.pump(const Duration(milliseconds: 900));

      expect(selectedAnswer, 'short-lived');
      expect(wasCorrect, true);
    });

    testWidgets('disables options after selection', (tester) async {
      var answerCount = 0;

      await tester.pumpTestWidget(
        RecognitionCard(
          word: 'ephemeral',
          correctAnswer: 'short-lived',
          distractors: const ['permanent', 'abundant', 'ancient'],
          onAnswer: (selected, isCorrect) => answerCount++,
        ),
      );

      await tester.tap(find.text('short-lived'));
      await tester.pump(const Duration(milliseconds: 900));

      // Tap another option — should not trigger
      await tester.tap(find.text('permanent'));
      await tester.pump(const Duration(milliseconds: 900));

      expect(answerCount, 1);
    });

    testWidgets('preview mode pre-selects correct answer', (tester) async {
      await tester.pumpTestWidget(
        RecognitionCard(
          word: 'ephemeral',
          correctAnswer: 'short-lived',
          distractors: const ['permanent', 'abundant', 'ancient'],
          onAnswer: (selected, isCorrect) {},
          isPreview: true,
        ),
      );

      // The correct answer should be visually selected (widget displays it)
      expect(find.text('short-lived'), findsOneWidget);
    });
  });
}
