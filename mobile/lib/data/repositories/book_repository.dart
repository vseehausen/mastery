import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/database.dart';

/// Repository for Book entity operations
class BookRepository {
  BookRepository(this._db);

  final AppDatabase _db;
  final _uuid = const Uuid();

  /// Find book by title and author for a user
  Future<Book?> findByTitleAndAuthor({
    required String userId,
    required String title,
    String? author,
  }) async {
    final query = _db.select(_db.books)
      ..where((b) => b.userId.equals(userId))
      ..where((b) => b.title.equals(title))
      ..where((b) => b.deletedAt.isNull());

    if (author != null) {
      query.where((b) => b.author.equals(author));
    } else {
      query.where((b) => b.author.isNull());
    }

    return query.getSingleOrNull();
  }

  /// Create a new book
  Future<Book> create({
    required String userId,
    required String title,
    String? author,
    String? languageId,
    String? asin,
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();

    final companion = BooksCompanion.insert(
      id: id,
      userId: userId,
      title: title,
      author: Value(author),
      languageId: Value(languageId),
      asin: Value(asin),
      createdAt: now,
      updatedAt: now,
      isPendingSync: const Value(true),
    );

    await _db.into(_db.books).insert(companion);
    return (_db.select(_db.books)
          ..where((b) => b.id.equals(id)))
        .getSingle();
  }

  /// Find or create book
  Future<Book> findOrCreate({
    required String userId,
    required String title,
    String? author,
    String? languageId,
  }) async {
    final existing = await findByTitleAndAuthor(
      userId: userId,
      title: title,
      author: author,
    );

    if (existing != null) return existing;

    return create(
      userId: userId,
      title: title,
      author: author,
      languageId: languageId,
    );
  }

  /// Get all books for a user
  Future<List<Book>> getAllForUser(String userId) async {
    return (_db.select(_db.books)
          ..where((b) => b.userId.equals(userId))
          ..where((b) => b.deletedAt.isNull())
          ..orderBy([(b) => OrderingTerm.desc(b.updatedAt)]))
        .get();
  }

  /// Get book by ID
  Future<Book?> getById(String id) async {
    return (_db.select(_db.books)..where((b) => b.id.equals(id)))
        .getSingleOrNull();
  }

  /// Update book's highlight count
  Future<void> updateHighlightCount(String bookId, int delta) async {
    final book = await getById(bookId);
    if (book == null) return;

    await (_db.update(_db.books)..where((b) => b.id.equals(bookId))).write(
      BooksCompanion(
        highlightCount: Value(book.highlightCount + delta),
        updatedAt: Value(DateTime.now()),
        isPendingSync: const Value(true),
      ),
    );
  }

  /// Increment highlight count
  Future<void> incrementHighlightCount(String bookId) async {
    final book = await getById(bookId);
    if (book == null) return;

    await (_db.update(_db.books)..where((b) => b.id.equals(bookId))).write(
      BooksCompanion(
        highlightCount: Value(book.highlightCount + 1),
        updatedAt: Value(DateTime.now()),
        isPendingSync: const Value(true),
      ),
    );
  }

  /// Soft delete a book
  Future<void> softDelete(String id) async {
    await (_db.update(_db.books)..where((b) => b.id.equals(id))).write(
      BooksCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
        isPendingSync: const Value(true),
      ),
    );
  }

  /// Get books pending sync
  Future<List<Book>> getPendingSync(String userId) async {
    return (_db.select(_db.books)
          ..where((b) => b.userId.equals(userId))
          ..where((b) => b.isPendingSync.equals(true)))
        .get();
  }

  /// Mark book as synced
  Future<void> markSynced(String id) async {
    await (_db.update(_db.books)..where((b) => b.id.equals(id))).write(
      BooksCompanion(
        isPendingSync: const Value(false),
        lastSyncedAt: Value(DateTime.now()),
      ),
    );
  }
}
