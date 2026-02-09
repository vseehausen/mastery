import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/services/supabase_data_service.dart';
import '../domain/models/cue.dart';
import '../domain/models/encounter.dart';
import '../domain/models/learning_card.dart';
import '../domain/models/learning_session.dart';
import '../domain/models/meaning.dart';
import '../domain/models/progress_stage.dart';
import '../domain/models/source.dart';
import '../domain/models/streak.dart';
import '../domain/models/user_preferences.dart';
import '../domain/models/vocabulary.dart';
import 'auth_provider.dart';

// =============================================================================
// Core Service Provider
// =============================================================================

/// Provider for the Supabase data service
final supabaseDataServiceProvider = Provider<SupabaseDataService>((ref) {
  return SupabaseDataService(Supabase.instance.client);
});

// =============================================================================
// Vocabulary Providers
// =============================================================================

/// Provider for all vocabulary of the current user (sorted newest first)
final vocabularyListProvider =
    FutureProvider.autoDispose<List<VocabularyModel>>((ref) async {
      final userId = ref.watch(currentUserIdProvider);
      if (userId == null) return [];

      final service = ref.watch(supabaseDataServiceProvider);
      final data = await service.getVocabulary(userId);
      return data.map(VocabularyModel.fromJson).toList();
    });

/// Provider for a single vocabulary entry by ID
final vocabularyByIdProvider = FutureProvider.autoDispose
    .family<VocabularyModel?, String>((ref, id) async {
      final service = ref.watch(supabaseDataServiceProvider);
      final data = await service.getVocabularyById(id);
      if (data == null) return null;
      return VocabularyModel.fromJson(data);
    });

/// Provider for vocabulary count
final vocabularyCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return 0;

  final service = ref.watch(supabaseDataServiceProvider);
  return service.countVocabulary(userId);
});

/// Provider for searching vocabulary
final vocabularySearchProvider = FutureProvider.autoDispose
    .family<List<VocabularyModel>, String>((ref, query) async {
      final userId = ref.watch(currentUserIdProvider);
      if (userId == null) return [];
      if (query.isEmpty) return [];

      final service = ref.watch(supabaseDataServiceProvider);
      final data = await service.searchVocabulary(userId, query);
      return data.map(VocabularyModel.fromJson).toList();
    });

/// Provider for set of vocabulary IDs that have meanings (are enriched)
final enrichedVocabularyIdsProvider = FutureProvider.autoDispose<Set<String>>((
  ref,
) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return <String>{};

  final service = ref.watch(supabaseDataServiceProvider);
  final list = await service.getEnrichedVocabularyIds(userId);
  return list.toSet();
});

/// Provider for vocabulary counts grouped by progress stage
final vocabularyStageCountsProvider =
    FutureProvider.autoDispose<Map<ProgressStage, int>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return {};
  final service = ref.watch(supabaseDataServiceProvider);
  return service.getVocabularyStageCounts(userId);
});

// =============================================================================
// Meaning Providers
// =============================================================================

/// Provider for meanings of a vocabulary item
final meaningsProvider = FutureProvider.autoDispose
    .family<List<MeaningModel>, String>((ref, vocabularyId) async {
      final service = ref.watch(supabaseDataServiceProvider);
      final data = await service.getMeanings(vocabularyId);
      return data.map(MeaningModel.fromJson).toList();
    });

/// Provider for primary meaning of a vocabulary item
final primaryMeaningProvider = FutureProvider.autoDispose
    .family<MeaningModel?, String>((ref, vocabularyId) async {
      final service = ref.watch(supabaseDataServiceProvider);
      final data = await service.getPrimaryMeaning(vocabularyId);
      if (data == null) return null;
      return MeaningModel.fromJson(data);
    });

/// Provider for map of all primary translations (vocabularyId -> translation)
final primaryTranslationsMapProvider =
    FutureProvider.autoDispose<Map<String, String>>((ref) async {
      final userId = ref.watch(currentUserIdProvider);
      if (userId == null) return {};

      final service = ref.watch(supabaseDataServiceProvider);
      return service.getAllPrimaryTranslations(userId);
    });

// =============================================================================
// Learning Card Providers
// =============================================================================

/// Provider for all learning cards of the current user
final learningCardsProvider =
    FutureProvider.autoDispose<List<LearningCardModel>>((ref) async {
      final userId = ref.watch(currentUserIdProvider);
      if (userId == null) return [];

      final service = ref.watch(supabaseDataServiceProvider);
      final data = await service.getLearningCards(userId);
      return data.map(LearningCardModel.fromJson).toList();
    });

/// Provider for due learning cards
final dueCardsProvider = FutureProvider.autoDispose<List<LearningCardModel>>((
  ref,
) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];

  final service = ref.watch(supabaseDataServiceProvider);
  final data = await service.getDueCards(userId);
  return data.map(LearningCardModel.fromJson).toList();
});

/// Provider for new cards
final newCardsProvider = FutureProvider.autoDispose<List<LearningCardModel>>((
  ref,
) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];

  final service = ref.watch(supabaseDataServiceProvider);
  final data = await service.getNewCards(userId);
  return data.map(LearningCardModel.fromJson).toList();
});

/// Provider for a learning card by vocabulary ID
final learningCardByVocabularyIdProvider = FutureProvider.autoDispose
    .family<LearningCardModel?, String>((ref, vocabularyId) async {
      final userId = ref.watch(currentUserIdProvider);
      if (userId == null) return null;

      final service = ref.watch(supabaseDataServiceProvider);
      final data = await service.getLearningCardByVocabularyId(
        userId,
        vocabularyId,
      );
      if (data == null) return null;
      return LearningCardModel.fromJson(data);
    });

// =============================================================================
// Session Providers
// =============================================================================

/// Provider for active learning session
final activeSessionProvider = FutureProvider.autoDispose<LearningSessionModel?>(
  (ref) async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return null;

    final service = ref.watch(supabaseDataServiceProvider);
    final data = await service.getActiveSession(userId);
    if (data == null) return null;
    return LearningSessionModel.fromJson(data);
  },
);

// =============================================================================
// User Preferences Providers
// =============================================================================

/// Provider for user learning preferences
final userPreferencesProvider =
    FutureProvider.autoDispose<UserPreferencesModel>((ref) async {
      final userId = ref.watch(currentUserIdProvider);
      if (userId == null) {
        throw StateError('User not logged in');
      }

      final service = ref.watch(supabaseDataServiceProvider);
      final data = await service.getOrCreatePreferences(userId);
      return UserPreferencesModel.fromJson(data);
    });

// =============================================================================
// Streak Providers
// =============================================================================

/// Provider for user streak
final streakProvider = FutureProvider.autoDispose<StreakModel>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    throw StateError('User not logged in');
  }

  final service = ref.watch(supabaseDataServiceProvider);
  final data = await service.getOrCreateStreak(userId);
  return StreakModel.fromJson(data);
});

// =============================================================================
// Encounter Providers
// =============================================================================

/// Provider for most recent encounter for a vocabulary item
final mostRecentEncounterProvider = FutureProvider.autoDispose
    .family<EncounterModel?, String>((ref, vocabularyId) async {
      final service = ref.watch(supabaseDataServiceProvider);
      final data = await service.getMostRecentEncounter(vocabularyId);
      if (data == null) return null;
      return EncounterModel.fromJson(data);
    });

// =============================================================================
// Source Providers
// =============================================================================

/// Provider for a source by ID
final sourceByIdProvider = FutureProvider.autoDispose
    .family<SourceModel?, String?>((ref, sourceId) async {
      if (sourceId == null) return null;
      final service = ref.watch(supabaseDataServiceProvider);
      final data = await service.getSourceById(sourceId);
      if (data == null) return null;
      return SourceModel.fromJson(data);
    });

// =============================================================================
// Cue Providers
// =============================================================================

/// Provider for cues for a vocabulary item
final cuesForVocabularyProvider = FutureProvider.autoDispose
    .family<List<CueModel>, String>((ref, vocabularyId) async {
      final service = ref.watch(supabaseDataServiceProvider);
      final data = await service.getCuesForVocabulary(vocabularyId);
      return data.map(CueModel.fromJson).toList();
    });

/// Provider for cues for a specific meaning
final cuesForMeaningProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, meaningId) async {
      final service = ref.watch(supabaseDataServiceProvider);
      return service.getCuesForMeaning(meaningId);
    });
