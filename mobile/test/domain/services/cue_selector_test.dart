import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/domain/models/cue_type.dart';
import 'package:mastery/domain/models/session_card.dart';
import 'package:mastery/domain/services/cue_selector.dart';

void main() {
  group('CueSelector', () {
    late CueSelector selector;

    /// Create a mock SessionCard with specified state and stability
    SessionCard createCard({
      int state = 2,
      double stability = 21.0,
      bool hasMeanings = true,
    }) {
      return SessionCard.fromJson({
        'card_id': 'card-123',
        'vocabulary_id': 'vocab-456',
        'state': state,
        'due': DateTime.now().toIso8601String(),
        'stability': stability,
        'difficulty': 0.3,
        'reps': 5,
        'lapses': 0,
        'last_review': DateTime.now().toIso8601String(),
        'is_leech': false,
        'created_at': DateTime.now().toIso8601String(),
        'word': 'house',
        'stem': 'hous',
        'meanings': hasMeanings
            ? [
                {
                  'id': 'meaning-1',
                  'primary_translation': 'Haus',
                  'english_definition': 'A building',
                  'synonyms': ['home'],
                  'is_primary': true,
                  'sort_order': 0,
                },
              ]
            : <Map<String, dynamic>>[],
        'cues': <Map<String, dynamic>>[],
        'has_encounter_context': false,
        'has_confusables': false,
      });
    }

    setUp(() {
      // Use a seeded random for deterministic tests
      selector = CueSelector(random: Random(42));
    });

    group('getMaturityStage', () {
      test('returns newCard for state 0', () {
        final card = createCard(state: 0, stability: 0.0);
        expect(selector.getMaturityStage(card), MaturityStage.newCard);
      });

      test('returns newCard for state 1 with stability < 1.0', () {
        final card = createCard(state: 1, stability: 0.5);
        expect(selector.getMaturityStage(card), MaturityStage.newCard);
      });

      test('returns growing for state 1 with stability >= 1.0', () {
        final card = createCard(state: 1, stability: 1.0);
        expect(selector.getMaturityStage(card), MaturityStage.growing);
      });

      test('returns growing for state 2 with stability < 21.0', () {
        final card = createCard(state: 2, stability: 10.0);
        expect(selector.getMaturityStage(card), MaturityStage.growing);
      });

      test('returns mature for state 2 with stability >= 21.0', () {
        final card = createCard(state: 2, stability: 21.0);
        expect(selector.getMaturityStage(card), MaturityStage.mature);
      });

      test('returns growing for state 3 (relearning)', () {
        final card = createCard(state: 3, stability: 5.0);
        expect(selector.getMaturityStage(card), MaturityStage.growing);
      });
    });

    group('selectCueType', () {
      test('returns translation when no meaning data', () {
        final card = createCard(state: 2, stability: 50.0);

        final result = selector.selectCueType(card: card, hasMeaning: false);

        expect(result, CueType.translation);
      });

      test('returns translation for new cards', () {
        final card = createCard(state: 0, stability: 0.0);

        final result = selector.selectCueType(card: card, hasMeaning: true);

        expect(result, CueType.translation);
      });

      test('returns translation for learning cards with low stability', () {
        final card = createCard(state: 1, stability: 0.5);

        final result = selector.selectCueType(card: card, hasMeaning: true);

        expect(result, CueType.translation);
      });

      group('growing cards', () {
        late SessionCard growingCard;

        setUp(() {
          growingCard = createCard(state: 2, stability: 10.0);
        });

        test('selects from growing weights', () {
          // Run multiple times to verify weighted selection
          final results = <CueType>{};
          for (var i = 0; i < 100; i++) {
            final localSelector = CueSelector(random: Random(i));
            final result = localSelector.selectCueType(
              card: growingCard,
              hasMeaning: true,
            );
            results.add(result);
          }

          // Growing cards should primarily get translation, definition, synonym
          expect(results, contains(CueType.translation));
          // May or may not contain definition/synonym due to weights
        });

        test('includes contextCloze when hasEncounterContext is true', () {
          final card = SessionCard.fromJson({
            'card_id': 'card-123',
            'vocabulary_id': 'vocab-456',
            'state': 2,
            'due': DateTime.now().toIso8601String(),
            'stability': 10.0,
            'difficulty': 0.3,
            'reps': 5,
            'lapses': 0,
            'is_leech': false,
            'created_at': DateTime.now().toIso8601String(),
            'word': 'house',
            'meanings': [
              {
                'id': 'm1',
                'primary_translation': 'Haus',
                'english_definition': 'building',
                'synonyms': <String>[],
                'is_primary': true,
                'sort_order': 0,
              },
            ],
            'cues': <Map<String, dynamic>>[],
            'has_encounter_context': true,
            'has_confusables': false,
          });

          // Run multiple times to potentially hit contextCloze
          final results = <CueType>{};
          for (var i = 0; i < 200; i++) {
            final localSelector = CueSelector(random: Random(i));
            final result = localSelector.selectCueType(
              card: card,
              hasMeaning: true,
              hasEncounterContext: true,
            );
            results.add(result);
          }

          // With 5% weight for contextCloze, we should see it eventually
          expect(results, contains(CueType.contextCloze));
        });
      });

      group('mature cards', () {
        late SessionCard matureCard;

        setUp(() {
          matureCard = createCard(state: 2, stability: 30.0);
        });

        test('selects from mature weights', () {
          // Run multiple times to verify weighted selection
          final results = <CueType>{};
          for (var i = 0; i < 100; i++) {
            final localSelector = CueSelector(random: Random(i));
            final result = localSelector.selectCueType(
              card: matureCard,
              hasMeaning: true,
            );
            results.add(result);
          }

          // Mature cards should get a variety of cue types
          expect(results, contains(CueType.translation));
          expect(results, contains(CueType.definition));
        });

        test('includes disambiguation when hasConfusables is true', () {
          final card = SessionCard.fromJson({
            'card_id': 'card-123',
            'vocabulary_id': 'vocab-456',
            'state': 2,
            'due': DateTime.now().toIso8601String(),
            'stability': 30.0,
            'difficulty': 0.3,
            'reps': 10,
            'lapses': 0,
            'is_leech': false,
            'created_at': DateTime.now().toIso8601String(),
            'word': 'house',
            'meanings': [
              {
                'id': 'm1',
                'primary_translation': 'Haus',
                'english_definition': 'building',
                'synonyms': <String>[],
                'is_primary': true,
                'sort_order': 0,
              },
            ],
            'cues': <Map<String, dynamic>>[],
            'has_encounter_context': false,
            'has_confusables': true,
          });

          // Run multiple times to potentially hit disambiguation
          final results = <CueType>{};
          for (var i = 0; i < 200; i++) {
            final localSelector = CueSelector(random: Random(i));
            final result = localSelector.selectCueType(
              card: card,
              hasMeaning: true,
              hasConfusables: true,
            );
            results.add(result);
          }

          // With 20% weight for disambiguation, we should see it
          expect(results, contains(CueType.disambiguation));
        });

        test('includes contextCloze when hasEncounterContext is true', () {
          final card = SessionCard.fromJson({
            'card_id': 'card-123',
            'vocabulary_id': 'vocab-456',
            'state': 2,
            'due': DateTime.now().toIso8601String(),
            'stability': 30.0,
            'difficulty': 0.3,
            'reps': 10,
            'lapses': 0,
            'is_leech': false,
            'created_at': DateTime.now().toIso8601String(),
            'word': 'house',
            'meanings': [
              {
                'id': 'm1',
                'primary_translation': 'Haus',
                'english_definition': 'building',
                'synonyms': <String>[],
                'is_primary': true,
                'sort_order': 0,
              },
            ],
            'cues': <Map<String, dynamic>>[],
            'has_encounter_context': true,
            'has_confusables': false,
          });

          // Run multiple times to potentially hit contextCloze
          final results = <CueType>{};
          for (var i = 0; i < 200; i++) {
            final localSelector = CueSelector(random: Random(i));
            final result = localSelector.selectCueType(
              card: card,
              hasMeaning: true,
              hasEncounterContext: true,
            );
            results.add(result);
          }

          // With 15% weight for contextCloze, we should see it
          expect(results, contains(CueType.contextCloze));
        });
      });
    });

    group('weighted random selection', () {
      test('respects weight distribution over many samples', () {
        final matureCard = createCard(state: 2, stability: 30.0);
        final counts = <CueType, int>{};

        // Run 1000 times to get a distribution
        for (var i = 0; i < 1000; i++) {
          final localSelector = CueSelector(random: Random(i));
          final result = localSelector.selectCueType(
            card: matureCard,
            hasMeaning: true,
          );
          counts[result] = (counts[result] ?? 0) + 1;
        }

        // Mature weights: translation(20), definition(25), synonym(20)
        // Total = 65 (without context/confusables)
        // Expected percentages: translation ~31%, definition ~38%, synonym ~31%

        final translationPct = (counts[CueType.translation] ?? 0) / 1000 * 100;
        final definitionPct = (counts[CueType.definition] ?? 0) / 1000 * 100;
        final synonymPct = (counts[CueType.synonym] ?? 0) / 1000 * 100;

        // Allow reasonable variance
        expect(translationPct, greaterThan(20));
        expect(translationPct, lessThan(45));
        expect(definitionPct, greaterThan(25));
        expect(definitionPct, lessThan(50));
        expect(synonymPct, greaterThan(20));
        expect(synonymPct, lessThan(45));
      });
    });
  });
}
