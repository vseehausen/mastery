import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/data/database/database.dart';
import 'package:mastery/data/repositories/source_repository.dart';

import '../../helpers/test_helpers.dart';

void main() {
  late AppDatabase database;
  late SourceRepository repository;

  setUp(() async {
    database = createTestDatabase();
    repository = SourceRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('SourceRepository', () {
    group('create', () {
      test('creates a source and returns it', () async {
        final source = await repository.create(
          userId: TestData.testUserId,
          type: 'book',
          title: 'Test Book',
          author: 'Test Author',
        );

        expect(source.title, 'Test Book');
        expect(source.author, 'Test Author');
        expect(source.type, 'book');
        expect(source.userId, TestData.testUserId);
        expect(source.isPendingSync, true);
      });

      test('creates source without author', () async {
        final source = await repository.create(
          userId: TestData.testUserId,
          type: 'manual',
          title: 'No Author',
        );

        expect(source.title, 'No Author');
        expect(source.author, isNull);
      });
    });

    group('findByTypeAndTitle', () {
      test('finds source with matching type, title and author', () async {
        await repository.create(
          userId: TestData.testUserId,
          type: 'book',
          title: 'Unique Title',
          author: 'Unique Author',
        );

        final found = await repository.findByTypeAndTitle(
          userId: TestData.testUserId,
          type: 'book',
          title: 'Unique Title',
          author: 'Unique Author',
        );

        expect(found, isNotNull);
        expect(found!.title, 'Unique Title');
      });

      test('returns null when source not found', () async {
        final found = await repository.findByTypeAndTitle(
          userId: TestData.testUserId,
          type: 'book',
          title: 'Nonexistent',
          author: 'Nobody',
        );

        expect(found, isNull);
      });

      test('does not find deleted sources', () async {
        final source = await repository.create(
          userId: TestData.testUserId,
          type: 'book',
          title: 'Deleted',
          author: 'Author',
        );
        await repository.softDelete(source.id);

        final found = await repository.findByTypeAndTitle(
          userId: TestData.testUserId,
          type: 'book',
          title: 'Deleted',
          author: 'Author',
        );

        expect(found, isNull);
      });
    });

    group('findOrCreate', () {
      test('returns existing source if found', () async {
        final created = await repository.create(
          userId: TestData.testUserId,
          type: 'book',
          title: 'Existing',
          author: 'Author',
        );

        final found = await repository.findOrCreate(
          userId: TestData.testUserId,
          type: 'book',
          title: 'Existing',
          author: 'Author',
        );

        expect(found.id, created.id);
      });

      test('creates new source if not found', () async {
        final source = await repository.findOrCreate(
          userId: TestData.testUserId,
          type: 'website',
          title: 'New Source',
        );

        expect(source.title, 'New Source');
        expect(source.type, 'website');
      });
    });

    group('getAllForUser', () {
      test('returns empty list when no sources exist', () async {
        final sources = await repository.getAllForUser(TestData.testUserId);
        expect(sources, isEmpty);
      });

      test('returns only sources for specified user', () async {
        await repository.create(
          userId: 'user-1',
          type: 'book',
          title: 'User 1 Book',
        );
        await repository.create(
          userId: 'user-2',
          type: 'book',
          title: 'User 2 Book',
        );

        final user1Sources = await repository.getAllForUser('user-1');
        expect(user1Sources.length, 1);
        expect(user1Sources.first.title, 'User 1 Book');
      });

      test('excludes deleted sources', () async {
        final source = await repository.create(
          userId: TestData.testUserId,
          type: 'book',
          title: 'Deleted',
        );
        await repository.softDelete(source.id);

        final sources = await repository.getAllForUser(TestData.testUserId);
        expect(sources, isEmpty);
      });
    });

    group('markSynced', () {
      test('clears pending sync flag', () async {
        final source = await repository.create(
          userId: TestData.testUserId,
          type: 'book',
          title: 'Test',
        );
        expect(source.isPendingSync, true);

        await repository.markSynced(source.id);

        final updated = await repository.getById(source.id);
        expect(updated!.isPendingSync, false);
        expect(updated.lastSyncedAt, isNotNull);
      });
    });
  });
}
