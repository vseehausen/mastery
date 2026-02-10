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
          onGrade: (_) {},
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
          onGrade: (_) {},
        ),
      );

      expect(find.text('A bank stores money.'), findsNothing);
    });

    testWidgets('correct answer shows success feedback', (tester) async {
      int? gradeReceived;

      await tester.pumpTestWidget(
        DisambiguationCard(
          clozeSentence: 'The ___ was full of money.',
          options: const ['bank', 'bench', 'blank'],
          correctIndex: 0,
          explanation: 'A bank stores money.',
          onGrade: (rating) => gradeReceived = rating,
        ),
      );

      await tester.tap(find.text('bank'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Correct'), findsOneWidget);
      expect(find.text('A bank stores money.'), findsOneWidget);
      expect(gradeReceived, 3); // ReviewRating.good
    });

    testWidgets('incorrect answer shows failure feedback', (tester) async {
      int? gradeReceived;

      await tester.pumpTestWidget(
        DisambiguationCard(
          clozeSentence: 'The ___ was full of money.',
          options: const ['bank', 'bench', 'blank'],
          correctIndex: 0,
          explanation: 'A bank stores money.',
          onGrade: (rating) => gradeReceived = rating,
        ),
      );

      await tester.tap(find.text('bench'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Not quite'), findsOneWidget);
      expect(find.text('A bank stores money.'), findsOneWidget);
      expect(gradeReceived, 1); // ReviewRating.again
    });

    testWidgets('disables options after selection', (tester) async {
      int gradeCount = 0;

      await tester.pumpTestWidget(
        DisambiguationCard(
          clozeSentence: 'The ___ was full of money.',
          options: const ['bank', 'bench', 'blank'],
          correctIndex: 0,
          explanation: 'A bank stores money.',
          onGrade: (_) => gradeCount++,
        ),
      );

      await tester.tap(find.text('bank'));
      await tester.pumpAndSettle();

      // Tap another option - should not trigger another grade
      await tester.tap(find.text('bench'));
      await tester.pumpAndSettle();

      expect(gradeCount, 1);
    });

    testWidgets('highlights correct option after wrong answer', (tester) async {
      await tester.pumpTestWidget(
        DisambiguationCard(
          clozeSentence: 'The ___ was full of money.',
          options: const ['bank', 'bench', 'blank'],
          correctIndex: 0,
          explanation: 'A bank stores money.',
          onGrade: (_) {},
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
              onGrade: (_) {
                setState(() => sentence = 'She sat on the ___.');
              },
            );
          },
        ),
      );

      await tester.tap(find.text('bank'));
      await tester.pumpAndSettle();

      // After grade callback triggers state change, widget should reset
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
          onGrade: (_) {},
          isPreview: true,
        ),
      );

      // Explanation visible immediately
      expect(find.text('A bank stores money.'), findsOneWidget);
      // Correct feedback shown
      expect(find.textContaining('Correct'), findsOneWidget);
    });
  });
}
