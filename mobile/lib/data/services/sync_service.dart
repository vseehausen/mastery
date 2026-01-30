import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase_client.dart';
import '../database/database.dart';
import '../repositories/learning_card_repository.dart';
import '../repositories/review_log_repository.dart';
import '../repositories/session_repository.dart';
import '../repositories/streak_repository.dart';
import '../repositories/sync_outbox_repository.dart';
import '../repositories/user_preferences_repository.dart';

/// Service for syncing local changes to Supabase
class SyncService {
  SyncService({
    required SyncOutboxRepository outboxRepo,
    required AppDatabase db,
    LearningCardRepository? learningCardRepository,
    SessionRepository? sessionRepository,
    StreakRepository? streakRepository,
    UserPreferencesRepository? userPreferencesRepository,
    ReviewLogRepository? reviewLogRepository,
  }) : _outboxRepo = outboxRepo,
       _db = db,
       _learningCardRepository = learningCardRepository,
       _sessionRepository = sessionRepository,
       _streakRepository = streakRepository,
       _userPreferencesRepository = userPreferencesRepository,
       _reviewLogRepository = reviewLogRepository;

  final SyncOutboxRepository _outboxRepo;
  final AppDatabase _db;
  final LearningCardRepository? _learningCardRepository;
  final SessionRepository? _sessionRepository;
  final StreakRepository? _streakRepository;
  final UserPreferencesRepository? _userPreferencesRepository;
  final ReviewLogRepository? _reviewLogRepository;

  bool _isSyncing = false;

  /// Check if sync is in progress
  bool get isSyncing => _isSyncing;

  /// Push pending local changes to the server
  Future<SyncPushResult> pushChanges() async {
    if (_isSyncing) {
      return SyncPushResult(
        applied: 0,
        failed: 0,
        error: 'Sync already in progress',
      );
    }

    if (!SupabaseConfig.isAuthenticated) {
      return SyncPushResult(applied: 0, failed: 0, error: 'Not authenticated');
    }

    _isSyncing = true;

    try {
      final pendingItems = await _outboxRepo.getPendingItemsForSync();

      // Collect learning data pending sync
      final learningChanges = await _collectLearningChanges();
      final allChanges = <Map<String, dynamic>>[];

      // Add outbox items
      for (final item in pendingItems) {
        allChanges.add({
          'table': item.entityTable,
          'operation': item.operation,
          'id': item.recordId,
          'data': jsonDecode(item.payload),
        });
      }

      // Add learning changes
      allChanges.addAll(learningChanges);

      if (allChanges.isEmpty) {
        return SyncPushResult(applied: 0, failed: 0);
      }

      final response = await SupabaseConfig.client.functions.invoke(
        'sync/push',
        body: {'changes': allChanges},
        method: HttpMethod.post,
      );

      if (response.status != 200) {
        return SyncPushResult(
          applied: 0,
          failed: allChanges.length,
          error: 'Server returned ${response.status}',
        );
      }

      final result = response.data as Map<String, dynamic>;
      final applied = result['applied'] as int? ?? 0;

      // Mark successfully synced outbox items
      for (final item in pendingItems) {
        await _outboxRepo.markSynced(item.id);
      }

      // Update lastSyncedAt for synced records
      final syncedAt = DateTime.now();
      await _updateLastSyncedAt(pendingItems, syncedAt);

      // Mark learning data as synced
      await _markLearningDataSynced();

      return SyncPushResult(applied: applied, failed: 0);
    } catch (e) {
      return SyncPushResult(applied: 0, failed: 0, error: e.toString());
    } finally {
      _isSyncing = false;
    }
  }

  /// Collect pending learning data changes for sync
  Future<List<Map<String, dynamic>>> _collectLearningChanges() async {
    final changes = <Map<String, dynamic>>[];

    // Learning cards
    if (_learningCardRepository != null) {
      final pendingCards = await _learningCardRepository.getPendingSync();
      for (final card in pendingCards) {
        changes.add({
          'table': 'learning_cards',
          'operation': 'upsert',
          'id': card.id,
          'data': _learningCardToJson(card),
        });
      }
    }

    // Learning sessions
    if (_sessionRepository != null) {
      final pendingSessions = await _sessionRepository.getPendingSync();
      for (final session in pendingSessions) {
        changes.add({
          'table': 'learning_sessions',
          'operation': 'upsert',
          'id': session.id,
          'data': _learningSessionToJson(session),
        });
      }
    }

    // Streaks
    if (_streakRepository != null) {
      final pendingStreaks = await _streakRepository.getPendingSync();
      for (final streak in pendingStreaks) {
        changes.add({
          'table': 'streaks',
          'operation': 'upsert',
          'id': streak.id,
          'data': _streakToJson(streak),
        });
      }
    }

    // User learning preferences
    if (_userPreferencesRepository != null) {
      final pendingPrefs = await _userPreferencesRepository.getPendingSync();
      for (final pref in pendingPrefs) {
        changes.add({
          'table': 'user_learning_preferences',
          'operation': 'upsert',
          'id': pref.id,
          'data': _userPreferencesToJson(pref),
        });
      }
    }

    // Review logs (push-only, append-only)
    if (_reviewLogRepository != null) {
      final pendingLogs = await _reviewLogRepository.getPendingSync();
      for (final log in pendingLogs) {
        changes.add({
          'table': 'review_logs',
          'operation': 'insert',
          'id': log.id,
          'data': _reviewLogToJson(log),
        });
      }
    }

    return changes;
  }

  /// Mark all pending learning data as synced
  Future<void> _markLearningDataSynced() async {
    if (_learningCardRepository != null) {
      final pendingCards = await _learningCardRepository.getPendingSync();
      for (final card in pendingCards) {
        await _learningCardRepository.markSynced(card.id);
      }
    }

    if (_sessionRepository != null) {
      final pendingSessions = await _sessionRepository.getPendingSync();
      for (final session in pendingSessions) {
        await _sessionRepository.markSynced(session.id);
      }
    }

    if (_streakRepository != null) {
      final pendingStreaks = await _streakRepository.getPendingSync();
      for (final streak in pendingStreaks) {
        await _streakRepository.markSynced(streak.id);
      }
    }

    if (_userPreferencesRepository != null) {
      final pendingPrefs = await _userPreferencesRepository.getPendingSync();
      for (final pref in pendingPrefs) {
        await _userPreferencesRepository.markSynced(pref.id);
      }
    }

    if (_reviewLogRepository != null) {
      final pendingLogs = await _reviewLogRepository.getPendingSync();
      for (final log in pendingLogs) {
        await _reviewLogRepository.markSynced(log.id);
      }
    }
  }

  /// Convert LearningCard to JSON for sync
  Map<String, dynamic> _learningCardToJson(LearningCard card) {
    return {
      'id': card.id,
      'user_id': card.userId,
      'vocabulary_id': card.vocabularyId,
      'state': card.state,
      'due': card.due.toIso8601String(),
      'stability': card.stability,
      'difficulty': card.difficulty,
      'reps': card.reps,
      'lapses': card.lapses,
      'last_review': card.lastReview?.toIso8601String(),
      'is_leech': card.isLeech,
      'created_at': card.createdAt.toIso8601String(),
      'updated_at': card.updatedAt.toIso8601String(),
      'deleted_at': card.deletedAt?.toIso8601String(),
      'version': card.version,
    };
  }

  /// Convert LearningSession to JSON for sync
  Map<String, dynamic> _learningSessionToJson(LearningSession session) {
    return {
      'id': session.id,
      'user_id': session.userId,
      'started_at': session.startedAt.toIso8601String(),
      'expires_at': session.expiresAt.toIso8601String(),
      'planned_minutes': session.plannedMinutes,
      'elapsed_seconds': session.elapsedSeconds,
      'bonus_seconds': session.bonusSeconds,
      'items_presented': session.itemsPresented,
      'items_completed': session.itemsCompleted,
      'new_words_presented': session.newWordsPresented,
      'reviews_presented': session.reviewsPresented,
      'accuracy_rate': session.accuracyRate,
      'avg_response_time_ms': session.avgResponseTimeMs,
      'outcome': session.outcome,
      'created_at': session.createdAt.toIso8601String(),
      'updated_at': session.updatedAt.toIso8601String(),
    };
  }

  /// Convert Streak to JSON for sync
  Map<String, dynamic> _streakToJson(Streak streak) {
    return {
      'id': streak.id,
      'user_id': streak.userId,
      'current_count': streak.currentCount,
      'longest_count': streak.longestCount,
      'last_completed_date': streak.lastCompletedDate?.toIso8601String(),
      'created_at': streak.createdAt.toIso8601String(),
      'updated_at': streak.updatedAt.toIso8601String(),
    };
  }

  /// Convert UserLearningPreference to JSON for sync
  Map<String, dynamic> _userPreferencesToJson(UserLearningPreference pref) {
    return {
      'id': pref.id,
      'user_id': pref.userId,
      'daily_time_target_minutes': pref.dailyTimeTargetMinutes,
      'target_retention': pref.targetRetention,
      'intensity': pref.intensity,
      'new_word_suppression_active': pref.newWordSuppressionActive,
      'created_at': pref.createdAt.toIso8601String(),
      'updated_at': pref.updatedAt.toIso8601String(),
    };
  }

  /// Convert ReviewLog to JSON for sync
  Map<String, dynamic> _reviewLogToJson(ReviewLog log) {
    return {
      'id': log.id,
      'user_id': log.userId,
      'learning_card_id': log.learningCardId,
      'rating': log.rating,
      'interaction_mode': log.interactionMode,
      'state_before': log.stateBefore,
      'state_after': log.stateAfter,
      'stability_before': log.stabilityBefore,
      'stability_after': log.stabilityAfter,
      'difficulty_before': log.difficultyBefore,
      'difficulty_after': log.difficultyAfter,
      'response_time_ms': log.responseTimeMs,
      'retrievability_at_review': log.retrievabilityAtReview,
      'reviewed_at': log.reviewedAt.toIso8601String(),
      'session_id': log.sessionId,
    };
  }

  /// Pull remote changes from the server using direct Supabase queries
  Future<SyncPullResult> pullChanges(DateTime? lastSyncedAt) async {
    if (_isSyncing) {
      return SyncPullResult(
        sources: 0,
        encounters: 0,
        vocabulary: 0,
        error: 'Sync already in progress',
      );
    }

    if (!SupabaseConfig.isAuthenticated) {
      return SyncPullResult(
        sources: 0,
        encounters: 0,
        vocabulary: 0,
        error: 'Not authenticated',
      );
    }

    _isSyncing = true;

    try {
      final since = (lastSyncedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
          .toIso8601String();
      final client = SupabaseConfig.client;

      // Fetch sources directly from Supabase
      final sourcesResponse = await client
          .from('sources')
          .select()
          .gt('updated_at', since);
      final sourcesList = sourcesResponse as List<dynamic>;

      // Fetch encounters directly from Supabase
      final encountersResponse = await client
          .from('encounters')
          .select()
          .gt('updated_at', since);
      final encountersList = encountersResponse as List<dynamic>;

      // Fetch vocabulary directly from Supabase
      final vocabResponse = await client
          .from('vocabulary')
          .select()
          .gt('updated_at', since);
      final vocabulary = vocabResponse as List<dynamic>;

      // Fetch learning_cards directly from Supabase
      final cardsResponse = await client
          .from('learning_cards')
          .select()
          .gt('updated_at', since);
      final learningCards = cardsResponse as List<dynamic>;

      // Fetch learning_sessions directly from Supabase
      final sessionsResponse = await client
          .from('learning_sessions')
          .select()
          .gt('updated_at', since);
      final learningSessions = sessionsResponse as List<dynamic>;

      // Fetch streaks directly from Supabase
      final streaksResponse = await client
          .from('streaks')
          .select()
          .gt('updated_at', since);
      final streaks = streaksResponse as List<dynamic>;

      // Fetch user_learning_preferences directly from Supabase
      final prefsResponse = await client
          .from('user_learning_preferences')
          .select()
          .gt('updated_at', since);
      final userPreferences = prefsResponse as List<dynamic>;

      // Save sources to local database
      for (final item in sourcesList) {
        final s = item as Map<String, dynamic>;
        final entry = SourcesCompanion(
          id: Value(s['id'] as String),
          userId: Value(s['user_id'] as String),
          type: Value(s['type'] as String),
          title: Value(s['title'] as String),
          author: Value(s['author'] as String?),
          asin: Value(s['asin'] as String?),
          url: Value(s['url'] as String?),
          domain: Value(s['domain'] as String?),
          createdAt: Value(DateTime.parse(s['created_at'] as String)),
          updatedAt: Value(DateTime.parse(s['updated_at'] as String)),
          deletedAt: Value(
            s['deleted_at'] != null
                ? DateTime.parse(s['deleted_at'] as String)
                : null,
          ),
          lastSyncedAt: Value(DateTime.now()),
          isPendingSync: const Value(false),
          version: Value(s['version'] as int? ?? 1),
        );
        await _db.into(_db.sources).insertOnConflictUpdate(entry);
      }

      // Save encounters to local database
      for (final item in encountersList) {
        final e = item as Map<String, dynamic>;
        final entry = EncountersCompanion(
          id: Value(e['id'] as String),
          userId: Value(e['user_id'] as String),
          vocabularyId: Value(e['vocabulary_id'] as String),
          sourceId: Value(e['source_id'] as String?),
          context: Value(e['context'] as String?),
          locatorJson: Value(e['locator_json'] as String?),
          occurredAt: Value(
            e['occurred_at'] != null
                ? DateTime.parse(e['occurred_at'] as String)
                : null,
          ),
          createdAt: Value(DateTime.parse(e['created_at'] as String)),
          updatedAt: Value(DateTime.parse(e['updated_at'] as String)),
          deletedAt: Value(
            e['deleted_at'] != null
                ? DateTime.parse(e['deleted_at'] as String)
                : null,
          ),
          lastSyncedAt: Value(DateTime.now()),
          isPendingSync: const Value(false),
          version: Value(e['version'] as int? ?? 1),
        );
        await _db.into(_db.encounters).insertOnConflictUpdate(entry);
      }

      // Save vocabulary to local database
      for (final item in vocabulary) {
        final v = item as Map<String, dynamic>;
        final entry = VocabularysCompanion(
          id: Value(v['id'] as String),
          userId: Value(v['user_id'] as String),
          word: Value(v['word'] as String),
          stem: Value(v['stem'] as String?),
          contentHash: Value(v['content_hash'] as String),
          createdAt: Value(DateTime.parse(v['created_at'] as String)),
          updatedAt: Value(DateTime.parse(v['updated_at'] as String)),
          deletedAt: Value(
            v['deleted_at'] != null
                ? DateTime.parse(v['deleted_at'] as String)
                : null,
          ),
          lastSyncedAt: Value(DateTime.now()),
          isPendingSync: const Value(false),
          version: Value(v['version'] as int? ?? 1),
        );
        await _db.into(_db.vocabularys).insertOnConflictUpdate(entry);
      }

      // Save learning cards to local database
      for (final item in learningCards) {
        final c = item as Map<String, dynamic>;
        final entry = LearningCardsCompanion(
          id: Value(c['id'] as String),
          userId: Value(c['user_id'] as String),
          vocabularyId: Value(c['vocabulary_id'] as String),
          state: Value(c['state'] as int),
          due: Value(DateTime.parse(c['due'] as String)),
          stability: Value((c['stability'] as num).toDouble()),
          difficulty: Value((c['difficulty'] as num).toDouble()),
          reps: Value(c['reps'] as int),
          lapses: Value(c['lapses'] as int),
          lastReview: Value(
            c['last_review'] != null
                ? DateTime.parse(c['last_review'] as String)
                : null,
          ),
          isLeech: Value(c['is_leech'] as bool),
          createdAt: Value(DateTime.parse(c['created_at'] as String)),
          updatedAt: Value(DateTime.parse(c['updated_at'] as String)),
          deletedAt: Value(
            c['deleted_at'] != null
                ? DateTime.parse(c['deleted_at'] as String)
                : null,
          ),
          version: Value(c['version'] as int? ?? 1),
          lastSyncedAt: Value(DateTime.now()),
          isPendingSync: const Value(false),
        );
        await _db.into(_db.learningCards).insertOnConflictUpdate(entry);
      }

      // Save learning sessions to local database
      for (final item in learningSessions) {
        final s = item as Map<String, dynamic>;
        final entry = LearningSessionsCompanion(
          id: Value(s['id'] as String),
          userId: Value(s['user_id'] as String),
          startedAt: Value(DateTime.parse(s['started_at'] as String)),
          expiresAt: Value(DateTime.parse(s['expires_at'] as String)),
          plannedMinutes: Value(s['planned_minutes'] as int),
          elapsedSeconds: Value(s['elapsed_seconds'] as int? ?? 0),
          bonusSeconds: Value(s['bonus_seconds'] as int? ?? 0),
          itemsPresented: Value(s['items_presented'] as int? ?? 0),
          itemsCompleted: Value(s['items_completed'] as int? ?? 0),
          newWordsPresented: Value(s['new_words_presented'] as int? ?? 0),
          reviewsPresented: Value(s['reviews_presented'] as int? ?? 0),
          accuracyRate: Value(
            s['accuracy_rate'] != null
                ? (s['accuracy_rate'] as num).toDouble()
                : null,
          ),
          avgResponseTimeMs: Value(s['avg_response_time_ms'] as int?),
          outcome: Value(s['outcome'] as int? ?? 0),
          createdAt: Value(DateTime.parse(s['created_at'] as String)),
          updatedAt: Value(DateTime.parse(s['updated_at'] as String)),
          isPendingSync: const Value(false),
        );
        await _db.into(_db.learningSessions).insertOnConflictUpdate(entry);
      }

      // Save streaks to local database
      for (final item in streaks) {
        final st = item as Map<String, dynamic>;
        final entry = StreaksCompanion(
          id: Value(st['id'] as String),
          userId: Value(st['user_id'] as String),
          currentCount: Value(st['current_count'] as int? ?? 0),
          longestCount: Value(st['longest_count'] as int? ?? 0),
          lastCompletedDate: Value(
            st['last_completed_date'] != null
                ? DateTime.parse(st['last_completed_date'] as String)
                : null,
          ),
          createdAt: Value(DateTime.parse(st['created_at'] as String)),
          updatedAt: Value(DateTime.parse(st['updated_at'] as String)),
          lastSyncedAt: Value(DateTime.now()),
          isPendingSync: const Value(false),
        );
        await _db.into(_db.streaks).insertOnConflictUpdate(entry);
      }

      // Save user learning preferences to local database
      for (final item in userPreferences) {
        final p = item as Map<String, dynamic>;
        final entry = UserLearningPreferencesCompanion(
          id: Value(p['id'] as String),
          userId: Value(p['user_id'] as String),
          dailyTimeTargetMinutes: Value(
            p['daily_time_target_minutes'] as int? ?? 10,
          ),
          targetRetention: Value(
            p['target_retention'] != null
                ? (p['target_retention'] as num).toDouble()
                : 0.90,
          ),
          intensity: Value(p['intensity'] as int? ?? 1),
          newWordSuppressionActive: Value(
            p['new_word_suppression_active'] as bool? ?? false,
          ),
          createdAt: Value(DateTime.parse(p['created_at'] as String)),
          updatedAt: Value(DateTime.parse(p['updated_at'] as String)),
          lastSyncedAt: Value(DateTime.now()),
          isPendingSync: const Value(false),
        );
        await _db
            .into(_db.userLearningPreferences)
            .insertOnConflictUpdate(entry);
      }

      return SyncPullResult(
        sources: sourcesList.length,
        encounters: encountersList.length,
        vocabulary: vocabulary.length,
        learningCards: learningCards.length,
        learningSessions: learningSessions.length,
        streaks: streaks.length,
        userPreferences: userPreferences.length,
      );
    } catch (e) {
      return SyncPullResult(
        sources: 0,
        encounters: 0,
        vocabulary: 0,
        error: e.toString(),
      );
    } finally {
      _isSyncing = false;
    }
  }

  /// Full sync (push then pull)
  Future<SyncResult> sync() async {
    final pushResult = await pushChanges();
    if (pushResult.error != null) {
      return SyncResult(push: pushResult, pull: null);
    }

    // TODO: Get last sync timestamp from preferences
    final pullResult = await pullChanges(null);

    return SyncResult(push: pushResult, pull: pullResult);
  }

  Future<void> _updateLastSyncedAt(
    List<SyncOutboxData> items,
    DateTime syncedAt,
  ) async {
    for (final item in items) {
      if (item.entityTable == 'sources') {
        await (_db.update(
          _db.sources,
        )..where((s) => s.id.equals(item.recordId))).write(
          SourcesCompanion(
            lastSyncedAt: Value(syncedAt),
            isPendingSync: const Value(false),
          ),
        );
      } else if (item.entityTable == 'encounters') {
        await (_db.update(
          _db.encounters,
        )..where((e) => e.id.equals(item.recordId))).write(
          EncountersCompanion(
            lastSyncedAt: Value(syncedAt),
            isPendingSync: const Value(false),
          ),
        );
      } else if (item.entityTable == 'vocabulary') {
        await (_db.update(
          _db.vocabularys,
        )..where((v) => v.id.equals(item.recordId))).write(
          VocabularysCompanion(
            lastSyncedAt: Value(syncedAt),
            isPendingSync: const Value(false),
          ),
        );
      }
    }
  }
}

/// Result of a sync push operation
class SyncPushResult {
  SyncPushResult({required this.applied, required this.failed, this.error});

  final int applied;
  final int failed;
  final String? error;

  bool get hasError => error != null;
}

/// Result of a sync pull operation
class SyncPullResult {
  SyncPullResult({
    required this.sources,
    required this.encounters,
    required this.vocabulary,
    this.learningCards = 0,
    this.learningSessions = 0,
    this.streaks = 0,
    this.userPreferences = 0,
    this.error,
  });

  final int sources;
  final int encounters;
  final int vocabulary;
  final int learningCards;
  final int learningSessions;
  final int streaks;
  final int userPreferences;
  final String? error;

  bool get hasError => error != null;
}

/// Combined result of a full sync
class SyncResult {
  SyncResult({required this.push, this.pull});

  final SyncPushResult push;
  final SyncPullResult? pull;

  bool get hasError => push.hasError || (pull?.hasError ?? false);
}
