import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/repositories/confusable_set_repository.dart';
import '../data/repositories/cue_repository.dart';
import '../data/repositories/learning_card_repository.dart';
import '../data/repositories/meaning_edit_repository.dart';
import '../data/repositories/meaning_repository.dart';
import '../data/repositories/review_log_repository.dart';
import '../data/repositories/session_repository.dart';
import '../data/repositories/streak_repository.dart';
import '../data/repositories/user_preferences_repository.dart';
import '../domain/services/distractor_service.dart';
import '../domain/services/enrichment_service.dart';
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
// Meaning Graph Repository Providers (005-meaning-graph)
// =============================================================================

@Riverpod(keepAlive: true)
MeaningRepository meaningRepository(Ref ref) {
  final db = ref.watch(databaseProvider);
  return MeaningRepository(db);
}

@Riverpod(keepAlive: true)
CueRepository cueRepository(Ref ref) {
  final db = ref.watch(databaseProvider);
  return CueRepository(db);
}

@Riverpod(keepAlive: true)
ConfusableSetRepository confusableSetRepository(Ref ref) {
  final db = ref.watch(databaseProvider);
  return ConfusableSetRepository(db);
}

@Riverpod(keepAlive: true)
MeaningEditRepository meaningEditRepository(Ref ref) {
  final db = ref.watch(databaseProvider);
  return MeaningEditRepository(db);
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
  final meaningRepo = ref.watch(meaningRepositoryProvider);
  final confusableSetRepo = ref.watch(confusableSetRepositoryProvider);
  final encounterRepo = ref.watch(
      database_provider.encounterRepositoryProvider);

  return SessionPlanner(
    learningCardRepository: learningCardRepo,
    userPreferencesRepository: userPrefsRepo,
    telemetryService: telemetryService,
    srsScheduler: srsScheduler,
    meaningRepository: meaningRepo,
    confusableSetRepository: confusableSetRepo,
    encounterRepository: encounterRepo,
  );
}

@Riverpod(keepAlive: true)
DistractorService distractorService(Ref ref) {
  final vocabRepo = ref.watch(database_provider.vocabularyRepositoryProvider);
  return DistractorService(vocabRepo);
}

@Riverpod(keepAlive: true)
EnrichmentService enrichmentService(Ref ref) {
  return EnrichmentService(
    supabaseClient: Supabase.instance.client,
    meaningRepository: ref.watch(meaningRepositoryProvider),
    cueRepository: ref.watch(cueRepositoryProvider),
    confusableSetRepository: ref.watch(confusableSetRepositoryProvider),
    userPreferencesRepository: ref.watch(userPreferencesRepositoryProvider),
  );
}
