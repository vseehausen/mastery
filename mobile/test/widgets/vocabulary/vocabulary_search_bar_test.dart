import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/features/vocabulary/presentation/widgets/vocabulary_search_bar.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('VocabularySearchBar', () {
    testWidgets('displays search icon', (tester) async {
      await tester.pumpTestWidget(
        const VocabularySearchBar(),
      );

      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('displays placeholder text', (tester) async {
      await tester.pumpTestWidget(
        const VocabularySearchBar(),
      );

      expect(find.text('Search words...'), findsOneWidget);
    });

    testWidgets('calls onChanged when text is entered', (tester) async {
      String? changedText;

      await tester.pumpTestWidget(
        VocabularySearchBar(
          onChanged: (text) => changedText = text,
        ),
      );

      await tester.enterText(find.byType(TextField), 'ephemeral');
      expect(changedText, 'ephemeral');
    });

    testWidgets('shows close button when text is entered', (tester) async {
      final controller = TextEditingController(text: 'test');

      await tester.pumpTestWidget(
        VocabularySearchBar(
          controller: controller,
        ),
      );

      // Widget uses Icons.close not Icons.clear
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('hides close button when text is empty', (tester) async {
      final controller = TextEditingController();

      await tester.pumpTestWidget(
        VocabularySearchBar(
          controller: controller,
        ),
      );

      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('clears text when close button is tapped', (tester) async {
      var cleared = false;
      final controller = TextEditingController(text: 'test');

      await tester.pumpTestWidget(
        VocabularySearchBar(
          controller: controller,
          onClear: () => cleared = true,
        ),
      );

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      
      expect(controller.text, isEmpty);
      expect(cleared, true);
    });

    testWidgets('renders correctly in dark theme', (tester) async {
      await tester.pumpTestWidget(
        const VocabularySearchBar(),
        themeMode: ThemeMode.dark,
      );

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('renders correctly in light theme', (tester) async {
      await tester.pumpTestWidget(
        const VocabularySearchBar(),
        themeMode: ThemeMode.light,
      );

      expect(find.byType(TextField), findsOneWidget);
    });
  });
}
