import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/domain/models/cue_type.dart';
import 'package:mastery/domain/models/session_card.dart';

void main() {
  group('SessionMeaning', () {
    test('fromJson parses all fields correctly', () {
      final json = {
        'id': 'meaning-123',
        'primary_translation': 'Haus',
        'english_definition': 'A building for human habitation',
        'extended_definition': 'A structure serving as a dwelling',
        'part_of_speech': 'noun',
        'synonyms': ['home', 'dwelling', 'residence'],
        'is_primary': true,
        'sort_order': 0,
      };

      final meaning = SessionMeaning.fromJson(json);

      expect(meaning.id, 'meaning-123');
      expect(meaning.primaryTranslation, 'Haus');
      expect(meaning.englishDefinition, 'A building for human habitation');
      expect(meaning.extendedDefinition, 'A structure serving as a dwelling');
      expect(meaning.partOfSpeech, 'noun');
      expect(meaning.synonyms, ['home', 'dwelling', 'residence']);
      expect(meaning.isPrimary, true);
      expect(meaning.sortOrder, 0);
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'meaning-123',
        'primary_translation': 'Haus',
        'english_definition': 'A building',
        'extended_definition': null,
        'part_of_speech': null,
        'synonyms': null,
        'is_primary': null,
        'sort_order': null,
      };

      final meaning = SessionMeaning.fromJson(json);

      expect(meaning.extendedDefinition, isNull);
      expect(meaning.partOfSpeech, isNull);
      expect(meaning.synonyms, isEmpty);
      expect(meaning.isPrimary, false);
      expect(meaning.sortOrder, 0);
    });

    test('fromJson handles empty synonyms list', () {
      final json = {
        'id': 'meaning-123',
        'primary_translation': 'Haus',
        'english_definition': 'A building',
        'synonyms': <String>[],
      };

      final meaning = SessionMeaning.fromJson(json);

      expect(meaning.synonyms, isEmpty);
    });
  });

  group('SessionCue', () {
    test('fromJson parses all fields correctly', () {
      final json = {
        'id': 'cue-123',
        'meaning_id': 'meaning-456',
        'cue_type': 'translation',
        'prompt_text': 'What is the German word for house?',
        'answer_text': 'Haus',
        'hint_text': 'Starts with H',
      };

      final cue = SessionCue.fromJson(json);

      expect(cue.id, 'cue-123');
      expect(cue.meaningId, 'meaning-456');
      expect(cue.cueType, CueType.translation);
      expect(cue.promptText, 'What is the German word for house?');
      expect(cue.answerText, 'Haus');
      expect(cue.hintText, 'Starts with H');
    });

    test('fromJson handles null hint text', () {
      final json = {
        'id': 'cue-123',
        'meaning_id': 'meaning-456',
        'cue_type': 'definition',
        'prompt_text': 'A building for habitation',
        'answer_text': 'house',
        'hint_text': null,
      };

      final cue = SessionCue.fromJson(json);

      expect(cue.hintText, isNull);
      expect(cue.cueType, CueType.definition);
    });

    test('fromJson parses all cue types', () {
      final cueTypes = [
        ('translation', CueType.translation),
        ('definition', CueType.definition),
        ('synonym', CueType.synonym),
        ('context_cloze', CueType.contextCloze),
        ('disambiguation', CueType.disambiguation),
      ];

      for (final (dbString, expectedType) in cueTypes) {
        final json = {
          'id': 'cue-123',
          'meaning_id': 'meaning-456',
          'cue_type': dbString,
          'prompt_text': 'prompt',
          'answer_text': 'answer',
        };

        final cue = SessionCue.fromJson(json);
        expect(cue.cueType, expectedType, reason: 'Failed for $dbString');
      }
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
        'stem': 'hous',
        'meanings': [
          {
            'id': 'meaning-1',
            'primary_translation': 'Haus',
            'english_definition': 'A building for habitation',
            'synonyms': ['home'],
            'is_primary': true,
            'sort_order': 0,
          },
          {
            'id': 'meaning-2',
            'primary_translation': 'Zuhause',
            'english_definition': 'A place of residence',
            'synonyms': <String>[],
            'is_primary': false,
            'sort_order': 1,
          },
        ],
        'cues': [
          {
            'id': 'cue-1',
            'meaning_id': 'meaning-1',
            'cue_type': 'translation',
            'prompt_text': 'What is house in German?',
            'answer_text': 'Haus',
          },
          {
            'id': 'cue-2',
            'meaning_id': 'meaning-1',
            'cue_type': 'definition',
            'prompt_text': 'A building for habitation',
            'answer_text': 'house',
          },
        ],
        'has_encounter_context': true,
        'has_confusables': false,
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
      expect(card.stem, 'hous');
      expect(card.meanings, hasLength(2));
      expect(card.cues, hasLength(2));
      expect(card.hasEncounterContext, true);
      expect(card.hasConfusables, false);
    });

    test('fromJson handles null optional fields', () {
      final json = {
        ...validJson,
        'last_review': null,
        'stem': null,
        'has_encounter_context': null,
        'has_confusables': null,
      };

      final card = SessionCard.fromJson(json);

      expect(card.lastReview, isNull);
      expect(card.stem, isNull);
      expect(card.hasEncounterContext, false);
      expect(card.hasConfusables, false);
    });

    test('fromJson handles empty meanings and cues', () {
      final json = {
        ...validJson,
        'meanings': <Map<String, dynamic>>[],
        'cues': <Map<String, dynamic>>[],
      };

      final card = SessionCard.fromJson(json);

      expect(card.meanings, isEmpty);
      expect(card.cues, isEmpty);
      expect(card.hasMeaning, false);
    });

    test('fromJson handles null meanings and cues', () {
      final json = {...validJson, 'meanings': null, 'cues': null};

      final card = SessionCard.fromJson(json);

      expect(card.meanings, isEmpty);
      expect(card.cues, isEmpty);
    });

    test('hasMeaning returns true when meanings exist', () {
      final card = SessionCard.fromJson(validJson);
      expect(card.hasMeaning, true);
    });

    test('primaryMeaning returns meaning with isPrimary=true', () {
      final card = SessionCard.fromJson(validJson);

      final primary = card.primaryMeaning;

      expect(primary, isNotNull);
      expect(primary!.id, 'meaning-1');
      expect(primary.isPrimary, true);
    });

    test('primaryMeaning returns first meaning when none is primary', () {
      final json = {
        ...validJson,
        'meanings': [
          {
            'id': 'meaning-1',
            'primary_translation': 'Haus',
            'english_definition': 'A building',
            'synonyms': <String>[],
            'is_primary': false,
            'sort_order': 0,
          },
          {
            'id': 'meaning-2',
            'primary_translation': 'Zuhause',
            'english_definition': 'Home',
            'synonyms': <String>[],
            'is_primary': false,
            'sort_order': 1,
          },
        ],
      };

      final card = SessionCard.fromJson(json);

      expect(card.primaryMeaning, isNotNull);
      expect(card.primaryMeaning!.id, 'meaning-1');
    });

    test('primaryMeaning returns null when no meanings', () {
      final json = {...validJson, 'meanings': <Map<String, dynamic>>[]};

      final card = SessionCard.fromJson(json);

      expect(card.primaryMeaning, isNull);
    });

    test('getCue returns cue by type', () {
      final card = SessionCard.fromJson(validJson);

      final translationCue = card.getCue(CueType.translation);
      final definitionCue = card.getCue(CueType.definition);
      final synonymCue = card.getCue(CueType.synonym);

      expect(translationCue, isNotNull);
      expect(translationCue!.id, 'cue-1');
      expect(definitionCue, isNotNull);
      expect(definitionCue!.id, 'cue-2');
      expect(synonymCue, isNull);
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
