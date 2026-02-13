import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/features/learn/widgets/disambiguation_card.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('DisambiguationCard', () {
    testWidgets('shows cloze sentence and options', (tester) async {
      await tester.pumpTestWidget(
        DisambiguationCard(
          clozeSentence: 'The ___ was full of money.',
          options: const ['bank', 'bench', 'blank'],
          correctIndex: 0,
          explanation: 'A bank stores money.',
          onAnswer: (_) {},
        ),
      );

      expect(find.text('Choose the correct word.'), findsOneWidget);
      expect(find.text('The ___ was full of money.'), findsOneWidget);
      expect(find.text('bank'), findsOneWidget);
      expect(find.text('bench'), findsOneWidget);
      expect(find.text('blank'), findsOneWidget);
    });

    testWidgets('hides explanation before answer', (tester) async {
      await tester.pumpTestWidget(
        DisambiguationCard(
          clozeSentence: 'The ___ was full of money.',
          options: const ['bank', 'bench', 'blank'],
          correctIndex: 0,
          explanation: 'A bank stores money.',
          onAnswer: (_) {},
        ),
      );

      expect(find.text('A bank stores money.'), findsNothing);
    });

    testWidgets('correct answer calls onAnswer(true)', (tester) async {
      bool? correctReceived;

      await tester.pumpTestWidget(
        DisambiguationCard(
          clozeSentence: 'The ___ was full of money.',
          options: const ['bank', 'bench', 'blank'],
          correctIndex: 0,
          explanation: 'A bank stores money.',
          onAnswer: (isCorrect) => correctReceived = isCorrect,
        ),
      );

      await tester.tap(find.text('bank'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Correct'), findsOneWidget);
      expect(find.text('A bank stores money.'), findsOneWidget);
      expect(correctReceived, true);
    });

    testWidgets('incorrect answer calls onAnswer(false)', (tester) async {
      bool? correctReceived;

      await tester.pumpTestWidget(
        DisambiguationCard(
          clozeSentence: 'The ___ was full of money.',
          options: const ['bank', 'bench', 'blank'],
          correctIndex: 0,
          explanation: 'A bank stores money.',
          onAnswer: (isCorrect) => correctReceived = isCorrect,
        ),
      );

      await tester.tap(find.text('bench'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Not quite'), findsOneWidget);
      expect(find.text('A bank stores money.'), findsOneWidget);
      expect(correctReceived, false);
    });

    testWidgets('disables options after selection', (tester) async {
      int answerCount = 0;

      await tester.pumpTestWidget(
        DisambiguationCard(
          clozeSentence: 'The ___ was full of money.',
          options: const ['bank', 'bench', 'blank'],
          correctIndex: 0,
          explanation: 'A bank stores money.',
          onAnswer: (_) => answerCount++,
        ),
      );

      await tester.tap(find.text('bank'));
      await tester.pumpAndSettle();

      // Tap another option - should not trigger another callback
      await tester.tap(find.text('bench'));
      await tester.pumpAndSettle();

      expect(answerCount, 1);
    });

    testWidgets('highlights correct option after wrong answer', (tester) async {
      await tester.pumpTestWidget(
        DisambiguationCard(
          clozeSentence: 'The ___ was full of money.',
          options: const ['bank', 'bench', 'blank'],
          correctIndex: 0,
          explanation: 'A bank stores money.',
          onAnswer: (_) {},
        ),
      );

      await tester.tap(find.text('bench'));
      await tester.pumpAndSettle();

      // Both the selected (wrong) and correct options should be visible
      expect(find.text('bank'), findsOneWidget);
      expect(find.text('bench'), findsOneWidget);
    });

    testWidgets('resets on new sentence', (tester) async {
      var sentence = 'The ___ was full of money.';

      await tester.pumpTestWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return DisambiguationCard(
              clozeSentence: sentence,
              options: const ['bank', 'bench', 'blank'],
              correctIndex: 0,
              explanation: 'A bank stores money.',
              onAnswer: (_) {
                setState(() => sentence = 'She sat on the ___.');
              },
            );
          },
        ),
      );

      await tester.tap(find.text('bank'));
      await tester.pumpAndSettle();

      // After answer callback triggers state change, widget should reset
      expect(find.text('She sat on the ___.'), findsOneWidget);
    });

    testWidgets('preview mode pre-selects correct answer and shows explanation',
        (tester) async {
      await tester.pumpTestWidget(
        DisambiguationCard(
          clozeSentence: 'The ___ was full of money.',
          options: const ['bank', 'bench', 'blank'],
          correctIndex: 0,
          explanation: 'A bank stores money.',
          onAnswer: (_) {},
          isPreview: true,
        ),
      );

      // Explanation visible immediately
      expect(find.text('A bank stores money.'), findsOneWidget);
      // Correct feedback shown
      expect(find.textContaining('Correct'), findsOneWidget);
    });

    testWidgets('fires onAnswered callback when correct option selected',
        (tester) async {
      var answeredCount = 0;

      await tester.pumpTestWidget(
        DisambiguationCard(
          clozeSentence: 'The ___ was full of money.',
          options: const ['bank', 'bench', 'blank'],
          correctIndex: 0,
          explanation: 'A bank stores money.',
          onAnswer: (_) {},
          onAnswered: () => answeredCount++,
        ),
      );

      await tester.tap(find.text('bank'));
      await tester.pumpAndSettle();

      expect(answeredCount, 1);
    });

    testWidgets('fires onAnswered callback when incorrect option selected',
        (tester) async {
      var answeredCount = 0;

      await tester.pumpTestWidget(
        DisambiguationCard(
          clozeSentence: 'The ___ was full of money.',
          options: const ['bank', 'bench', 'blank'],
          correctIndex: 0,
          explanation: 'A bank stores money.',
          onAnswer: (_) {},
          onAnswered: () => answeredCount++,
        ),
      );

      await tester.tap(find.text('bench'));
      await tester.pumpAndSettle();

      expect(answeredCount, 1);
    });
  });
}
