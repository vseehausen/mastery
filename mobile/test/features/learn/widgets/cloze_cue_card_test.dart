import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/features/learn/widgets/cloze_cue_card.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('ClozeCueCard', () {
    testWidgets('shows microcopy and sentence with blank', (tester) async {
      await tester.pumpTestWidget(
        ClozeCueCard(
          sentenceWithBlank: 'The ___ nature of beauty makes it precious.',
          targetWord: 'ephemeral',
          onGrade: (_) {},
        ),
      );

      expect(find.text('Fill the blank.'), findsOneWidget);
      expect(
        find.text('The ___ nature of beauty makes it precious.'),
        findsOneWidget,
      );
    });

    testWidgets('hides answer before reveal', (tester) async {
      await tester.pumpTestWidget(
        ClozeCueCard(
          sentenceWithBlank: 'The ___ nature of beauty.',
          targetWord: 'ephemeral',
          onGrade: (_) {},
        ),
      );

      expect(find.text('ephemeral'), findsNothing);
      expect(find.text('Show Answer'), findsOneWidget);
    });

    testWidgets('reveals answer and grade buttons on tap', (tester) async {
      await tester.pumpTestWidget(
        ClozeCueCard(
          sentenceWithBlank: 'The ___ nature of beauty.',
          targetWord: 'ephemeral',
          onGrade: (_) {},
        ),
      );

      await tester.tap(find.text('Show Answer'));
      await tester.pumpAndSettle();

      expect(find.text('ephemeral'), findsOneWidget);
      expect(find.text('How well did you remember?'), findsOneWidget);
      expect(find.text('Again'), findsOneWidget);
      expect(find.text('Hard'), findsOneWidget);
      expect(find.text('Good'), findsOneWidget);
      expect(find.text('Easy'), findsOneWidget);
    });

    testWidgets('calls onGrade with correct rating', (tester) async {
      int? gradeReceived;

      await tester.pumpTestWidget(
        ClozeCueCard(
          sentenceWithBlank: 'A sentence.',
          targetWord: 'word',
          onGrade: (rating) => gradeReceived = rating,
        ),
      );

      await tester.tap(find.text('Show Answer'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Good'));
      expect(gradeReceived, 3);
    });

    testWidgets('shows hint when tapped', (tester) async {
      await tester.pumpTestWidget(
        ClozeCueCard(
          sentenceWithBlank: 'A sentence with ___.',
          targetWord: 'word',
          hintText: 'It means something fleeting.',
          onGrade: (_) {},
        ),
      );

      expect(find.text('Show hint'), findsOneWidget);
      expect(find.text('It means something fleeting.'), findsNothing);

      await tester.tap(find.text('Show hint'));
      await tester.pumpAndSettle();

      expect(find.text('It means something fleeting.'), findsOneWidget);
    });

    testWidgets('hint hidden after reveal', (tester) async {
      await tester.pumpTestWidget(
        ClozeCueCard(
          sentenceWithBlank: 'A sentence with ___.',
          targetWord: 'word',
          hintText: 'A hint.',
          onGrade: (_) {},
        ),
      );

      await tester.tap(find.text('Show Answer'));
      await tester.pumpAndSettle();

      expect(find.text('Show hint'), findsNothing);
    });

    testWidgets('resets on new sentence', (tester) async {
      var sentence = 'First ___ sentence.';

      await tester.pumpTestWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return ClozeCueCard(
              sentenceWithBlank: sentence,
              targetWord: 'word',
              onGrade: (_) {
                setState(() => sentence = 'Second ___ sentence.');
              },
            );
          },
        ),
      );

      await tester.tap(find.text('Show Answer'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Good'));
      await tester.pumpAndSettle();

      expect(find.text('Show Answer'), findsOneWidget);
    });

    testWidgets('preview mode shows answer immediately with no buttons',
        (tester) async {
      await tester.pumpTestWidget(
        ClozeCueCard(
          sentenceWithBlank: 'The ___ nature of beauty.',
          targetWord: 'ephemeral',
          onGrade: (_) {},
          isPreview: true,
        ),
      );

      // Answer visible immediately
      expect(find.text('ephemeral'), findsOneWidget);
      // No Show Answer button
      expect(find.text('Show Answer'), findsNothing);
      // No grade buttons
      expect(find.text('Again'), findsNothing);
      expect(find.text('Hard'), findsNothing);
      expect(find.text('Good'), findsNothing);
      expect(find.text('Easy'), findsNothing);
    });
  });
}
