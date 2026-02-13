import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/domain/services/response_time_rating.dart';
import 'package:mastery/domain/services/srs_scheduler.dart';

void main() {
  group('ResponseTimeRating', () {
    group('default thresholds (3000/8000)', () {
      const rating = ResponseTimeRating();

      test('incorrect → again regardless of response time', () {
        expect(
          rating.rate(5000, isCorrect: false),
          ReviewRating.again,
        );
      });

      test('incorrect with fast time → still again', () {
        expect(
          rating.rate(1000, isCorrect: false),
          ReviewRating.again,
        );
      });

      test('correct under 3s → easy', () {
        expect(
          rating.rate(2000, isCorrect: true),
          ReviewRating.easy,
        );
      });

      test('correct at exactly 3s → good (boundary)', () {
        // 3000 is NOT < 3000, so it falls through to good
        expect(
          rating.rate(3000, isCorrect: true),
          ReviewRating.good,
        );
      });

      test('correct between 3-8s → good', () {
        expect(
          rating.rate(5000, isCorrect: true),
          ReviewRating.good,
        );
      });

      test('correct at exactly 8s → good (boundary, not hard)', () {
        // 8000 is NOT > 8000, so it stays good
        expect(
          rating.rate(8000, isCorrect: true),
          ReviewRating.good,
        );
      });

      test('correct over 8s → hard', () {
        expect(
          rating.rate(9000, isCorrect: true),
          ReviewRating.hard,
        );
      });

      test('correct at 0ms → easy', () {
        expect(
          rating.rate(0, isCorrect: true),
          ReviewRating.easy,
        );
      });

      test('correct at very slow 30s → hard', () {
        expect(
          rating.rate(30000, isCorrect: true),
          ReviewRating.hard,
        );
      });
    });

    group('custom thresholds', () {
      test('custom fast=2000 slow=5000 maps correctly', () {
        const rating = ResponseTimeRating(
          fastThresholdMs: 2000,
          slowThresholdMs: 5000,
        );

        expect(rating.rate(1000, isCorrect: true), ReviewRating.easy);
        expect(rating.rate(3000, isCorrect: true), ReviewRating.good);
        expect(rating.rate(6000, isCorrect: true), ReviewRating.hard);
        expect(rating.rate(1000, isCorrect: false), ReviewRating.again);
      });

      test('custom thresholds with boundary values', () {
        const rating = ResponseTimeRating(
          fastThresholdMs: 2000,
          slowThresholdMs: 5000,
        );

        // At exactly fast threshold → good (not easy)
        expect(rating.rate(2000, isCorrect: true), ReviewRating.good);
        // At exactly slow threshold → good (not hard)
        expect(rating.rate(5000, isCorrect: true), ReviewRating.good);
      });
    });

    group('edge cases', () {
      test('negative response time treated as fast', () {
        const rating = ResponseTimeRating();
        expect(rating.rate(-100, isCorrect: true), ReviewRating.easy);
      });

      test('default fallback 5000ms → good', () {
        const rating = ResponseTimeRating();
        expect(rating.rate(5000, isCorrect: true), ReviewRating.good);
      });
    });
  });
}
