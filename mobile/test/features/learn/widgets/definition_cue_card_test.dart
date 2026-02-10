import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/features/learn/widgets/definition_cue_card.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('DefinitionCueCard', () {
    testWidgets('shows microcopy and definition prompt', (tester) async {
      await tester.pumpTestWidget(
        DefinitionCueCard(
          definition: 'Achieves results with minimal waste.',
          targetWord: 'efficient',
          onGrade: (_) {},
        ),
      );

      expect(find.text('Which word fits best?'), findsOneWidget);
      expect(find.text('Achieves results with minimal waste.'), findsOneWidget);
    });

    testWidgets('hides answer before reveal', (tester) async {
      await tester.pumpTestWidget(
        DefinitionCueCard(
          definition: 'Achieves results.',
          targetWord: 'efficient',
          onGrade: (_) {},
        ),
      );

      expect(find.text('efficient'), findsNothing);
      expect(find.text('Show Answer'), findsOneWidget);
    });

    testWidgets('reveals answer and grade buttons on tap', (tester) async {
      await tester.pumpTestWidget(
        DefinitionCueCard(
          definition: 'Achieves results.',
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

    testWidgets('calls onGrade with correct rating', (tester) async {
      int? gradeReceived;

      await tester.pumpTestWidget(
        DefinitionCueCard(
          definition: 'Test definition.',
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
        DefinitionCueCard(
          definition: 'A definition.',
          targetWord: 'word',
          hintText: 'Think about resources.',
          onGrade: (_) {},
        ),
      );

      expect(find.text('Show hint'), findsOneWidget);
      expect(find.text('Think about resources.'), findsNothing);

      await tester.tap(find.text('Show hint'));
      await tester.pumpAndSettle();

      expect(find.text('Think about resources.'), findsOneWidget);
    });

    testWidgets('hint hidden after reveal', (tester) async {
      await tester.pumpTestWidget(
        DefinitionCueCard(
          definition: 'A definition.',
          targetWord: 'word',
          hintText: 'A hint.',
          onGrade: (_) {},
        ),
      );

      await tester.tap(find.text('Show Answer'));
      await tester.pumpAndSettle();

      expect(find.text('Show hint'), findsNothing);
    });

    testWidgets('resets on new definition', (tester) async {
      var definition = 'First definition.';

      await tester.pumpTestWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return DefinitionCueCard(
              definition: definition,
              targetWord: 'word',
              onGrade: (_) {
                setState(() => definition = 'Second definition.');
              },
            );
          },
        ),
      );

      await tester.tap(find.text('Show Answer'));
      await tester.pumpAndSettle();

      // Grade to trigger update
      await tester.tap(find.text('Good'));
      await tester.pumpAndSettle();

      // Should be back to unrevealed state
      expect(find.text('Show Answer'), findsOneWidget);
    });

    testWidgets('preview mode shows answer immediately with no buttons',
        (tester) async {
      await tester.pumpTestWidget(
        DefinitionCueCard(
          definition: 'Achieves results with minimal waste.',
          targetWord: 'efficient',
          onGrade: (_) {},
          isPreview: true,
        ),
      );

      // Answer visible immediately
      expect(find.text('efficient'), findsOneWidget);
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
