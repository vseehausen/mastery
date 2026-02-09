import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/core/widgets/progress_stage_badge.dart';
import 'package:mastery/domain/models/progress_stage.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('ProgressStageBadge', () {
    group('displays correct stage name', () {
      testWidgets('shows "New" for captured stage', (tester) async {
        await tester.pumpTestWidget(
          const ProgressStageBadge(stage: ProgressStage.captured),
        );

        expect(find.text('New'), findsOneWidget);
      });

      testWidgets('shows "Practicing" for practicing stage', (tester) async {
        await tester.pumpTestWidget(
          const ProgressStageBadge(stage: ProgressStage.practicing),
        );

        expect(find.text('Practicing'), findsOneWidget);
      });

      testWidgets('shows "Stabilizing" for stabilizing stage', (tester) async {
        await tester.pumpTestWidget(
          const ProgressStageBadge(stage: ProgressStage.stabilizing),
        );

        expect(find.text('Stabilizing'), findsOneWidget);
      });

      testWidgets('shows "Known" for known stage', (tester) async {
        await tester.pumpTestWidget(
          const ProgressStageBadge(stage: ProgressStage.known),
        );

        expect(find.text('Known'), findsOneWidget);
      });

      testWidgets('shows "Mastered" for mastered stage', (tester) async {
        await tester.pumpTestWidget(
          const ProgressStageBadge(stage: ProgressStage.mastered),
        );

        expect(find.text('Mastered'), findsOneWidget);
      });
    });

    group('compact mode padding', () {
      testWidgets('uses smaller padding when compact is true', (tester) async {
        await tester.pumpTestWidget(
          const ProgressStageBadge(
            stage: ProgressStage.captured,
            compact: true,
          ),
        );

        final container = tester.widget<Container>(find.byType(Container));
        final padding = container.padding as EdgeInsets;
        expect(padding.left, 8);
        expect(padding.right, 8);
        expect(padding.top, 4);
        expect(padding.bottom, 4);
      });

      testWidgets('uses larger padding when compact is false', (tester) async {
        await tester.pumpTestWidget(
          const ProgressStageBadge(
            stage: ProgressStage.captured,
            compact: false,
          ),
        );

        final container = tester.widget<Container>(find.byType(Container));
        final padding = container.padding as EdgeInsets;
        expect(padding.left, 10);
        expect(padding.right, 10);
        expect(padding.top, 5);
        expect(padding.bottom, 5);
      });
    });

    testWidgets('container has borderRadius of 12', (tester) async {
      await tester.pumpTestWidget(
        const ProgressStageBadge(stage: ProgressStage.practicing),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(12));
    });

    testWidgets('renders correctly in dark mode', (tester) async {
      await tester.pumpTestWidget(
        const ProgressStageBadge(stage: ProgressStage.mastered),
        themeMode: ThemeMode.dark,
      );

      expect(find.text('Mastered'), findsOneWidget);

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, isNotNull);
      expect(decoration.borderRadius, BorderRadius.circular(12));
    });
  });
}
