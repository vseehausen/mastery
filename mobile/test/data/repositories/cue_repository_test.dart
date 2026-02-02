import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/data/database/database.dart';
import 'package:mastery/data/repositories/cue_repository.dart';
import 'package:mastery/data/repositories/meaning_repository.dart';
import 'package:mastery/data/repositories/vocabulary_repository.dart';
import '../../helpers/test_helpers.dart';

void main() {
  group('CueRepository', () {
    late AppDatabase db;
    late CueRepository repository;
    late MeaningRepository meaningRepository;
    late VocabularyRepository vocabRepository;

    setUp(() async {
      db = createTestDatabase();
      repository = CueRepository(db);
      meaningRepository = MeaningRepository(db);
      vocabRepository = VocabularyRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    Future<String> createTestVocabulary() async {
      final vocab = await vocabRepository.create(
        userId: 'user-1',
        word: 'test-${DateTime.now().microsecondsSinceEpoch}',
        contentHash: 'hash-${DateTime.now().microsecondsSinceEpoch}',
      );
      return vocab.id;
    }

    Future<String> createTestMeaning(String vocabId) async {
      final meaning = await meaningRepository.create(
        userId: 'user-1',
        vocabularyId: vocabId,
        languageCode: 'de',
        primaryTranslation: 'effizient',
        englishDefinition: 'Minimal waste.',
        isPrimary: true,
      );
      return meaning.id;
    }

    group('create', () {
      test('creates a cue with required fields', () async {
        final vocabId = await createTestVocabulary();
        final meaningId = await createTestMeaning(vocabId);

        final cue = await repository.create(
          userId: 'user-1',
          meaningId: meaningId,
          cueType: 'translation',
          promptText: 'effizient',
          answerText: 'efficient',
        );

        expect(cue.id, isNotEmpty);
        expect(cue.meaningId, meaningId);
        expect(cue.cueType, 'translation');
        expect(cue.promptText, 'effizient');
        expect(cue.answerText, 'efficient');
        expect(cue.hintText, isNull);
      });

      test('creates a cue with hint and metadata', () async {
        final vocabId = await createTestVocabulary();
        final meaningId = await createTestMeaning(vocabId);

        final cue = await repository.create(
          userId: 'user-1',
          meaningId: meaningId,
          cueType: 'definition',
          promptText: 'Achieving results with minimal waste.',
          answerText: 'efficient',
          hintText: 'Think about resource usage.',
          metadata: '{"category": "adjective"}',
        );

        expect(cue.hintText, 'Think about resource usage.');
        expect(cue.metadata, contains('adjective'));
      });
    });

    group('getForMeaning', () {
      test('returns all cues for a meaning', () async {
        final vocabId = await createTestVocabulary();
        final meaningId = await createTestMeaning(vocabId);

        await repository.create(
          userId: 'user-1',
          meaningId: meaningId,
          cueType: 'translation',
          promptText: 'effizient',
          answerText: 'efficient',
        );
        await repository.create(
          userId: 'user-1',
          meaningId: meaningId,
          cueType: 'definition',
          promptText: 'Minimal waste.',
          answerText: 'efficient',
        );

        final cues = await repository.getForMeaning(meaningId);
        expect(cues, hasLength(2));
      });

      test('filters by cue type', () async {
        final vocabId = await createTestVocabulary();
        final meaningId = await createTestMeaning(vocabId);

        await repository.create(
          userId: 'user-1',
          meaningId: meaningId,
          cueType: 'translation',
          promptText: 'effizient',
          answerText: 'efficient',
        );
        await repository.create(
          userId: 'user-1',
          meaningId: meaningId,
          cueType: 'definition',
          promptText: 'Minimal waste.',
          answerText: 'efficient',
        );

        final translationCues =
            await repository.getForMeaning(meaningId, cueType: 'translation');
        expect(translationCues, hasLength(1));
        expect(translationCues.first.cueType, 'translation');
      });
    });

    group('getForVocabulary', () {
      test('returns cues across all active meanings for a word', () async {
        final vocabId = await createTestVocabulary();
        final meaningId1 = await createTestMeaning(vocabId);

        // Create a second active meaning
        final meaning2 = await meaningRepository.create(
          userId: 'user-1',
          vocabularyId: vocabId,
          languageCode: 'de',
          primaryTranslation: 'wirksam',
          englishDefinition: 'Desired effect.',
          isPrimary: true,
        );

        await repository.create(
          userId: 'user-1',
          meaningId: meaningId1,
          cueType: 'translation',
          promptText: 'effizient',
          answerText: 'efficient',
        );
        await repository.create(
          userId: 'user-1',
          meaningId: meaning2.id,
          cueType: 'translation',
          promptText: 'wirksam',
          answerText: 'effective',
        );

        final cues = await repository.getForVocabulary(vocabId);
        expect(cues, hasLength(2));
      });

      test('excludes cues from inactive meanings', () async {
        final vocabId = await createTestVocabulary();

        // Create a meaning then deactivate it
        final inactiveMeaning = await meaningRepository.create(
          userId: 'user-1',
          vocabularyId: vocabId,
          languageCode: 'de',
          primaryTranslation: 'deaktiviert',
          englishDefinition: 'Inactive meaning.',
        );
        await meaningRepository.update(id: inactiveMeaning.id, isActive: false);

        await repository.create(
          userId: 'user-1',
          meaningId: inactiveMeaning.id,
          cueType: 'translation',
          promptText: 'deaktiviert',
          answerText: 'deactivated',
        );

        final cues = await repository.getForVocabulary(vocabId);
        expect(cues, isEmpty);
      });

      test('returns empty list for unenriched word', () async {
        final vocabId = await createTestVocabulary();
        final cues = await repository.getForVocabulary(vocabId);
        expect(cues, isEmpty);
      });
    });
  });
}
