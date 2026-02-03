import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/domain/models/meaning.dart';
import 'package:mastery/features/vocabulary/presentation/widgets/meaning_card.dart';

import '../../../../helpers/test_helpers.dart';

MeaningModel _createMeaning({
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
  return MeaningModel(
    id: 'meaning-1',
    userId: 'user-1',
    vocabularyId: 'vocab-1',
    languageCode: 'de',
    primaryTranslation: primaryTranslation,
    alternativeTranslations: alternatives,
    englishDefinition: englishDefinition,
    extendedDefinition: extendedDefinition,
    partOfSpeech: partOfSpeech,
    synonyms: synonyms,
    confidence: confidence,
    isPrimary: isPrimary,
    isActive: true,
    sortOrder: 0,
    source: 'openai',
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('MeaningCard', () {
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

    testWidgets('shows part of speech when present', (tester) async {
      final meaning = _createMeaning(partOfSpeech: 'adjective');

      await tester.pumpTestWidget(
        MeaningCard(meaning: meaning),
      );

      expect(find.text('adjective'), findsOneWidget);
    });

    testWidgets('shows synonyms inline with dot separator', (tester) async {
      final meaning = _createMeaning(
        synonyms: ['effective', 'productive'],
      );

      await tester.pumpTestWidget(
        MeaningCard(meaning: meaning),
      );

      expect(find.textContaining('effective'), findsOneWidget);
      expect(find.textContaining('productive'), findsOneWidget);
    });

    testWidgets('respects displayMode native - hides definition',
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

    testWidgets('respects displayMode english - hides translation',
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

    testWidgets('shows Edit button when onEdit provided', (tester) async {
      final meaning = _createMeaning();

      await tester.pumpTestWidget(
        MeaningCard(meaning: meaning, onEdit: () {}),
      );

      expect(find.text('Edit'), findsOneWidget);
    });

    testWidgets('hides Edit button when onEdit not provided', (tester) async {
      final meaning = _createMeaning();

      await tester.pumpTestWidget(
        MeaningCard(meaning: meaning),
      );

      expect(find.text('Edit'), findsNothing);
    });

    testWidgets('calls onEdit when Edit tapped', (tester) async {
      var editCalled = false;
      final meaning = _createMeaning();

      await tester.pumpTestWidget(
        MeaningCard(meaning: meaning, onEdit: () => editCalled = true),
      );

      await tester.tap(find.text('Edit'));
      expect(editCalled, isTrue);
    });
  });
}
