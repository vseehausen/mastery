import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/repositories/learning_card_repository.dart';
import '../data/repositories/review_log_repository.dart';
import '../data/repositories/session_repository.dart';
import '../data/repositories/streak_repository.dart';
import '../data/repositories/user_preferences_repository.dart';
import '../domain/services/distractor_service.dart';
import '../domain/services/session_planner.dart';
import '../domain/services/srs_scheduler.dart';
import '../domain/services/telemetry_service.dart';
import 'database_provider.dart' as database_provider;
import 'database_provider.dart' show databaseProvider;

part 'learning_providers.g.dart';

// =============================================================================
// Repository Providers
// =============================================================================

@Riverpod(keepAlive: true)
LearningCardRepository learningCardRepository(Ref ref) {
  final db = ref.watch(databaseProvider);
  return LearningCardRepository(db);
}

@Riverpod(keepAlive: true)
ReviewLogRepository reviewLogRepository(Ref ref) {
  final db = ref.watch(databaseProvider);
  return ReviewLogRepository(db);
}

@Riverpod(keepAlive: true)
SessionRepository sessionRepository(Ref ref) {
  final db = ref.watch(databaseProvider);
  final reviewLogRepo = ref.watch(reviewLogRepositoryProvider);
  return SessionRepository(db, reviewLogRepo);
}

@Riverpod(keepAlive: true)
StreakRepository streakRepository(Ref ref) {
  final db = ref.watch(databaseProvider);
  return StreakRepository(db);
}

@Riverpod(keepAlive: true)
UserPreferencesRepository userPreferencesRepository(Ref ref) {
  final db = ref.watch(databaseProvider);
  return UserPreferencesRepository(db);
}

// =============================================================================
// Service Providers
// =============================================================================

@riverpod
SrsScheduler srsScheduler(Ref ref, {double targetRetention = 0.90}) {
  return SrsScheduler(targetRetention: targetRetention);
}

@Riverpod(keepAlive: true)
TelemetryService telemetryService(Ref ref) {
  final reviewLogRepo = ref.watch(reviewLogRepositoryProvider);
  return TelemetryService(reviewLogRepo);
}

@Riverpod(keepAlive: true)
SessionPlanner sessionPlanner(Ref ref) {
  final learningCardRepo = ref.watch(learningCardRepositoryProvider);
  final userPrefsRepo = ref.watch(userPreferencesRepositoryProvider);
  final telemetryService = ref.watch(telemetryServiceProvider);
  final srsScheduler = ref.watch(srsSchedulerProvider());

  return SessionPlanner(
    learningCardRepository: learningCardRepo,
    userPreferencesRepository: userPrefsRepo,
    telemetryService: telemetryService,
    srsScheduler: srsScheduler,
  );
}

@Riverpod(keepAlive: true)
DistractorService distractorService(Ref ref) {
  final vocabRepo = ref.watch(database_provider.vocabularyRepositoryProvider);
  return DistractorService(vocabRepo);
}
