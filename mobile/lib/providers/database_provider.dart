import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/database.dart';
import '../data/repositories/book_repository.dart';
import '../data/repositories/highlight_repository.dart';
import '../data/repositories/sync_outbox_repository.dart';
import '../data/services/sync_service.dart';
import '../features/import/import_service.dart';
import '../features/search/services/search_service.dart';

/// Provider for the app database
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// Provider for BookRepository
final bookRepositoryProvider = Provider<BookRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return BookRepository(db);
});

/// Provider for HighlightRepository
final highlightRepositoryProvider = Provider<HighlightRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return HighlightRepository(db);
});

/// Provider for SyncOutboxRepository
final syncOutboxRepositoryProvider = Provider<SyncOutboxRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return SyncOutboxRepository(db);
});

/// Provider for SyncService
final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.watch(databaseProvider);
  final outboxRepo = ref.watch(syncOutboxRepositoryProvider);
  return SyncService(db: db, outboxRepo: outboxRepo);
});

/// Provider for ImportService
final importServiceProvider = Provider<ImportService>((ref) {
  final db = ref.watch(databaseProvider);
  final bookRepo = ref.watch(bookRepositoryProvider);
  final highlightRepo = ref.watch(highlightRepositoryProvider);
  return ImportService(
    db: db,
    bookRepo: bookRepo,
    highlightRepo: highlightRepo,
  );
});

/// Provider for SearchService
final searchServiceProvider = Provider<SearchService>((ref) {
  final highlightRepo = ref.watch(highlightRepositoryProvider);
  return SearchService(highlightRepo);
});
