import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/features/learn/widgets/synonym_cue_card.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('SynonymCueCard', () {
    testWidgets('shows microcopy and synonym prompt', (tester) async {
      await tester.pumpTestWidget(
        SynonymCueCard(
          synonymPhrase: 'Productive and streamlined with minimal waste',
          targetWord: 'efficient',
          onGrade: (_) {},
        ),
      );

      expect(find.text('Recall the word.'), findsOneWidget);
      expect(
        find.text('Productive and streamlined with minimal waste'),
        findsOneWidget,
      );
    });

    testWidgets('hides answer before reveal', (tester) async {
      await tester.pumpTestWidget(
        SynonymCueCard(
          synonymPhrase: 'A synonym phrase.',
          targetWord: 'efficient',
          onGrade: (_) {},
        ),
      );

      expect(find.text('efficient'), findsNothing);
      expect(find.text('Show Answer'), findsOneWidget);
    });

    testWidgets('reveals answer and grade buttons on tap', (tester) async {
      await tester.pumpTestWidget(
        SynonymCueCard(
          synonymPhrase: 'Productive and streamlined.',
          targetWord: 'efficient',
          onGrade: (_) {},
        ),
      );

      await tester.tap(find.text('Show Answer'));
      await tester.pumpAndSettle();

      expect(find.text('efficient'), findsOneWidget);
      expect(find.text('How well did you remember?'), findsOneWidget);
      expect(find.text('Again'), findsOneWidget);
      expect(find.text('Hard'), findsOneWidget);
      expect(find.text('Good'), findsOneWidget);
      expect(find.text('Easy'), findsOneWidget);
    });

    testWidgets('calls onGrade with Again rating', (tester) async {
      int? gradeReceived;

      await tester.pumpTestWidget(
        SynonymCueCard(
          synonymPhrase: 'A phrase.',
          targetWord: 'word',
          onGrade: (rating) => gradeReceived = rating,
        ),
      );

      await tester.tap(find.text('Show Answer'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Again'));
      expect(gradeReceived, 1);
    });

    testWidgets('calls onGrade with Easy rating', (tester) async {
      int? gradeReceived;

      await tester.pumpTestWidget(
        SynonymCueCard(
          synonymPhrase: 'A phrase.',
          targetWord: 'word',
          onGrade: (rating) => gradeReceived = rating,
        ),
      );

      await tester.tap(find.text('Show Answer'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Easy'));
      expect(gradeReceived, 4);
    });

    testWidgets('resets on new synonym phrase', (tester) async {
      var phrase = 'First phrase.';

      await tester.pumpTestWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return SynonymCueCard(
              synonymPhrase: phrase,
              targetWord: 'word',
              onGrade: (_) {
                setState(() => phrase = 'Second phrase.');
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
  });
}
