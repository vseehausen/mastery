import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/database.dart';
import 'review_log_repository.dart';

/// Session outcome enum values
class SessionOutcome {
  static const int inProgress = 0;
  static const int complete = 1;
  static const int partial = 2;
  static const int expired = 3;
}

/// Repository for managing learning sessions
class SessionRepository {
  SessionRepository(this._db, this._reviewLogRepository);

  final AppDatabase _db;
  final ReviewLogRepository _reviewLogRepository;
  static const _uuid = Uuid();

  /// Create a new learning session
  Future<LearningSession> create({
    required String userId,
    required int plannedMinutes,
    DateTime? expiresAt,
  }) async {
    final now = DateTime.now().toUtc();
    // Default expiresAt to end of local day (23:59:59)
    final localNow = DateTime.now();
    final defaultExpiresAt =
        expiresAt ??
        DateTime(
          localNow.year,
          localNow.month,
          localNow.day,
          23,
          59,
          59,
        ).toUtc();

    final companion = LearningSessionsCompanion.insert(
      id: _uuid.v4(),
      userId: userId,
      startedAt: now,
      expiresAt: defaultExpiresAt,
      plannedMinutes: plannedMinutes,
      createdAt: now,
      updatedAt: now,
    );

    await _db.into(_db.learningSessions).insert(companion);
    return (await getById(companion.id.value))!;
  }

  /// Get a session by ID
  Future<LearningSession?> getById(String id) {
    return (_db.select(
      _db.learningSessions,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Get active session for a user (outcome = in_progress AND not expired)
  Future<LearningSession?> getActiveSession(String userId) async {
    final now = DateTime.now().toUtc();
    return (_db.select(_db.learningSessions)
          ..where((t) => t.userId.equals(userId))
          ..where((t) => t.outcome.equals(SessionOutcome.inProgress))
          ..where((t) => t.expiresAt.isBiggerThanValue(now))
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Check if user has completed a session today
  Future<bool> hasCompletedToday(String userId) async {
    final now = DateTime.now().toUtc();
    final startOfDay = DateTime(now.year, now.month, now.day).toUtc();

    final completedSessions =
        await (_db.select(_db.learningSessions)
              ..where((t) => t.userId.equals(userId))
              ..where((t) => t.outcome.equals(SessionOutcome.complete))
              ..where((t) => t.startedAt.isBiggerOrEqualValue(startOfDay)))
            .get();

    return completedSessions.isNotEmpty;
  }

  /// Update session progress after each item
  Future<LearningSession> updateProgress({
    required String sessionId,
    required int elapsedSeconds,
    required int itemsPresented,
    required int itemsCompleted,
    required int newWordsPresented,
    required int reviewsPresented,
  }) async {
    final now = DateTime.now().toUtc();
    await (_db.update(
      _db.learningSessions,
    )..where((t) => t.id.equals(sessionId))).write(
      LearningSessionsCompanion(
        elapsedSeconds: Value(elapsedSeconds),
        itemsPresented: Value(itemsPresented),
        itemsCompleted: Value(itemsCompleted),
        newWordsPresented: Value(newWordsPresented),
        reviewsPresented: Value(reviewsPresented),
        updatedAt: Value(now),
        isPendingSync: const Value(true),
      ),
    );

    return (await getById(sessionId))!;
  }

  /// Add bonus time to session
  Future<LearningSession> addBonusTime({
    required String sessionId,
    required int bonusSeconds,
  }) async {
    final session = await getById(sessionId);
    if (session == null) {
      throw StateError('Session not found: $sessionId');
    }

    final now = DateTime.now().toUtc();
    final newBonusTotal = session.bonusSeconds + bonusSeconds;

    await (_db.update(
      _db.learningSessions,
    )..where((t) => t.id.equals(sessionId))).write(
      LearningSessionsCompanion(
        bonusSeconds: Value(newBonusTotal),
        outcome: const Value(SessionOutcome.inProgress), // Resume session
        updatedAt: Value(now),
        isPendingSync: const Value(true),
      ),
    );

    return (await getById(sessionId))!;
  }

  /// End session with specified outcome
  Future<LearningSession> endSession({
    required String sessionId,
    required int outcome,
  }) async {
    final now = DateTime.now().toUtc();

    // Compute session aggregates from review logs
    final accuracyRate = await _reviewLogRepository.computeSessionAccuracy(
      sessionId,
    );
    final avgResponseTimeMs = await _reviewLogRepository
        .computeSessionAvgResponseTime(sessionId);

    await (_db.update(
      _db.learningSessions,
    )..where((t) => t.id.equals(sessionId))).write(
      LearningSessionsCompanion(
        outcome: Value(outcome),
        accuracyRate: Value(accuracyRate),
        avgResponseTimeMs: Value(avgResponseTimeMs),
        updatedAt: Value(now),
        isPendingSync: const Value(true),
      ),
    );

    return (await getById(sessionId))!;
  }

  /// Mark expired sessions as expired
  Future<int> expireStaleSessions(String userId) async {
    final now = DateTime.now().toUtc();

    final staleSessions =
        await (_db.select(_db.learningSessions)
              ..where((t) => t.userId.equals(userId))
              ..where((t) => t.outcome.equals(SessionOutcome.inProgress))
              ..where((t) => t.expiresAt.isSmallerOrEqualValue(now)))
            .get();

    for (final session in staleSessions) {
      await (_db.update(
        _db.learningSessions,
      )..where((t) => t.id.equals(session.id))).write(
        LearningSessionsCompanion(
          outcome: const Value(SessionOutcome.expired),
          updatedAt: Value(now),
          isPendingSync: const Value(true),
        ),
      );
    }

    return staleSessions.length;
  }

  /// Get recent sessions for a user
  Future<List<LearningSession>> getRecentSessions(
    String userId, {
    int limit = 10,
  }) {
    return (_db.select(_db.learningSessions)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
          ..limit(limit))
        .get();
  }

  /// Get sessions pending sync
  Future<List<LearningSession>> getPendingSync() {
    return (_db.select(
      _db.learningSessions,
    )..where((t) => t.isPendingSync.equals(true))).get();
  }

  /// Mark session as synced
  Future<void> markSynced(String id) async {
    await (_db.update(_db.learningSessions)..where((t) => t.id.equals(id)))
        .write(const LearningSessionsCompanion(isPendingSync: Value(false)));
  }

  /// Get today's partial session (if any) for resuming
  Future<LearningSession?> getTodayPartialSession(String userId) async {
    final now = DateTime.now().toUtc();
    final startOfDay = DateTime(now.year, now.month, now.day).toUtc();

    return (_db.select(_db.learningSessions)
          ..where((t) => t.userId.equals(userId))
          ..where((t) => t.outcome.equals(SessionOutcome.partial))
          ..where((t) => t.startedAt.isBiggerOrEqualValue(startOfDay))
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Calculate remaining time for a session in seconds
  int getRemainingSeconds(LearningSession session) {
    final totalSeconds = (session.plannedMinutes * 60) + session.bonusSeconds;
    final remaining = totalSeconds - session.elapsedSeconds;
    return remaining > 0 ? remaining : 0;
  }
}
