import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/data/database/database.dart';
import 'package:mastery/data/repositories/review_log_repository.dart';
import 'package:mastery/data/repositories/session_repository.dart';
import '../../helpers/test_helpers.dart';

void main() {
  group('SessionRepository', () {
    late AppDatabase db;
    late SessionRepository repository;
    late ReviewLogRepository reviewLogRepository;

    setUp(() async {
      db = createTestDatabase();
      reviewLogRepository = ReviewLogRepository(db);
      repository = SessionRepository(db, reviewLogRepository);
    });

    tearDown(() async {
      await db.close();
    });

    group('create', () {
      test('creates a new session with provided values', () async {
        final session = await repository.create(
          userId: 'user-1',
          plannedMinutes: 10,
        );

        expect(session.id, isNotEmpty);
        expect(session.userId, equals('user-1'));
        expect(session.plannedMinutes, equals(10));
        expect(session.elapsedSeconds, equals(0));
        expect(session.bonusSeconds, equals(0));
        expect(session.outcome, equals(SessionOutcome.inProgress));
      });

      test('sets default expiresAt to end of day', () async {
        final session = await repository.create(
          userId: 'user-1',
          plannedMinutes: 10,
        );

        // expiresAt should be at end of day (23:59:59 local time converted to UTC)
        // The stored value is in UTC, so we check it represents end-of-day
        expect(session.expiresAt.minute, equals(59));
        expect(session.expiresAt.second, equals(59));
        // The hour depends on timezone offset, so we just verify it's later today
        expect(
          session.expiresAt.isAfter(DateTime.now().toUtc()),
          isTrue,
        );
      });

      test('uses custom expiresAt when provided', () async {
        final customExpiry = DateTime.now().add(const Duration(hours: 2)).toUtc();
        final session = await repository.create(
          userId: 'user-1',
          plannedMinutes: 10,
          expiresAt: customExpiry,
        );

        expect(session.expiresAt.hour, equals(customExpiry.hour));
      });
    });

    group('getById', () {
      test('returns session when it exists', () async {
        final created = await repository.create(
          userId: 'user-1',
          plannedMinutes: 10,
        );

        final retrieved = await repository.getById(created.id);

        expect(retrieved, isNotNull);
        expect(retrieved!.id, equals(created.id));
      });

      test('returns null when session does not exist', () async {
        final retrieved = await repository.getById('non-existent-id');
        expect(retrieved, isNull);
      });
    });

    group('getActiveSession', () {
      test('returns active in-progress session', () async {
        final session = await repository.create(
          userId: 'user-1',
          plannedMinutes: 10,
        );

        final active = await repository.getActiveSession('user-1');

        expect(active, isNotNull);
        expect(active!.id, equals(session.id));
      });

      test('returns null when no active session exists', () async {
        final active = await repository.getActiveSession('user-1');
        expect(active, isNull);
      });

      test('returns null for completed sessions', () async {
        final session = await repository.create(
          userId: 'user-1',
          plannedMinutes: 10,
        );

        await repository.endSession(
          sessionId: session.id,
          outcome: SessionOutcome.complete,
        );

        final active = await repository.getActiveSession('user-1');
        expect(active, isNull);
      });
    });

    group('hasCompletedToday', () {
      test('returns true when session completed today', () async {
        final session = await repository.create(
          userId: 'user-1',
          plannedMinutes: 10,
        );

        await repository.endSession(
          sessionId: session.id,
          outcome: SessionOutcome.complete,
        );

        final hasCompleted = await repository.hasCompletedToday('user-1');
        expect(hasCompleted, isTrue);
      });

      test('returns false when no session completed today', () async {
        final hasCompleted = await repository.hasCompletedToday('user-1');
        expect(hasCompleted, isFalse);
      });

      test('returns false for partial sessions', () async {
        final session = await repository.create(
          userId: 'user-1',
          plannedMinutes: 10,
        );

        await repository.endSession(
          sessionId: session.id,
          outcome: SessionOutcome.partial,
        );

        final hasCompleted = await repository.hasCompletedToday('user-1');
        expect(hasCompleted, isFalse);
      });
    });

    group('updateProgress', () {
      test('updates session progress fields', () async {
        final session = await repository.create(
          userId: 'user-1',
          plannedMinutes: 10,
        );

        final updated = await repository.updateProgress(
          sessionId: session.id,
          elapsedSeconds: 120,
          itemsPresented: 5,
          itemsCompleted: 4,
          newWordsPresented: 2,
          reviewsPresented: 3,
        );

        expect(updated.elapsedSeconds, equals(120));
        expect(updated.itemsPresented, equals(5));
        expect(updated.itemsCompleted, equals(4));
        expect(updated.newWordsPresented, equals(2));
        expect(updated.reviewsPresented, equals(3));
        expect(updated.isPendingSync, isTrue);
      });
    });

    group('addBonusTime', () {
      test('adds bonus seconds to session', () async {
        final session = await repository.create(
          userId: 'user-1',
          plannedMinutes: 10,
        );

        final updated = await repository.addBonusTime(
          sessionId: session.id,
          bonusSeconds: 120,
        );

        expect(updated.bonusSeconds, equals(120));
        expect(updated.outcome, equals(SessionOutcome.inProgress));
      });

      test('accumulates bonus time on multiple calls', () async {
        final session = await repository.create(
          userId: 'user-1',
          plannedMinutes: 10,
        );

        await repository.addBonusTime(sessionId: session.id, bonusSeconds: 120);
        final updated = await repository.addBonusTime(
          sessionId: session.id,
          bonusSeconds: 120,
        );

        expect(updated.bonusSeconds, equals(240));
      });
    });

    group('endSession', () {
      test('sets outcome and computes aggregates', () async {
        final session = await repository.create(
          userId: 'user-1',
          plannedMinutes: 10,
        );

        final ended = await repository.endSession(
          sessionId: session.id,
          outcome: SessionOutcome.complete,
        );

        expect(ended.outcome, equals(SessionOutcome.complete));
        expect(ended.isPendingSync, isTrue);
      });

      test('sets partial outcome correctly', () async {
        final session = await repository.create(
          userId: 'user-1',
          plannedMinutes: 10,
        );

        final ended = await repository.endSession(
          sessionId: session.id,
          outcome: SessionOutcome.partial,
        );

        expect(ended.outcome, equals(SessionOutcome.partial));
      });
    });

    group('expireStaleSessions', () {
      test('marks expired sessions as expired', () async {
        // Create a session with past expiry
        final pastExpiry = DateTime.now().subtract(const Duration(hours: 1)).toUtc();
        final session = await repository.create(
          userId: 'user-1',
          plannedMinutes: 10,
          expiresAt: pastExpiry,
        );

        final expiredCount = await repository.expireStaleSessions('user-1');

        expect(expiredCount, equals(1));

        final updatedSession = await repository.getById(session.id);
        expect(updatedSession!.outcome, equals(SessionOutcome.expired));
      });

      test('does not expire active sessions', () async {
        await repository.create(
          userId: 'user-1',
          plannedMinutes: 10,
        );

        final expiredCount = await repository.expireStaleSessions('user-1');

        expect(expiredCount, equals(0));
      });
    });

    group('getRecentSessions', () {
      test('returns sessions ordered by startedAt descending', () async {
        await repository.create(userId: 'user-1', plannedMinutes: 5);
        await Future<void>.delayed(const Duration(milliseconds: 10));
        await repository.create(userId: 'user-1', plannedMinutes: 10);

        final sessions = await repository.getRecentSessions('user-1');

        expect(sessions.length, equals(2));
        expect(sessions.first.plannedMinutes, equals(10)); // Most recent first
      });

      test('respects limit parameter', () async {
        for (var i = 0; i < 5; i++) {
          await repository.create(userId: 'user-1', plannedMinutes: 10);
        }

        final sessions = await repository.getRecentSessions('user-1', limit: 3);

        expect(sessions.length, equals(3));
      });
    });

    group('getPendingSync', () {
      test('returns sessions with isPendingSync=true', () async {
        final session = await repository.create(
          userId: 'user-1',
          plannedMinutes: 10,
        );

        // Update to set pending sync
        await repository.updateProgress(
          sessionId: session.id,
          elapsedSeconds: 60,
          itemsPresented: 1,
          itemsCompleted: 1,
          newWordsPresented: 0,
          reviewsPresented: 1,
        );

        final pendingSessions = await repository.getPendingSync();

        expect(pendingSessions.length, equals(1));
        expect(pendingSessions.first.isPendingSync, isTrue);
      });
    });

    group('markSynced', () {
      test('clears pending sync flag', () async {
        final session = await repository.create(
          userId: 'user-1',
          plannedMinutes: 10,
        );

        await repository.updateProgress(
          sessionId: session.id,
          elapsedSeconds: 60,
          itemsPresented: 1,
          itemsCompleted: 1,
          newWordsPresented: 0,
          reviewsPresented: 1,
        );

        await repository.markSynced(session.id);

        final synced = await repository.getById(session.id);
        expect(synced!.isPendingSync, isFalse);
      });
    });

    group('getRemainingSeconds', () {
      test('calculates remaining time correctly', () async {
        final session = await repository.create(
          userId: 'user-1',
          plannedMinutes: 10,
        );

        // Update with some elapsed time
        final updated = await repository.updateProgress(
          sessionId: session.id,
          elapsedSeconds: 300, // 5 minutes elapsed
          itemsPresented: 10,
          itemsCompleted: 10,
          newWordsPresented: 2,
          reviewsPresented: 8,
        );

        final remaining = repository.getRemainingSeconds(updated);

        // 10 minutes = 600 seconds, 300 elapsed = 300 remaining
        expect(remaining, equals(300));
      });

      test('includes bonus seconds in calculation', () async {
        final session = await repository.create(
          userId: 'user-1',
          plannedMinutes: 10,
        );

        await repository.addBonusTime(sessionId: session.id, bonusSeconds: 120);
        final updated = await repository.updateProgress(
          sessionId: session.id,
          elapsedSeconds: 600, // 10 minutes elapsed (original time)
          itemsPresented: 20,
          itemsCompleted: 20,
          newWordsPresented: 5,
          reviewsPresented: 15,
        );

        final remaining = repository.getRemainingSeconds(updated);

        // 600 (planned) + 120 (bonus) - 600 (elapsed) = 120
        expect(remaining, equals(120));
      });

      test('returns 0 when time exceeded', () async {
        final session = await repository.create(
          userId: 'user-1',
          plannedMinutes: 10,
        );

        final updated = await repository.updateProgress(
          sessionId: session.id,
          elapsedSeconds: 700, // More than planned
          itemsPresented: 25,
          itemsCompleted: 25,
          newWordsPresented: 5,
          reviewsPresented: 20,
        );

        final remaining = repository.getRemainingSeconds(updated);

        expect(remaining, equals(0));
      });
    });
  });
}
