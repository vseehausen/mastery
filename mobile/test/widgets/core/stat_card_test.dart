import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/core/widgets/stat_card.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('StatCard', () {
    testWidgets('displays label and value', (tester) async {
      await tester.pumpTestWidget(
        const StatCard(
          label: 'Total Words',
          value: '1,234',
        ),
      );

      expect(find.text('Total Words'), findsOneWidget);
      expect(find.text('1,234'), findsOneWidget);
    });

    testWidgets('displays icon when provided', (tester) async {
      await tester.pumpTestWidget(
        const StatCard(
          label: 'Books',
          value: '5',
          icon: Icons.book,
        ),
      );

      expect(find.byIcon(Icons.book), findsOneWidget);
    });

    testWidgets('does not display icon when not provided', (tester) async {
      await tester.pumpTestWidget(
        const StatCard(
          label: 'Count',
          value: '10',
        ),
      );

      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('applies custom background color', (tester) async {
      await tester.pumpTestWidget(
        const StatCard(
          label: 'Custom',
          value: '0',
          backgroundColor: Colors.blue,
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.blue);
    });

    testWidgets('renders correctly in dark theme', (tester) async {
      await tester.pumpTestWidget(
        const StatCard(
          label: 'Dark Card',
          value: '100',
        ),
        themeMode: ThemeMode.dark,
      );

      expect(find.text('Dark Card'), findsOneWidget);
      expect(find.text('100'), findsOneWidget);
    });

    testWidgets('renders correctly in light theme', (tester) async {
      await tester.pumpTestWidget(
        const StatCard(
          label: 'Light Card',
          value: '200',
        ),
        themeMode: ThemeMode.light,
      );

      expect(find.text('Light Card'), findsOneWidget);
    });

    testWidgets('has rounded corners', (tester) async {
      await tester.pumpTestWidget(
        const StatCard(
          label: 'Rounded',
          value: '0',
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(12));
    });
  });
}
