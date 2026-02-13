import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/domain/models/session_card.dart';

void main() {
  group('ClozeText', () {
    test('fromJson parses all fields correctly', () {
      final json = {
        'sentence': 'Wi-Fi has become so ubiquitous.',
        'before': 'Wi-Fi has become so ',
        'blank': 'ubiquitous',
        'after': '.',
      };

      final cloze = ClozeText.fromJson(json);

      expect(cloze.sentence, 'Wi-Fi has become so ubiquitous.');
      expect(cloze.before, 'Wi-Fi has become so ');
      expect(cloze.blank, 'ubiquitous');
      expect(cloze.after, '.');
    });

    test('fromJson handles missing fields with empty strings', () {
      final json = {
        'sentence': 'Test sentence',
      };

      final cloze = ClozeText.fromJson(json);

      expect(cloze.sentence, 'Test sentence');
      expect(cloze.before, '');
      expect(cloze.blank, '');
      expect(cloze.after, '');
    });
  });

  group('Confusable', () {
    test('fromJson parses all fields correctly', () {
      final json = {
        'word': 'affect',
        'disambiguation_sentence': {
          'sentence': 'The decision will affect everyone.',
          'before': 'The decision will ',
          'blank': 'affect',
          'after': ' everyone.',
        },
      };

      final confusable = Confusable.fromJson(json);

      expect(confusable.word, 'affect');
      expect(confusable.disambiguationSentence, isNotNull);
      expect(confusable.disambiguationSentence!.sentence,
          'The decision will affect everyone.');
      expect(confusable.disambiguationSentence!.before, 'The decision will ');
      expect(confusable.disambiguationSentence!.blank, 'affect');
      expect(confusable.disambiguationSentence!.after, ' everyone.');
    });

    test('fromJson handles missing disambiguation_sentence', () {
      final json = {
        'word': 'affect',
      };

      final confusable = Confusable.fromJson(json);

      expect(confusable.word, 'affect');
      expect(confusable.disambiguationSentence, isNull);
    });
  });

  group('LanguageTranslations', () {
    test('fromJson parses all fields correctly', () {
      final json = {
        'primary': 'Haus',
        'alternatives': ['Gebäude', 'Wohnung'],
      };

      final translations = LanguageTranslations.fromJson(json);

      expect(translations.primary, 'Haus');
      expect(translations.alternatives, ['Gebäude', 'Wohnung']);
    });

    test('fromJson handles missing primary', () {
      final json = {
        'alternatives': ['alt1'],
      };

      final translations = LanguageTranslations.fromJson(json);

      expect(translations.primary, '');
      expect(translations.alternatives, ['alt1']);
    });
  });

  group('SessionCard', () {
    late Map<String, dynamic> validJson;

    setUp(() {
      validJson = {
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
        'example_sentences': [
          {
            'sentence': 'This is my house.',
            'before': 'This is my ',
            'blank': 'house',
            'after': '.',
          },
        ],
        'pronunciation_ipa': '/haʊs/',
        'translations': {
          'de': {
            'primary': 'Haus',
            'alternatives': ['Gebäude'],
          },
        },
        'cefr_level': 'A1',
        'overrides': <String, dynamic>{},
        'encounter_context': 'I saw a beautiful house.',
        'has_confusables': false,
        'non_translation_success_count': 5,
        'lapses_last_8': 2,
        'lapses_last_12': 3,
        'hard_method_success_count': 1,
      };
    });

    test('fromJson parses all fields correctly', () {
      final card = SessionCard.fromJson(validJson);

      expect(card.cardId, 'card-123');
      expect(card.vocabularyId, 'vocab-456');
      expect(card.state, 2);
      expect(card.due, DateTime.utc(2024, 1, 15, 10));
      expect(card.stability, 21.5);
      expect(card.difficulty, 0.3);
      expect(card.reps, 10);
      expect(card.lapses, 1);
      expect(card.lastReview, DateTime.utc(2024, 1, 1, 10));
      expect(card.isLeech, false);
      expect(card.createdAt, DateTime.utc(2023, 12, 1, 10));
      expect(card.word, 'house');
      expect(card.stem, 'house');
      expect(card.englishDefinition, 'A building for human habitation');
      expect(card.partOfSpeech, 'noun');
      expect(card.synonyms, ['home', 'dwelling']);
      expect(card.antonyms, isEmpty);
      expect(card.confusables, isEmpty);
      expect(card.exampleSentences, hasLength(1));
      expect(card.exampleSentences.first.sentence, 'This is my house.');
      expect(card.exampleSentences.first.before, 'This is my ');
      expect(card.exampleSentences.first.blank, 'house');
      expect(card.exampleSentences.first.after, '.');
      expect(card.pronunciationIpa, '/haʊs/');
      expect(card.translations, hasLength(1));
      expect(card.cefrLevel, 'A1');
      expect(card.overrides, isEmpty);
      expect(card.encounterContext, 'I saw a beautiful house.');
      expect(card.hasConfusables, false);
      expect(card.nonTranslationSuccessCount, 5);
      expect(card.lapsesLast8, 2);
      expect(card.lapsesLast12, 3);
      expect(card.hardMethodSuccessCount, 1);
    });

    test('fromJson handles null optional fields', () {
      final json = {
        ...validJson,
        'last_review': null,
        'part_of_speech': null,
        'pronunciation_ipa': null,
        'cefr_level': null,
        'encounter_context': null,
        'has_confusables': null,
        'non_translation_success_count': null,
        'hard_method_success_count': null,
      };

      final card = SessionCard.fromJson(json);

      expect(card.lastReview, isNull);
      expect(card.partOfSpeech, isNull);
      expect(card.pronunciationIpa, isNull);
      expect(card.cefrLevel, isNull);
      expect(card.encounterContext, isNull);
      expect(card.hasConfusables, false);
      expect(card.nonTranslationSuccessCount, 0);
      expect(card.hardMethodSuccessCount, 0);
    });

    test('fromJson falls back lapses_last_8/12 to lapses when absent', () {
      final json = Map<String, dynamic>.from(validJson);
      json.remove('lapses_last_8');
      json.remove('lapses_last_12');

      final card = SessionCard.fromJson(json);

      // Should fall back to lapses value (1)
      expect(card.lapsesLast8, 1);
      expect(card.lapsesLast12, 1);
    });

    test('fromJson defaults hard_method_success_count to 0 when absent', () {
      final json = Map<String, dynamic>.from(validJson);
      json.remove('hard_method_success_count');

      final card = SessionCard.fromJson(json);

      expect(card.hardMethodSuccessCount, 0);
    });

    test('fromJson parses confusables correctly', () {
      final json = {
        ...validJson,
        'confusables': [
          {
            'word': 'affect',
            'disambiguation_sentences': ['Sentence 1'],
          },
        ],
        'has_confusables': true,
      };

      final card = SessionCard.fromJson(json);

      expect(card.confusables, hasLength(1));
      expect(card.confusables.first.word, 'affect');
      expect(card.hasConfusables, true);
    });

    test('displayWord returns stem', () {
      final card = SessionCard.fromJson(validJson);
      expect(card.displayWord, 'house');
    });

    test('primaryTranslation returns first translation', () {
      final card = SessionCard.fromJson(validJson);
      expect(card.primaryTranslation, 'Haus');
    });

    test('primaryTranslation uses override when present', () {
      final json = {
        ...validJson,
        'overrides': {
          'primary_translation': 'Override Translation',
        },
      };

      final card = SessionCard.fromJson(json);
      expect(card.primaryTranslation, 'Override Translation');
    });

    test('primaryTranslation returns empty string when no translations', () {
      final json = {
        ...validJson,
        'translations': <String, dynamic>{},
      };

      final card = SessionCard.fromJson(json);
      expect(card.primaryTranslation, '');
    });

    test('isNewWord returns true for state 0', () {
      final json = {...validJson, 'state': 0};
      final card = SessionCard.fromJson(json);
      expect(card.isNewWord, true);
    });

    test('isNewWord returns false for state > 0', () {
      final json = {...validJson, 'state': 2};
      final card = SessionCard.fromJson(json);
      expect(card.isNewWord, false);
    });

    test('toLearningCard converts correctly', () {
      final card = SessionCard.fromJson(validJson);
      const userId = 'user-123';

      final learningCard = card.toLearningCard(userId);

      expect(learningCard.id, card.cardId);
      expect(learningCard.userId, userId);
      expect(learningCard.vocabularyId, card.vocabularyId);
      expect(learningCard.state, card.state);
      expect(learningCard.due, card.due);
      expect(learningCard.stability, card.stability);
      expect(learningCard.difficulty, card.difficulty);
      expect(learningCard.reps, card.reps);
      expect(learningCard.lapses, card.lapses);
      expect(learningCard.lastReview, card.lastReview);
      expect(learningCard.isLeech, card.isLeech);
      expect(learningCard.createdAt, card.createdAt);
    });
  });
}
