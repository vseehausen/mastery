import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/data/database/database.dart';
import 'package:mastery/data/repositories/meaning_repository.dart';
import 'package:mastery/data/repositories/vocabulary_repository.dart';
import '../../helpers/test_helpers.dart';

void main() {
  group('MeaningRepository', () {
    late AppDatabase db;
    late MeaningRepository repository;
    late VocabularyRepository vocabRepository;

    setUp(() async {
      db = createTestDatabase();
      repository = MeaningRepository(db);
      vocabRepository = VocabularyRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    Future<String> createTestVocabulary({String userId = 'user-1'}) async {
      final vocab = await vocabRepository.create(
        userId: userId,
        word: 'test-${DateTime.now().microsecondsSinceEpoch}',
        contentHash: 'hash-${DateTime.now().microsecondsSinceEpoch}',
      );
      return vocab.id;
    }

    group('create', () {
      test('creates a meaning with required fields', () async {
        final vocabId = await createTestVocabulary();
        final meaning = await repository.create(
          userId: 'user-1',
          vocabularyId: vocabId,
          languageCode: 'de',
          primaryTranslation: 'effizient',
          englishDefinition: 'Achieving results with minimal waste.',
        );

        expect(meaning.id, isNotEmpty);
        expect(meaning.userId, 'user-1');
        expect(meaning.vocabularyId, vocabId);
        expect(meaning.languageCode, 'de');
        expect(meaning.primaryTranslation, 'effizient');
        expect(meaning.englishDefinition, 'Achieving results with minimal waste.');
        expect(meaning.isPrimary, isFalse);
        expect(meaning.isActive, isTrue);
        expect(meaning.source, 'ai');
        expect(meaning.confidence, 1.0);
      });

      test('creates a meaning with optional fields', () async {
        final vocabId = await createTestVocabulary();
        final meaning = await repository.create(
          userId: 'user-1',
          vocabularyId: vocabId,
          languageCode: 'de',
          primaryTranslation: 'effizient',
          englishDefinition: 'Achieving results with minimal waste.',
          alternativeTranslations: ['leistungsfähig', 'ressourcenschonend'],
          partOfSpeech: 'adjective',
          synonyms: ['productive', 'effective'],
          confidence: 0.95,
          isPrimary: true,
          sortOrder: 0,
          source: 'ai',
        );

        expect(meaning.isPrimary, isTrue);
        expect(meaning.confidence, 0.95);
        expect(meaning.partOfSpeech, 'adjective');
        expect(meaning.sortOrder, 0);
      });
    });

    group('getForVocabulary', () {
      test('returns all active meanings for a word', () async {
        final vocabId = await createTestVocabulary();
        await repository.create(
          userId: 'user-1',
          vocabularyId: vocabId,
          languageCode: 'de',
          primaryTranslation: 'effizient',
          englishDefinition: 'Minimal waste.',
          sortOrder: 0,
        );
        await repository.create(
          userId: 'user-1',
          vocabularyId: vocabId,
          languageCode: 'de',
          primaryTranslation: 'wirksam',
          englishDefinition: 'Producing the desired effect.',
          sortOrder: 1,
        );

        final meanings = await repository.getForVocabulary(vocabId);
        expect(meanings, hasLength(2));
        expect(meanings[0].sortOrder, 0);
        expect(meanings[1].sortOrder, 1);
      });

      test('excludes soft-deleted meanings', () async {
        final vocabId = await createTestVocabulary();
        final m = await repository.create(
          userId: 'user-1',
          vocabularyId: vocabId,
          languageCode: 'de',
          primaryTranslation: 'effizient',
          englishDefinition: 'Minimal waste.',
        );
        await repository.softDelete(m.id);

        final meanings = await repository.getForVocabulary(vocabId);
        expect(meanings, isEmpty);
      });
    });

    group('getPrimary', () {
      test('returns the primary meaning', () async {
        final vocabId = await createTestVocabulary();
        await repository.create(
          userId: 'user-1',
          vocabularyId: vocabId,
          languageCode: 'de',
          primaryTranslation: 'effizient',
          englishDefinition: 'Minimal waste.',
          isPrimary: true,
        );
        await repository.create(
          userId: 'user-1',
          vocabularyId: vocabId,
          languageCode: 'de',
          primaryTranslation: 'wirksam',
          englishDefinition: 'Desired effect.',
          isPrimary: false,
        );

        final primary = await repository.getPrimary(vocabId);
        expect(primary, isNotNull);
        expect(primary!.primaryTranslation, 'effizient');
      });

      test('returns null when no primary exists', () async {
        final vocabId = await createTestVocabulary();
        await repository.create(
          userId: 'user-1',
          vocabularyId: vocabId,
          languageCode: 'de',
          primaryTranslation: 'effizient',
          englishDefinition: 'Minimal waste.',
          isPrimary: false,
        );

        final primary = await repository.getPrimary(vocabId);
        expect(primary, isNull);
      });
    });

    group('update', () {
      test('updates specified fields only', () async {
        final vocabId = await createTestVocabulary();
        final m = await repository.create(
          userId: 'user-1',
          vocabularyId: vocabId,
          languageCode: 'de',
          primaryTranslation: 'effizient',
          englishDefinition: 'Minimal waste.',
        );

        final updated = await repository.update(
          id: m.id,
          primaryTranslation: 'leistungsfähig',
        );

        expect(updated.primaryTranslation, 'leistungsfähig');
        expect(updated.englishDefinition, 'Minimal waste.');
        expect(updated.version, m.version + 1);
      });

      test('throws when meaning not found', () async {
        expect(
          () => repository.update(id: 'nonexistent', primaryTranslation: 'x'),
          throwsA(isA<StateError>()),
        );
      });
    });

    group('pinAsPrimary', () {
      test('sets the specified meaning as primary and unsets others', () async {
        final vocabId = await createTestVocabulary();
        final m1 = await repository.create(
          userId: 'user-1',
          vocabularyId: vocabId,
          languageCode: 'de',
          primaryTranslation: 'effizient',
          englishDefinition: 'Minimal waste.',
          isPrimary: true,
        );
        final m2 = await repository.create(
          userId: 'user-1',
          vocabularyId: vocabId,
          languageCode: 'de',
          primaryTranslation: 'wirksam',
          englishDefinition: 'Desired effect.',
          isPrimary: false,
        );

        await repository.pinAsPrimary(m2.id);

        final updatedM1 = await repository.getById(m1.id);
        final updatedM2 = await repository.getById(m2.id);
        expect(updatedM1!.isPrimary, isFalse);
        expect(updatedM2!.isPrimary, isTrue);
      });
    });

    group('softDelete', () {
      test('sets deletedAt without removing the record', () async {
        final vocabId = await createTestVocabulary();
        final m = await repository.create(
          userId: 'user-1',
          vocabularyId: vocabId,
          languageCode: 'de',
          primaryTranslation: 'effizient',
          englishDefinition: 'Minimal waste.',
        );

        await repository.softDelete(m.id);

        final deleted = await repository.getById(m.id);
        expect(deleted, isNotNull);
        expect(deleted!.deletedAt, isNotNull);
      });
    });

    group('hasEnrichedMeanings', () {
      test('returns false for unenriched word', () async {
        final vocabId = await createTestVocabulary();
        final result = await repository.hasEnrichedMeanings(vocabId);
        expect(result, isFalse);
      });

      test('returns true for enriched word', () async {
        final vocabId = await createTestVocabulary();
        await repository.create(
          userId: 'user-1',
          vocabularyId: vocabId,
          languageCode: 'de',
          primaryTranslation: 'effizient',
          englishDefinition: 'Minimal waste.',
        );
        final result = await repository.hasEnrichedMeanings(vocabId);
        expect(result, isTrue);
      });
    });
  });
}
