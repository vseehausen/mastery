import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/features/auth/presentation/widgets/auth_logo.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('AuthLogo', () {
    testWidgets('displays title', (tester) async {
      await tester.pumpTestWidget(const AuthLogo(title: 'Welcome to Mastery'));

      expect(find.text('Welcome to Mastery'), findsOneWidget);
    });

    testWidgets('displays subtitle when provided', (tester) async {
      await tester.pumpTestWidget(
        const AuthLogo(title: 'Welcome', subtitle: 'Sign in to continue'),
      );

      expect(find.text('Welcome'), findsOneWidget);
      expect(find.text('Sign in to continue'), findsOneWidget);
    });

    testWidgets('does not display subtitle when not provided', (tester) async {
      await tester.pumpTestWidget(const AuthLogo(title: 'Title Only'));

      expect(find.text('Title Only'), findsOneWidget);
      // Should only have one Text widget for the title
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('displays logo icon', (tester) async {
      await tester.pumpTestWidget(const AuthLogo(title: 'Test'));

      expect(find.byIcon(Icons.auto_stories), findsOneWidget);
    });

    testWidgets('renders correctly in dark theme', (tester) async {
      await tester.pumpTestWidget(
        const AuthLogo(title: 'Dark Theme', subtitle: 'Testing dark mode'),
        themeMode: ThemeMode.dark,
      );

      expect(find.text('Dark Theme'), findsOneWidget);
    });

    testWidgets('renders correctly in light theme', (tester) async {
      await tester.pumpTestWidget(
        const AuthLogo(title: 'Light Theme'),
        themeMode: ThemeMode.light,
      );

      expect(find.text('Light Theme'), findsOneWidget);
    });
  });
}
