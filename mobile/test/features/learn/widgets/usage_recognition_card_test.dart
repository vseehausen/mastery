import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/features/learn/widgets/usage_recognition_card.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('UsageRecognitionCard', () {
    const word = 'abate';
    const correctSentence = 'The storm will abate by morning.';
    const incorrectSentences = [
      'She decided to abate the cake evenly.',
      'He used a knife to abate the rope.',
    ];

    testWidgets('shows word and microcopy', (tester) async {
      await tester.pumpTestWidget(
        UsageRecognitionCard(
          word: word,
          correctSentence: correctSentence,
          incorrectSentences: incorrectSentences,
          onAnswer: (_) {},
        ),
      );

      expect(find.text(word), findsOneWidget);
      expect(
        find.text('Which sentence uses the word correctly?'),
        findsOneWidget,
      );
    });

    testWidgets('displays all 3 sentence options', (tester) async {
      await tester.pumpTestWidget(
        UsageRecognitionCard(
          word: word,
          correctSentence: correctSentence,
          incorrectSentences: incorrectSentences,
          onAnswer: (_) {},
        ),
      );

      expect(find.text(correctSentence), findsOneWidget);
      expect(find.text(incorrectSentences[0]), findsOneWidget);
      expect(find.text(incorrectSentences[1]), findsOneWidget);
    });

    testWidgets('correct answer calls onAnswer(true)', (tester) async {
      bool? correctReceived;

      await tester.pumpTestWidget(
        UsageRecognitionCard(
          word: word,
          correctSentence: correctSentence,
          incorrectSentences: incorrectSentences,
          onAnswer: (isCorrect) => correctReceived = isCorrect,
        ),
      );

      await tester.tap(find.text(correctSentence));
      await tester.pumpAndSettle();

      expect(correctReceived, true);
    });

    testWidgets('incorrect answer calls onAnswer(false)', (tester) async {
      bool? correctReceived;

      await tester.pumpTestWidget(
        UsageRecognitionCard(
          word: word,
          correctSentence: correctSentence,
          incorrectSentences: incorrectSentences,
          onAnswer: (isCorrect) => correctReceived = isCorrect,
        ),
      );

      await tester.tap(find.text(incorrectSentences[0]));
      await tester.pumpAndSettle();

      expect(correctReceived, false);
    });

    testWidgets('shows success feedback for correct answer', (tester) async {
      await tester.pumpTestWidget(
        UsageRecognitionCard(
          word: word,
          correctSentence: correctSentence,
          incorrectSentences: incorrectSentences,
          onAnswer: (_) {},
        ),
      );

      await tester.tap(find.text(correctSentence));
      await tester.pumpAndSettle();

      expect(find.textContaining('Correct'), findsOneWidget);
    });

    testWidgets('shows failure feedback for incorrect answer', (tester) async {
      await tester.pumpTestWidget(
        UsageRecognitionCard(
          word: word,
          correctSentence: correctSentence,
          incorrectSentences: incorrectSentences,
          onAnswer: (_) {},
        ),
      );

      await tester.tap(find.text(incorrectSentences[0]));
      await tester.pumpAndSettle();

      expect(find.textContaining('Not quite'), findsOneWidget);
    });

    testWidgets('disables options after selection', (tester) async {
      int answerCount = 0;

      await tester.pumpTestWidget(
        UsageRecognitionCard(
          word: word,
          correctSentence: correctSentence,
          incorrectSentences: incorrectSentences,
          onAnswer: (_) => answerCount++,
        ),
      );

      await tester.tap(find.text(correctSentence));
      await tester.pumpAndSettle();

      // Tap another option - should not trigger another callback
      await tester.tap(find.text(incorrectSentences[0]));
      await tester.pumpAndSettle();

      expect(answerCount, 1);
    });

    testWidgets('highlights correct option after wrong answer', (tester) async {
      await tester.pumpTestWidget(
        UsageRecognitionCard(
          word: word,
          correctSentence: correctSentence,
          incorrectSentences: incorrectSentences,
          onAnswer: (_) {},
        ),
      );

      await tester.tap(find.text(incorrectSentences[0]));
      await tester.pumpAndSettle();

      // Correct option should still be visible
      expect(find.text(correctSentence), findsOneWidget);
    });

    testWidgets('resets on new word/sentence', (tester) async {
      var currentWord = word;
      var currentCorrect = correctSentence;

      await tester.pumpTestWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return UsageRecognitionCard(
              word: currentWord,
              correctSentence: currentCorrect,
              incorrectSentences: incorrectSentences,
              onAnswer: (_) {
                setState(() {
                  currentWord = 'diminish';
                  currentCorrect = 'The noise will diminish over time.';
                });
              },
            );
          },
        ),
      );

      await tester.tap(find.text(correctSentence));
      await tester.pumpAndSettle();

      // After answer callback triggers state change, widget should reset
      expect(find.text('diminish'), findsOneWidget);
    });

    testWidgets('preview mode pre-selects correct answer', (tester) async {
      await tester.pumpTestWidget(
        UsageRecognitionCard(
          word: word,
          correctSentence: correctSentence,
          incorrectSentences: incorrectSentences,
          onAnswer: (_) {},
          isPreview: true,
        ),
      );

      // Correct feedback shown immediately
      expect(find.textContaining('Correct'), findsOneWidget);
    });
  });
}
