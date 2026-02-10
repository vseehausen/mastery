import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/features/learn/widgets/recognition_card.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('RecognitionCard', () {
    late String? selectedAnswer;
    late bool? wasCorrect;

    void onAnswer(String answer, bool correct) {
      selectedAnswer = answer;
      wasCorrect = correct;
    }

    setUp(() {
      selectedAnswer = null;
      wasCorrect = null;
    });

    testWidgets('displays word prominently', (tester) async {
      await tester.pumpTestWidget(
        RecognitionCard(
          word: 'ephemeral',
          correctAnswer: 'lasting a short time',
          distractors: const ['permanent', 'significant', 'expensive'],
          onAnswer: onAnswer,
        ),
      );

      expect(find.text('ephemeral'), findsOneWidget);
    });

    testWidgets('displays all answer options (correct + distractors)', (
      tester,
    ) async {
      await tester.pumpTestWidget(
        RecognitionCard(
          word: 'ephemeral',
          correctAnswer: 'lasting a short time',
          distractors: const ['permanent', 'significant', 'expensive'],
          onAnswer: onAnswer,
        ),
      );

      // All 4 options should be visible
      expect(find.text('lasting a short time'), findsOneWidget);
      expect(find.text('permanent'), findsOneWidget);
      expect(find.text('significant'), findsOneWidget);
      expect(find.text('expensive'), findsOneWidget);
    });

    testWidgets('calls onAnswer with true when correct answer tapped', (
      tester,
    ) async {
      await tester.pumpTestWidget(
        RecognitionCard(
          word: 'ephemeral',
          correctAnswer: 'lasting a short time',
          distractors: const ['permanent', 'significant', 'expensive'],
          onAnswer: onAnswer,
        ),
      );

      await tester.tap(find.text('lasting a short time'));
      // Wait for the 800ms delay before callback is called
      await tester.pump(const Duration(milliseconds: 900));

      expect(selectedAnswer, equals('lasting a short time'));
      expect(wasCorrect, isTrue);
    });

    testWidgets('calls onAnswer with false when wrong answer tapped', (
      tester,
    ) async {
      await tester.pumpTestWidget(
        RecognitionCard(
          word: 'ephemeral',
          correctAnswer: 'lasting a short time',
          distractors: const ['permanent', 'significant', 'expensive'],
          onAnswer: onAnswer,
        ),
      );

      await tester.tap(find.text('permanent'));
      // Wait for the 800ms delay before callback is called
      await tester.pump(const Duration(milliseconds: 900));

      expect(selectedAnswer, equals('permanent'));
      expect(wasCorrect, isFalse);
    });

    testWidgets('displays context when provided', (tester) async {
      await tester.pumpTestWidget(
        RecognitionCard(
          word: 'ephemeral',
          correctAnswer: 'lasting a short time',
          distractors: const ['permanent', 'significant', 'expensive'],
          context: 'The ephemeral nature of fame...',
          onAnswer: onAnswer,
        ),
      );

      expect(find.textContaining('ephemeral nature'), findsOneWidget);
    });

    testWidgets('builds successfully with shuffled options', (tester) async {
      // This test verifies the widget builds and displays all options
      // Full shuffle verification would require internal state inspection
      // For now we verify the widget builds and all options are present

      await tester.pumpTestWidget(
        RecognitionCard(
          word: 'ephemeral',
          correctAnswer: 'lasting a short time',
          distractors: const ['permanent', 'significant', 'expensive'],
          onAnswer: onAnswer,
        ),
      );

      // Widget builds without error with shuffled options
      expect(find.byType(RecognitionCard), findsOneWidget);

      // All options should be present regardless of order
      expect(find.text('lasting a short time'), findsOneWidget);
      expect(find.text('permanent'), findsOneWidget);
      expect(find.text('significant'), findsOneWidget);
      expect(find.text('expensive'), findsOneWidget);
    });

    testWidgets('renders correctly in dark theme', (tester) async {
      await tester.pumpTestWidget(
        RecognitionCard(
          word: 'ephemeral',
          correctAnswer: 'lasting a short time',
          distractors: const ['permanent', 'significant', 'expensive'],
          onAnswer: onAnswer,
        ),
        themeMode: ThemeMode.dark,
      );

      expect(find.text('ephemeral'), findsOneWidget);
      expect(find.byType(RecognitionCard), findsOneWidget);
    });

    testWidgets('renders correctly in light theme', (tester) async {
      await tester.pumpTestWidget(
        RecognitionCard(
          word: 'ephemeral',
          correctAnswer: 'lasting a short time',
          distractors: const ['permanent', 'significant', 'expensive'],
          onAnswer: onAnswer,
        ),
        themeMode: ThemeMode.light,
      );

      expect(find.text('ephemeral'), findsOneWidget);
      expect(find.byType(RecognitionCard), findsOneWidget);
    });

    testWidgets('preview mode pre-selects correct answer', (tester) async {
      await tester.pumpTestWidget(
        RecognitionCard(
          word: 'ephemeral',
          correctAnswer: 'lasting a short time',
          distractors: const ['permanent', 'significant', 'expensive'],
          onAnswer: onAnswer,
          isPreview: true,
        ),
      );

      // Correct answer should show check icon (feedback state)
      expect(find.byIcon(Icons.check), findsOneWidget);
      // No interaction needed — answer already selected
      expect(selectedAnswer, isNull); // onAnswer not called in preview
    });
  });
}
