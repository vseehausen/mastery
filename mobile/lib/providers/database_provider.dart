import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/database.dart';
import '../data/repositories/encounter_repository.dart';
import '../data/repositories/learning_card_repository.dart';
import '../data/repositories/review_log_repository.dart';
import '../data/repositories/session_repository.dart';
import '../data/repositories/source_repository.dart';
import '../data/repositories/streak_repository.dart';
import '../data/repositories/sync_outbox_repository.dart';
import '../data/repositories/user_preferences_repository.dart';
import '../data/repositories/vocabulary_repository.dart';
import '../data/services/realtime_sync_service.dart';
import '../data/services/sync_service.dart';
import 'auth_provider.dart';

/// Provider for the app database
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// Provider for SourceRepository
final sourceRepositoryProvider = Provider<SourceRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return SourceRepository(db);
});

/// Provider for EncounterRepository
final encounterRepositoryProvider = Provider<EncounterRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return EncounterRepository(db);
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

/// Provider for RealtimeSyncService - auto-syncs when server data changes
final realtimeSyncServiceProvider = Provider<RealtimeSyncService?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  final syncService = ref.watch(syncServiceProvider);
  final service = RealtimeSyncService(syncService, userId);
  
  service.start();
  ref.onDispose(() => service.stop());
  
  return service;
});
