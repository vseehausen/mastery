import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/data/database/database.dart';
import 'package:mastery/data/repositories/vocabulary_repository.dart';

import '../../helpers/test_helpers.dart';

void main() {
  late AppDatabase database;
  late VocabularyRepository repository;

  setUp(() async {
    database = createTestDatabase();
    repository = VocabularyRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('VocabularyRepository', () {
    group('create', () {
      test('creates a vocabulary entry and returns it', () async {
        final vocab = await repository.create(
          userId: TestData.testUserId,
          word: 'ephemeral',
          contentHash: 'hash-123',
          stem: 'ephemer',
        );

        expect(vocab.word, 'ephemeral');
        expect(vocab.userId, TestData.testUserId);
        expect(vocab.stem, 'ephemer');
        expect(vocab.isPendingSync, true);
      });

      test('generates unique IDs for each entry', () async {
        final vocab1 = await repository.create(
          userId: TestData.testUserId,
          word: 'word1',
          contentHash: 'hash-1',
        );
        final vocab2 = await repository.create(
          userId: TestData.testUserId,
          word: 'word2',
          contentHash: 'hash-2',
        );

        expect(vocab1.id, isNot(vocab2.id));
      });
    });

    group('existsByContentHash', () {
      test('returns true when entry exists', () async {
        await repository.create(
          userId: TestData.testUserId,
          word: 'test',
          contentHash: 'unique-hash',
        );

        final exists = await repository.existsByContentHash(
          userId: TestData.testUserId,
          contentHash: 'unique-hash',
        );

        expect(exists, true);
      });

      test('returns false when entry does not exist', () async {
        final exists = await repository.existsByContentHash(
          userId: TestData.testUserId,
          contentHash: 'nonexistent-hash',
        );

        expect(exists, false);
      });

      test('returns false for different user', () async {
        await repository.create(
          userId: 'user-1',
          word: 'test',
          contentHash: 'shared-hash',
        );

        final exists = await repository.existsByContentHash(
          userId: 'user-2',
          contentHash: 'shared-hash',
        );

        expect(exists, false);
      });
    });

    group('getAllForUser', () {
      test('returns empty list when no vocabulary exists', () async {
        final vocab = await repository.getAllForUser(TestData.testUserId);
        expect(vocab, isEmpty);
      });

      test('returns only vocabulary for specified user', () async {
        await repository.create(
          userId: 'user-1',
          word: 'word1',
          contentHash: 'hash-1',
        );
        await repository.create(
          userId: 'user-2',
          word: 'word2',
          contentHash: 'hash-2',
        );

        final user1Vocab = await repository.getAllForUser('user-1');
        final user2Vocab = await repository.getAllForUser('user-2');

        expect(user1Vocab.length, 1);
        expect(user1Vocab.first.word, 'word1');
        expect(user2Vocab.length, 1);
        expect(user2Vocab.first.word, 'word2');
      });

      test('excludes soft-deleted entries', () async {
        final vocab = await repository.create(
          userId: TestData.testUserId,
          word: 'deleted',
          contentHash: 'hash-del',
        );
        await repository.softDelete(vocab.id);

        final allVocab = await repository.getAllForUser(TestData.testUserId);
        expect(allVocab, isEmpty);
      });
    });

    group('getById', () {
      test('returns vocabulary when it exists', () async {
        final created = await repository.create(
          userId: TestData.testUserId,
          word: 'test',
          contentHash: 'hash-123',
        );

        final found = await repository.getById(created.id);
        expect(found, isNotNull);
        expect(found!.word, 'test');
      });

      test('returns null when vocabulary does not exist', () async {
        final found = await repository.getById('nonexistent-id');
        expect(found, isNull);
      });
    });

    group('search', () {
      test('finds vocabulary matching query', () async {
        await repository.create(
          userId: TestData.testUserId,
          word: 'ephemeral',
          contentHash: 'hash-1',
        );
        await repository.create(
          userId: TestData.testUserId,
          word: 'temporary',
          contentHash: 'hash-2',
        );

        final results = await repository.search(
          userId: TestData.testUserId,
          query: 'ephem',
        );

        expect(results.length, 1);
        expect(results.first.word, 'ephemeral');
      });

      test('returns empty list for no matches', () async {
        await repository.create(
          userId: TestData.testUserId,
          word: 'test',
          contentHash: 'hash-1',
        );

        final results = await repository.search(
          userId: TestData.testUserId,
          query: 'xyz',
        );

        expect(results, isEmpty);
      });
    });

    group('softDelete', () {
      test('marks entry as deleted', () async {
        final vocab = await repository.create(
          userId: TestData.testUserId,
          word: 'test',
          contentHash: 'hash-123',
        );

        await repository.softDelete(vocab.id);

        final found = await repository.getById(vocab.id);
        expect(found!.deletedAt, isNotNull);
        expect(found.isPendingSync, true);
      });

      test('increments version on delete', () async {
        final vocab = await repository.create(
          userId: TestData.testUserId,
          word: 'test',
          contentHash: 'hash-123',
        );
        final originalVersion = vocab.version;

        await repository.softDelete(vocab.id);

        final found = await repository.getById(vocab.id);
        expect(found!.version, originalVersion + 1);
      });
    });

    group('countForUser', () {
      test('returns 0 when no vocabulary exists', () async {
        final count = await repository.countForUser(TestData.testUserId);
        expect(count, 0);
      });

      test('returns correct count', () async {
        await repository.create(
          userId: TestData.testUserId,
          word: 'word1',
          contentHash: 'hash-1',
        );
        await repository.create(
          userId: TestData.testUserId,
          word: 'word2',
          contentHash: 'hash-2',
        );

        final count = await repository.countForUser(TestData.testUserId);
        expect(count, 2);
      });

      test('excludes soft-deleted entries', () async {
        final vocab = await repository.create(
          userId: TestData.testUserId,
          word: 'deleted',
          contentHash: 'hash-1',
        );
        await repository.create(
          userId: TestData.testUserId,
          word: 'active',
          contentHash: 'hash-2',
        );
        await repository.softDelete(vocab.id);

        final count = await repository.countForUser(TestData.testUserId);
        expect(count, 1);
      });
    });

    group('markSynced', () {
      test('clears pending sync flag and sets synced timestamp', () async {
        final vocab = await repository.create(
          userId: TestData.testUserId,
          word: 'test',
          contentHash: 'hash-123',
        );
        expect(vocab.isPendingSync, true);

        await repository.markSynced(vocab.id);

        final found = await repository.getById(vocab.id);
        expect(found!.isPendingSync, false);
        expect(found.lastSyncedAt, isNotNull);
      });
    });

    group('getPendingSync', () {
      test('returns only entries pending sync', () async {
        final vocab1 = await repository.create(
          userId: TestData.testUserId,
          word: 'pending',
          contentHash: 'hash-1',
        );
        final vocab2 = await repository.create(
          userId: TestData.testUserId,
          word: 'synced',
          contentHash: 'hash-2',
        );
        await repository.markSynced(vocab2.id);

        final pending = await repository.getPendingSync(TestData.testUserId);

        expect(pending.length, 1);
        expect(pending.first.id, vocab1.id);
      });
    });
  });
}
