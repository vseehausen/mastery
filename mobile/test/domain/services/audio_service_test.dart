import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/domain/services/audio_service.dart';
import 'package:mastery/domain/models/session_card.dart';

void main() {
  group('AudioService', () {
    late AudioService audioService;

    setUp(() {
      audioService = AudioService();
    });

    tearDown(() {
      audioService.dispose();
    });

    test('play with null URL is a no-op', () async {
      // Should not throw
      await audioService.play(null);
    });

    test('stop when not playing does not throw', () async {
      await audioService.stop();
    });

    test('dispose does not throw', () {
      audioService.dispose();
    });

    test('prefetchForSession with empty list does not throw', () async {
      await audioService.prefetchForSession([], 'us');
    });
  });

  group('SessionCard.audioUrlFor', () {
    test('returns URL for matching accent', () {
      final card = _makeCard(audioUrls: {
        'us': 'https://example.com/us.mp3',
        'gb': 'https://example.com/gb.mp3',
      });
      expect(card.audioUrlFor('us'), 'https://example.com/us.mp3');
      expect(card.audioUrlFor('gb'), 'https://example.com/gb.mp3');
    });

    test('returns null for missing accent', () {
      final card =
          _makeCard(audioUrls: {'us': 'https://example.com/us.mp3'});
      expect(card.audioUrlFor('gb'), isNull);
    });

    test('returns null when audioUrls is null', () {
      final card = _makeCard(audioUrls: null);
      expect(card.audioUrlFor('us'), isNull);
    });
  });

  group('SessionCard.fromJson audio_urls', () {
    test('parses audio_urls from JSON', () {
      final json = {
        'card_id': 'c1',
        'vocabulary_id': 'v1',
        'state': 0,
        'due': '2026-01-01T00:00:00.000Z',
        'stability': 1.0,
        'difficulty': 0.5,
        'reps': 0,
        'lapses': 0,
        'is_leech': false,
        'created_at': '2026-01-01T00:00:00.000Z',
        'word': 'test',
        'stem': 'test',
        'english_definition': 'a test',
        'synonyms': <dynamic>[],
        'antonyms': <dynamic>[],
        'confusables': <dynamic>[],
        'example_sentences': <dynamic>[],
        'usage_examples': <dynamic>[],
        'translations': <String, dynamic>{},
        'overrides': <String, dynamic>{},
        'audio_urls': {'us': 'https://example.com/us.mp3', 'gb': 'https://example.com/gb.mp3'},
      };
      final card = SessionCard.fromJson(json);
      expect(card.audioUrls, {'us': 'https://example.com/us.mp3', 'gb': 'https://example.com/gb.mp3'});
      expect(card.audioUrlFor('us'), 'https://example.com/us.mp3');
      expect(card.audioUrlFor('gb'), 'https://example.com/gb.mp3');
    });

    test('audio_urls defaults to null when missing from JSON', () {
      final json = {
        'card_id': 'c1',
        'vocabulary_id': 'v1',
        'state': 0,
        'due': '2026-01-01T00:00:00.000Z',
        'stability': 1.0,
        'difficulty': 0.5,
        'reps': 0,
        'lapses': 0,
        'is_leech': false,
        'created_at': '2026-01-01T00:00:00.000Z',
        'word': 'test',
        'stem': 'test',
        'english_definition': 'a test',
        'synonyms': <dynamic>[],
        'antonyms': <dynamic>[],
        'confusables': <dynamic>[],
        'example_sentences': <dynamic>[],
        'usage_examples': <dynamic>[],
        'translations': <String, dynamic>{},
        'overrides': <String, dynamic>{},
      };
      final card = SessionCard.fromJson(json);
      expect(card.audioUrls, isNull);
      expect(card.audioUrlFor('us'), isNull);
    });
  });
}

SessionCard _makeCard({Map<String, String>? audioUrls}) {
  return SessionCard(
    cardId: 'test-card',
    vocabularyId: 'test-vocab',
    state: 0,
    due: DateTime.now(),
    stability: 1.0,
    difficulty: 0.5,
    reps: 0,
    lapses: 0,
    isLeech: false,
    createdAt: DateTime.now(),
    word: 'test',
    stem: 'test',
    englishDefinition: 'a test word',
    synonyms: [],
    antonyms: [],
    confusables: [],
    exampleSentences: [],
    usageExamples: [],
    translations: {},
    overrides: {},
    hasConfusables: false,
    nonTranslationSuccessCount: 0,
    lapsesLast8: 0,
    lapsesLast12: 0,
    hardMethodSuccessCount: 0,
    audioUrls: audioUrls,
  );
}
