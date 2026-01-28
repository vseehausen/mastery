import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/features/home/presentation/widgets/shadow_brain_card.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('ShadowBrainCard', () {
    testWidgets('displays total words count', (tester) async {
      await tester.pumpTestWidget(
        const ShadowBrainCard(
          totalWords: 1234,
          activeWords: 500,
          progressPercent: 0.5,
        ),
      );

      expect(find.text('1234'), findsOneWidget);
    });

    testWidgets('displays active words count', (tester) async {
      await tester.pumpTestWidget(
        const ShadowBrainCard(
          totalWords: 1000,
          activeWords: 750,
          progressPercent: 0.75,
        ),
      );

      expect(find.text('750'), findsOneWidget);
    });

    testWidgets('displays progress indicator', (tester) async {
      await tester.pumpTestWidget(
        const ShadowBrainCard(
          totalWords: 100,
          activeWords: 50,
          progressPercent: 0.5,
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('handles zero values', (tester) async {
      await tester.pumpTestWidget(
        const ShadowBrainCard(
          totalWords: 0,
          activeWords: 0,
          progressPercent: 0,
        ),
      );

      expect(find.text('0'), findsWidgets);
    });

    testWidgets('renders correctly in dark theme', (tester) async {
      await tester.pumpTestWidget(
        const ShadowBrainCard(
          totalWords: 100,
          activeWords: 50,
          progressPercent: 0.5,
        ),
        themeMode: ThemeMode.dark,
      );

      expect(find.byType(ShadowBrainCard), findsOneWidget);
    });

    testWidgets('renders correctly in light theme', (tester) async {
      await tester.pumpTestWidget(
        const ShadowBrainCard(
          totalWords: 200,
          activeWords: 100,
          progressPercent: 0.5,
        ),
        themeMode: ThemeMode.light,
      );

      expect(find.byType(ShadowBrainCard), findsOneWidget);
    });
  });
}
