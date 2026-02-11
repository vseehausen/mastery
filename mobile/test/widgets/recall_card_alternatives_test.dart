import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/features/learn/widgets/recall_card.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('RecallCard with alternatives', () {
    testWidgets('displays alternatives after revealing answer', (tester) async {
      await tester.pumpTestWidget(
        RecallCard(
          word: 'ephemeral',
          answer: 'lasting a short time',
          alternatives: ['temporary', 'fleeting', 'transient'],
          onGrade: (_) {},
        ),
      );

      // Reveal answer
      final showButton = find.textContaining('Show');
      await tester.tap(showButton);
      await tester.pump();

      // Answer should be visible
      expect(find.text('lasting a short time'), findsOneWidget);

      // Alternatives should be visible as comma-separated list
      expect(find.text('temporary, fleeting, transient'), findsOneWidget);
    });

    testWidgets('does not display alternatives when none provided', (tester) async {
      await tester.pumpTestWidget(
        RecallCard(
          word: 'ephemeral',
          answer: 'lasting a short time',
          onGrade: (_) {},
        ),
      );

      // Reveal answer
      final showButton = find.textContaining('Show');
      await tester.tap(showButton);
      await tester.pump();

      // Answer should be visible
      expect(find.text('lasting a short time'), findsOneWidget);

      // No alternatives text should appear
      expect(find.textContaining('temporary'), findsNothing);
    });

    testWidgets('does not display alternatives when empty list provided', (tester) async {
      await tester.pumpTestWidget(
        RecallCard(
          word: 'ephemeral',
          answer: 'lasting a short time',
          alternatives: [],
          onGrade: (_) {},
        ),
      );

      // Reveal answer
      final showButton = find.textContaining('Show');
      await tester.tap(showButton);
      await tester.pump();

      // Answer should be visible
      expect(find.text('lasting a short time'), findsOneWidget);

      // No extra spacing or empty alternative text
      expect(find.textContaining(','), findsNothing);
    });

    testWidgets('displays alternatives in preview mode', (tester) async {
      await tester.pumpTestWidget(
        RecallCard(
          word: 'ephemeral',
          answer: 'lasting a short time',
          alternatives: ['temporary', 'fleeting'],
          onGrade: (_) {},
          isPreview: true,
        ),
      );

      // Answer visible immediately in preview mode
      expect(find.text('lasting a short time'), findsOneWidget);

      // Alternatives should also be visible
      expect(find.text('temporary, fleeting'), findsOneWidget);
    });
  });
}
