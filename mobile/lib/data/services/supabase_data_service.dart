import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/app_defaults.dart';
import '../../core/effective_day.dart';
import '../../domain/models/progress_stage.dart';

/// Service that wraps Supabase queries for direct data access.
/// Replaces Drift/SQLite repositories with cloud-first approach.
class SupabaseDataService {
  SupabaseDataService(this._client);

  final SupabaseClient _client;

  // ===========================================================================
  // Vocabulary
  // ===========================================================================

  /// Get all vocabulary for a user, sorted by newest first
  Future<List<Map<String, dynamic>>> getVocabulary(String userId) async {
    final response = await _client
        .from('vocabulary')
        .select()
        .eq('user_id', userId)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response as List);
  }

  /// Get a single vocabulary item by ID
  Future<Map<String, dynamic>?> getVocabularyById(String id) async {
    final response = await _client
        .from('vocabulary')
        .select()
        .eq('id', id)
        .maybeSingle();
    return response;
  }

  /// Search vocabulary by word
  Future<List<Map<String, dynamic>>> searchVocabulary(
    String userId,
    String query,
  ) async {
    final response = await _client
        .from('vocabulary')
        .select()
        .eq('user_id', userId)
        .isFilter('deleted_at', null)
        .or('word.ilike.%$query%,stem.ilike.%$query%')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response as List);
  }

  /// Count vocabulary for a user
  Future<int> countVocabulary(String userId) async {
    final response = await _client
        .from('vocabulary')
        .select()
        .eq('user_id', userId)
        .isFilter('deleted_at', null)
        .count(CountOption.exact);
    return response.count;
  }

  /// Delete a vocabulary item (soft delete)
  Future<void> deleteVocabulary(String id) async {
    await _client
        .from('vocabulary')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }

  // ===========================================================================
  // Global Dictionary
  // ===========================================================================

  /// Get all vocabulary IDs that have global dictionary data (are enriched)
  Future<List<String>> getEnrichedVocabularyIds(String userId) async {
    final response = await _client
        .from('vocabulary')
        .select('id')
        .eq('user_id', userId)
        .isFilter('deleted_at', null)
        .not('global_dictionary_id', 'is', null);
    final list = List<Map<String, dynamic>>.from(response as List);
    return list.map((m) => m['id'] as String).toList();
  }

  /// Get all primary translations for the current user's vocabulary.
  /// Queries vocabulary JOIN global_dictionary, extracting translations.
  /// Returns a map of vocabularyId -> primaryTranslation.
  Future<Map<String, String>> getAllPrimaryTranslations(
    String userId, {
    String nativeLanguageCode = 'de',
  }) async {
    final response = await _client
        .from('vocabulary')
        .select('id, overrides, global_dictionary!inner(translations)')
        .eq('user_id', userId)
        .isFilter('deleted_at', null)
        .not('global_dictionary_id', 'is', null);
    final list = List<Map<String, dynamic>>.from(response as List);

    final result = <String, String>{};
    for (final row in list) {
      final vocabId = row['id'] as String;

      // Check overrides first
      final overrides = row['overrides'];
      if (overrides is Map && overrides['primary_translation'] is String) {
        result[vocabId] = overrides['primary_translation'] as String;
        continue;
      }

      // Extract from global_dictionary translations
      final gd = row['global_dictionary'];
      if (gd is Map<String, dynamic>) {
        final translations = gd['translations'];
        if (translations is Map) {
          final langData = translations[nativeLanguageCode];
          if (langData is Map && langData['primary'] is String) {
            result[vocabId] = langData['primary'] as String;
            continue;
          }
          // Fall back to first available language
          for (final entry in translations.entries) {
            final val = entry.value;
            if (val is Map && val['primary'] is String) {
              result[vocabId] = val['primary'] as String;
              break;
            }
          }
        }
      }
    }
    return result;
  }

  /// Get global dictionary data for a vocabulary item.
  /// Returns the global_dictionary row joined via vocabulary.global_dictionary_id.
  Future<Map<String, dynamic>?> getGlobalDictionaryForVocabulary(
    String vocabularyId,
  ) async {
    final response = await _client
        .from('vocabulary')
        .select('global_dictionary_id, global_dictionary!inner(*)')
        .eq('id', vocabularyId)
        .not('global_dictionary_id', 'is', null)
        .maybeSingle();

    if (response == null) return null;
    final gd = response['global_dictionary'];
    if (gd is Map<String, dynamic>) return gd;
    return null;
  }

  /// Update vocabulary overrides (replaces meaning edits).
  /// Merges the given overrides into the existing overrides JSONB.
  Future<void> updateVocabularyOverrides(
    String vocabularyId,
    Map<String, dynamic> overrides,
  ) async {
    // Fetch current overrides, merge, then update
    final current = await _client
        .from('vocabulary')
        .select('overrides')
        .eq('id', vocabularyId)
        .single();

    final existing = current['overrides'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(current['overrides'] as Map)
        : <String, dynamic>{};
    existing.addAll(overrides);

    await _client
        .from('vocabulary')
        .update({
          'overrides': existing,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', vocabularyId);
  }

  /// Get a single vocabulary item with its global dictionary data
  Future<Map<String, dynamic>?> getVocabularyWithGlobalDict(
    String vocabularyId,
  ) async {
    final response = await _client
        .from('vocabulary')
        .select('*, global_dictionary(*)')
        .eq('id', vocabularyId)
        .maybeSingle();
    return response;
  }

  /// Get all vocabulary items with global dictionary data for a user
  Future<List<Map<String, dynamic>>> getVocabularyWithGlobalDictForUser(
    String userId,
  ) async {
    final response = await _client
        .from('vocabulary')
        .select('*, global_dictionary(*)')
        .eq('user_id', userId)
        .isFilter('deleted_at', null);
    return List<Map<String, dynamic>>.from(response as List);
  }

  // ===========================================================================
  // Learning Cards
  // ===========================================================================

  /// Get session cards with all data needed for learning sessions.
  /// Uses RPC to fetch cards with embedded vocabulary, meanings, cues in one query.
  Future<List<Map<String, dynamic>>> getSessionCards(
    String userId, {
    required int reviewLimit,
    required int newLimit,
    List<String> excludeIds = const [],
  }) async {
    final response = await _client.rpc<List<dynamic>>(
      'get_session_cards',
      params: {
        'p_user_id': userId,
        'p_review_limit': reviewLimit,
        'p_new_limit': newLimit,
        'p_exclude_ids': excludeIds.isEmpty
            ? '{}'
            : '{${excludeIds.join(',')}}',
      },
    );

    final result = List<Map<String, dynamic>>.from(response);
    return result;
  }

  /// Check if there is at least one brand-new word (state=0, enriched, created in last 24h)
  Future<bool> hasBrandNewWord(String userId) async {
    final enrichedIds = await getEnrichedVocabularyIds(userId);
    if (enrichedIds.isEmpty) return false;

    final oneDayAgo = DateTime.now().toUtc().subtract(
      const Duration(hours: 24),
    );
    final response = await _client
        .from('learning_cards')
        .select('id')
        .eq('user_id', userId)
        .eq('state', 0)
        .isFilter('deleted_at', null)
        .inFilter('vocabulary_id', enrichedIds)
        .gte('created_at', oneDayAgo.toIso8601String())
        .limit(1);

    final list = List<Map<String, dynamic>>.from(response as List);
    return list.isNotEmpty;
  }

  /// Get all learning cards for a user
  Future<List<Map<String, dynamic>>> getLearningCards(String userId) async {
    final response = await _client
        .from('learning_cards')
        .select()
        .eq('user_id', userId)
        .isFilter('deleted_at', null);
    return List<Map<String, dynamic>>.from(response as List);
  }

  /// Get a learning card by ID
  Future<Map<String, dynamic>?> getLearningCardById(String id) async {
    final response = await _client
        .from('learning_cards')
        .select()
        .eq('id', id)
        .maybeSingle();
    return response;
  }

  /// Get a learning card by vocabulary ID
  Future<Map<String, dynamic>?> getLearningCardByVocabularyId(
    String userId,
    String vocabularyId,
  ) async {
    final response = await _client
        .from('learning_cards')
        .select()
        .eq('user_id', userId)
        .eq('vocabulary_id', vocabularyId)
        .isFilter('deleted_at', null)
        .maybeSingle();
    return response;
  }

  /// Get count of successful non-translation reviews for a learning card.
  Future<int> getNonTranslationSuccessCount(String learningCardId) async {
    final response = await _client
        .from('review_logs')
        .select('id')
        .eq('learning_card_id', learningCardId)
        .gte('rating', 3)
        .inFilter('cue_type', [
          'definition',
          'synonym',
          'context_cloze',
          'disambiguation',
          'novel_cloze',
          'usage_recognition',
        ])
        .count(CountOption.exact);

    return response.count;
  }

  /// Get due cards (where due <= now) - only returns cards with enriched vocabulary
  Future<List<Map<String, dynamic>>> getDueCards(
    String userId, {
    int? limit,
  }) async {
    final enrichedIds = await getEnrichedVocabularyIds(userId);
    if (enrichedIds.isEmpty) return [];

    final now = DateTime.now().toUtc().toIso8601String();
    var query = _client
        .from('learning_cards')
        .select()
        .eq('user_id', userId)
        .isFilter('deleted_at', null)
        .lte('due', now)
        .gt('state', 0) // Exclude new cards
        .inFilter('vocabulary_id', enrichedIds)
        .order('due');

    if (limit != null) {
      query = query.limit(limit);
    }

    final response = await query;
    return List<Map<String, dynamic>>.from(response as List);
  }

  /// Get count of overdue cards (only enriched vocabulary)
  Future<int> getOverdueCount(String userId) async {
    final enrichedIds = await getEnrichedVocabularyIds(userId);
    if (enrichedIds.isEmpty) return 0;

    final now = DateTime.now().toUtc().toIso8601String();
    final response = await _client
        .from('learning_cards')
        .select()
        .eq('user_id', userId)
        .isFilter('deleted_at', null)
        .lte('due', now)
        .gt('state', 0) // Exclude new cards
        .inFilter('vocabulary_id', enrichedIds)
        .count(CountOption.exact);
    return response.count;
  }

  /// Get new cards (state = 0) - only returns cards with enriched vocabulary
  Future<List<Map<String, dynamic>>> getNewCards(
    String userId, {
    int? limit,
  }) async {
    final enrichedIds = await getEnrichedVocabularyIds(userId);
    if (enrichedIds.isEmpty) return [];

    var query = _client
        .from('learning_cards')
        .select()
        .eq('user_id', userId)
        .isFilter('deleted_at', null)
        .eq('state', 0)
        .inFilter('vocabulary_id', enrichedIds)
        .order('created_at');

    if (limit != null) {
      query = query.limit(limit);
    }

    final response = await query;
    return List<Map<String, dynamic>>.from(response as List);
  }

  /// Get leech cards - only returns cards with enriched vocabulary
  Future<List<Map<String, dynamic>>> getLeechCards(String userId) async {
    final enrichedIds = await getEnrichedVocabularyIds(userId);
    if (enrichedIds.isEmpty) return [];

    final now = DateTime.now().toUtc().toIso8601String();
    final response = await _client
        .from('learning_cards')
        .select()
        .eq('user_id', userId)
        .isFilter('deleted_at', null)
        .eq('is_leech', true)
        .lte('due', now)
        .inFilter('vocabulary_id', enrichedIds)
        .order('lapses', ascending: false);
    return List<Map<String, dynamic>>.from(response as List);
  }

  /// Count enriched new words available (state=0 + has global dictionary data)
  /// This is the "server buffer" — words ready for introduction.
  Future<int> countEnrichedNewWords(String userId) async {
    final enrichedIds = await getEnrichedVocabularyIds(userId);
    if (enrichedIds.isEmpty) return 0;

    final response = await _client
        .from('learning_cards')
        .select()
        .eq('user_id', userId)
        .eq('state', 0)
        .isFilter('deleted_at', null)
        .inFilter('vocabulary_id', enrichedIds)
        .count(CountOption.exact);
    return response.count;
  }

  /// Update a learning card after review
  Future<void> updateLearningCard({
    required String cardId,
    required int state,
    required DateTime due,
    required double stability,
    required double difficulty,
    required int reps,
    required int lapses,
    required bool isLeech,
    String? progressStage,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final map = <String, dynamic>{
      'state': state,
      'due': due.toUtc().toIso8601String(),
      'stability': stability,
      'difficulty': difficulty,
      'reps': reps,
      'lapses': lapses,
      'is_leech': isLeech,
      'last_review': now,
      'updated_at': now,
    };
    if (progressStage != null) {
      map['progress_stage'] = progressStage;
    }
    await _client.from('learning_cards').update(map).eq('id', cardId);
  }

  /// Get vocabulary counts grouped by progress stage via RPC.
  Future<Map<ProgressStage, int>> getVocabularyStageCounts(
    String userId,
  ) async {
    final response = await _client.rpc<List<dynamic>>(
      'get_vocabulary_stage_counts',
      params: {'p_user_id': userId},
    );
    final rows = List<Map<String, dynamic>>.from(response);
    final counts = {for (final s in ProgressStage.values) s: 0};
    for (final row in rows) {
      final stageName = row['stage'] as String;
      final count = (row['count'] as num).toInt();
      // Aggregate (captured may appear twice: from cards + from vocab without cards)
      try {
        final stage = ProgressStage.fromString(stageName);
        counts[stage] = (counts[stage] ?? 0) + count;
      } catch (_) {
        // Skip unknown stages
      }
    }
    return counts;
  }

  // ===========================================================================
  // Review Logs
  // ===========================================================================

  /// Insert a review log
  Future<void> insertReviewLog({
    required String id,
    required String userId,
    required String learningCardId,
    required int rating,
    required int interactionMode,
    required int stateBefore,
    required int stateAfter,
    required double stabilityBefore,
    required double stabilityAfter,
    required double difficultyBefore,
    required double difficultyAfter,
    required int responseTimeMs,
    required double retrievabilityAtReview,
    String? sessionId,
    String? cueType,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await _client.from('review_logs').insert({
      'id': id,
      'user_id': userId,
      'learning_card_id': learningCardId,
      'rating': rating,
      'interaction_mode': interactionMode,
      'state_before': stateBefore,
      'state_after': stateAfter,
      'stability_before': stabilityBefore,
      'stability_after': stabilityAfter,
      'difficulty_before': difficultyBefore,
      'difficulty_after': difficultyAfter,
      'response_time_ms': responseTimeMs,
      'retrievability_at_review': retrievabilityAtReview,
      'reviewed_at': now,
      'session_id': sessionId,
      'cue_type': cueType,
    });
  }

  // ===========================================================================
  // Learning Sessions
  // ===========================================================================

  /// Get active session for a user
  Future<Map<String, dynamic>?> getActiveSession(String userId) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final response = await _client
        .from('learning_sessions')
        .select()
        .eq('user_id', userId)
        .eq('outcome', 0) // in_progress
        .gte('expires_at', now)
        .order('started_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return response;
  }

  /// Create a new learning session
  Future<Map<String, dynamic>> createSession({
    required String id,
    required String userId,
    required int plannedMinutes,
    required DateTime expiresAt,
  }) async {
    final now = DateTime.now().toUtc();
    final data = {
      'id': id,
      'user_id': userId,
      'started_at': now.toIso8601String(),
      'expires_at': expiresAt.toUtc().toIso8601String(),
      'planned_minutes': plannedMinutes,
      'elapsed_seconds': 0,
      'bonus_seconds': 0,
      'items_presented': 0,
      'items_completed': 0,
      'new_words_presented': 0,
      'reviews_presented': 0,
      'outcome': 0,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };
    await _client.from('learning_sessions').insert(data);
    return data;
  }

  /// Update session progress
  Future<void> updateSessionProgress({
    required String sessionId,
    required int elapsedSeconds,
    required int itemsPresented,
    required int itemsCompleted,
    required int newWordsPresented,
    required int reviewsPresented,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await _client
        .from('learning_sessions')
        .update({
          'elapsed_seconds': elapsedSeconds,
          'items_presented': itemsPresented,
          'items_completed': itemsCompleted,
          'new_words_presented': newWordsPresented,
          'reviews_presented': reviewsPresented,
          'updated_at': now,
        })
        .eq('id', sessionId);
  }

  /// End a session
  Future<void> endSession({
    required String sessionId,
    required int outcome,
    double? accuracyRate,
    int? avgResponseTimeMs,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await _client
        .from('learning_sessions')
        .update({
          'outcome': outcome,
          'accuracy_rate': accuracyRate,
          'avg_response_time_ms': avgResponseTimeMs,
          'updated_at': now,
        })
        .eq('id', sessionId);
  }

  /// Add bonus time to an active session
  Future<void> addBonusTime({
    required String sessionId,
    required int bonusSeconds,
  }) async {
    // Get current session to read current bonus_seconds and expires_at
    final session = await _client
        .from('learning_sessions')
        .select()
        .eq('id', sessionId)
        .single();

    final currentBonus = (session['bonus_seconds'] as int?) ?? 0;
    final currentExpiry = DateTime.parse(session['expires_at'] as String);

    final now = DateTime.now().toUtc();
    final newExpiry = currentExpiry.add(Duration(seconds: bonusSeconds));

    await _client
        .from('learning_sessions')
        .update({
          'bonus_seconds': currentBonus + bonusSeconds,
          'expires_at': newExpiry.toIso8601String(),
          'updated_at': now.toIso8601String(),
        })
        .eq('id', sessionId);
  }

  /// Get count of new cards (only enriched vocabulary)
  Future<int> getNewCardCount(String userId) async {
    final enrichedIds = await getEnrichedVocabularyIds(userId);
    if (enrichedIds.isEmpty) return 0;

    final response = await _client
        .from('learning_cards')
        .select()
        .eq('user_id', userId)
        .isFilter('deleted_at', null)
        .eq('state', 0)
        .inFilter('vocabulary_id', enrichedIds)
        .count(CountOption.exact);
    return response.count;
  }

  /// Get today's completed session stats (items reviewed + accuracy)
  Future<({int itemsReviewed, double? accuracyPercent})?> getTodaySessionStats(
    String userId,
  ) async {
    final startOfDay = effectiveDayStartUtc();

    final response = await _client
        .from('learning_sessions')
        .select('items_completed, accuracy_rate')
        .eq('user_id', userId)
        .gt('outcome', 0)
        .gte('started_at', startOfDay.toIso8601String())
        .order('started_at', ascending: false);

    final sessions = List<Map<String, dynamic>>.from(response as List);
    if (sessions.isEmpty) return null;

    var totalItems = 0;
    var totalAccuracy = 0.0;
    var accuracyCount = 0;

    for (final session in sessions) {
      totalItems += (session['items_completed'] as int?) ?? 0;
      final accuracy = session['accuracy_rate'] as num?;
      if (accuracy != null) {
        totalAccuracy += accuracy.toDouble();
        accuracyCount++;
      }
    }

    return (
      itemsReviewed: totalItems,
      accuracyPercent: accuracyCount > 0
          ? (totalAccuracy / accuracyCount * 100)
          : null,
    );
  }

  /// Get the next future due date for enriched learning cards
  Future<DateTime?> getNextDueDate(String userId) async {
    final enrichedIds = await getEnrichedVocabularyIds(userId);
    if (enrichedIds.isEmpty) return null;

    final now = DateTime.now().toUtc().toIso8601String();
    final response = await _client
        .from('learning_cards')
        .select('due')
        .eq('user_id', userId)
        .isFilter('deleted_at', null)
        .gt('state', 0)
        .gt('due', now)
        .inFilter('vocabulary_id', enrichedIds)
        .order('due')
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return DateTime.parse(response['due'] as String);
  }

  // ===========================================================================
  // User Preferences
  // ===========================================================================

  /// Get or create user preferences
  Future<Map<String, dynamic>> getOrCreatePreferences(String userId) async {
    var response = await _client
        .from('user_learning_preferences')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) {
      // Create default preferences
      final now = DateTime.now().toUtc().toIso8601String();
      final id = const Uuid().v4();
      final data = {
        'id': id,
        'user_id': userId,
        'daily_time_target_minutes': AppDefaults.sessionDefault,
        'target_retention': AppDefaults.retentionDefault,
        'new_words_per_session': AppDefaults.newWordsDefault,
        'new_word_suppression_active': false,
        'native_language_code': AppDefaults.nativeLanguageCode,
        'created_at': now,
        'updated_at': now,
      };
      await _client.from('user_learning_preferences').insert(data);
      response = data;
    }

    return response;
  }

  /// Update user preferences
  Future<void> updatePreferences({
    required String userId,
    int? dailyTimeTargetMinutes,
    double? targetRetention,
    int? newWordsPerSession,
    bool? newWordSuppressionActive,
    String? nativeLanguageCode,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (dailyTimeTargetMinutes != null) {
      updates['daily_time_target_minutes'] = dailyTimeTargetMinutes;
    }
    if (targetRetention != null) {
      updates['target_retention'] = targetRetention;
    }
    if (newWordsPerSession != null) {
      updates['new_words_per_session'] = newWordsPerSession;
    }
    if (newWordSuppressionActive != null) {
      updates['new_word_suppression_active'] = newWordSuppressionActive;
    }
    if (nativeLanguageCode != null) {
      updates['native_language_code'] = nativeLanguageCode;
    }
    await _client
        .from('user_learning_preferences')
        .update(updates)
        .eq('user_id', userId);
  }

  // ===========================================================================
  // Streaks
  // ===========================================================================

  /// Get or create streak for user
  Future<Map<String, dynamic>> getOrCreateStreak(String userId) async {
    var response = await _client
        .from('streaks')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) {
      final now = DateTime.now().toUtc().toIso8601String();
      final id = const Uuid().v4();
      final data = {
        'id': id,
        'user_id': userId,
        'current_count': 0,
        'longest_count': 0,
        'last_completed_date': null,
        'created_at': now,
        'updated_at': now,
      };
      await _client.from('streaks').insert(data);
      response = data;
    }

    return response;
  }

  /// Update streak
  Future<void> updateStreak({
    required String id,
    required int currentCount,
    required int longestCount,
    DateTime? lastCompletedDate,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await _client
        .from('streaks')
        .update({
          'current_count': currentCount,
          'longest_count': longestCount,
          'last_completed_date': lastCompletedDate?.toUtc().toIso8601String(),
          'updated_at': now,
        })
        .eq('id', id);
  }

  // ===========================================================================
  // Encounters
  // ===========================================================================

  /// Get the most recent encounter for a vocabulary item
  Future<Map<String, dynamic>?> getMostRecentEncounter(
    String vocabularyId,
  ) async {
    final response = await _client
        .from('encounters')
        .select()
        .eq('vocabulary_id', vocabularyId)
        .isFilter('deleted_at', null)
        .order('occurred_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return response;
  }

  /// Get all encounters for a vocabulary item
  Future<List<Map<String, dynamic>>> getEncounters(String vocabularyId) async {
    final response = await _client
        .from('encounters')
        .select()
        .eq('vocabulary_id', vocabularyId)
        .isFilter('deleted_at', null)
        .order('occurred_at', ascending: false);
    return List<Map<String, dynamic>>.from(response as List);
  }

  // ===========================================================================
  // Sources
  // ===========================================================================

  /// Get a source by ID
  Future<Map<String, dynamic>?> getSourceById(String id) async {
    final response = await _client
        .from('sources')
        .select()
        .eq('id', id)
        .maybeSingle();
    return response;
  }

  // ===========================================================================
  // Confusable Sets
  // ===========================================================================

  /// Get confusable sets containing a vocabulary item
  Future<List<Map<String, dynamic>>> getConfusableSetsForVocabulary(
    String vocabularyId,
  ) async {
    // First get member records
    final membersResponse = await _client
        .from('confusable_set_members')
        .select('confusable_set_id')
        .eq('vocabulary_id', vocabularyId);
    final members = List<Map<String, dynamic>>.from(membersResponse as List);
    if (members.isEmpty) return [];

    final setIds = members
        .map((m) => m['confusable_set_id'] as String)
        .toList();
    final response = await _client
        .from('confusable_sets')
        .select()
        .inFilter('id', setIds)
        .isFilter('deleted_at', null);
    return List<Map<String, dynamic>>.from(response as List);
  }

  // ===========================================================================
  // Enrichment Feedback
  // ===========================================================================

  /// Create enrichment feedback
  Future<void> createEnrichmentFeedback({
    required String userId,
    required String globalDictionaryId,
    required String fieldName,
    required String rating,
    String? flagCategory,
    String? comment,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await _client.from('enrichment_feedback').insert({
      'id': const Uuid().v4(),
      'user_id': userId,
      'global_dictionary_id': globalDictionaryId,
      'field_name': fieldName,
      'rating': rating,
      'flag_category': flagCategory,
      'comment': comment,
      'created_at': now,
    });
  }

  /// Get enrichment feedback for a global dictionary entry
  Future<List<Map<String, dynamic>>> getEnrichmentFeedback(
    String globalDictionaryId,
  ) async {
    final response = await _client
        .from('enrichment_feedback')
        .select()
        .eq('global_dictionary_id', globalDictionaryId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response as List);
  }

  // ===========================================================================
  // Review Logs (Telemetry)
  // ===========================================================================

  /// Get review count for a user
  Future<int> getReviewCount(String userId) async {
    final response = await _client
        .from('review_logs')
        .select()
        .eq('user_id', userId)
        .count(CountOption.exact);
    return response.count;
  }

  /// Get average response time in milliseconds
  Future<double> getAverageResponseTime(
    String userId, {
    int windowSize = 50,
  }) async {
    final response = await _client
        .from('review_logs')
        .select('response_time_ms')
        .eq('user_id', userId)
        .not('response_time_ms', 'is', null)
        .order('reviewed_at', ascending: false)
        .limit(windowSize);
    final list = List<Map<String, dynamic>>.from(response as List);
    if (list.isEmpty) return 15000.0; // Default 15 seconds

    final total = list.fold<int>(
      0,
      (sum, r) => sum + (r['response_time_ms'] as int),
    );
    return total / list.length;
  }

  /// Create a review log entry
  Future<void> createReviewLog({
    required String id,
    required String sessionId,
    required String learningCardId,
    required int rating,
    required int responseTimeMs,
    required String userId,
    int? oldState,
    int? newState,
    double? oldStability,
    double? newStability,
    double? oldDifficulty,
    double? newDifficulty,
    DateTime? oldDue,
    DateTime? newDue,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await _client.from('review_logs').insert({
      'id': id,
      'session_id': sessionId,
      'learning_card_id': learningCardId,
      'user_id': userId,
      'rating': rating,
      'response_time_ms': responseTimeMs,
      'old_state': oldState,
      'new_state': newState,
      'old_stability': oldStability,
      'new_stability': newStability,
      'old_difficulty': oldDifficulty,
      'new_difficulty': newDifficulty,
      'old_due': oldDue?.toUtc().toIso8601String(),
      'new_due': newDue?.toUtc().toIso8601String(),
      'reviewed_at': now,
    });
  }

  // ===========================================================================
}
