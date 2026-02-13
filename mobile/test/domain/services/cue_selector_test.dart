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
      String? encounterContext,
      bool hasConfusables = false,
      List<Map<String, dynamic>>? exampleSentences,
      List<Map<String, dynamic>>? usageExamples,
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
        'stem': 'house',
        'english_definition': 'A building for human habitation',
        'part_of_speech': 'noun',
        'synonyms': ['home', 'dwelling'],
        'antonyms': <String>[],
        'confusables': hasConfusables
            ? [
                {
                  'word': 'horse',
                  'disambiguation_sentence': {
                    'sentence': 'A horse is an animal.',
                    'before': 'A ',
                    'blank': 'horse',
                    'after': ' is an animal.',
                  },
                  'disambiguation_sentences': [
                    {
                      'sentence': 'A horse is an animal.',
                      'before': 'A ',
                      'blank': 'horse',
                      'after': ' is an animal.',
                    },
                    {
                      'sentence': 'The horse galloped.',
                      'before': 'The ',
                      'blank': 'horse',
                      'after': ' galloped.',
                    },
                  ],
                  'l1_translation': 'Pferd',
                },
              ]
            : <Map<String, dynamic>>[],
        'example_sentences': exampleSentences ??
            [
              {
                'sentence': 'This is my house.',
                'before': 'This is my ',
                'blank': 'house',
                'after': '.',
              },
            ],
        'usage_examples': usageExamples ?? <Map<String, dynamic>>[],
        'pronunciation_ipa': '/haʊs/',
        'translations': {
          'de': {
            'primary': 'Haus',
            'alternatives': ['Gebäude'],
            'confusable_alternatives': ['Hase'],
          },
        },
        'cefr_level': 'A1',
        'overrides': <String, dynamic>{},
        'encounter_context': encounterContext,
        'has_confusables': hasConfusables,
        'non_translation_success_count': 0,
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
      test('returns translation for new cards', () {
        final card = createCard(state: 0, stability: 0.0);

        final result = selector.selectCueType(card: card);

        expect(result, CueType.translation);
      });

      test('returns translation for learning cards with low stability', () {
        final card = createCard(state: 1, stability: 0.5);

        final result = selector.selectCueType(card: card);

        expect(result, CueType.translation);
      });

      group('growing cards', () {
        late SessionCard growingCard;

        setUp(() {
          growingCard = createCard(state: 2, stability: 10.0);
        });

        test('selects from growing weights', () {
          final results = <CueType>{};
          for (var i = 0; i < 100; i++) {
            final localSelector = CueSelector(random: Random(i));
            final result = localSelector.selectCueType(card: growingCard);
            results.add(result);
          }

          expect(results, contains(CueType.translation));
        });

        test('includes contextCloze when hasEncounterContext is true', () {
          final card = createCard(
            state: 2,
            stability: 10.0,
            encounterContext: 'I saw a beautiful house.',
          );

          final results = <CueType>{};
          for (var i = 0; i < 200; i++) {
            final localSelector = CueSelector(random: Random(i));
            final result = localSelector.selectCueType(card: card);
            results.add(result);
          }

          expect(results, contains(CueType.contextCloze));
        });

        test('includes novelCloze when multiple example sentences exist', () {
          final card = createCard(
            state: 2,
            stability: 10.0,
            exampleSentences: [
              {
                'sentence': 'This is my house.',
                'before': 'This is my ',
                'blank': 'house',
                'after': '.',
              },
              {
                'sentence': 'A house on the hill.',
                'before': 'A ',
                'blank': 'house',
                'after': ' on the hill.',
              },
            ],
          );

          final results = <CueType>{};
          for (var i = 0; i < 300; i++) {
            final localSelector = CueSelector(random: Random(i));
            final result = localSelector.selectCueType(card: card);
            results.add(result);
          }

          expect(results, contains(CueType.novelCloze));
        });
      });

      group('mature cards', () {
        late SessionCard matureCard;

        setUp(() {
          matureCard = createCard(state: 2, stability: 30.0);
        });

        test('selects from mature weights', () {
          final results = <CueType>{};
          for (var i = 0; i < 100; i++) {
            final localSelector = CueSelector(random: Random(i));
            final result = localSelector.selectCueType(card: matureCard);
            results.add(result);
          }

          expect(results, contains(CueType.translation));
          expect(results, contains(CueType.definition));
        });

        test('includes disambiguation when hasConfusables is true', () {
          final card = createCard(
            state: 2,
            stability: 30.0,
            hasConfusables: true,
          );

          final results = <CueType>{};
          for (var i = 0; i < 200; i++) {
            final localSelector = CueSelector(random: Random(i));
            final result = localSelector.selectCueType(card: card);
            results.add(result);
          }

          expect(results, contains(CueType.disambiguation));
        });

        test('includes usageRecognition when usage examples exist', () {
          final card = createCard(
            state: 2,
            stability: 30.0,
            usageExamples: [
              {
                'correct_sentence': {
                  'sentence': 'The house was large.',
                  'before': 'The ',
                  'blank': 'house',
                  'after': ' was large.',
                },
                'incorrect_sentences': [
                  {
                    'sentence': 'He housed the ball.',
                    'before': 'He ',
                    'blank': 'housed',
                    'after': ' the ball.',
                  },
                  {
                    'sentence': 'She house her coat.',
                    'before': 'She ',
                    'blank': 'house',
                    'after': ' her coat.',
                  },
                ],
              },
            ],
          );

          final results = <CueType>{};
          for (var i = 0; i < 200; i++) {
            final localSelector = CueSelector(random: Random(i));
            final result = localSelector.selectCueType(card: card);
            results.add(result);
          }

          expect(results, contains(CueType.usageRecognition));
        });

        test('includes contextCloze when hasEncounterContext is true', () {
          final card = createCard(
            state: 2,
            stability: 30.0,
            encounterContext: 'I saw a beautiful house.',
          );

          final results = <CueType>{};
          for (var i = 0; i < 200; i++) {
            final localSelector = CueSelector(random: Random(i));
            final result = localSelector.selectCueType(card: card);
            results.add(result);
          }

          expect(results, contains(CueType.contextCloze));
        });
      });
    });

    group('weighted random selection', () {
      test('respects weight distribution over many samples', () {
        final matureCard = createCard(state: 2, stability: 30.0);
        final counts = <CueType, int>{};

        for (var i = 0; i < 1000; i++) {
          final localSelector = CueSelector(random: Random(i));
          final result = localSelector.selectCueType(card: matureCard);
          counts[result] = (counts[result] ?? 0) + 1;
        }

        // Mature weights: translation(15), definition(20), synonym(15)
        // Total = 50 (without context/confusables/usage)
        // Expected percentages: translation ~30%, definition ~40%, synonym ~30%

        final translationPct = (counts[CueType.translation] ?? 0) / 1000 * 100;
        final definitionPct = (counts[CueType.definition] ?? 0) / 1000 * 100;
        final synonymPct = (counts[CueType.synonym] ?? 0) / 1000 * 100;

        expect(translationPct, greaterThan(15));
        expect(translationPct, lessThan(50));
        expect(definitionPct, greaterThan(25));
        expect(definitionPct, lessThan(55));
        expect(synonymPct, greaterThan(15));
        expect(synonymPct, lessThan(50));
      });
    });

    group('buildCueContent', () {
      test('contextCloze uses encounter context with regex when available', () {
        final card = createCard(encounterContext: 'I live in a beautiful house.');

        final cue = selector.buildCueContent(card, CueType.contextCloze);

        expect(cue.prompt, 'I live in a beautiful _____.');
        expect(cue.answer, 'house');
      });

      test('contextCloze uses pre-split example sentence when no encounter context', () {
        final card = createCard(encounterContext: null);

        final cue = selector.buildCueContent(card, CueType.contextCloze);

        expect(cue.prompt, 'This is my _____.');
        expect(cue.answer, 'house');
      });

      test('contextCloze falls back to translation when no context available', () {
        final cardJson = <String, dynamic>{
          'card_id': 'card-123',
          'vocabulary_id': 'vocab-456',
          'state': 2,
          'due': '2024-01-15T10:00:00.000Z',
          'stability': 21.5,
          'difficulty': 0.3,
          'reps': 10,
          'lapses': 1,
          'last_review': '2024-01-01T10:00:00.000Z',
          'is_leech': false,
          'created_at': '2023-12-01T10:00:00.000Z',
          'word': 'house',
          'stem': 'house',
          'english_definition': 'A building for human habitation',
          'part_of_speech': 'noun',
          'synonyms': ['home', 'dwelling'],
          'antonyms': <String>[],
          'confusables': <Map<String, dynamic>>[],
          'example_sentences': <Map<String, dynamic>>[],
          'usage_examples': <Map<String, dynamic>>[],
          'pronunciation_ipa': '/haʊs/',
          'translations': {
            'de': {
              'primary': 'Haus',
              'alternatives': ['Gebäude'],
            },
          },
          'cefr_level': 'A1',
          'overrides': <String, dynamic>{},
          'encounter_context': null,
          'has_confusables': false,
          'non_translation_success_count': 0,
        };

        final card = SessionCard.fromJson(cardJson);
        final cue = selector.buildCueContent(card, CueType.contextCloze);

        expect(cue.prompt, 'A building for human habitation');
        expect(cue.answer, 'Haus');
      });

      test('disambiguation uses pre-split format from confusables', () {
        final card = createCard(hasConfusables: true);

        final cue = selector.buildCueContent(card, CueType.disambiguation);

        // Should use one of the disambiguation sentences
        expect(cue.answer, 'horse');
        expect(cue.prompt, contains('_____'));
      });

      test('disambiguation falls back to definition when no confusables', () {
        final card = createCard(hasConfusables: false);

        final cue = selector.buildCueContent(card, CueType.disambiguation);

        expect(cue.prompt, 'house');
        expect(cue.answer, 'A building for human habitation');
      });

      test('translation cue uses english definition and primary translation', () {
        final card = createCard();

        final cue = selector.buildCueContent(card, CueType.translation);

        expect(cue.prompt, 'A building for human habitation');
        expect(cue.answer, 'Haus');
      });

      test('definition/synonym cue alternates between definition, translation, synonym', () {
        final card = createCard();

        // Run multiple times to see all options
        final prompts = <String>{};
        for (var i = 0; i < 100; i++) {
          final localSelector = CueSelector(random: Random(i));
          final cue = localSelector.buildCueContent(card, CueType.definition);
          prompts.add(cue.prompt);
        }

        // Should see definition, translation, and synonym as prompts
        expect(prompts, contains('A building for human habitation'));
        expect(prompts, contains('Haus'));
        expect(prompts, contains('home'));
      });

      test('definition/synonym cue always answers with the target word', () {
        final card = createCard();

        for (var i = 0; i < 20; i++) {
          final localSelector = CueSelector(random: Random(i));
          final cue = localSelector.buildCueContent(card, CueType.definition);
          expect(cue.answer, 'house');
        }
      });

      test('novelCloze uses non-first example sentence', () {
        final card = createCard(
          exampleSentences: [
            {
              'sentence': 'This is my house.',
              'before': 'This is my ',
              'blank': 'house',
              'after': '.',
            },
            {
              'sentence': 'A house on the hill.',
              'before': 'A ',
              'blank': 'house',
              'after': ' on the hill.',
            },
          ],
        );

        final cue = selector.buildCueContent(card, CueType.novelCloze);

        expect(cue.prompt, 'A _____ on the hill.');
        expect(cue.answer, 'house');
      });

      test('novelCloze falls back to definition when only one sentence', () {
        final card = createCard();

        final cue = selector.buildCueContent(card, CueType.novelCloze);

        expect(cue.prompt, 'A building for human habitation');
        expect(cue.answer, 'house');
      });

      test('usageRecognition returns correct sentence as prompt', () {
        final card = createCard(
          usageExamples: [
            {
              'correct_sentence': {
                'sentence': 'The house was large.',
                'before': 'The ',
                'blank': 'house',
                'after': ' was large.',
              },
              'incorrect_sentences': [
                {
                  'sentence': 'He housed the ball.',
                  'before': 'He ',
                  'blank': 'housed',
                  'after': ' the ball.',
                },
              ],
            },
          ],
        );

        final cue = selector.buildCueContent(card, CueType.usageRecognition);

        expect(cue.prompt, 'The house was large.');
        expect(cue.answer, 'house');
      });

      test('usageRecognition falls back when no usage examples', () {
        final card = createCard();

        final cue = selector.buildCueContent(card, CueType.usageRecognition);

        expect(cue.prompt, 'A building for human habitation');
        expect(cue.answer, 'Haus');
      });
    });
  });
}
