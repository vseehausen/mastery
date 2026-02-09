import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/core/theme/color_tokens.dart';
import 'package:mastery/domain/models/progress_stage.dart';
import 'package:mastery/features/learn/widgets/progress_micro_feedback.dart';

void main() {
  group('ProgressMicroFeedback', () {
    testWidgets('displays word and stage in correct format', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [MasteryColorScheme.light]),
          home: const Scaffold(
            body: ProgressMicroFeedback(
              stage: ProgressStage.stabilizing,
              wordText: 'ubiquitous',
            ),
          ),
        ),
      );

      expect(find.text('ubiquitous → Stabilizing'), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('displays Mastered with special format', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [MasteryColorScheme.light]),
          home: const Scaffold(
            body: ProgressMicroFeedback(
              stage: ProgressStage.mastered,
              wordText: 'ubiquitous',
            ),
          ),
        ),
      );

      expect(find.text('ubiquitous — Mastered.'), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('badge appears after fade-in', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [MasteryColorScheme.light]),
          home: const Scaffold(
            body: ProgressMicroFeedback(
              stage: ProgressStage.known,
              wordText: 'test',
            ),
          ),
        ),
      );

      // Initially invisible (opacity 0)
      var animatedOpacity = tester.widget<AnimatedOpacity>(
        find.byType(AnimatedOpacity),
      );
      expect(animatedOpacity.opacity, 0.0);

      // After delay and animations, becomes visible
      await tester.pumpAndSettle();
      animatedOpacity = tester.widget<AnimatedOpacity>(
        find.byType(AnimatedOpacity),
      );
      expect(animatedOpacity.opacity, 1.0);
    });

    testWidgets('displays correct color for Known stage', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [MasteryColorScheme.light]),
          home: const Scaffold(
            body: ProgressMicroFeedback(
              stage: ProgressStage.known,
              wordText: 'test',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the container and check its color
      final container = tester.widget<Container>(
        find
            .ancestor(
              of: find.textContaining('Known'),
              matching: find.byType(Container),
            )
            .first,
      );

      final decoration = container.decoration as BoxDecoration;
      final expectedColor = ProgressStage.known.getColor(
        MasteryColorScheme.light,
      );
      expect(decoration.color, expectedColor);
    });

    testWidgets('has proper text styling', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [MasteryColorScheme.light]),
          home: const Scaffold(
            body: ProgressMicroFeedback(
              stage: ProgressStage.known,
              wordText: 'test',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check text style
      final textWidget = tester.widget<Text>(find.text('test → Known'));
      expect(textWidget.style?.color, Colors.white);
      expect(textWidget.style?.fontSize, 14);
      expect(textWidget.style?.fontWeight, FontWeight.w600);
    });

    testWidgets('has proper container styling', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [MasteryColorScheme.light]),
          home: const Scaffold(
            body: ProgressMicroFeedback(
              stage: ProgressStage.known,
              wordText: 'test',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check container shape
      final container = tester.widget<Container>(
        find
            .ancestor(
              of: find.textContaining('Known'),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(12));
    });

    testWidgets('widget is properly sized', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [MasteryColorScheme.light]),
          home: const Scaffold(
            body: Center(
              child: ProgressMicroFeedback(
                stage: ProgressStage.stabilizing,
                wordText: 'test',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final containerFinder = find
          .ancestor(
            of: find.textContaining('Stabilizing'),
            matching: find.byType(Container),
          )
          .first;

      final size = tester.getSize(containerFinder);

      // Badge should be reasonably sized (not too big or too small)
      expect(size.width, greaterThan(60));
      expect(size.width, lessThan(300));
      expect(size.height, greaterThan(20));
      expect(size.height, lessThan(60));
    });

    testWidgets('works in dark mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            brightness: Brightness.dark,
            extensions: [MasteryColorScheme.dark],
          ),
          home: const Scaffold(
            body: ProgressMicroFeedback(
              stage: ProgressStage.known,
              wordText: 'test',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should display without errors
      expect(find.text('test → Known'), findsOneWidget);
    });

    testWidgets('badge fades out after timeout', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [MasteryColorScheme.light]),
          home: const Scaffold(
            body: ProgressMicroFeedback(
              stage: ProgressStage.stabilizing,
              wordText: 'test',
            ),
          ),
        ),
      );

      // Let fade-in complete
      await tester.pumpAndSettle();

      // Verify visible
      var animatedOpacity = tester.widget<AnimatedOpacity>(
        find.byType(AnimatedOpacity),
      );
      expect(animatedOpacity.opacity, 1.0);

      // Advance past fade-out timer (2600ms total)
      await tester.pump(const Duration(milliseconds: 2600));
      await tester.pumpAndSettle();

      // Should now be faded out
      animatedOpacity = tester.widget<AnimatedOpacity>(
        find.byType(AnimatedOpacity),
      );
      expect(animatedOpacity.opacity, 0.0);
    });
  });
}
