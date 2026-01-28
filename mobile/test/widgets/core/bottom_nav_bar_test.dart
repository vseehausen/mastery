import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/core/widgets/bottom_nav_bar.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('BottomNavBar', () {
    testWidgets('displays all four navigation tabs', (tester) async {
      await tester.pumpTestWidget(
        BottomNavBar(
          selectedIndex: 0,
          onTabSelected: (_) {},
        ),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Learn'), findsOneWidget);
      expect(find.text('Words'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('displays correct icons', (tester) async {
      await tester.pumpTestWidget(
        BottomNavBar(
          selectedIndex: 0,
          onTabSelected: (_) {},
        ),
      );

      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
      expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
      expect(find.byIcon(Icons.book_outlined), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    });

    testWidgets('calls onTabSelected with correct index when tab is tapped', (tester) async {
      int? selectedIndex;

      await tester.pumpTestWidget(
        BottomNavBar(
          selectedIndex: 0,
          onTabSelected: (index) => selectedIndex = index,
        ),
      );

      // Tap on 'Words' tab (index 2)
      await tester.tap(find.text('Words'));
      expect(selectedIndex, 2);

      // Tap on 'Settings' tab (index 3)
      await tester.tap(find.text('Settings'));
      expect(selectedIndex, 3);
    });

    testWidgets('renders correctly in dark theme', (tester) async {
      await tester.pumpTestWidget(
        BottomNavBar(
          selectedIndex: 1,
          onTabSelected: (_) {},
        ),
        themeMode: ThemeMode.dark,
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Learn'), findsOneWidget);
    });

    testWidgets('renders correctly in light theme', (tester) async {
      await tester.pumpTestWidget(
        BottomNavBar(
          selectedIndex: 2,
          onTabSelected: (_) {},
        ),
        themeMode: ThemeMode.light,
      );

      expect(find.text('Words'), findsOneWidget);
    });
  });
}
