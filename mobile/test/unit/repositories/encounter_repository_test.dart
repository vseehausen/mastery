import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/data/database/database.dart';
import 'package:mastery/data/repositories/encounter_repository.dart';
import 'package:mastery/data/repositories/source_repository.dart';
import 'package:mastery/data/repositories/vocabulary_repository.dart';

import '../../helpers/test_helpers.dart';

void main() {
  late AppDatabase database;
  late EncounterRepository encounterRepo;
  late VocabularyRepository vocabRepo;
  late SourceRepository sourceRepo;

  setUp(() async {
    database = createTestDatabase();
    encounterRepo = EncounterRepository(database);
    vocabRepo = VocabularyRepository(database);
    sourceRepo = SourceRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('EncounterRepository', () {
    group('create', () {
      test('creates an encounter and returns it', () async {
        final vocab = await vocabRepo.create(
          userId: TestData.testUserId,
          word: 'ephemeral',
          contentHash: 'hash-1',
        );

        final encounter = await encounterRepo.create(
          userId: TestData.testUserId,
          vocabularyId: vocab.id,
          context: 'The ephemeral nature of things.',
          occurredAt: DateTime.now(),
        );

        expect(encounter.vocabularyId, vocab.id);
        expect(encounter.context, 'The ephemeral nature of things.');
        expect(encounter.isPendingSync, true);
      });

      test('creates encounter with source', () async {
        final vocab = await vocabRepo.create(
          userId: TestData.testUserId,
          word: 'test',
          contentHash: 'hash-2',
        );
        final source = await sourceRepo.create(
          userId: TestData.testUserId,
          type: 'book',
          title: 'Test Book',
        );

        final encounter = await encounterRepo.create(
          userId: TestData.testUserId,
          vocabularyId: vocab.id,
          sourceId: source.id,
          context: 'Some context.',
        );

        expect(encounter.sourceId, source.id);
      });

      test('creates encounter without source', () async {
        final vocab = await vocabRepo.create(
          userId: TestData.testUserId,
          word: 'manual',
          contentHash: 'hash-3',
        );

        final encounter = await encounterRepo.create(
          userId: TestData.testUserId,
          vocabularyId: vocab.id,
        );

        expect(encounter.sourceId, isNull);
      });
    });

    group('getForVocabulary', () {
      test('returns encounters for a vocabulary item', () async {
        final vocab = await vocabRepo.create(
          userId: TestData.testUserId,
          word: 'word',
          contentHash: 'hash-1',
        );

        await encounterRepo.create(
          userId: TestData.testUserId,
          vocabularyId: vocab.id,
          context: 'Context 1',
          occurredAt: DateTime(2026, 1, 1),
        );
        await encounterRepo.create(
          userId: TestData.testUserId,
          vocabularyId: vocab.id,
          context: 'Context 2',
          occurredAt: DateTime(2026, 1, 2),
        );

        final encounters = await encounterRepo.getForVocabulary(vocab.id);
        expect(encounters.length, 2);
      });

      test('returns empty list when no encounters exist', () async {
        final encounters = await encounterRepo.getForVocabulary('nonexistent');
        expect(encounters, isEmpty);
      });
    });

    group('getMostRecentForVocabulary', () {
      test('returns the most recent encounter', () async {
        final vocab = await vocabRepo.create(
          userId: TestData.testUserId,
          word: 'word',
          contentHash: 'hash-1',
        );

        await encounterRepo.create(
          userId: TestData.testUserId,
          vocabularyId: vocab.id,
          context: 'Old context',
          occurredAt: DateTime(2026, 1, 1),
        );
        await encounterRepo.create(
          userId: TestData.testUserId,
          vocabularyId: vocab.id,
          context: 'New context',
          occurredAt: DateTime(2026, 1, 10),
        );

        final recent = await encounterRepo.getMostRecentForVocabulary(vocab.id);
        expect(recent, isNotNull);
        expect(recent!.context, 'New context');
      });

      test('returns null when no encounters exist', () async {
        final recent = await encounterRepo.getMostRecentForVocabulary(
          'nonexistent',
        );
        expect(recent, isNull);
      });
    });

    group('getForSource', () {
      test('returns encounters for a source', () async {
        final vocab = await vocabRepo.create(
          userId: TestData.testUserId,
          word: 'word',
          contentHash: 'hash-1',
        );
        final source = await sourceRepo.create(
          userId: TestData.testUserId,
          type: 'book',
          title: 'Test Book',
        );

        await encounterRepo.create(
          userId: TestData.testUserId,
          vocabularyId: vocab.id,
          sourceId: source.id,
          context: 'From book',
        );

        final encounters = await encounterRepo.getForSource(source.id);
        expect(encounters.length, 1);
        expect(encounters.first.context, 'From book');
      });
    });

    group('markSynced', () {
      test('clears pending sync flag', () async {
        final vocab = await vocabRepo.create(
          userId: TestData.testUserId,
          word: 'word',
          contentHash: 'hash-1',
        );
        final encounter = await encounterRepo.create(
          userId: TestData.testUserId,
          vocabularyId: vocab.id,
        );
        expect(encounter.isPendingSync, true);

        await encounterRepo.markSynced(encounter.id);

        final encounters = await encounterRepo.getForVocabulary(vocab.id);
        expect(encounters.first.isPendingSync, false);
        expect(encounters.first.lastSyncedAt, isNotNull);
      });
    });
  });
}
