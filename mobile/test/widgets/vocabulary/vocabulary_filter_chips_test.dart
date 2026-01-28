import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/core/theme/color_tokens.dart';
import 'package:mastery/features/vocabulary/presentation/widgets/vocabulary_filter_chips.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('VocabularyFilterChips', () {
    testWidgets('displays all filter options', (tester) async {
      await tester.pumpTestWidget(
        VocabularyFilterChips(
          onFilterChanged: (_) {},
        ),
      );

      expect(find.text('All'), findsOneWidget);
      expect(find.text('New'), findsOneWidget);
      expect(find.text('Learning'), findsOneWidget);
      expect(find.text('Known'), findsOneWidget);
    });

    testWidgets('calls onFilterChanged with null when All is tapped', (tester) async {
      LearningStatus? selectedStatus = LearningStatus.known;

      await tester.pumpTestWidget(
        VocabularyFilterChips(
          onFilterChanged: (status) => selectedStatus = status,
        ),
      );

      await tester.tap(find.text('All'));
      await tester.pump();

      expect(selectedStatus, isNull);
    });

    testWidgets('calls onFilterChanged with correct status when chip is tapped', (tester) async {
      LearningStatus? selectedStatus;

      await tester.pumpTestWidget(
        VocabularyFilterChips(
          onFilterChanged: (status) => selectedStatus = status,
        ),
      );

      await tester.tap(find.text('Learning'));
      await tester.pump();

      expect(selectedStatus, LearningStatus.learning);
    });

    testWidgets('renders correctly in dark theme', (tester) async {
      await tester.pumpTestWidget(
        VocabularyFilterChips(
          onFilterChanged: (_) {},
        ),
        themeMode: ThemeMode.dark,
      );

      expect(find.text('All'), findsOneWidget);
    });

    testWidgets('renders correctly in light theme', (tester) async {
      await tester.pumpTestWidget(
        VocabularyFilterChips(
          onFilterChanged: (_) {},
        ),
        themeMode: ThemeMode.light,
      );

      expect(find.text('All'), findsOneWidget);
    });
  });
}
