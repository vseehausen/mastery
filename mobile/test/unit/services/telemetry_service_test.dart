import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/domain/services/telemetry_service.dart';
import 'package:mastery/data/database/database.dart';
import 'package:mastery/data/repositories/review_log_repository.dart';
import '../../helpers/test_helpers.dart';

void main() {
  group('TelemetryService', () {
    late AppDatabase db;
    late ReviewLogRepository reviewLogRepo;
    late TelemetryService telemetryService;

    setUp(() async {
      db = createTestDatabase();
      reviewLogRepo = ReviewLogRepository(db);
      telemetryService = TelemetryService(reviewLogRepo);
    });

    tearDown(() async {
      await db.close();
    });

    group('getEstimatedSecondsPerItem', () {
      test(
        'returns default 15 seconds for new users with no reviews',
        () async {
          final estimate = await telemetryService.getEstimatedSecondsPerItem(
            'new-user',
          );
          expect(estimate, equals(15.0));
        },
      );

      test(
        'computes average from recent review logs when enough data',
        () async {
          // Need at least 10 reviews before telemetry is used
          for (var i = 0; i < 12; i++) {
            // Mix of 10000 and 20000 ms = average 15000 ms = 15 seconds
            final ms = i % 2 == 0 ? 10000 : 20000;
            await _insertReviewLog(db, 'user-1', ms, i);
          }

          final estimate = await telemetryService.getEstimatedSecondsPerItem(
            'user-1',
          );

          // Average of alternating 10 and 20 seconds = 15 seconds
          expect(estimate, closeTo(15.0, 0.5));
        },
      );

      test('returns default when user has fewer than 10 reviews', () async {
        // Insert fewer than minReviewsForTelemetry (10)
        for (var i = 0; i < 5; i++) {
          await _insertReviewLog(db, 'user-1', 5000, i); // 5 seconds each
        }

        final estimate = await telemetryService.getEstimatedSecondsPerItem(
          'user-1',
        );

        // Should return default (15 seconds) since not enough data
        expect(estimate, equals(15.0));
      });
    });
  });
}

/// Helper to insert a review log with a specific response time
Future<void> _insertReviewLog(
  AppDatabase db,
  String userId,
  int responseTimeMs,
  int uniqueIndex,
) async {
  final now = DateTime.now().toUtc();
  final id = '${userId}_$uniqueIndex';

  await db
      .into(db.reviewLogs)
      .insert(
        ReviewLogsCompanion.insert(
          id: id,
          userId: userId,
          learningCardId: 'card-$id',
          rating: 3,
          interactionMode: 0,
          stateBefore: 1,
          stateAfter: 2,
          stabilityBefore: 0.0,
          stabilityAfter: 1.0,
          difficultyBefore: 5.0,
          difficultyAfter: 5.0,
          responseTimeMs: responseTimeMs,
          retrievabilityAtReview: 0.9,
          reviewedAt: now,
        ),
      );
}
