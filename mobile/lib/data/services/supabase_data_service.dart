import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

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
        .ilike('word', '%$query%')
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

  // ===========================================================================
  // Meanings
  // ===========================================================================

  /// Get all meanings for a vocabulary word
  Future<List<Map<String, dynamic>>> getMeanings(String vocabularyId) async {
    final response = await _client
        .from('meanings')
        .select()
        .eq('vocabulary_id', vocabularyId)
        .isFilter('deleted_at', null)
        .order('sort_order');
    return List<Map<String, dynamic>>.from(response as List);
  }

  /// Get the primary meaning for a vocabulary word
  Future<Map<String, dynamic>?> getPrimaryMeaning(String vocabularyId) async {
    final response = await _client
        .from('meanings')
        .select()
        .eq('vocabulary_id', vocabularyId)
        .eq('is_primary', true)
        .isFilter('deleted_at', null)
        .maybeSingle();
    return response;
  }

  /// Get all vocabulary IDs that have meanings (are enriched)
  Future<List<String>> getEnrichedVocabularyIds(String userId) async {
    final response = await _client
        .from('meanings')
        .select('vocabulary_id')
        .eq('user_id', userId)
        .isFilter('deleted_at', null);
    final list = List<Map<String, dynamic>>.from(response as List);
    // Use toSet().toList() to deduplicate
    return list.map((m) => m['vocabulary_id'] as String).toSet().toList();
  }

  /// Update a meaning
  Future<void> updateMeaning({
    required String id,
    String? primaryTranslation,
    String? englishDefinition,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (primaryTranslation != null) {
      updates['primary_translation'] = primaryTranslation;
    }
    if (englishDefinition != null) {
      updates['english_definition'] = englishDefinition;
    }
    await _client.from('meanings').update(updates).eq('id', id);
  }

  // ===========================================================================
  // Learning Cards
  // ===========================================================================

  /// Get session cards with all data needed for learning sessions.
  /// Uses RPC to fetch cards with embedded vocabulary, meanings, cues in one query.
  Future<List<Map<String, dynamic>>> getSessionCards(
    String userId, {
    int limit = 50,
  }) async {
    final response = await _client.rpc<List<dynamic>>(
      'get_session_cards',
      params: {
        'p_user_id': userId,
        'p_limit': limit,
      },
    );
    return List<Map<String, dynamic>>.from(response);
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

  /// Get due cards (where due <= now) - only returns cards with meanings
  Future<List<Map<String, dynamic>>> getDueCards(
    String userId, {
    int? limit,
  }) async {
    // First get vocabulary IDs that have meanings
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

  /// Get count of overdue cards
  Future<int> getOverdueCount(String userId) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final response = await _client
        .from('learning_cards')
        .select()
        .eq('user_id', userId)
        .isFilter('deleted_at', null)
        .lte('due', now)
        .gt('state', 0) // Exclude new cards
        .count(CountOption.exact);
    return response.count;
  }

  /// Get new cards (state = 0) - only returns cards with meanings
  Future<List<Map<String, dynamic>>> getNewCards(
    String userId, {
    int? limit,
  }) async {
    // First get vocabulary IDs that have meanings
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

  /// Get leech cards - only returns cards with meanings
  Future<List<Map<String, dynamic>>> getLeechCards(String userId) async {
    // First get vocabulary IDs that have meanings
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

  /// Count enriched new words available (state=0 + has meanings)
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
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await _client.from('learning_cards').update({
      'state': state,
      'due': due.toUtc().toIso8601String(),
      'stability': stability,
      'difficulty': difficulty,
      'reps': reps,
      'lapses': lapses,
      'is_leech': isLeech,
      'last_review': now,
      'updated_at': now,
    }).eq('id', cardId);
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
    await _client.from('learning_sessions').update({
      'elapsed_seconds': elapsedSeconds,
      'items_presented': itemsPresented,
      'items_completed': itemsCompleted,
      'new_words_presented': newWordsPresented,
      'reviews_presented': reviewsPresented,
      'updated_at': now,
    }).eq('id', sessionId);
  }

  /// End a session
  Future<void> endSession({
    required String sessionId,
    required int outcome,
    double? accuracyRate,
    int? avgResponseTimeMs,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await _client.from('learning_sessions').update({
      'outcome': outcome,
      'accuracy_rate': accuracyRate,
      'avg_response_time_ms': avgResponseTimeMs,
      'updated_at': now,
    }).eq('id', sessionId);
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

    await _client.from('learning_sessions').update({
      'bonus_seconds': currentBonus + bonusSeconds,
      'expires_at': newExpiry.toIso8601String(),
      'updated_at': now.toIso8601String(),
    }).eq('id', sessionId);
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
        'daily_time_target_minutes': 10,
        'target_retention': 0.90,
        'intensity': 1,
        'new_word_suppression_active': false,
        'native_language_code': 'de',
        'meaning_display_mode': 'both',
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
    int? intensity,
    bool? newWordSuppressionActive,
    String? nativeLanguageCode,
    String? meaningDisplayMode,
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
    if (intensity != null) {
      updates['intensity'] = intensity;
    }
    if (newWordSuppressionActive != null) {
      updates['new_word_suppression_active'] = newWordSuppressionActive;
    }
    if (nativeLanguageCode != null) {
      updates['native_language_code'] = nativeLanguageCode;
    }
    if (meaningDisplayMode != null) {
      updates['meaning_display_mode'] = meaningDisplayMode;
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
    await _client.from('streaks').update({
      'current_count': currentCount,
      'longest_count': longestCount,
      'last_completed_date': lastCompletedDate?.toUtc().toIso8601String(),
      'updated_at': now,
    }).eq('id', id);
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
  // Cues
  // ===========================================================================

  /// Get cues for a vocabulary item (via meanings)
  Future<List<Map<String, dynamic>>> getCuesForVocabulary(
    String vocabularyId,
  ) async {
    // First get meaning IDs for this vocabulary
    final meanings = await getMeanings(vocabularyId);
    if (meanings.isEmpty) return [];

    final meaningIds = meanings.map((m) => m['id'] as String).toList();
    final response = await _client
        .from('cues')
        .select()
        .inFilter('meaning_id', meaningIds)
        .isFilter('deleted_at', null);
    return List<Map<String, dynamic>>.from(response as List);
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

    final setIds =
        members.map((m) => m['confusable_set_id'] as String).toList();
    final response = await _client
        .from('confusable_sets')
        .select()
        .inFilter('id', setIds)
        .isFilter('deleted_at', null);
    return List<Map<String, dynamic>>.from(response as List);
  }

  // ===========================================================================
  // Meaning Edits
  // ===========================================================================

  /// Create a meaning edit record
  Future<void> createMeaningEdit({
    required String id,
    required String userId,
    required String meaningId,
    required String fieldName,
    required String originalValue,
    required String userValue,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await _client.from('meaning_edits').insert({
      'id': id,
      'user_id': userId,
      'meaning_id': meaningId,
      'field_name': fieldName,
      'original_value': originalValue,
      'user_value': userValue,
      'created_at': now,
    });
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

    final total = list.fold<int>(0, (sum, r) => sum + (r['response_time_ms'] as int));
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
