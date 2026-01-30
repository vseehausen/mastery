import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/database.dart';

/// Repository for managing review logs (append-only telemetry)
class ReviewLogRepository {
  ReviewLogRepository(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  /// Insert a new review log
  Future<ReviewLog> insert({
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
  }) async {
    final now = DateTime.now().toUtc();
    final companion = ReviewLogsCompanion.insert(
      id: _uuid.v4(),
      userId: userId,
      learningCardId: learningCardId,
      rating: rating,
      interactionMode: interactionMode,
      stateBefore: stateBefore,
      stateAfter: stateAfter,
      stabilityBefore: stabilityBefore,
      stabilityAfter: stabilityAfter,
      difficultyBefore: difficultyBefore,
      difficultyAfter: difficultyAfter,
      responseTimeMs: responseTimeMs,
      retrievabilityAtReview: retrievabilityAtReview,
      reviewedAt: now,
      sessionId: Value(sessionId),
    );

    await _db.into(_db.reviewLogs).insert(companion);
    return (await getById(companion.id.value))!;
  }

  /// Get a review log by ID
  Future<ReviewLog?> getById(String id) {
    return (_db.select(_db.reviewLogs)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Get all review logs for a session
  Future<List<ReviewLog>> getBySession(String sessionId) {
    return (_db.select(_db.reviewLogs)
          ..where((t) => t.sessionId.equals(sessionId))
          ..orderBy([(t) => OrderingTerm.asc(t.reviewedAt)]))
        .get();
  }

  /// Get all review logs for a learning card
  Future<List<ReviewLog>> getByLearningCard(String learningCardId) {
    return (_db.select(_db.reviewLogs)
          ..where((t) => t.learningCardId.equals(learningCardId))
          ..orderBy([(t) => OrderingTerm.asc(t.reviewedAt)]))
        .get();
  }

  /// Get average response time for a user (for telemetry/estimation)
  /// Uses the last N reviews to compute a rolling average
  Future<double> getAverageResponseTime(String userId, {int windowSize = 50}) async {
    final logs = await (_db.select(_db.reviewLogs)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm.desc(t.reviewedAt)])
          ..limit(windowSize))
        .get();

    if (logs.isEmpty) {
      return 15000.0; // Default 15 seconds in ms
    }

    final total = logs.fold<int>(0, (sum, log) => sum + log.responseTimeMs);
    return total / logs.length;
  }

  /// Get review count for a user
  Future<int> getReviewCount(String userId) async {
    final logs = await (_db.select(_db.reviewLogs)
          ..where((t) => t.userId.equals(userId)))
        .get();
    return logs.length;
  }

  /// Get recent reviews for a user (for display/analytics)
  Future<List<ReviewLog>> getRecentReviews(String userId, {int limit = 20}) {
    return (_db.select(_db.reviewLogs)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm.desc(t.reviewedAt)])
          ..limit(limit))
        .get();
  }

  /// Get logs pending sync
  Future<List<ReviewLog>> getPendingSync() {
    return (_db.select(_db.reviewLogs)
          ..where((t) => t.isPendingSync.equals(true)))
        .get();
  }

  /// Mark log as synced
  Future<void> markSynced(String id) async {
    await (_db.update(_db.reviewLogs)..where((t) => t.id.equals(id)))
        .write(const ReviewLogsCompanion(
      isPendingSync: Value(false),
    ));
  }

  /// Compute accuracy rate for a session (fraction of reviews rated Good/Easy)
  Future<double?> computeSessionAccuracy(String sessionId) async {
    final logs = await getBySession(sessionId);
    if (logs.isEmpty) return null;

    final goodOrEasy = logs.where((l) => l.rating >= 3).length;
    return goodOrEasy / logs.length;
  }

  /// Compute average response time for a session
  Future<int?> computeSessionAvgResponseTime(String sessionId) async {
    final logs = await getBySession(sessionId);
    if (logs.isEmpty) return null;

    final total = logs.fold<int>(0, (sum, log) => sum + log.responseTimeMs);
    return (total / logs.length).round();
  }
}
