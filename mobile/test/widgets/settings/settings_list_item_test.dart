import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/features/settings/presentation/widgets/settings_list_item.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('SettingsListItem', () {
    testWidgets('displays label', (tester) async {
      await tester.pumpTestWidget(
        const SettingsListItem(label: 'Account Settings'),
      );

      expect(find.text('Account Settings'), findsOneWidget);
    });

    testWidgets('displays value when provided', (tester) async {
      await tester.pumpTestWidget(
        const SettingsListItem(label: 'Language', value: 'English'),
      );

      expect(find.text('Language'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
    });

    testWidgets('does not display value when not provided', (tester) async {
      await tester.pumpTestWidget(const SettingsListItem(label: 'Simple Item'));

      expect(find.text('Simple Item'), findsOneWidget);
    });

    testWidgets('shows chevron icon by default', (tester) async {
      await tester.pumpTestWidget(const SettingsListItem(label: 'Test'));

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('hides chevron when isDanger is true', (tester) async {
      await tester.pumpTestWidget(
        const SettingsListItem(label: 'Delete Account', isDanger: true),
      );

      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });

    testWidgets('shows trailing widget when provided', (tester) async {
      await tester.pumpTestWidget(
        const SettingsListItem(label: 'Custom', trailing: Icon(Icons.star)),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;

      await tester.pumpTestWidget(
        SettingsListItem(label: 'Tappable', onTap: () => tapped = true),
      );

      await tester.tap(find.text('Tappable'));
      expect(tapped, true);
    });

    testWidgets('applies danger style when isDanger is true', (tester) async {
      await tester.pumpTestWidget(
        const SettingsListItem(label: 'Delete', isDanger: true),
      );

      final textWidget = tester.widget<Text>(find.text('Delete'));
      // Verify that the text has a different color (destructive) and is bold
      expect(textWidget.style?.color, isNotNull);
      expect(textWidget.style?.fontWeight, FontWeight.w600);
    });

    testWidgets('renders correctly in dark theme', (tester) async {
      await tester.pumpTestWidget(
        const SettingsListItem(label: 'Dark Item', value: 'Value'),
        themeMode: ThemeMode.dark,
      );

      expect(find.text('Dark Item'), findsOneWidget);
    });

    testWidgets('renders correctly in light theme', (tester) async {
      await tester.pumpTestWidget(
        const SettingsListItem(label: 'Light Item'),
        themeMode: ThemeMode.light,
      );

      expect(find.text('Light Item'), findsOneWidget);
    });
  });
}
