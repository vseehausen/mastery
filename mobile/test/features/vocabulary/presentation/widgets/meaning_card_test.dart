import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/data/database/database.dart';
import 'package:mastery/features/vocabulary/presentation/widgets/meaning_card.dart';

import '../../../../helpers/test_helpers.dart';

Meaning _createMeaning({
  String primaryTranslation = 'effizient',
  String englishDefinition = 'Achieving results with minimal waste.',
  String? extendedDefinition,
  String? partOfSpeech,
  List<String> alternatives = const [],
  List<String> synonyms = const [],
  double confidence = 0.9,
  bool isPrimary = true,
}) {
  final now = DateTime.now();
  return Meaning(
    id: 'meaning-1',
    userId: 'user-1',
    vocabularyId: 'vocab-1',
    languageCode: 'de',
    primaryTranslation: primaryTranslation,
    alternativeTranslations: jsonEncode(alternatives),
    englishDefinition: englishDefinition,
    extendedDefinition: extendedDefinition,
    partOfSpeech: partOfSpeech,
    synonyms: jsonEncode(synonyms),
    confidence: confidence,
    isPrimary: isPrimary,
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
  group('MeaningCard', () {
    group('collapsed state', () {
      testWidgets('shows primary translation and definition', (tester) async {
        final meaning = _createMeaning();

        await tester.pumpTestWidget(
          MeaningCard(meaning: meaning),
        );

        expect(find.text('effizient'), findsOneWidget);
        expect(
          find.text('Achieving results with minimal waste.'),
          findsOneWidget,
        );
      });

      testWidgets('shows Primary badge when isPrimary', (tester) async {
        final meaning = _createMeaning(isPrimary: true);

        await tester.pumpTestWidget(
          MeaningCard(meaning: meaning),
        );

        expect(find.text('Primary'), findsOneWidget);
      });

      testWidgets('hides Primary badge when not primary', (tester) async {
        final meaning = _createMeaning(isPrimary: false);

        await tester.pumpTestWidget(
          MeaningCard(meaning: meaning),
        );

        expect(find.text('Primary'), findsNothing);
      });

      testWidgets('shows part of speech when present', (tester) async {
        final meaning = _createMeaning(partOfSpeech: 'adjective');

        await tester.pumpTestWidget(
          MeaningCard(meaning: meaning),
        );

        expect(find.text('adjective'), findsOneWidget);
      });

      testWidgets('shows low confidence indicator when < 0.6',
          (tester) async {
        final meaning = _createMeaning(confidence: 0.4);

        await tester.pumpTestWidget(
          MeaningCard(meaning: meaning),
        );

        expect(find.byIcon(Icons.info_outline), findsOneWidget);
      });

      testWidgets('hides low confidence indicator when >= 0.6',
          (tester) async {
        final meaning = _createMeaning(confidence: 0.9);

        await tester.pumpTestWidget(
          MeaningCard(meaning: meaning),
        );

        expect(find.byIcon(Icons.info_outline), findsNothing);
      });

      testWidgets('respects displayMode native — hides definition',
          (tester) async {
        final meaning = _createMeaning();

        await tester.pumpTestWidget(
          MeaningCard(meaning: meaning, displayMode: 'native'),
        );

        expect(find.text('effizient'), findsOneWidget);
        expect(
          find.text('Achieving results with minimal waste.'),
          findsNothing,
        );
      });

      testWidgets('respects displayMode english — hides translation',
          (tester) async {
        final meaning = _createMeaning();

        await tester.pumpTestWidget(
          MeaningCard(meaning: meaning, displayMode: 'english'),
        );

        expect(find.text('effizient'), findsNothing);
        expect(
          find.text('Achieving results with minimal waste.'),
          findsOneWidget,
        );
      });
    });

    group('expanded state', () {
      testWidgets('expands on tap and shows alternatives', (tester) async {
        final meaning = _createMeaning(
          alternatives: ['leistungsfähig', 'rationell', 'wirkungsvoll'],
        );

        await tester.pumpTestWidget(
          MeaningCard(meaning: meaning),
        );

        // Tap to expand
        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();

        expect(find.text('Alternatives'), findsOneWidget);
        expect(find.text('leistungsfähig'), findsOneWidget);
        expect(find.text('rationell'), findsOneWidget);
        expect(find.text('wirkungsvoll'), findsOneWidget);
      });

      testWidgets('shows +N more for alternatives exceeding 3',
          (tester) async {
        final meaning = _createMeaning(
          alternatives: ['a', 'b', 'c', 'd', 'e'],
        );

        await tester.pumpTestWidget(
          MeaningCard(meaning: meaning),
        );

        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();

        expect(find.text('+2 more'), findsOneWidget);
      });

      testWidgets('shows synonyms when present', (tester) async {
        final meaning = _createMeaning(
          synonyms: ['effective', 'productive'],
        );

        await tester.pumpTestWidget(
          MeaningCard(meaning: meaning),
        );

        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();

        expect(find.text('Synonyms'), findsOneWidget);
        expect(find.text('effective, productive'), findsOneWidget);
      });

      testWidgets('shows extended definition when present', (tester) async {
        final meaning = _createMeaning(
          extendedDefinition: 'Used to describe processes or systems.',
        );

        await tester.pumpTestWidget(
          MeaningCard(meaning: meaning),
        );

        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();

        expect(
          find.text('Used to describe processes or systems.'),
          findsOneWidget,
        );
      });

      testWidgets('shows Edit button when onEdit provided', (tester) async {
        final meaning = _createMeaning();

        await tester.pumpTestWidget(
          MeaningCard(meaning: meaning, onEdit: () {}),
        );

        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();

        expect(find.text('Edit'), findsOneWidget);
      });

      testWidgets('shows Pin button for non-primary when onPin provided',
          (tester) async {
        final meaning = _createMeaning(isPrimary: false);

        await tester.pumpTestWidget(
          MeaningCard(meaning: meaning, onPin: () {}),
        );

        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();

        expect(find.text('Pin as primary'), findsOneWidget);
      });

      testWidgets('hides Pin button for primary meaning', (tester) async {
        final meaning = _createMeaning(isPrimary: true);

        await tester.pumpTestWidget(
          MeaningCard(meaning: meaning, onPin: () {}),
        );

        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();

        expect(find.text('Pin as primary'), findsNothing);
      });

      testWidgets('calls onEdit when Edit tapped', (tester) async {
        var editCalled = false;
        final meaning = _createMeaning();

        await tester.pumpTestWidget(
          MeaningCard(meaning: meaning, onEdit: () => editCalled = true),
        );

        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Edit'));
        expect(editCalled, isTrue);
      });

      testWidgets('calls onPin when Pin tapped', (tester) async {
        var pinCalled = false;
        final meaning = _createMeaning(isPrimary: false);

        await tester.pumpTestWidget(
          MeaningCard(meaning: meaning, onPin: () => pinCalled = true),
        );

        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Pin as primary'));
        expect(pinCalled, isTrue);
      });

      testWidgets('collapses on second tap', (tester) async {
        final meaning = _createMeaning(
          synonyms: ['effective'],
        );

        await tester.pumpTestWidget(
          MeaningCard(meaning: meaning),
        );

        // Expand
        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();
        expect(find.text('Synonyms'), findsOneWidget);

        // Collapse
        await tester.tap(find.byType(InkWell).first);
        await tester.pumpAndSettle();
        expect(find.text('Synonyms'), findsNothing);
      });
    });
  });
}
