import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/data/database/database.dart';
import 'package:mastery/features/vocabulary/presentation/widgets/meaning_editor.dart';

import '../../../../helpers/test_helpers.dart';

Meaning _createMeaning({
  String primaryTranslation = 'effizient',
  String englishDefinition = 'Achieving results with minimal waste.',
}) {
  final now = DateTime.now();
  return Meaning(
    id: 'meaning-1',
    userId: 'user-1',
    vocabularyId: 'vocab-1',
    languageCode: 'de',
    primaryTranslation: primaryTranslation,
    alternativeTranslations: '[]',
    englishDefinition: englishDefinition,
    synonyms: '[]',
    confidence: 0.9,
    isPrimary: true,
    isActive: true,
    sortOrder: 0,
    source: 'openai',
    createdAt: now,
    updatedAt: now,
    isPendingSync: false,
    version: 1,
  );
}

void main() {
  group('MeaningEditor', () {
    testWidgets('displays initial values in text fields', (tester) async {
      final meaning = _createMeaning();

      await tester.pumpTestWidget(
        MeaningEditor(
          meaning: meaning,
          onSave: ({String? primaryTranslation, String? englishDefinition}) {},
          onCancel: () {},
        ),
      );

      expect(find.text('effizient'), findsOneWidget);
      expect(
        find.text('Achieving results with minimal waste.'),
        findsOneWidget,
      );
    });

    testWidgets('shows Edit Meaning header', (tester) async {
      final meaning = _createMeaning();

      await tester.pumpTestWidget(
        MeaningEditor(
          meaning: meaning,
          onSave: ({String? primaryTranslation, String? englishDefinition}) {},
          onCancel: () {},
        ),
      );

      expect(find.text('Edit Meaning'), findsOneWidget);
    });

    testWidgets('Save button disabled when no changes', (tester) async {
      final meaning = _createMeaning();

      await tester.pumpTestWidget(
        MeaningEditor(
          meaning: meaning,
          onSave: ({String? primaryTranslation, String? englishDefinition}) {},
          onCancel: () {},
        ),
      );

      final saveButton = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(saveButton.onPressed, isNull);
    });

    testWidgets('Save button enabled after editing translation',
        (tester) async {
      final meaning = _createMeaning();

      await tester.pumpTestWidget(
        MeaningEditor(
          meaning: meaning,
          onSave: ({String? primaryTranslation, String? englishDefinition}) {},
          onCancel: () {},
        ),
      );

      // Edit the translation field (first TextField)
      await tester.enterText(find.byType(TextField).first, 'leistungsfähig');
      await tester.pump();

      final saveButton = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(saveButton.onPressed, isNotNull);
    });

    testWidgets('Save button enabled after editing definition',
        (tester) async {
      final meaning = _createMeaning();

      await tester.pumpTestWidget(
        MeaningEditor(
          meaning: meaning,
          onSave: ({String? primaryTranslation, String? englishDefinition}) {},
          onCancel: () {},
        ),
      );

      // Edit the definition field (second TextField)
      await tester.enterText(find.byType(TextField).last, 'New definition.');
      await tester.pump();

      final saveButton = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(saveButton.onPressed, isNotNull);
    });

    testWidgets('onSave called with only changed translation',
        (tester) async {
      final meaning = _createMeaning();
      String? savedTranslation;
      String? savedDefinition;

      await tester.pumpTestWidget(
        MeaningEditor(
          meaning: meaning,
          onSave: ({String? primaryTranslation, String? englishDefinition}) {
            savedTranslation = primaryTranslation;
            savedDefinition = englishDefinition;
          },
          onCancel: () {},
        ),
      );

      await tester.enterText(find.byType(TextField).first, 'leistungsfähig');
      await tester.pump();

      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(savedTranslation, 'leistungsfähig');
      expect(savedDefinition, isNull);
    });

    testWidgets('onSave called with only changed definition', (tester) async {
      final meaning = _createMeaning();
      String? savedTranslation;
      String? savedDefinition;

      await tester.pumpTestWidget(
        MeaningEditor(
          meaning: meaning,
          onSave: ({String? primaryTranslation, String? englishDefinition}) {
            savedTranslation = primaryTranslation;
            savedDefinition = englishDefinition;
          },
          onCancel: () {},
        ),
      );

      await tester.enterText(find.byType(TextField).last, 'Updated def.');
      await tester.pump();

      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(savedTranslation, isNull);
      expect(savedDefinition, 'Updated def.');
    });

    testWidgets('onSave called with both changed fields', (tester) async {
      final meaning = _createMeaning();
      String? savedTranslation;
      String? savedDefinition;

      await tester.pumpTestWidget(
        MeaningEditor(
          meaning: meaning,
          onSave: ({String? primaryTranslation, String? englishDefinition}) {
            savedTranslation = primaryTranslation;
            savedDefinition = englishDefinition;
          },
          onCancel: () {},
        ),
      );

      await tester.enterText(find.byType(TextField).first, 'neu');
      await tester.enterText(find.byType(TextField).last, 'New def.');
      await tester.pump();

      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(savedTranslation, 'neu');
      expect(savedDefinition, 'New def.');
    });

    testWidgets('onCancel called when Cancel tapped', (tester) async {
      final meaning = _createMeaning();
      var cancelCalled = false;

      await tester.pumpTestWidget(
        MeaningEditor(
          meaning: meaning,
          onSave: ({String? primaryTranslation, String? englishDefinition}) {},
          onCancel: () => cancelCalled = true,
        ),
      );

      await tester.tap(find.text('Cancel'));
      expect(cancelCalled, isTrue);
    });

    testWidgets('trims whitespace on save', (tester) async {
      final meaning = _createMeaning();
      String? savedTranslation;

      await tester.pumpTestWidget(
        MeaningEditor(
          meaning: meaning,
          onSave: ({String? primaryTranslation, String? englishDefinition}) {
            savedTranslation = primaryTranslation;
          },
          onCancel: () {},
        ),
      );

      await tester.enterText(find.byType(TextField).first, '  trimmed  ');
      await tester.pump();

      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(savedTranslation, 'trimmed');
    });
  });
}
