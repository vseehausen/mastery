import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/features/learn/widgets/recall_card.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('RecallCard', () {
    late int? selectedGrade;

    void onGrade(int grade) {
      selectedGrade = grade;
    }

    setUp(() {
      selectedGrade = null;
    });

    testWidgets('displays word prominently', (tester) async {
      await tester.pumpTestWidget(
        RecallCard(
          word: 'ephemeral',
          answer: 'lasting a short time',
          onGrade: onGrade,
        ),
      );

      expect(find.text('ephemeral'), findsOneWidget);
    });

    testWidgets('initially hides the answer', (tester) async {
      await tester.pumpTestWidget(
        RecallCard(
          word: 'ephemeral',
          answer: 'lasting a short time',
          onGrade: onGrade,
        ),
      );

      // Answer should not be visible initially
      // Look for the show answer button instead
      expect(find.textContaining('Show'), findsOneWidget);
    });

    testWidgets('shows answer when show button is tapped', (tester) async {
      await tester.pumpTestWidget(
        RecallCard(
          word: 'ephemeral',
          answer: 'lasting a short time',
          onGrade: onGrade,
        ),
      );

      // Find and tap the show answer button
      final showButton = find.textContaining('Show');
      await tester.tap(showButton);
      await tester.pump();

      // Answer should now be visible
      expect(find.text('lasting a short time'), findsOneWidget);
    });

    testWidgets('shows grade buttons after revealing answer', (tester) async {
      await tester.pumpTestWidget(
        RecallCard(
          word: 'ephemeral',
          answer: 'lasting a short time',
          onGrade: onGrade,
        ),
      );

      // Reveal answer
      final showButton = find.textContaining('Show');
      await tester.tap(showButton);
      await tester.pump();

      // Grade buttons should be visible
      expect(find.text('Again'), findsOneWidget);
      expect(find.text('Hard'), findsOneWidget);
      expect(find.text('Good'), findsOneWidget);
      expect(find.text('Easy'), findsOneWidget);
    });

    testWidgets('calls onGrade with 1 when Again tapped', (tester) async {
      await tester.pumpTestWidget(
        RecallCard(
          word: 'ephemeral',
          answer: 'lasting a short time',
          onGrade: onGrade,
        ),
      );

      // Reveal answer
      await tester.tap(find.textContaining('Show'));
      await tester.pump();

      // Tap Again
      await tester.tap(find.text('Again'));
      await tester.pump();

      expect(selectedGrade, equals(1));
    });

    testWidgets('calls onGrade with 2 when Hard tapped', (tester) async {
      await tester.pumpTestWidget(
        RecallCard(
          word: 'ephemeral',
          answer: 'lasting a short time',
          onGrade: onGrade,
        ),
      );

      // Reveal answer
      await tester.tap(find.textContaining('Show'));
      await tester.pump();

      // Tap Hard
      await tester.tap(find.text('Hard'));
      await tester.pump();

      expect(selectedGrade, equals(2));
    });

    testWidgets('calls onGrade with 3 when Good tapped', (tester) async {
      await tester.pumpTestWidget(
        RecallCard(
          word: 'ephemeral',
          answer: 'lasting a short time',
          onGrade: onGrade,
        ),
      );

      // Reveal answer
      await tester.tap(find.textContaining('Show'));
      await tester.pump();

      // Tap Good
      await tester.tap(find.text('Good'));
      await tester.pump();

      expect(selectedGrade, equals(3));
    });

    testWidgets('calls onGrade with 4 when Easy tapped', (tester) async {
      await tester.pumpTestWidget(
        RecallCard(
          word: 'ephemeral',
          answer: 'lasting a short time',
          onGrade: onGrade,
        ),
      );

      // Reveal answer
      await tester.tap(find.textContaining('Show'));
      await tester.pump();

      // Tap Easy
      await tester.tap(find.text('Easy'));
      await tester.pump();

      expect(selectedGrade, equals(4));
    });

    testWidgets('displays context when provided', (tester) async {
      await tester.pumpTestWidget(
        RecallCard(
          word: 'ephemeral',
          answer: 'lasting a short time',
          context: 'The ephemeral nature of fame...',
          onGrade: onGrade,
        ),
      );

      expect(find.textContaining('ephemeral nature'), findsOneWidget);
    });

    testWidgets('renders correctly in dark theme', (tester) async {
      await tester.pumpTestWidget(
        RecallCard(
          word: 'ephemeral',
          answer: 'lasting a short time',
          onGrade: onGrade,
        ),
        themeMode: ThemeMode.dark,
      );

      expect(find.text('ephemeral'), findsOneWidget);
      expect(find.byType(RecallCard), findsOneWidget);
    });

    testWidgets('renders correctly in light theme', (tester) async {
      await tester.pumpTestWidget(
        RecallCard(
          word: 'ephemeral',
          answer: 'lasting a short time',
          onGrade: onGrade,
        ),
        themeMode: ThemeMode.light,
      );

      expect(find.text('ephemeral'), findsOneWidget);
      expect(find.byType(RecallCard), findsOneWidget);
    });
  });
}
