import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/data/database/database.dart';
import 'package:mastery/data/repositories/streak_repository.dart';
import '../../helpers/test_helpers.dart';

void main() {
  group('StreakRepository', () {
    late AppDatabase db;
    late StreakRepository repository;

    setUp(() async {
      db = createTestDatabase();
      repository = StreakRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    group('get', () {
      test('creates streak with defaults if not exists', () async {
        final streak = await repository.get('user-1');

        expect(streak.userId, equals('user-1'));
        expect(streak.currentCount, equals(0));
        expect(streak.longestCount, equals(0));
        expect(streak.lastCompletedDate, isNull);
      });

      test('returns existing streak for user', () async {
        // First call creates the streak
        await repository.get('user-1');

        // Increment the streak
        await repository.increment('user-1');

        // Second call returns the existing streak
        final streak = await repository.get('user-1');

        expect(streak.currentCount, equals(1));
      });
    });

    group('increment', () {
      test('increments current count by 1', () async {
        await repository.get('user-1'); // Create streak

        final updated = await repository.increment('user-1');

        expect(updated.currentCount, equals(1));
        expect(updated.lastCompletedDate, isNotNull);
      });

      test('does not increment if already incremented today', () async {
        await repository.get('user-1');
        await repository.increment('user-1');
        final secondIncrement = await repository.increment('user-1');

        expect(secondIncrement.currentCount, equals(1)); // Still 1
      });

      test('updates longest count when current exceeds it', () async {
        await repository.get('user-1');

        final updated = await repository.increment('user-1');

        expect(updated.currentCount, equals(1));
        expect(updated.longestCount, equals(1));
      });

      test('sets isPendingSync to true', () async {
        await repository.get('user-1');
        final updated = await repository.increment('user-1');

        expect(updated.isPendingSync, isTrue);
      });
    });

    group('reset', () {
      test('resets current count to 0', () async {
        await repository.get('user-1');
        await repository.increment('user-1');

        final reset = await repository.reset('user-1');

        expect(reset.currentCount, equals(0));
      });

      test('preserves longest count', () async {
        await repository.get('user-1');
        await repository.increment('user-1');

        final beforeReset = await repository.get('user-1');
        final longestBefore = beforeReset.longestCount;

        final reset = await repository.reset('user-1');

        expect(reset.longestCount, equals(longestBefore));
      });

      test('sets isPendingSync to true', () async {
        await repository.get('user-1');
        final reset = await repository.reset('user-1');

        expect(reset.isPendingSync, isTrue);
      });
    });

    group('checkAndResetIfNeeded', () {
      test('returns false for new streak (no lastCompletedDate)', () async {
        await repository.get('user-1');

        final wasReset = await repository.checkAndResetIfNeeded('user-1');

        expect(wasReset, isFalse);
      });

      test('does not reset if completed today', () async {
        await repository.get('user-1');
        await repository.increment('user-1');

        final wasReset = await repository.checkAndResetIfNeeded('user-1');

        expect(wasReset, isFalse);

        final streak = await repository.get('user-1');
        expect(streak.currentCount, equals(1));
      });

      // Note: Testing "yesterday" and "before yesterday" scenarios requires
      // manipulating lastCompletedDate which is set automatically.
      // In production, these would be integration tests with time manipulation.
    });

    group('updateLongest', () {
      test('updates longest when current exceeds it', () async {
        // Directly manipulate to test updateLongest
        await repository.get('user-1');
        await repository.increment('user-1');

        await repository.updateLongest('user-1');

        final streak = await repository.get('user-1');
        expect(streak.longestCount, greaterThanOrEqualTo(streak.currentCount));
      });

      test('does not update if current does not exceed longest', () async {
        await repository.get('user-1');

        await repository.updateLongest('user-1');

        final streak = await repository.get('user-1');
        expect(streak.longestCount, equals(0));
      });
    });

    group('hasCompletedToday', () {
      test('returns false when never completed', () async {
        await repository.get('user-1');

        final hasCompleted = await repository.hasCompletedToday('user-1');

        expect(hasCompleted, isFalse);
      });

      test('returns true after completing today', () async {
        await repository.get('user-1');
        await repository.increment('user-1');

        final hasCompleted = await repository.hasCompletedToday('user-1');

        expect(hasCompleted, isTrue);
      });
    });

    group('getPendingSync', () {
      test('returns streaks with isPendingSync=true', () async {
        await repository.get('user-1');
        await repository.increment('user-1');

        final pendingStreaks = await repository.getPendingSync();

        expect(pendingStreaks.length, equals(1));
        expect(pendingStreaks.first.isPendingSync, isTrue);
      });

      test('returns empty list when no pending sync', () async {
        // Create and sync a streak
        await repository.get('user-1');
        final streak = await repository.get('user-1');
        await repository.markSynced(streak.id);

        final pendingStreaks = await repository.getPendingSync();

        expect(pendingStreaks, isEmpty);
      });
    });

    group('markSynced', () {
      test('clears pending sync flag and sets synced timestamp', () async {
        await repository.get('user-1');
        await repository.increment('user-1');

        final streak = await repository.get('user-1');
        await repository.markSynced(streak.id);

        final synced = await repository.get('user-1');
        expect(synced.isPendingSync, isFalse);
        expect(synced.lastSyncedAt, isNotNull);
      });
    });
  });
}
