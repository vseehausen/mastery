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

    testWidgets('displays all progress stage filter options', (tester) async {
      await tester.pumpTestWidget(
        VocabularyFilterChips(
          selectedFilter: VocabularyFilter.all,
          onFilterChanged: (_) {},
        ),
      );

      expect(find.text('Captured'), findsOneWidget);
      expect(find.text('Practicing'), findsOneWidget);
      expect(find.text('Stabilizing'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Mastered'), findsOneWidget);
    });

    testWidgets('tapping Not Enriched chip calls onFilterChanged', (
      tester,
    ) async {
      VocabularyFilter? selected;
      await tester.pumpTestWidget(
        VocabularyFilterChips(
          selectedFilter: VocabularyFilter.all,
          onFilterChanged: (filter) => selected = filter,
        ),
      );

      await tester.tap(find.text('Not Enriched'));
      await tester.pump();
      expect(selected, VocabularyFilter.notEnriched);
    });

    testWidgets('tapping Captured chip calls onFilterChanged', (tester) async {
      VocabularyFilter? selected;
      await tester.pumpTestWidget(
        VocabularyFilterChips(
          selectedFilter: VocabularyFilter.all,
          onFilterChanged: (filter) => selected = filter,
        ),
      );

      await tester.scrollUntilVisible(find.text('Captured'), 100);
      await tester.tap(find.text('Captured'));
      await tester.pump();
      expect(selected, VocabularyFilter.captured);
    });

    testWidgets('tapping Practicing chip calls onFilterChanged', (
      tester,
    ) async {
      VocabularyFilter? selected;
      await tester.pumpTestWidget(
        VocabularyFilterChips(
          selectedFilter: VocabularyFilter.all,
          onFilterChanged: (filter) => selected = filter,
        ),
      );

      await tester.scrollUntilVisible(find.text('Practicing'), 100);
      await tester.tap(find.text('Practicing'));
      await tester.pump();
      expect(selected, VocabularyFilter.practicing);
    });

    testWidgets('tapping Stabilizing chip calls onFilterChanged', (
      tester,
    ) async {
      VocabularyFilter? selected;
      await tester.pumpTestWidget(
        VocabularyFilterChips(
          selectedFilter: VocabularyFilter.all,
          onFilterChanged: (filter) => selected = filter,
        ),
      );

      await tester.scrollUntilVisible(find.text('Stabilizing'), 100);
      await tester.tap(find.text('Stabilizing'));
      await tester.pump();
      expect(selected, VocabularyFilter.stabilizing);
    });

    testWidgets('tapping Active chip calls onFilterChanged', (tester) async {
      VocabularyFilter? selected;
      await tester.pumpTestWidget(
        VocabularyFilterChips(
          selectedFilter: VocabularyFilter.all,
          onFilterChanged: (filter) => selected = filter,
        ),
      );

      await tester.scrollUntilVisible(find.text('Active'), 100);
      await tester.tap(find.text('Active'));
      await tester.pump();
      expect(selected, VocabularyFilter.active);
    });

    testWidgets('tapping Mastered chip calls onFilterChanged', (tester) async {
      VocabularyFilter? selected;
      await tester.pumpTestWidget(
        VocabularyFilterChips(
          selectedFilter: VocabularyFilter.all,
          onFilterChanged: (filter) => selected = filter,
        ),
      );

      await tester.scrollUntilVisible(find.text('Mastered'), 100);
      await tester.tap(find.text('Mastered'));
      await tester.pump();
      expect(selected, VocabularyFilter.mastered);
    });
  });
}
