import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/core/theme/color_tokens.dart';
import 'package:mastery/core/widgets/progress_stage_badge.dart';
import 'package:mastery/core/widgets/status_badge.dart';
import 'package:mastery/core/widgets/word_card.dart';
import 'package:mastery/domain/models/progress_stage.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('WordCard', () {
    testWidgets('displays word and definition', (tester) async {
      await tester.pumpTestWidget(
        WordCard(
          word: 'ephemeral',
          definition: 'lasting for a very short time',
          onTap: () {},
        ),
      );

      expect(find.text('ephemeral'), findsOneWidget);
      expect(find.text('lasting for a very short time'), findsOneWidget);
    });

    testWidgets('displays enriched icon when isEnriched is true', (
      tester,
    ) async {
      await tester.pumpTestWidget(
        WordCard(
          word: 'test',
          definition: 'test definition',
          isEnriched: true,
          onTap: () {},
        ),
      );

      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    });

    testWidgets('does not display enriched icon when isEnriched is false', (
      tester,
    ) async {
      await tester.pumpTestWidget(
        WordCard(
          word: 'test',
          definition: 'test definition',
          isEnriched: false,
          onTap: () {},
        ),
      );

      expect(find.byIcon(Icons.auto_awesome), findsNothing);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;

      await tester.pumpTestWidget(
        WordCard(
          word: 'test',
          definition: 'definition',
          onTap: () => tapped = true,
        ),
      );

      await tester.tap(find.byType(InkWell));
      expect(tapped, true);
    });

    testWidgets('shows chevron icon', (tester) async {
      await tester.pumpTestWidget(
        WordCard(word: 'test', definition: 'definition', onTap: () {}),
      );

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('renders correctly in dark theme', (tester) async {
      await tester.pumpTestWidget(
        WordCard(
          word: 'dark word',
          definition: 'dark definition',
          onTap: () {},
        ),
        themeMode: ThemeMode.dark,
      );

      expect(find.text('dark word'), findsOneWidget);
    });

    testWidgets('truncates long word with ellipsis', (tester) async {
      await tester.pumpTestWidget(
        WordCard(
          word: 'supercalifragilisticexpialidocious',
          definition: 'A very long word',
          onTap: () {},
        ),
      );

      final wordText = tester.widget<Text>(
        find.text('supercalifragilisticexpialidocious'),
      );
      expect(wordText.maxLines, 1);
      expect(wordText.overflow, TextOverflow.ellipsis);
    });

    testWidgets('truncates long definition to 2 lines', (tester) async {
      await tester.pumpTestWidget(
        WordCard(
          word: 'test',
          definition:
              'This is a very long definition that should span multiple lines and eventually get truncated with an ellipsis at the end.',
          onTap: () {},
        ),
      );

      final defText = tester.widget<Text>(
        find.text(
          'This is a very long definition that should span multiple lines and eventually get truncated with an ellipsis at the end.',
        ),
      );
      expect(defText.maxLines, 2);
      expect(defText.overflow, TextOverflow.ellipsis);
    });

    testWidgets('has divider at bottom', (tester) async {
      await tester.pumpTestWidget(
        WordCard(word: 'test', definition: 'definition', onTap: () {}),
      );

      expect(find.byType(Divider), findsOneWidget);
    });

    testWidgets('shows ProgressStageBadge when progressStage is set', (
      tester,
    ) async {
      await tester.pumpTestWidget(
        WordCard(
          word: 'test',
          definition: 'definition',
          progressStage: ProgressStage.practicing,
          onTap: () {},
        ),
      );

      expect(find.byType(ProgressStageBadge), findsOneWidget);
      expect(find.text('Practicing'), findsOneWidget);
    });

    testWidgets(
      'shows StatusBadge when status is set and progressStage is null',
      (tester) async {
        await tester.pumpTestWidget(
          WordCard(
            word: 'test',
            definition: 'definition',
            status: LearningStatus.learning,
            onTap: () {},
          ),
        );

        expect(find.byType(StatusBadge), findsOneWidget);
      },
    );

    testWidgets(
      'prefers ProgressStageBadge over StatusBadge when both are set',
      (tester) async {
        await tester.pumpTestWidget(
          WordCard(
            word: 'test',
            definition: 'definition',
            progressStage: ProgressStage.active,
            status: LearningStatus.learning,
            onTap: () {},
          ),
        );

        expect(find.byType(ProgressStageBadge), findsOneWidget);
        expect(find.byType(StatusBadge), findsNothing);
      },
    );
  });
}
