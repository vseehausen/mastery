import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/data/database/database.dart';
import 'package:mastery/data/repositories/book_repository.dart';

import '../../helpers/test_helpers.dart';

void main() {
  late AppDatabase database;
  late BookRepository repository;

  setUp(() async {
    database = createTestDatabase();
    repository = BookRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('BookRepository', () {
    group('create', () {
      test('creates a book and returns it', () async {
        final book = await repository.create(
          userId: TestData.testUserId,
          title: 'Test Book',
          author: 'Test Author',
        );

        expect(book.title, 'Test Book');
        expect(book.author, 'Test Author');
        expect(book.userId, TestData.testUserId);
        expect(book.isPendingSync, true);
      });

      test('creates book without author', () async {
        final book = await repository.create(
          userId: TestData.testUserId,
          title: 'No Author Book',
        );

        expect(book.title, 'No Author Book');
        expect(book.author, isNull);
      });
    });

    group('findByTitleAndAuthor', () {
      test('finds book with matching title and author', () async {
        await repository.create(
          userId: TestData.testUserId,
          title: 'Unique Title',
          author: 'Unique Author',
        );

        final found = await repository.findByTitleAndAuthor(
          userId: TestData.testUserId,
          title: 'Unique Title',
          author: 'Unique Author',
        );

        expect(found, isNotNull);
        expect(found!.title, 'Unique Title');
      });

      test('returns null when book not found', () async {
        final found = await repository.findByTitleAndAuthor(
          userId: TestData.testUserId,
          title: 'Nonexistent',
          author: 'Nobody',
        );

        expect(found, isNull);
      });

      test('finds book without author when author is null', () async {
        await repository.create(
          userId: TestData.testUserId,
          title: 'No Author Book',
        );

        final found = await repository.findByTitleAndAuthor(
          userId: TestData.testUserId,
          title: 'No Author Book',
        );

        expect(found, isNotNull);
        expect(found!.author, isNull);
      });

      test('does not find deleted books', () async {
        final book = await repository.create(
          userId: TestData.testUserId,
          title: 'Deleted Book',
          author: 'Author',
        );
        await repository.softDelete(book.id);

        final found = await repository.findByTitleAndAuthor(
          userId: TestData.testUserId,
          title: 'Deleted Book',
          author: 'Author',
        );

        expect(found, isNull);
      });
    });

    group('findOrCreate', () {
      test('returns existing book if found', () async {
        final created = await repository.create(
          userId: TestData.testUserId,
          title: 'Existing Book',
          author: 'Author',
        );

        final found = await repository.findOrCreate(
          userId: TestData.testUserId,
          title: 'Existing Book',
          author: 'Author',
        );

        expect(found.id, created.id);
      });

      test('creates new book if not found', () async {
        final book = await repository.findOrCreate(
          userId: TestData.testUserId,
          title: 'New Book',
          author: 'New Author',
        );

        expect(book.title, 'New Book');
        expect(book.author, 'New Author');
      });
    });

    group('getAllForUser', () {
      test('returns empty list when no books exist', () async {
        final books = await repository.getAllForUser(TestData.testUserId);
        expect(books, isEmpty);
      });

      test('returns only books for specified user', () async {
        await repository.create(
          userId: 'user-1',
          title: 'User 1 Book',
        );
        await repository.create(
          userId: 'user-2',
          title: 'User 2 Book',
        );

        final user1Books = await repository.getAllForUser('user-1');
        expect(user1Books.length, 1);
        expect(user1Books.first.title, 'User 1 Book');
      });

      test('excludes deleted books', () async {
        final book = await repository.create(
          userId: TestData.testUserId,
          title: 'Deleted',
        );
        await repository.softDelete(book.id);

        final books = await repository.getAllForUser(TestData.testUserId);
        expect(books, isEmpty);
      });
    });

    group('getById', () {
      test('returns book when it exists', () async {
        final created = await repository.create(
          userId: TestData.testUserId,
          title: 'Test',
        );

        final found = await repository.getById(created.id);
        expect(found, isNotNull);
        expect(found!.title, 'Test');
      });

      test('returns null when book does not exist', () async {
        final found = await repository.getById('nonexistent');
        expect(found, isNull);
      });
    });

    group('softDelete', () {
      test('marks book as deleted', () async {
        final book = await repository.create(
          userId: TestData.testUserId,
          title: 'To Delete',
        );

        await repository.softDelete(book.id);

        final found = await repository.getById(book.id);
        expect(found!.deletedAt, isNotNull);
        expect(found.isPendingSync, true);
      });
    });

    group('incrementHighlightCount', () {
      test('increments highlight count by 1', () async {
        final book = await repository.create(
          userId: TestData.testUserId,
          title: 'Test',
        );
        expect(book.highlightCount, 0);

        await repository.incrementHighlightCount(book.id);

        final updated = await repository.getById(book.id);
        expect(updated!.highlightCount, 1);
      });
    });

    group('markSynced', () {
      test('clears pending sync flag', () async {
        final book = await repository.create(
          userId: TestData.testUserId,
          title: 'Test',
        );
        expect(book.isPendingSync, true);

        await repository.markSynced(book.id);

        final updated = await repository.getById(book.id);
        expect(updated!.isPendingSync, false);
        expect(updated.lastSyncedAt, isNotNull);
      });
    });
  });
}
