import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/database.dart';

/// Intensity level enum values
class Intensity {
  static const int light = 0;
  static const int normal = 1;
  static const int intense = 2;

  /// Get new words per 10 minutes based on intensity
  static int getNewWordsPerTenMinutes(int intensity) {
    switch (intensity) {
      case light:
        return 2;
      case intense:
        return 8;
      case normal:
      default:
        return 5;
    }
  }

  /// Get new word cap based on intensity and time budget
  static int getNewWordCap(int intensity, int timeMinutes) {
    final perTenMinutes = getNewWordsPerTenMinutes(intensity);
    return (timeMinutes ~/ 10) * perTenMinutes;
  }
}

/// Repository for managing user learning preferences
class UserPreferencesRepository {
  UserPreferencesRepository(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  /// Default preference values
  static const defaultDailyTimeTargetMinutes = 10;
  static const defaultTargetRetention = 0.90;
  static const defaultIntensity = Intensity.normal;

  /// Get preferences for a user
  Future<UserLearningPreference?> get(String userId) {
    return (_db.select(
      _db.userLearningPreferences,
    )..where((t) => t.userId.equals(userId))).getSingleOrNull();
  }

  /// Get preferences for a user, creating with defaults if not exists
  Future<UserLearningPreference> getOrCreateWithDefaults(String userId) async {
    var prefs = await get(userId);

    prefs ??= await _createWithDefaults(userId);

    return prefs;
  }

  /// Create preferences with default values
  Future<UserLearningPreference> _createWithDefaults(String userId) async {
    final now = DateTime.now().toUtc();
    final companion = UserLearningPreferencesCompanion.insert(
      id: _uuid.v4(),
      userId: userId,
      createdAt: now,
      updatedAt: now,
    );

    await _db.into(_db.userLearningPreferences).insert(companion);
    return (await get(userId))!;
  }

  /// Update preferences (upsert)
  Future<UserLearningPreference> upsert({
    required String userId,
    int? dailyTimeTargetMinutes,
    double? targetRetention,
    int? intensity,
    bool? newWordSuppressionActive,
  }) async {
    final existing = await get(userId);
    final now = DateTime.now().toUtc();

    if (existing == null) {
      // Create new
      final companion = UserLearningPreferencesCompanion.insert(
        id: _uuid.v4(),
        userId: userId,
        dailyTimeTargetMinutes: Value(
          dailyTimeTargetMinutes ?? defaultDailyTimeTargetMinutes,
        ),
        targetRetention: Value(targetRetention ?? defaultTargetRetention),
        intensity: Value(intensity ?? defaultIntensity),
        newWordSuppressionActive: Value(newWordSuppressionActive ?? false),
        createdAt: now,
        updatedAt: now,
      );

      await _db.into(_db.userLearningPreferences).insert(companion);
    } else {
      // Update existing
      await (_db.update(
        _db.userLearningPreferences,
      )..where((t) => t.userId.equals(userId))).write(
        UserLearningPreferencesCompanion(
          dailyTimeTargetMinutes: dailyTimeTargetMinutes != null
              ? Value(dailyTimeTargetMinutes)
              : const Value.absent(),
          targetRetention: targetRetention != null
              ? Value(targetRetention)
              : const Value.absent(),
          intensity: intensity != null
              ? Value(intensity)
              : const Value.absent(),
          newWordSuppressionActive: newWordSuppressionActive != null
              ? Value(newWordSuppressionActive)
              : const Value.absent(),
          updatedAt: Value(now),
          isPendingSync: const Value(true),
        ),
      );
    }

    return (await get(userId))!;
  }

  /// Update daily time target
  Future<UserLearningPreference> updateDailyTimeTarget(
    String userId,
    int minutes,
  ) async {
    // Clamp to valid range
    final clampedMinutes = minutes.clamp(1, 60);
    return upsert(userId: userId, dailyTimeTargetMinutes: clampedMinutes);
  }

  /// Update target retention
  Future<UserLearningPreference> updateTargetRetention(
    String userId,
    double retention,
  ) async {
    // Clamp to valid range
    final clampedRetention = retention.clamp(0.85, 0.95);
    return upsert(userId: userId, targetRetention: clampedRetention);
  }

  /// Update intensity
  Future<UserLearningPreference> updateIntensity(
    String userId,
    int intensity,
  ) async {
    // Clamp to valid range
    final clampedIntensity = intensity.clamp(0, 2);
    return upsert(userId: userId, intensity: clampedIntensity);
  }

  /// Update new word suppression state (for hysteresis)
  Future<UserLearningPreference> updateNewWordSuppression(
    String userId,
    bool suppressed,
  ) async {
    return upsert(userId: userId, newWordSuppressionActive: suppressed);
  }

  /// Update native language code
  Future<UserLearningPreference> updateNativeLanguageCode(
    String userId,
    String languageCode,
  ) async {
    final existing = await getOrCreateWithDefaults(userId);
    final now = DateTime.now().toUtc();

    await (_db.update(
      _db.userLearningPreferences,
    )..where((t) => t.userId.equals(userId))).write(
      UserLearningPreferencesCompanion(
        nativeLanguageCode: Value(languageCode),
        updatedAt: Value(now),
        isPendingSync: const Value(true),
      ),
    );

    return (await get(userId)) ?? existing;
  }

  /// Update meaning display mode ('native', 'english', 'both')
  Future<UserLearningPreference> updateMeaningDisplayMode(
    String userId,
    String displayMode,
  ) async {
    final existing = await getOrCreateWithDefaults(userId);
    final now = DateTime.now().toUtc();

    await (_db.update(
      _db.userLearningPreferences,
    )..where((t) => t.userId.equals(userId))).write(
      UserLearningPreferencesCompanion(
        meaningDisplayMode: Value(displayMode),
        updatedAt: Value(now),
        isPendingSync: const Value(true),
      ),
    );

    return (await get(userId)) ?? existing;
  }

  /// Get preferences pending sync
  Future<List<UserLearningPreference>> getPendingSync() {
    return (_db.select(
      _db.userLearningPreferences,
    )..where((t) => t.isPendingSync.equals(true))).get();
  }

  /// Mark preferences as synced
  Future<void> markSynced(String id) async {
    final now = DateTime.now().toUtc();
    await (_db.update(
      _db.userLearningPreferences,
    )..where((t) => t.id.equals(id))).write(
      UserLearningPreferencesCompanion(
        isPendingSync: const Value(false),
        lastSyncedAt: Value(now),
      ),
    );
  }
}
