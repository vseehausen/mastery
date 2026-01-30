import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/database.dart';

/// Repository for managing streaks
class StreakRepository {
  StreakRepository(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  /// Get streak for a user (creates with defaults if not exists)
  Future<Streak> get(String userId) async {
    var streak = await (_db.select(_db.streaks)
          ..where((t) => t.userId.equals(userId)))
        .getSingleOrNull();

    streak ??= await _create(userId);

    return streak;
  }

  /// Create a new streak record for a user
  Future<Streak> _create(String userId) async {
    final now = DateTime.now().toUtc();
    final companion = StreaksCompanion.insert(
      id: _uuid.v4(),
      userId: userId,
      createdAt: now,
      updatedAt: now,
    );

    await _db.into(_db.streaks).insert(companion);
    return (await _getById(companion.id.value))!;
  }

  Future<Streak?> _getById(String id) {
    return (_db.select(_db.streaks)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Increment streak (call when session is completed)
  /// Returns the updated streak
  Future<Streak> increment(String userId) async {
    final streak = await get(userId);
    final now = DateTime.now().toUtc();
    final today = DateTime(now.year, now.month, now.day);

    // Check if already incremented today
    if (streak.lastCompletedDate != null) {
      final lastDate = streak.lastCompletedDate!;
      final lastDay =
          DateTime(lastDate.year, lastDate.month, lastDate.day);

      if (lastDay == today) {
        // Already incremented today, do nothing
        return streak;
      }
    }

    final newCount = streak.currentCount + 1;
    final newLongest =
        newCount > streak.longestCount ? newCount : streak.longestCount;

    await (_db.update(_db.streaks)..where((t) => t.userId.equals(userId)))
        .write(StreaksCompanion(
      currentCount: Value(newCount),
      longestCount: Value(newLongest),
      lastCompletedDate: Value(now),
      updatedAt: Value(now),
      isPendingSync: const Value(true),
    ));

    return (await get(userId));
  }

  /// Reset streak to zero (call when user misses a day)
  Future<Streak> reset(String userId) async {
    final now = DateTime.now().toUtc();

    // Ensure streak exists
    await get(userId);

    await (_db.update(_db.streaks)..where((t) => t.userId.equals(userId)))
        .write(StreaksCompanion(
      currentCount: const Value(0),
      updatedAt: Value(now),
      isPendingSync: const Value(true),
    ));

    return (await get(userId));
  }

  /// Check if streak should be reset (missed a day)
  /// Returns true if streak was reset
  Future<bool> checkAndResetIfNeeded(String userId) async {
    final streak = await get(userId);

    if (streak.lastCompletedDate == null) {
      return false; // No streak to reset
    }

    final now = DateTime.now().toUtc();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final lastDate = streak.lastCompletedDate!;
    final lastDay = DateTime(lastDate.year, lastDate.month, lastDate.day);

    // If last completed date is before yesterday, reset streak
    if (lastDay.isBefore(yesterday)) {
      await reset(userId);
      return true;
    }

    return false;
  }

  /// Update longest streak if current exceeds it
  Future<void> updateLongest(String userId) async {
    final streak = await get(userId);

    if (streak.currentCount > streak.longestCount) {
      final now = DateTime.now().toUtc();
      await (_db.update(_db.streaks)..where((t) => t.userId.equals(userId)))
          .write(StreaksCompanion(
        longestCount: Value(streak.currentCount),
        updatedAt: Value(now),
        isPendingSync: const Value(true),
      ));
    }
  }

  /// Check if user has completed session today
  Future<bool> hasCompletedToday(String userId) async {
    final streak = await get(userId);

    if (streak.lastCompletedDate == null) {
      return false;
    }

    final now = DateTime.now().toUtc();
    final today = DateTime(now.year, now.month, now.day);

    final lastDate = streak.lastCompletedDate!;
    final lastDay = DateTime(lastDate.year, lastDate.month, lastDate.day);

    return lastDay == today;
  }

  /// Get streaks pending sync
  Future<List<Streak>> getPendingSync() {
    return (_db.select(_db.streaks)
          ..where((t) => t.isPendingSync.equals(true)))
        .get();
  }

  /// Mark streak as synced
  Future<void> markSynced(String id) async {
    final now = DateTime.now().toUtc();
    await (_db.update(_db.streaks)..where((t) => t.id.equals(id)))
        .write(StreaksCompanion(
      isPendingSync: const Value(false),
      lastSyncedAt: Value(now),
    ));
  }
}
