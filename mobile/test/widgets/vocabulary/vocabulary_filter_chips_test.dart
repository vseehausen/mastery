import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/features/vocabulary/presentation/widgets/vocabulary_filter_chips.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('VocabularyFilterChips', () {
    testWidgets('displays all filter options', (tester) async {
      await tester.pumpTestWidget(
        VocabularyFilterChips(
          selectedFilter: VocabularyFilter.all,
          onFilterChanged: (_) {},
        ),
      );

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Enriched'), findsOneWidget);
      expect(find.text('Not Enriched'), findsOneWidget);
    });

    testWidgets('calls onFilterChanged with all when All is tapped', (
      tester,
    ) async {
      VocabularyFilter selectedFilter = VocabularyFilter.enriched;

      await tester.pumpTestWidget(
        VocabularyFilterChips(
          selectedFilter: selectedFilter,
          onFilterChanged: (filter) => selectedFilter = filter,
        ),
      );

      await tester.tap(find.text('All'));
      await tester.pump();

      expect(selectedFilter, VocabularyFilter.all);
    });

    testWidgets(
      'calls onFilterChanged with correct filter when chip is tapped',
      (tester) async {
        VocabularyFilter selectedFilter = VocabularyFilter.all;

        await tester.pumpTestWidget(
          VocabularyFilterChips(
            selectedFilter: selectedFilter,
            onFilterChanged: (filter) => selectedFilter = filter,
          ),
        );

        await tester.tap(find.text('Enriched'));
        await tester.pump();

        expect(selectedFilter, VocabularyFilter.enriched);
      },
    );

    testWidgets('renders correctly in dark theme', (tester) async {
      await tester.pumpTestWidget(
        VocabularyFilterChips(
          selectedFilter: VocabularyFilter.all,
          onFilterChanged: (_) {},
        ),
        themeMode: ThemeMode.dark,
      );

      expect(find.text('All'), findsOneWidget);
    });

    testWidgets('renders correctly in light theme', (tester) async {
      await tester.pumpTestWidget(
        VocabularyFilterChips(
          selectedFilter: VocabularyFilter.all,
          onFilterChanged: (_) {},
        ),
        themeMode: ThemeMode.light,
      );

      expect(find.text('All'), findsOneWidget);
    });

    testWidgets('shows sparkle icon on Enriched chip', (tester) async {
      await tester.pumpTestWidget(
        VocabularyFilterChips(
          selectedFilter: VocabularyFilter.all,
          onFilterChanged: (_) {},
        ),
      );

      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    });
  });
}
