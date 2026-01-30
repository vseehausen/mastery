import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/features/settings/presentation/widgets/settings_section.dart';
import 'package:mastery/features/settings/presentation/widgets/settings_list_item.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('SettingsSection', () {
    testWidgets('displays title', (tester) async {
      await tester.pumpTestWidget(
        const SettingsSection(
          title: 'ACCOUNT',
          children: [SettingsListItem(label: 'Profile')],
        ),
      );

      expect(find.text('ACCOUNT'), findsOneWidget);
    });

    testWidgets('displays children', (tester) async {
      await tester.pumpTestWidget(
        const SettingsSection(
          title: 'TEST',
          children: [
            SettingsListItem(label: 'Item 1'),
            SettingsListItem(label: 'Item 2'),
          ],
        ),
      );

      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
    });

    testWidgets('renders correctly in dark theme', (tester) async {
      await tester.pumpTestWidget(
        const SettingsSection(
          title: 'DARK',
          children: [SettingsListItem(label: 'Test')],
        ),
        themeMode: ThemeMode.dark,
      );

      expect(find.text('DARK'), findsOneWidget);
    });

    testWidgets('renders correctly in light theme', (tester) async {
      await tester.pumpTestWidget(
        const SettingsSection(
          title: 'LIGHT',
          children: [SettingsListItem(label: 'Test')],
        ),
        themeMode: ThemeMode.light,
      );

      expect(find.text('LIGHT'), findsOneWidget);
    });
  });
}
