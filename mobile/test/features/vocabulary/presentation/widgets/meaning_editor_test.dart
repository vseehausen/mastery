import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:mastery/domain/models/global_dictionary.dart';
import 'package:mastery/features/vocabulary/presentation/widgets/meaning_editor.dart';

import '../../../../helpers/test_helpers.dart';

GlobalDictionaryModel _createGlobalDict({
  String primaryTranslation = 'effizient',
  String englishDefinition = 'Achieving results with minimal waste.',
  String? partOfSpeech,
  List<String> synonyms = const [],
  List<String> alternativeTranslations = const [],
}) {
  return GlobalDictionaryModel(
    id: 'gd-1',
    lemma: 'effizient',
    partOfSpeech: partOfSpeech,
    englishDefinition: englishDefinition,
    translations: {
      'en': LanguageTranslations(
        primary: primaryTranslation,
        alternatives: alternativeTranslations,
      ),
    },
    synonyms: synonyms,
    antonyms: const [],
    confusables: const [],
    exampleSentences: const [],
  );
}

void main() {
  group('MeaningEditor', () {
    testWidgets('displays initial values in text fields', (tester) async {
      final globalDict = _createGlobalDict();

      await tester.pumpTestWidget(
        MeaningEditor(
          globalDict: globalDict,
          onSave:
              ({
                required String translation,
                required String definition,
                required String partOfSpeech,
                required List<String> synonyms,
                required List<String> alternativeTranslations,
              }) {},
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
      final globalDict = _createGlobalDict();

      await tester.pumpTestWidget(
        MeaningEditor(
          globalDict: globalDict,
          onSave:
              ({
                required String translation,
                required String definition,
                required String partOfSpeech,
                required List<String> synonyms,
                required List<String> alternativeTranslations,
              }) {},
          onCancel: () {},
        ),
      );

      expect(find.text('Edit Meaning'), findsOneWidget);
    });

    testWidgets('Save button disabled when no changes', (tester) async {
      final globalDict = _createGlobalDict();

      await tester.pumpTestWidget(
        MeaningEditor(
          globalDict: globalDict,
          onSave:
              ({
                required String translation,
                required String definition,
                required String partOfSpeech,
                required List<String> synonyms,
                required List<String> alternativeTranslations,
              }) {},
          onCancel: () {},
        ),
      );

      final saveButton = tester.widget<ShadButton>(find.byType(ShadButton).last);
      expect(saveButton.onPressed, isNull);
    });

    testWidgets('Save button enabled after editing translation', (
      tester,
    ) async {
      final globalDict = _createGlobalDict();

      await tester.pumpTestWidget(
        MeaningEditor(
          globalDict: globalDict,
          onSave:
              ({
                required String translation,
                required String definition,
                required String partOfSpeech,
                required List<String> synonyms,
                required List<String> alternativeTranslations,
              }) {},
          onCancel: () {},
        ),
      );

      // Edit the translation field (first TextField)
      await tester.enterText(find.byType(TextField).first, 'leistungsfähig');
      await tester.pump();

      final saveButton = tester.widget<ShadButton>(find.byType(ShadButton).last);
      expect(saveButton.onPressed, isNotNull);
    });

    testWidgets('Save button enabled after editing definition', (tester) async {
      final globalDict = _createGlobalDict();

      await tester.pumpTestWidget(
        MeaningEditor(
          globalDict: globalDict,
          onSave:
              ({
                required String translation,
                required String definition,
                required String partOfSpeech,
                required List<String> synonyms,
                required List<String> alternativeTranslations,
              }) {},
          onCancel: () {},
        ),
      );

      // Edit the definition field (second TextField - at index 1)
      final textFields = find.byType(TextField);
      expect(textFields, findsAtLeastNWidgets(2));
      await tester.enterText(textFields.at(1), 'New definition.');
      await tester.pump();

      final saveButton = tester.widget<ShadButton>(find.byType(ShadButton).last);
      expect(saveButton.onPressed, isNotNull);
    });

    testWidgets('onSave called with changed translation', (tester) async {
      final globalDict = _createGlobalDict();
      String? savedTranslation;

      await tester.pumpTestWidget(
        MeaningEditor(
          globalDict: globalDict,
          onSave:
              ({
                required String translation,
                required String definition,
                required String partOfSpeech,
                required List<String> synonyms,
                required List<String> alternativeTranslations,
              }) {
                savedTranslation = translation;
              },
          onCancel: () {},
        ),
      );

      await tester.enterText(find.byType(TextField).first, 'leistungsfähig');
      await tester.pump();

      await tester.tap(find.text('Save Changes'));
      await tester.pump();

      expect(savedTranslation, 'leistungsfähig');
    });

    testWidgets('onSave called with changed definition', (tester) async {
      final globalDict = _createGlobalDict();
      String? savedDefinition;

      await tester.pumpTestWidget(
        MeaningEditor(
          globalDict: globalDict,
          onSave:
              ({
                required String translation,
                required String definition,
                required String partOfSpeech,
                required List<String> synonyms,
                required List<String> alternativeTranslations,
              }) {
                savedDefinition = definition;
              },
          onCancel: () {},
        ),
      );

      await tester.enterText(find.byType(TextField).at(1), 'Updated def.');
      await tester.pump();

      await tester.tap(find.text('Save Changes'));
      await tester.pump();

      expect(savedDefinition, 'Updated def.');
    });

    testWidgets('onSave called with all fields', (tester) async {
      final globalDict = _createGlobalDict();
      String? savedTranslation;
      String? savedDefinition;

      await tester.pumpTestWidget(
        MeaningEditor(
          globalDict: globalDict,
          onSave:
              ({
                required String translation,
                required String definition,
                required String partOfSpeech,
                required List<String> synonyms,
                required List<String> alternativeTranslations,
              }) {
                savedTranslation = translation;
                savedDefinition = definition;
              },
          onCancel: () {},
        ),
      );

      await tester.enterText(find.byType(TextField).first, 'neu');
      await tester.enterText(find.byType(TextField).at(1), 'New def.');
      await tester.pump();

      await tester.tap(find.text('Save Changes'));
      await tester.pump();

      expect(savedTranslation, 'neu');
      expect(savedDefinition, 'New def.');
    });

    testWidgets('onCancel called when Cancel tapped', (tester) async {
      final globalDict = _createGlobalDict();
      var cancelCalled = false;

      await tester.pumpTestWidget(
        MeaningEditor(
          globalDict: globalDict,
          onSave:
              ({
                required String translation,
                required String definition,
                required String partOfSpeech,
                required List<String> synonyms,
                required List<String> alternativeTranslations,
              }) {},
          onCancel: () => cancelCalled = true,
        ),
      );

      await tester.tap(find.text('Cancel'));
      expect(cancelCalled, isTrue);
    });

    testWidgets('trims whitespace on save', (tester) async {
      final globalDict = _createGlobalDict();
      String? savedTranslation;

      await tester.pumpTestWidget(
        MeaningEditor(
          globalDict: globalDict,
          onSave:
              ({
                required String translation,
                required String definition,
                required String partOfSpeech,
                required List<String> synonyms,
                required List<String> alternativeTranslations,
              }) {
                savedTranslation = translation;
              },
          onCancel: () {},
        ),
      );

      await tester.enterText(find.byType(TextField).first, '  trimmed  ');
      await tester.pump();

      await tester.tap(find.text('Save Changes'));
      await tester.pump();

      expect(savedTranslation, 'trimmed');
    });

    testWidgets('displays part of speech label', (tester) async {
      final globalDict = _createGlobalDict(partOfSpeech: 'noun');

      await tester.pumpTestWidget(
        MeaningEditor(
          globalDict: globalDict,
          onSave:
              ({
                required String translation,
                required String definition,
                required String partOfSpeech,
                required List<String> synonyms,
                required List<String> alternativeTranslations,
              }) {},
          onCancel: () {},
        ),
      );

      expect(find.text('PART OF SPEECH'), findsOneWidget);
    });

    testWidgets('displays synonyms when provided', (tester) async {
      final globalDict = _createGlobalDict(synonyms: ['schnell', 'rasch']);

      await tester.pumpTestWidget(
        MeaningEditor(
          globalDict: globalDict,
          onSave:
              ({
                required String translation,
                required String definition,
                required String partOfSpeech,
                required List<String> synonyms,
                required List<String> alternativeTranslations,
              }) {},
          onCancel: () {},
        ),
      );

      expect(find.text('schnell'), findsOneWidget);
      expect(find.text('rasch'), findsOneWidget);
    });

    testWidgets('displays alternative translations when provided', (
      tester,
    ) async {
      final globalDict = _createGlobalDict(
        alternativeTranslations: ['powerful', 'capable'],
      );

      await tester.pumpTestWidget(
        MeaningEditor(
          globalDict: globalDict,
          onSave:
              ({
                required String translation,
                required String definition,
                required String partOfSpeech,
                required List<String> synonyms,
                required List<String> alternativeTranslations,
              }) {},
          onCancel: () {},
        ),
      );

      expect(find.text('powerful'), findsOneWidget);
      expect(find.text('capable'), findsOneWidget);
    });

    testWidgets('adding synonym via tag editor enables save button', (
      tester,
    ) async {
      final globalDict = _createGlobalDict(synonyms: ['fast']);

      await tester.pumpTestWidget(
        MeaningEditor(
          globalDict: globalDict,
          onSave:
              ({
                required String translation,
                required String definition,
                required String partOfSpeech,
                required List<String> synonyms,
                required List<String> alternativeTranslations,
              }) {},
          onCancel: () {},
        ),
      );

      // Find the Synonyms TextField (first tag editor, third TextField overall)
      final synonymTextField = find.byType(TextField).at(2);
      await tester.enterText(synonymTextField, 'quick');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      // Verify save button is enabled
      final saveButton = tester.widget<ShadButton>(find.byType(ShadButton).last);
      expect(saveButton.onPressed, isNotNull);
    });

    testWidgets('adding synonym via IconButton', (tester) async {
      final globalDict = _createGlobalDict(synonyms: ['fast']);

      await tester.pumpTestWidget(
        MeaningEditor(
          globalDict: globalDict,
          onSave:
              ({
                required String translation,
                required String definition,
                required String partOfSpeech,
                required List<String> synonyms,
                required List<String> alternativeTranslations,
              }) {},
          onCancel: () {},
        ),
      );

      // Enter text in synonyms tag editor
      final synonymTextField = find.byType(TextField).at(2);
      await tester.enterText(synonymTextField, 'quick');
      await tester.pump();

      // Tap the add button (IconButton with Icons.add)
      final addButtons = find.byIcon(Icons.add);
      expect(addButtons, findsAtLeastNWidgets(2)); // One for each tag editor
      await tester.tap(addButtons.first); // First is for synonyms
      await tester.pump();

      // Verify chip appears
      expect(find.text('quick'), findsOneWidget);
    });

    testWidgets('removing synonym chip via delete icon', (tester) async {
      final globalDict = _createGlobalDict(synonyms: ['fast']);

      await tester.pumpTestWidget(
        MeaningEditor(
          globalDict: globalDict,
          onSave:
              ({
                required String translation,
                required String definition,
                required String partOfSpeech,
                required List<String> synonyms,
                required List<String> alternativeTranslations,
              }) {},
          onCancel: () {},
        ),
      );

      // Verify chip is displayed
      expect(find.text('fast'), findsOneWidget);

      // Find and tap the delete icon on the chip
      final deleteIcon = find.byIcon(Icons.close).first;
      await tester.ensureVisible(deleteIcon);
      await tester.pumpAndSettle();
      await tester.tap(deleteIcon);
      await tester.pump();

      // Verify chip is removed
      expect(find.text('fast'), findsNothing);

      // Verify save button is enabled (change detected)
      final saveButton = tester.widget<ShadButton>(find.byType(ShadButton).last);
      expect(saveButton.onPressed, isNotNull);
    });

    testWidgets('adding alternative translation chip', (tester) async {
      final globalDict = _createGlobalDict(alternativeTranslations: ['capable']);

      await tester.pumpTestWidget(
        MeaningEditor(
          globalDict: globalDict,
          onSave:
              ({
                required String translation,
                required String definition,
                required String partOfSpeech,
                required List<String> synonyms,
                required List<String> alternativeTranslations,
              }) {},
          onCancel: () {},
        ),
      );

      // Find alternative translations TextField (second tag editor, fourth TextField overall)
      final altTransTextField = find.byType(TextField).at(3);
      await tester.enterText(altTransTextField, 'powerful');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      // Verify chip appears
      expect(find.text('powerful'), findsOneWidget);

      // Verify save button is enabled
      final saveButton = tester.widget<ShadButton>(find.byType(ShadButton).last);
      expect(saveButton.onPressed, isNotNull);
    });

    testWidgets('removing alternative translation chip', (tester) async {
      final globalDict = _createGlobalDict(alternativeTranslations: ['capable']);

      await tester.pumpTestWidget(
        MeaningEditor(
          globalDict: globalDict,
          onSave:
              ({
                required String translation,
                required String definition,
                required String partOfSpeech,
                required List<String> synonyms,
                required List<String> alternativeTranslations,
              }) {},
          onCancel: () {},
        ),
      );

      // Verify chip is displayed
      expect(find.text('capable'), findsOneWidget);

      // Find and tap the delete icon
      final deleteIcon = find.byIcon(Icons.close).first;
      await tester.ensureVisible(deleteIcon);
      await tester.pumpAndSettle();
      await tester.tap(deleteIcon);
      await tester.pump();

      // Verify chip is removed
      expect(find.text('capable'), findsNothing);

      // Verify save button is enabled
      final saveButton = tester.widget<ShadButton>(find.byType(ShadButton).last);
      expect(saveButton.onPressed, isNotNull);
    });

    testWidgets('onSave receives updated synonyms list', (tester) async {
      final globalDict = _createGlobalDict(synonyms: ['fast']);
      List<String>? savedSynonyms;

      await tester.pumpTestWidget(
        MeaningEditor(
          globalDict: globalDict,
          onSave:
              ({
                required String translation,
                required String definition,
                required String partOfSpeech,
                required List<String> synonyms,
                required List<String> alternativeTranslations,
              }) {
                savedSynonyms = synonyms;
              },
          onCancel: () {},
        ),
      );

      // Add a new synonym
      final synonymTextField = find.byType(TextField).at(2);
      await tester.enterText(synonymTextField, 'quick');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      // Save
      await tester.tap(find.text('Save Changes'));
      await tester.pump();

      // Verify saved list contains both synonyms
      expect(savedSynonyms, ['fast', 'quick']);
    });

    testWidgets('onSave receives updated alternative translations list', (
      tester,
    ) async {
      final globalDict = _createGlobalDict(alternativeTranslations: ['capable']);
      List<String>? savedAlternatives;

      await tester.pumpTestWidget(
        MeaningEditor(
          globalDict: globalDict,
          onSave:
              ({
                required String translation,
                required String definition,
                required String partOfSpeech,
                required List<String> synonyms,
                required List<String> alternativeTranslations,
              }) {
                savedAlternatives = alternativeTranslations;
              },
          onCancel: () {},
        ),
      );

      // Add a new alternative translation
      final altTransTextField = find.byType(TextField).at(3);
      await tester.enterText(altTransTextField, 'powerful');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      // Save
      await tester.tap(find.text('Save Changes'));
      await tester.pump();

      // Verify saved list contains both translations
      expect(savedAlternatives, ['capable', 'powerful']);
    });

    testWidgets(
      'save button disabled when removing and re-adding same synonym',
      (tester) async {
        final globalDict = _createGlobalDict(synonyms: ['fast']);

        await tester.pumpTestWidget(
          MeaningEditor(
            globalDict: globalDict,
            onSave:
                ({
                  required String translation,
                  required String definition,
                  required String partOfSpeech,
                  required List<String> synonyms,
                  required List<String> alternativeTranslations,
                }) {},
            onCancel: () {},
          ),
        );

        // Remove the existing synonym
        final deleteIcon = find.byIcon(Icons.close).first;
        await tester.tap(deleteIcon);
        await tester.pump();

        // Add it back
        final synonymTextField = find.byType(TextField).at(2);
        await tester.enterText(synonymTextField, 'fast');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();

        // Verify save button is disabled (no net change)
        final saveButton = tester.widget<ShadButton>(
          find.byType(ShadButton).last,
        );
        expect(saveButton.onPressed, isNull);
      },
    );
  });
}
