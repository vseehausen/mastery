import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/core/theme/color_tokens.dart';
import 'package:mastery/domain/models/progress_stage.dart';
import 'package:mastery/features/learn/widgets/progress_micro_feedback.dart';

void main() {
  group('ProgressMicroFeedback', () {
    testWidgets('displays stage name', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [MasteryColorScheme.light]),
          home: const Scaffold(
            body: ProgressMicroFeedback(stage: ProgressStage.stabilizing),
          ),
        ),
      );

      expect(find.text('Stabilizing'), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('badge appears after fade-in', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [MasteryColorScheme.light]),
          home: const Scaffold(
            body: ProgressMicroFeedback(stage: ProgressStage.active),
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

    testWidgets('displays correct color for Active stage', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [MasteryColorScheme.light]),
          home: const Scaffold(
            body: ProgressMicroFeedback(stage: ProgressStage.active),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the container and check its color
      final container = tester.widget<Container>(
        find.ancestor(
          of: find.text('Active'),
          matching: find.byType(Container),
        ).first,
      );

      final decoration = container.decoration as BoxDecoration;
      final expectedColor = ProgressStage.active.getColor(MasteryColorScheme.light);
      expect(decoration.color, expectedColor);
    });

    testWidgets('has proper text styling', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [MasteryColorScheme.light]),
          home: const Scaffold(
            body: ProgressMicroFeedback(stage: ProgressStage.active),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check text style
      final textWidget = tester.widget<Text>(find.text('Active'));
      expect(textWidget.style?.color, Colors.white);
      expect(textWidget.style?.fontSize, 12);
      expect(textWidget.style?.fontWeight, FontWeight.w600);
    });

    testWidgets('has proper container styling', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [MasteryColorScheme.light]),
          home: const Scaffold(
            body: ProgressMicroFeedback(stage: ProgressStage.active),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check container shape
      final container = tester.widget<Container>(
        find.ancestor(
          of: find.text('Active'),
          matching: find.byType(Container),
        ).first,
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
              child: ProgressMicroFeedback(stage: ProgressStage.stabilizing),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final containerFinder = find.ancestor(
        of: find.text('Stabilizing'),
        matching: find.byType(Container),
      ).first;

      final size = tester.getSize(containerFinder);

      // Badge should be reasonably sized (not too big or too small)
      expect(size.width, greaterThan(60));
      expect(size.width, lessThan(150));
      expect(size.height, greaterThan(20));
      expect(size.height, lessThan(50));
    });

    testWidgets('works in dark mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            brightness: Brightness.dark,
            extensions: [MasteryColorScheme.dark],
          ),
          home: const Scaffold(
            body: ProgressMicroFeedback(stage: ProgressStage.active),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should display without errors
      expect(find.text('Active'), findsOneWidget);
    });
  });
}
