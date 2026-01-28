import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/core/theme/color_tokens.dart';
import 'package:mastery/core/widgets/status_badge.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('StatusBadge', () {
    testWidgets('displays "Known" for known status', (tester) async {
      await tester.pumpTestWidget(
        const StatusBadge(status: LearningStatus.known),
      );

      expect(find.text('Known'), findsOneWidget);
    });

    testWidgets('displays "Learning" for learning status', (tester) async {
      await tester.pumpTestWidget(
        const StatusBadge(status: LearningStatus.learning),
      );

      expect(find.text('Learning'), findsOneWidget);
    });

    testWidgets('displays "New" for unknown status', (tester) async {
      await tester.pumpTestWidget(
        const StatusBadge(status: LearningStatus.unknown),
      );

      expect(find.text('New'), findsOneWidget);
    });

    testWidgets('applies compact styling when compact is true', (tester) async {
      await tester.pumpTestWidget(
        const StatusBadge(status: LearningStatus.known, compact: true),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final padding = container.padding as EdgeInsets;
      expect(padding.horizontal, 16); // 8 * 2 for compact
    });

    testWidgets('applies normal styling when compact is false', (tester) async {
      await tester.pumpTestWidget(
        const StatusBadge(status: LearningStatus.known, compact: false),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final padding = container.padding as EdgeInsets;
      expect(padding.horizontal, 20); // 10 * 2 for normal
    });

    testWidgets('renders correctly in dark theme', (tester) async {
      await tester.pumpTestWidget(
        const StatusBadge(status: LearningStatus.known),
        themeMode: ThemeMode.dark,
      );

      expect(find.text('Known'), findsOneWidget);
      // The badge should render without errors
    });

    testWidgets('renders correctly in light theme', (tester) async {
      await tester.pumpTestWidget(
        const StatusBadge(status: LearningStatus.learning),
        themeMode: ThemeMode.light,
      );

      expect(find.text('Learning'), findsOneWidget);
    });
  });

  group('LearningStatus', () {
    test('has three values', () {
      expect(LearningStatus.values.length, 3);
    });

    test('contains expected values', () {
      expect(LearningStatus.values, contains(LearningStatus.known));
      expect(LearningStatus.values, contains(LearningStatus.learning));
      expect(LearningStatus.values, contains(LearningStatus.unknown));
    });
  });
}
