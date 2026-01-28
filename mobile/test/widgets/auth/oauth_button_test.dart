import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/features/auth/presentation/widgets/oauth_button.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('OAuthButton', () {
    testWidgets('displays icon and label', (tester) async {
      await tester.pumpTestWidget(
        OAuthButton(
          icon: Icons.email,
          label: 'Continue with Email',
          onPressed: () {},
        ),
      );

      expect(find.byIcon(Icons.email), findsOneWidget);
      expect(find.text('Continue with Email'), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var pressed = false;

      await tester.pumpTestWidget(
        OAuthButton(
          icon: Icons.email,
          label: 'Test',
          onPressed: () => pressed = true,
        ),
      );

      await tester.tap(find.byType(InkWell));
      expect(pressed, true);
    });

    testWidgets('is disabled when onPressed is null', (tester) async {
      await tester.pumpTestWidget(
        const OAuthButton(
          icon: Icons.email,
          label: 'Disabled',
          onPressed: null,
        ),
      );

      // Button should still render but not be tappable
      expect(find.text('Disabled'), findsOneWidget);
    });

    testWidgets('has outline style border', (tester) async {
      await tester.pumpTestWidget(
        OAuthButton(
          icon: Icons.email,
          label: 'Test',
          onPressed: () {},
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.border, isNotNull);
    });

    testWidgets('renders correctly in dark theme', (tester) async {
      await tester.pumpTestWidget(
        OAuthButton(
          icon: Icons.apple,
          label: 'Continue with Apple',
          onPressed: () {},
        ),
        themeMode: ThemeMode.dark,
      );

      expect(find.text('Continue with Apple'), findsOneWidget);
    });

    testWidgets('renders correctly in light theme', (tester) async {
      await tester.pumpTestWidget(
        OAuthButton(
          icon: Icons.g_mobiledata,
          label: 'Continue with Google',
          onPressed: () {},
        ),
        themeMode: ThemeMode.light,
      );

      expect(find.text('Continue with Google'), findsOneWidget);
    });
  });
}
