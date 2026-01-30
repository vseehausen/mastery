import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/database.dart';
import '../data/repositories/book_repository.dart';
import '../data/repositories/learning_card_repository.dart';
import '../data/repositories/review_log_repository.dart';
import '../data/repositories/session_repository.dart';
import '../data/repositories/streak_repository.dart';
import '../data/repositories/sync_outbox_repository.dart';
import '../data/repositories/user_preferences_repository.dart';
import '../data/repositories/vocabulary_repository.dart';
import '../data/services/sync_service.dart';

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

/// Provider for SyncOutboxRepository
final syncOutboxRepositoryProvider = Provider<SyncOutboxRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return SyncOutboxRepository(db);
});

/// Provider for VocabularyRepository
final vocabularyRepositoryProvider = Provider<VocabularyRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return VocabularyRepository(db);
});

/// Provider for SyncService with learning data sync support
final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.watch(databaseProvider);
  final outboxRepo = ref.watch(syncOutboxRepositoryProvider);

  // Learning repositories for sync
  final learningCardRepo = LearningCardRepository(db);
  final reviewLogRepo = ReviewLogRepository(db);
  final sessionRepo = SessionRepository(db, reviewLogRepo);
  final streakRepo = StreakRepository(db);
  final userPrefsRepo = UserPreferencesRepository(db);

  return SyncService(
    db: db,
    outboxRepo: outboxRepo,
    learningCardRepository: learningCardRepo,
    sessionRepository: sessionRepo,
    streakRepository: streakRepo,
    userPreferencesRepository: userPrefsRepo,
    reviewLogRepository: reviewLogRepo,
  );
});
